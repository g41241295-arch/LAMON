import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/konsultasi/chat_dokter_screen.dart';
import 'notification_service.dart';

/// Service untuk mengelola Firebase Cloud Messaging (FCM) pada Android:
/// - Request permission setelah user login (Android 13+)
/// - Pendaftaran token FCM ke `users/{uid}.fcmTokens`
/// - Pembersihan token saat logout (arrayRemove -> deleteToken -> signOut)
/// - Penanganan tap notifikasi di background & terminated (routing ke ChatDokterScreen)
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _handlersConfigured = false;

  /// Memeriksa apakah platform saat ini didukung (hanya Android, bukan Web).
  bool get _isAndroidSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Menginisialisasi handler klik notifikasi (getInitialMessage & onMessageOpenedApp).
  void setupNotificationClickHandlers() {
    if (!_isAndroidSupported || _handlersConfigured) return;
    _handlersConfigured = true;

    // 1. Saat aplikasi dibuka dari background (onMessageOpenedApp)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FcmService] onMessageOpenedApp triggered: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // 2. Saat aplikasi dibuka dari kondisi terminated (getInitialMessage)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('[FcmService] getInitialMessage triggered: ${message.data}');
        // Beri sedikit jeda agar initial screen & auth selesai terbangun
        Future.delayed(const Duration(milliseconds: 600), () {
          _handleNotificationTap(message.data);
        });
      }
    }).catchError((err) {
      debugPrint('[FcmService] getInitialMessage error: $err');
    });
  }

  /// Panggil method ini SETELAH user berhasil login.
  /// Meminta izin notifikasi, mengambil token FCM, dan menyimpannya ke `users/{uid}.fcmTokens`.
  Future<void> setupForLoggedInUser(String uid) async {
    if (!_isAndroidSupported) return;

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request notification permission (Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FcmService] Notification permission status: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FcmService] Izin notifikasi ditolak oleh pengguna.');
        return;
      }

      // 2. Ambil token FCM perangkat ini
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;
        await _saveTokenToFirestore(uid, token);
      }

      // 3. Dengarkan onTokenRefresh
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[FcmService] Token FCM diperbarui.');
        final oldToken = _currentToken;
        _currentToken = newToken;
        await _replaceTokenInFirestore(uid, oldToken: oldToken, newToken: newToken);
      });
    } catch (e) {
      debugPrint('[FcmService] setupForLoggedInUser error (non-fatal): $e');
    }
  }

  /// Logout aman (URUTAN WAJIB):
  /// (a) arrayRemove token dari users/{uid}.fcmTokens (butuh masih login)
  /// (b) deleteToken FCM
  /// (c) baru signOut di sisi pemanggil
  Future<void> cleanUpBeforeLogout(String uid) async {
    if (!_isAndroidSupported) return;

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    final token = _currentToken ?? await FirebaseMessaging.instance.getToken().catchError((_) => null);
    if (token != null && token.isNotEmpty) {
      try {
        debugPrint('[FcmService] Menghapus token dari users/$uid...');
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        }).timeout(const Duration(seconds: 4));
        debugPrint('[FcmService] Token berhasil dihapus dari Firestore.');
      } catch (e) {
        debugPrint('[FcmService] Gagal menghapus token Firestore sebelum logout: $e');
      }
    }

    try {
      await FirebaseMessaging.instance.deleteToken().timeout(const Duration(seconds: 3));
      debugPrint('[FcmService] Device token deleted.');
    } catch (e) {
      debugPrint('[FcmService] Gagal deleteToken: $e');
    }

    _currentToken = null;
  }

  Future<void> _saveTokenToFirestore(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
      debugPrint('[FcmService] Token FCM berhasil disimpan ke users/$uid.');
    } catch (e) {
      debugPrint('[FcmService] Gagal menyimpan token ke Firestore: $e');
    }
  }

  Future<void> _replaceTokenInFirestore(
    String uid, {
    String? oldToken,
    required String newToken,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      if (oldToken != null && oldToken.isNotEmpty) {
        await docRef.update({
          'fcmTokens': FieldValue.arrayRemove([oldToken]),
        });
      }
      await docRef.set({
        'fcmTokens': FieldValue.arrayUnion([newToken]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FcmService] Gagal update token refresh di Firestore: $e');
    }
  }

  /// Menangani aksi tap notifikasi chat saat app di background atau terminated.
  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final consultationId = data['consultationId']?.toString().trim();
    final patientUid = data['patientUid']?.toString().trim();
    final recipientRole = data['recipientRole']?.toString().trim().toLowerCase();

    if (consultationId == null || consultationId.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('[FcmService] Tap notifikasi diabaikan: belum login.');
      return;
    }

    try {
      // Ambil data profil pengguna yang sedang login untuk validasi kepemilikan notifikasi
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        debugPrint('[FcmService] User document tidak ditemukan.');
        return;
      }

      final userData = userDoc.data()!;
      final userRole = (userData['role']?.toString() ?? '').toLowerCase();
      final doctorId = (userData['doctorId'] ?? userData['doctor_id'])?.toString().trim();
      final isDoctor = userRole == 'doctor' || userRole == 'dokter' || (doctorId != null && doctorId.isNotEmpty);

      // Cek apakah akun yang sedang login adalah penerima notifikasi yang sah
      bool isAuthorizedRecipient = false;
      if (recipientRole == 'doctor') {
        isAuthorizedRecipient = isDoctor;
      } else if (recipientRole == 'patient') {
        isAuthorizedRecipient = !isDoctor && currentUser.uid == patientUid;
      } else {
        // Fallback jika recipientRole tidak disertakan: cek kepemilikan
        if (currentUser.uid == patientUid) {
          isAuthorizedRecipient = true;
        } else if (isDoctor) {
          isAuthorizedRecipient = true;
        }
      }

      final navState = ChatInAppNotificationService.navigatorKey.currentState;
      if (navState == null) {
        debugPrint('[FcmService] NavigatorState belum tersedia.');
        return;
      }

      if (!isAuthorizedRecipient) {
        debugPrint('[FcmService] Akun login (${currentUser.uid}) BUKAN penerima notifikasi ini. Navigasi chat dicegah.');
        return;
      }

      debugPrint('[FcmService] Membuka ChatDokterScreen untuk konsultasi: $consultationId (isDoctor: $isDoctor)');
      navState.push(
        MaterialPageRoute(
          builder: (_) => ChatDokterScreen(
            consultationId: consultationId,
            isDoctor: isDoctor,
            patientUid: patientUid,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[FcmService] Error navigating to chat from notification: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pengingat_jam_makan/services/meal_reminder_service.dart';
import '../providers/app_state.dart';
import '../services/consultation_retention_service.dart';
import '../services/fcm_service.dart';
import 'biometric_gate.dart';

class BiometricAuthResult {
  final bool success;
  final bool noDeviceSecurity;
  final String? errorMessage;

  const BiometricAuthResult({
    required this.success,
    this.noDeviceSecurity = false,
    this.errorMessage,
  });
}

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  static String enabledKey(String uid) => 'biometric_login_enabled_$uid';
  static String promptShownKey(String uid) => 'biometric_prompt_shown_$uid';

  Future<bool> isBiometricEnabled(String uid) async {
    if (uid.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey(uid)) ?? false;
  }

  Future<void> setBiometricEnabled(String uid, bool enabled) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey(uid), enabled);
    await prefs.setBool(promptShownKey(uid), true);
  }

  /// Menghapus KEDUA flag biometrik saat logout eksplisit agar pasien
  /// ditawari kembali pada login berikutnya.
  Future<void> clearBiometricForUser(String uid) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(enabledKey(uid));
    await prefs.remove(promptShownKey(uid));
  }

  /// Mengecek apakah perangkat mendukung sidik jari / biometrik terdaftar.
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck && !isSupported) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (e) {
      debugPrint('[BiometricService] Gagal cek enrolled biometrics: $e');
      return false;
    }
  }

  /// Mengecek apakah perangkat minimal memiliki kunci layar (PIN/pola/sandi) atau biometrik.
  Future<bool> hasAnyDeviceSecurity() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (isSupported) return true;
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } catch (e) {
      debugPrint('[BiometricService] Gagal cek device security: $e');
      return false;
    }
  }

  /// Menampilkan dialog "Aktifkan masuk dengan sidik jari?" setelah login pasien berhasil
  /// apabila perangkat mendukung biometrik & sidik jari terdaftar dan pengguna belum pernah ditanya.
  Future<void> maybeOfferBiometricAfterLogin(
    BuildContext context, {
    required String uid,
  }) async {
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool(promptShownKey(uid)) ?? false;
      final alreadyEnabled = prefs.getBool(enabledKey(uid)) ?? false;
      if (alreadyShown || alreadyEnabled) return;

      final enrolled = await hasEnrolledBiometrics();
      if (!enrolled) return;

      if (!context.mounted) return;
      final activate = await showEnableBiometricDialog(context);
      await setBiometricEnabled(uid, activate == true);
    } catch (e) {
      debugPrint('[BiometricService] Error saat menawarkan biometrik: $e');
    }
  }

  /// Menjalankan prompt autentikasi biometrik dengan fallback ke PIN/pola/sandi perangkat
  /// (biometricOnly: false). Menangani semua exception dengan aman tanpa crash.
  Future<BiometricAuthResult> authenticateUser({
    String reason = 'Gunakan sidik jari untuk masuk ke akun LAMON Anda',
  }) async {
    try {
      final hasSecurity = await hasAnyDeviceSecurity();
      if (!hasSecurity) {
        return const BiometricAuthResult(
          success: false,
          noDeviceSecurity: true,
        );
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        return const BiometricAuthResult(success: true);
      }
      return const BiometricAuthResult(
        success: false,
        errorMessage: 'Verifikasi sidik jari belum berhasil. Silakan coba lagi.',
      );
    } on LocalAuthException catch (e) {
      debugPrint('[BiometricService] LocalAuthException (${e.code.name}): ${e.description}');
      switch (e.code) {
        case LocalAuthExceptionCode.noCredentialsSet:
          return const BiometricAuthResult(
            success: false,
            noDeviceSecurity: true,
          );
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          return const BiometricAuthResult(
            success: false,
            errorMessage:
                'Terlalu banyak percobaan gagal. Sensor dikunci sementara, gunakan PIN/kunci layar atau coba beberapa saat lagi.',
          );
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
          return const BiometricAuthResult(
            success: false,
            errorMessage: 'Verifikasi dibatalkan. Ketuk "Coba lagi" untuk melanjutkan.',
          );
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return const BiometricAuthResult(
            success: false,
            errorMessage:
                'Sensor sidik jari tidak tersedia saat ini. Gunakan kunci layar perangkat atau masuk dengan akun lain.',
          );
        default:
          return const BiometricAuthResult(
            success: false,
            errorMessage: 'Gagal memverifikasi identitas. Silakan coba lagi.',
          );
      }
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] PlatformException (${e.code}): ${e.message}');
      return const BiometricAuthResult(
        success: false,
        errorMessage: 'Verifikasi gagal atau dibatalkan. Silakan coba lagi.',
      );
    } catch (e) {
      debugPrint('[BiometricService] Unexpected error saat autentikasi: $e');
      return const BiometricAuthResult(
        success: false,
        errorMessage: 'Terjadi kendala saat verifikasi. Silakan coba lagi.',
      );
    }
  }

  /// Memulihkan state aplikasi pasien sama persis seperti login normal lalu navigasi.
  void completePatientLoginAndNavigate(
    BuildContext context, {
    required String uid,
    required String userName,
    required String email,
    required bool hasCompletedScreening,
  }) {
    final appState = AppState.of(context);
    appState.loginWithGoogle(userName, email);

    ConsultationRetentionService.instance.resetSession();
    ConsultationRetentionService.instance.runRetentionCleanup(
      uid: uid,
      isDoctor: false,
      doctorId: null,
    );

    if (!hasCompletedScreening) {
      Navigator.pushNamedAndRemoveUntil(context, '/screening/gender', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/beranda', (route) => false);
    }
  }

  /// Logout eksplisit untuk tombol "Masuk dengan akun lain" pada layar kunci biometrik.
  Future<void> performExplicitLogoutAndGoToLogin(
    BuildContext context, {
    required String uid,
  }) async {
    try {
      if (uid.isNotEmpty) {
        await FcmService.instance.cleanUpBeforeLogout(uid);
        await clearBiometricForUser(uid);
      }
      await MealReminderService.instance.cancelAlarmsForLogout();
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('[BiometricService] Error saat logout eksplisit: $e');
    }
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  /// Dipanggil saat splash screen selesai.
  /// Mengembalikan `true` bila navigasi sudah ditangani oleh alur biometrik pasien,
  /// atau `false` bila harus melanjutkan alur lama (navigasi ke `/login` + `signOut`).
  Future<bool> handleSplashNavigation(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final uid = user.uid;
      final biometricEnabled = await isBiometricEnabled(uid);
      if (!context.mounted) return true;
      if (!biometricEnabled) return false;

      final hasSecurity = await hasAnyDeviceSecurity();
      if (!context.mounted) return true;
      if (!hasSecurity) return false;

      // Baca dokumen users/{uid} dengan batas waktu 4 detik; fallback ke cache Firestore.
      DocumentSnapshot<Map<String, dynamic>>? userDoc;
      try {
        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('[BiometricService] Timeout/error baca Firestore server, mencoba cache: $e');
        try {
          userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get(const GetOptions(source: Source.cache));
        } catch (cacheErr) {
          debugPrint('[BiometricService] Gagal membaca cache Firestore: $cacheErr');
        }
      }

      if (!context.mounted) return true;
      if (userDoc == null || !userDoc.exists) return false;

      final data = userDoc.data() ?? {};
      final role = data['role'] as String?;
      final isDoctor = role == 'doctor' || role == 'dokter';
      final isAdmin = role == 'admin';
      final isPatient =
          !isDoctor && !isAdmin && (role == null || role == 'pengguna' || role == 'patient');

      if (!isPatient) return false;

      final email = (data['email']?.toString().trim().isNotEmpty == true)
          ? data['email'].toString().trim()
          : (user.email ?? '');
      String userName = email.isNotEmpty ? email.split('@')[0] : 'Pengguna';
      if (userName.isNotEmpty) {
        userName = userName[0].toUpperCase() + userName.substring(1);
      }
      if (data['nama'] != null && data['nama'].toString().trim().isNotEmpty) {
        userName = data['nama'].toString().trim();
      } else if (data['name'] != null && data['name'].toString().trim().isNotEmpty) {
        userName = data['name'].toString().trim();
      } else if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        userName = user.displayName!.trim();
      }
      final hasCompletedScreening = data['hasCompletedScreening'] == true;

      final authResult = await authenticateUser();
      if (!context.mounted) return true;

      if (authResult.noDeviceSecurity) {
        return false;
      }

      if (authResult.success) {
        completePatientLoginAndNavigate(
          context,
          uid: uid,
          userName: userName,
          email: email,
          hasCompletedScreening: hasCompletedScreening,
        );
        return true;
      }

      // Gagal atau dibatalkan -> tampilkan layar kunci sederhana
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BiometricLockScreen(
            uid: uid,
            userName: userName,
            email: email,
            hasCompletedScreening: hasCompletedScreening,
            initialMessage: authResult.errorMessage,
          ),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[BiometricService] Error di handleSplashNavigation: $e');
      return false;
    }
  }
}

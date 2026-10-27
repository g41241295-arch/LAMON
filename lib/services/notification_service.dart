import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// =============================================================================
// TODO(future-upgrade-blaze): Push Notifications with Firebase Cloud Messaging (FCM)
// =============================================================================
// Arsitektur ChatInAppNotificationService ini dirancang modular dengan interface
// showInAppMessage(...) agar sangat mudah diperluas ke push notifications sungguhan (FCM)
// tanpa merombak logika UI di bagian aplikasi lainnya jika di masa depan project
// di-upgrade ke paket berbayar (Firebase Blaze):
//
// Langkah Upgrade ke FCM (jika akun Blaze tersedia):
// 1. Pasang package `firebase_messaging` di pubspec.yaml.
// 2. Di service ini, tambahkan method `initializeFcm()` untuk requestPermission()
//    dan simpan device registration token ke Firestore: users/{uid}/fcmTokens.
// 3. Teruskan payload `FirebaseMessaging.onMessage` (foreground) langsung ke
//    method `showInAppMessage(...)` yang sudah ada di service ini.
// 4. Tangani `FirebaseMessaging.onMessageOpenedApp` untuk routing ke chat screen.
// 5. Buat Cloud Function di backend yang ter-trigger saat ada message baru di subkoleksi
//    messages, lalu mengirimkan payload FCM ke token penerima.
//
// Saat ini aplikasi menggunakan 100% in-app foreground notification via Firestore
// StreamSubscription real-time yang aman, cepat, dan bekerja penuh di paket gratis (Spark).
// =============================================================================

/// Service notifikasi in-app untuk pesan chat konsultasi.
/// Berjalan penuh di paket Spark (gratis) tanpa Firebase Blaze / Cloud Functions.
class ChatInAppNotificationService {
  ChatInAppNotificationService._();
  static final ChatInAppNotificationService instance =
      ChatInAppNotificationService._();

  /// Global key untuk Navigator agar notifikasi bisa muncul dan bernavigasi dari mana saja.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Global key untuk ScaffoldMessenger (fallback SnackBar).
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// ID konsultasi yang sedang aktif/sedang dibuka layarnya oleh pengguna saat ini.
  /// Jika sedang membuka chat ID ini, banner notifikasi untuk chat tersebut TIDAK akan muncul.
  String? currentActiveConsultationId;

  StreamSubscription? _consultationsSubscription;
  final Map<String, DateTime> _lastKnownMessageTimestamps = {};
  DateTime _serviceStartedAt = DateTime.now();

  OverlayEntry? _currentOverlayEntry;
  Timer? _overlayTimer;

  /// Memulai pemantauan pesan masuk realtime untuk user aktif.
  void startListeningForUser({
    required String uid,
    bool isDoctor = false,
    String? doctorId,
  }) {
    stopListening();
    _serviceStartedAt = DateTime.now();
    _lastKnownMessageTimestamps.clear();

    final FirebaseFirestore db = FirebaseFirestore.instance;

    Stream<QuerySnapshot<Map<String, dynamic>>> stream;
    if (isDoctor && doctorId != null && doctorId.isNotEmpty) {
      stream = db
          .collectionGroup('consultations')
          .where('doctorId', isEqualTo: doctorId)
          .snapshots();
    } else {
      stream = db
          .collection('users')
          .doc(uid)
          .collection('consultations')
          .snapshots();
    }

    _consultationsSubscription = stream.listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final consultationId = doc.id;
        final lastMessageText = (data['lastMessageText'] as String?)?.trim();
        final lastMessageAt = (data['lastMessageAt'] as Timestamp?)?.toDate();
        final lastSenderType = (data['lastMessageSenderType'] as String?)?.trim();

        if (lastMessageText == null ||
            lastMessageText.isEmpty ||
            lastMessageAt == null) {
          continue;
        }

        // Cek apakah pesan berasal dari pihak lawan
        final isFromPeer = isDoctor
            ? (lastSenderType == 'patient')
            : (lastSenderType == 'doctor');

        if (!isFromPeer) {
          _lastKnownMessageTimestamps[consultationId] = lastMessageAt;
          continue;
        }

        // Cek timestamp terakhir yang diketahui
        final previousTimestamp = _lastKnownMessageTimestamps[consultationId];
        _lastKnownMessageTimestamps[consultationId] = lastMessageAt;

        // Hanya tampilkan notifikasi jika:
        // 1. Pesan dikirim setelah service ini mulai mendengarkan (atau lebih baru dari data sebelumnya)
        // 2. Chat ini sedang TIDAK dibuka oleh user saat ini
        final isNewerThanStart = lastMessageAt.isAfter(_serviceStartedAt);
        final isNewerThanPrevious = previousTimestamp != null &&
            lastMessageAt.isAfter(previousTimestamp);

        if ((isNewerThanStart || isNewerThanPrevious) &&
            currentActiveConsultationId != consultationId) {
          final peerName = isDoctor
              ? ((data['patientName'] as String?)?.trim().isNotEmpty == true
                  ? (data['patientName'] as String).trim()
                  : 'Pasien')
              : ((data['doctorName'] as String?)?.trim().isNotEmpty == true
                  ? (data['doctorName'] as String).trim()
                  : 'Dokter');

          final patientUid = data['patientUid'] as String? ?? '';

          showInAppMessage(
            title: 'Pesan baru dari $peerName',
            message: lastMessageText,
            onTap: () {
              final nav = navigatorKey.currentState;
              if (nav != null) {
                nav.pushNamed(
                  '/konsultasi/chat/$consultationId',
                  arguments: {
                    'isDoctor': isDoctor,
                    'patientUid': patientUid,
                  },
                );
              }
            },
          );
        }
      }
    }, onError: (e) {
      debugPrint('[ChatNotificationService] Listener error: $e');
    });
  }

  /// Menghentikan pemantauan pesan masuk.
  void stopListening() {
    _consultationsSubscription?.cancel();
    _consultationsSubscription = null;
    _dismissOverlay();
  }

  /// Menampilkan banner notifikasi in-app di bagian atas layar.
  /// Dapat di-tap untuk membuka percakapan secara langsung.
  void showInAppMessage({
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    _dismissOverlay();

    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) {
      // Fallback ke floating SnackBar jika overlay belum siap
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF134563),
          duration: duration,
          action: onTap != null
              ? SnackBarAction(
                  label: 'Buka',
                  textColor: Colors.white,
                  onPressed: onTap,
                )
              : null,
        ),
      );
      return;
    }

    _currentOverlayEntry = OverlayEntry(
      builder: (context) => _TopInAppBanner(
        title: title,
        message: message,
        onTap: () {
          _dismissOverlay();
          onTap?.call();
        },
        onDismiss: _dismissOverlay,
      ),
    );

    overlayState.insert(_currentOverlayEntry!);

    _overlayTimer = Timer(duration, () {
      _dismissOverlay();
    });
  }

  void _dismissOverlay() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }
}

/// Widget banner mengambang halus di bagian atas layar untuk notifikasi in-app.
class _TopInAppBanner extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _TopInAppBanner({
    required this.title,
    required this.message,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_TopInAppBanner> createState() => _TopInAppBannerState();
}

class _TopInAppBannerState extends State<_TopInAppBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _animCtrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () async {
                    await _animCtrl.reverse();
                    widget.onTap();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF134563).withValues(alpha: 0.16),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Ikon balon pesan bergradasi
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF276F8F), AppColors.primary],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Judul & Isi Pesan
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.message,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF556066),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Tombol Tutup
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.neutralGray,
                          ),
                          onPressed: _handleDismiss,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

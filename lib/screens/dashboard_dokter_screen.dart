import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/consultation_model.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';
import '../widgets/app_header_pill.dart';
import 'dokter/doctor_home_tab.dart';
import 'dokter/doctor_messages_tab.dart';
import 'dokter/doctor_profile_tab.dart';

/// Shell Utama Dashboard Dokter (Role Dokter)
/// Beranda menjadi satu-satunya pusat navigasi.
/// Pesan dan Profil dibuka sebagai layar terpisah dengan tombol kembali (tanpa bottom navigation).
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final DoctorService _doctorService = DoctorService();

  DoctorModel? _doctor;
  bool _isLoadingDoctor = true;
  String? _errorMessage;

  StreamSubscription<List<ConsultationModel>>? _consultationsSub;
  StreamSubscription<Map<String, List<String>>>? _scheduleSub;
  StreamSubscription<User?>? _authSub; // Listener authStateChanges

  List<ConsultationModel> _consultations = [];
  Map<String, List<String>> _scheduleMap = {};

  // Guard: uid dokter yang sedang dimuat.
  // Dipakai untuk mendeteksi pergantian akun tanpa restart app.
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    // Dengarkan perubahan auth state. Setiap kali user berubah
    // (logout / login akun lain), state direset total dan data
    // dokter yang benar dimuat ulang dari Firestore.
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    if (!mounted) return;

    if (user == null) {
      // User logout → bersihkan state lama lalu arahkan ke /login
      _resetAllState();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    // Hanya reload jika uid BERUBAH (pergantian akun) atau belum pernah dimuat.
    // Ini mencegah data dokter lama nyangkut saat login akun berbeda.
    if (_currentUid != user.uid) {
      _resetAllState();
      _loadDoctorData(user: user);
    }
  }

  /// Reset SELURUH state dokter ke kondisi kosong.
  /// Dipanggil setiap kali ada pergantian akun agar tidak ada
  /// sisa data sesi dokter sebelumnya.
  void _resetAllState() {
    _consultationsSub?.cancel();
    _consultationsSub = null;
    _scheduleSub?.cancel();
    _scheduleSub = null;

    if (mounted) {
      debugPrint('[HIPOTESIS-3-D] State reset: _doctor set to null, previous _currentUid="$_currentUid"');
      setState(() {
        _doctor = null;
        _consultations = [];
        _scheduleMap = {};
        _isLoadingDoctor = true;
        _errorMessage = null;
        _currentUid = null;
      });
    }
  }

  @override
  void dispose() {
    _consultationsSub?.cancel();
    _scheduleSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDoctorData({User? user}) async {
    final currentUser = user ?? FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }

    // Catat uid yang sedang dimuat — sumber kebenaran tunggal untuk sesi ini.
    final String loadingUid = currentUser.uid;
    debugPrint('[HIPOTESIS-3-A] Resolved currentUser: uid="$loadingUid", email="${currentUser.email}"');

    if (mounted) {
      setState(() {
        _isLoadingDoctor = true;
        _errorMessage = null;
      });
    }

    try {
      // Guard: Pastikan role adalah doctor/dokter, jika bukan alihkan ke /beranda
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(loadingUid)
          .get();

      // Pastikan uid belum berubah selama proses async (antisipasi cepat ganti akun)
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != loadingUid) return;

      if (userDoc.exists) {
        final role = userDoc.data()?['role'] as String?;
        if (role != 'doctor' && role != 'dokter') {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/beranda', (route) => false);
          }
          return;
        }
      }

      // ─── Ambil doctorId dari users/{uid} ─────────────────────────────────────
      // Sumber kebenaran tunggal: field `doctorId` (atau `doctor_id`) di users/{uid}.
      // Di-trim untuk mencegah kegagalan pencarian akibat spasi tak terlihat.
      final rawDoctorId = userDoc.data()?['doctorId'] ?? userDoc.data()?['doctor_id'];
      final doctorId = rawDoctorId?.toString().trim();

      debugPrint('[HIPOTESIS-3-B] Read users/{uid}.doctorId: doctorId="$doctorId" for uid="$loadingUid" (raw="$rawDoctorId")');
      debugPrint('[DoctorAuth] --------------------------------------------------');
      debugPrint('[DoctorAuth] UID dokter login: "$loadingUid"');
      debugPrint('[DoctorAuth] Email dokter login: "${currentUser.email}"');
      debugPrint('[DoctorAuth] Raw doctorId dari users/{uid}: "$rawDoctorId" (${rawDoctorId.runtimeType})');
      debugPrint('[DoctorAuth] Clean doctorId: "$doctorId" (length: ${doctorId?.length ?? 0})');
      debugPrint('[DoctorAuth] --------------------------------------------------');

      DoctorModel? doc;
      String? fetchError;

      if (doctorId != null && doctorId.isNotEmpty) {
        // Ambil LANGSUNG dari doctors/{doctorId} secara strictly by-ID.
        debugPrint('[DoctorAuth] Querying doctors collection by ID: "$doctorId"');
        doc = await _doctorService.fetchById(doctorId);

        if (doc == null) {
          debugPrint('[DoctorAuth] GAGAL: Dokumen "$doctorId" tidak ditemukan di koleksi doctors.');
          fetchError =
              'Data dokter tidak ditemukan untuk akun ini.\n'
              '(doctorId: "$doctorId" tidak ditemukan di koleksi doctors)\n'
              'Silakan hubungi administrator.';
        } else {
          debugPrint('[HIPOTESIS-3-C] Fetched from doctors collection: document.id="${doc.id}", name="${doc.name}"');
          debugPrint('[DoctorAuth] SUKSES: Memuat dokter "${doc.name}" (id: ${doc.id}, spesialisasi: ${doc.specialty})');
        }
      } else {
        // Field doctorId tidak ada / kosong:
        // JANGAN fallback diam-diam ke dokter lain atau sembarang dokumen.
        debugPrint('[DoctorAuth] GAGAL: Field doctorId tidak ditemukan atau kosong di users/$loadingUid.');
        fetchError =
            'Data dokter tidak ditemukan untuk akun ini.\n'
            '(Field doctorId belum diatur pada akun ini)\n'
            'Silakan hubungi administrator.';
      }

      // Cek sekali lagi: uid tidak berubah selama proses fetch dokter
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != loadingUid) return;

      if (fetchError != null || doc == null) {
        setState(() {
          _isLoadingDoctor = false;
          _errorMessage = fetchError ??
              'Akun dokter belum terhubung ke data dokter.\n'
              'Silakan hubungi administrator.';
          _currentUid = loadingUid;
        });
        return;
      }

      debugPrint('[HIPOTESIS-3-D] State update: _doctor set to "${doc.name}" (id: ${doc.id}) for uid="$loadingUid"');
      setState(() {
        _doctor = doc;
        _isLoadingDoctor = false;
        _currentUid = loadingUid;
      });

      _listenConsultations(doc.id);
      _listenSchedule(doc.id);
    } catch (e) {
      if (mounted && FirebaseAuth.instance.currentUser?.uid == loadingUid) {
        setState(() {
          _isLoadingDoctor = false;
          _errorMessage = 'Terjadi kesalahan saat memuat data: $e';
          _currentUid = loadingUid;
        });
      }
    }
  }

  void _listenConsultations(String doctorId) {
    _consultationsSub?.cancel();
    _consultationsSub =
        _doctorService.watchDoctorConsultations(doctorId).listen((list) {
      if (mounted) {
        setState(() {
          _consultations = list;
        });
      }
    });
  }

  void _listenSchedule(String doctorId) {
    _scheduleSub?.cancel();
    final now = DateTime.now();
    _scheduleSub = _doctorService
        .watchMonthlySchedule(doctorId, now.year, now.month)
        .listen((map) {
      if (mounted) {
        setState(() {
          _scheduleMap = map;
        });
      }
    });
  }

  /// Buka layar Profil sebagai halaman terpisah dengan header pill krem.
  void _openProfileScreen() {
    if (_doctor == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.bgGradientMiddle,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppHeaderPill(
                  title: 'Profil Dokter',
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: DoctorProfileTab(
                    doctor: _doctor!,
                    onProfileUpdated: () => _loadDoctorData(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Buka layar Pesan sebagai halaman terpisah dengan header pill krem.
  void _openMessagesScreen({
    bool initialBelumDibalas = false,
    bool focusSearch = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.bgGradientMiddle,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppHeaderPill(
                  title: 'Pesan',
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: DoctorMessagesTab(
                    key: ValueKey('msg_${initialBelumDibalas}_$focusSearch'),
                    consultations: _consultations,
                    initialBelumDibalas: initialBelumDibalas,
                    focusSearch: focusSearch,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDoctor) {
      return const Scaffold(
        backgroundColor: AppColors.bgGradientMiddle,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Memuat profil dokter...',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _doctor == null) {
      return Scaffold(
        backgroundColor: AppColors.bgGradientMiddle,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.no_accounts_rounded,
                      size: 64,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Perhatian',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage ??
                        'Akun dokter belum terhubung ke data dokter.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.summaryCardSubtext,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Cukup signOut — _onAuthStateChanged akan menangani navigasi ke /login
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Keluar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Hitung total pesan unread untuk badge kartu Pesan di Beranda
    final totalUnread = _consultations.fold<int>(
      0,
      (total, c) =>
          total +
          (c.paymentStatus == PaymentStatus.paid ? c.unreadForDoctor : 0),
    );

    return Scaffold(
      backgroundColor: AppColors.bgGradientMiddle,
      body: SafeArea(
        bottom: true,
        child: DoctorHomeTab(
          doctor: _doctor!,
          consultations: _consultations,
          scheduleMap: _scheduleMap,
          totalUnreadMessages: totalUnread,
          onTapProfile: _openProfileScreen,
          onTapMessages: _openMessagesScreen,
          onTapWaitingResponse: () =>
              _openMessagesScreen(initialBelumDibalas: true),
        ),
      ),
    );
  }

}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/consultation_model.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';
import 'dokter/doctor_home_tab.dart';
import 'dokter/doctor_messages_tab.dart';
import 'dokter/doctor_profile_tab.dart';

/// Shell Utama Dashboard Dokter (Role Dokter)
/// Menampung 3 tab: Beranda, Pesan (dengan badge unread live), dan Profil.
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

  int _currentTabIndex = 0;
  bool _messagesInitialBelumDibalas = false;
  bool _messagesFocusSearch = false;

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
      setState(() {
        _doctor = null;
        _consultations = [];
        _scheduleMap = {};
        _isLoadingDoctor = true;
        _errorMessage = null;
        _currentTabIndex = 0;
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
      // Ini SATU-SATUNYA sumber kebenaran untuk "dokter yang sedang login".
      // Tidak boleh menggunakan variabel global/cache yang bisa basi.
      final doctorId = userDoc.data()?['doctorId'] as String?;

      DoctorModel? doc;
      String? fetchError;

      if (doctorId != null && doctorId.isNotEmpty) {
        // Ambil langsung dari doctors/{doctorId} — pakai doctorId yang benar
        doc = await _doctorService.fetchById(doctorId);

        if (doc == null) {
          // doctorId ada di Firestore users tapi dokumen doctors tidak ditemukan.
          // Tampilkan pesan error ramah alih-alih diam-diam menampilkan dokter lain.
          fetchError =
              'Akun dokter belum terhubung ke data dokter yang benar.\n'
              '(doctorId: "$doctorId" tidak ditemukan di koleksi doctors)\n'
              'Silakan hubungi administrator.';
        }
      } else {
        // Tidak ada doctorId → coba fallback: query doctors where uid == uid
        doc = await _doctorService.getDoctorByUid(loadingUid);
        if (doc == null) {
          fetchError =
              'Akun dokter belum terhubung ke data dokter.\n'
              'Silakan hubungi administrator.';
        }
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

  void _switchToTab(int index,
      {bool initialBelumDibalas = false, bool focusSearch = false}) {
    setState(() {
      _currentTabIndex = index;
      _messagesInitialBelumDibalas = initialBelumDibalas;
      _messagesFocusSearch = focusSearch;
    });
  }

  void _openProfileScreen() {
    if (_doctor == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.bgGradientMiddle,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primaryText),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Kembali',
            ),
            title: const Text(
              'Profil Dokter',
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: DoctorProfileTab(
            doctor: _doctor!,
            onProfileUpdated: _loadDoctorData,
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

    // Hitung total pesan unread untuk badge navigasi tab Pesan
    final totalUnread = _consultations.fold<int>(
      0,
      (total, c) =>
          total +
          (c.paymentStatus == PaymentStatus.paid ? c.unreadForDoctor : 0),
    );

    return Scaffold(
      backgroundColor: AppColors.bgGradientMiddle,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            // Tab 0: Beranda
            DoctorHomeTab(
              doctor: _doctor!,
              consultations: _consultations,
              scheduleMap: _scheduleMap,
              onTapProfile: _openProfileScreen,
              onTapSearch: () => _switchToTab(1, focusSearch: true),
              onTapWaitingResponse: () =>
                  _switchToTab(1, initialBelumDibalas: true),
            ),

            // Tab 1: Pesan
            DoctorMessagesTab(
              key: ValueKey(
                  'msg_${_messagesInitialBelumDibalas}_$_messagesFocusSearch'),
              consultations: _consultations,
              initialBelumDibalas: _messagesInitialBelumDibalas,
              focusSearch: _messagesFocusSearch,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildDoctorBottomBar(totalUnread),
    );
  }

  Widget _buildDoctorBottomBar(int totalUnread) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBarBg.withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: AppColors.navBarBorder, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tab 0: Beranda
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Beranda',
              ),

              // Tab 1: Pesan (dengan badge unread)
              _buildNavItem(
                index: 1,
                icon: Icons.chat_bubble_rounded,
                label: 'Pesan',
                badgeCount: totalUnread,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _currentTabIndex == index;
    final color = isSelected ? AppColors.primaryText : Colors.black54;

    return InkWell(
      onTap: () => setState(() => _currentTabIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD32F2F),
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

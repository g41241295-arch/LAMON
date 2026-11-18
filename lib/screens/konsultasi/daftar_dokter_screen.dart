import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/consultation_theme.dart';
import '../../models/doctor_model.dart';
import '../../services/consultation_service.dart';
import '../../services/doctor_service.dart';
import 'widgets/doctor_card.dart';

/// Layar Konsultasi Dokter (Sisi Pasien).
/// Menampilkan daftar dokter dengan pencarian lokal, kartu pembuka bernuansa hangat,
/// dan tab segmented "Pilih Dokter" serta "Rekomendasi".
class DaftarDokterScreen extends StatefulWidget {
  const DaftarDokterScreen({super.key});

  @override
  State<DaftarDokterScreen> createState() => _DaftarDokterScreenState();
}

class _DaftarDokterScreenState extends State<DaftarDokterScreen> {
  final DoctorService _doctorService = DoctorService();
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _searchController = TextEditingController();

  int _selectedTabIndex = 0; // 0: Pilih Dokter, 1: Rekomendasi
  String _searchQuery = '';
  bool _isSeeding = false;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    _consultationService.expirePastPendingConsultations();
    _doctorService.syncDoctorExperienceYears();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });

    _periodicTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSeed() async {
    setState(() => _isSeeding = true);
    try {
      await _doctorService.seedDoctors();
      if (mounted) {
        showConsultationSnackBar(
          context,
          message: 'Data dokter berhasil di-seed!',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showConsultationSnackBar(
          context,
          message: 'Seed gagal: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _handleChatTap(DoctorModel doctor) async {
    try {
      final existing =
          await _consultationService.getActiveOrWaitingConsultation(doctor.id);
      if (!mounted) return;
      if (existing != null) {
        Navigator.pushNamed(
          context,
          '/konsultasi/chat/${existing.id}',
          arguments: {
            'initialConsultation': existing,
            'patientUid': existing.patientUid,
          },
        );
        return;
      }
    } catch (e) {
      debugPrint('[DaftarDokterScreen] Error checking active consultation: $e');
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/konsultasi/pembayaran/${doctor.id}',
      arguments: doctor,
    );
  }

  void _showJamLainnya(BuildContext context, DoctorModel doctor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _JamLainnyaSheet(doctor: doctor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rightAction = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundHeaderAction(
          icon: Icons.history_rounded,
          tooltip: 'Riwayat Konsultasi',
          onTap: () => Navigator.pushNamed(context, '/konsultasi/riwayat'),
        ),
        if (kDebugMode) ...[
          const SizedBox(width: 8),
          _isSeeding
              ? const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ConsultationTheme.primary,
                      ),
                    ),
                  ),
                )
              : RoundHeaderAction(
                  icon: Icons.cloud_upload_outlined,
                  tooltip: 'Seed data dokter',
                  onTap: _runSeed,
                ),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: ConsultationTheme.scaffoldBg,
      appBar: ConsultationHeader(
        title: 'Konsultasi Dokter',
        rightAction: rightAction,
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<DoctorModel>>(
          stream: _doctorService.watchAll(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: ConsultationTheme.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: ConsultationTheme.lightBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 32,
                          color: ConsultationTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat data dokter',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ConsultationTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: ConsultationTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final rawDoctors = snapshot.data ?? [];

            return FutureBuilder<List<DoctorModel>>(
              future: _doctorService.filterAvailableDoctorsToday(rawDoctors),
              builder: (context, filterSnap) {
                if (filterSnap.connectionState == ConnectionState.waiting &&
                    !filterSnap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: ConsultationTheme.primary),
                  );
                }

                var availableDoctors = filterSnap.data ?? [];

                // Filter lokal pencarian (nama atau spesialisasi)
                if (_searchQuery.isNotEmpty) {
                  availableDoctors = availableDoctors.where((doc) {
                    final n = doc.name.toLowerCase();
                    final s = doc.specialty.toLowerCase();
                    return n.contains(_searchQuery) || s.contains(_searchQuery);
                  }).toList();
                }

                if (_selectedTabIndex == 1) {
                  // Tab Rekomendasi
                  final list = List<DoctorModel>.from(availableDoctors);
                  list.sort(DoctorService.compareDoctorRecommendation);
                  availableDoctors = list.take(5).toList();
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // ── Kartu Pembuka ──────────────────────────────────────────
                    _buildHeroBanner(),
                    const SizedBox(height: 14),

                    // ── Kolom Pencarian Pill ───────────────────────────────────
                    _buildSearchBar(),
                    const SizedBox(height: 16),

                    // ── Tab Segmented Pill ─────────────────────────────────────
                    _buildSegmentedTab(),
                    const SizedBox(height: 16),

                    // ── Daftar Kartu Dokter ────────────────────────────────────
                    if (availableDoctors.isEmpty)
                      _buildEmptyState()
                    else
                      ...availableDoctors.map(
                        (doctor) => DoctorCard(
                          doctor: doctor,
                          isRecommended: _selectedTabIndex == 1,
                          onTapCard: () {
                            Navigator.pushNamed(
                              context,
                              '/konsultasi/dokter/${doctor.id}',
                              arguments: doctor,
                            );
                          },
                          onTapChatButton: () => _handleChatTap(doctor),
                          onTapJamLainnya: doctor.operatingHours.length > 1
                              ? () => _showJamLainnya(context, doctor)
                              : null,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Kartu pembuka: gradient krem #FFFBF0 ke #FFF3D6, border krem, radius 20, padding 16x18.
  /// Judul "Pilih Dokter Terbaikmu" (bold 17 biru tua), subteks "Konsultasi lewat chat untuk kesehatan lambungmu." (12, #6B5A44),
  /// dan lingkaran putih 48 berisi ikon perisai-centang di kanan.
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFBF0),
            Color(0xFFFFF3D6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ConsultationTheme.cardBorder,
          width: 1,
        ),
        boxShadow: ConsultationTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Dokter Terbaikmu',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ConsultationTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Konsultasi lewat chat untuk kesehatan lambungmu.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B5A44),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: ConsultationTheme.teal,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  /// Kolom pencarian pill: putih, border krem, ikon cari teal, placeholder "Cari dokter atau spesialis…".
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: ConsultationTheme.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          color: ConsultationTheme.primary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Cari dokter atau spesialis…',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: ConsultationTheme.secondaryText,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ConsultationTheme.teal,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: ConsultationTheme.secondaryText),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }

  /// Tab segmented: wadah putih bergaris krem berbentuk pill dengan padding 4.
  /// Tab aktif latar biru tua teks putih, tab tidak aktif teks #5E7585.
  Widget _buildSegmentedTab() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: ConsultationTheme.cardBorder,
          width: 1,
        ),
        boxShadow: ConsultationTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              title: 'Pilih Dokter',
              index: 0,
            ),
          ),
          Expanded(
            child: _buildTabItem(
              title: 'Rekomendasi',
              index: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String title, required int index}) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ConsultationTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : ConsultationTheme.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearch = _searchQuery.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: ConsultationTheme.lightBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 34,
              color: ConsultationTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'Dokter tidak ditemukan' : 'Belum ada dokter yang praktik',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ConsultationTheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? 'Tidak ada dokter yang cocok dengan "$_searchQuery". Coba kata kunci lain.'
                : 'Saat ini belum ada dokter yang memiliki slot praktik aktif. Silakan cek kembali beberapa saat lagi.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: ConsultationTheme.secondaryText,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Bottom Sheet: Jam Lainnya bernuansa putih-krem formal
class _JamLainnyaSheet extends StatelessWidget {
  final DoctorModel doctor;
  const _JamLainnyaSheet({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9CDB8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Jam Operasional Praktik',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ConsultationTheme.primary,
              ),
            ),
            Text(
              doctor.name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ConsultationTheme.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            ...doctor.operatingHours.map(
              (h) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: ConsultationTheme.softBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ConsultationTheme.cardBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: ConsultationTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      h.display,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ConsultationTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

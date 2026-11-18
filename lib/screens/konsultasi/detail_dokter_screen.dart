import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/consultation_theme.dart';
import '../../models/doctor_model.dart';
import '../../services/consultation_service.dart';
import '../../services/doctor_service.dart';
import '../../utils/currency_formatter.dart';
import 'widgets/doctor_avatar.dart';

/// Layar Detail Dokter — menampilkan profil lengkap dokter dengan gaya formal modern.
class DetailDokterScreen extends StatefulWidget {
  final String doctorId;
  final DoctorModel? initialDoctor;

  const DetailDokterScreen({
    super.key,
    required this.doctorId,
    this.initialDoctor,
  });

  @override
  State<DetailDokterScreen> createState() => _DetailDokterScreenState();
}

class _DetailDokterScreenState extends State<DetailDokterScreen> {
  final DoctorService _doctorService = DoctorService();
  final ConsultationService _consultationService = ConsultationService();
  DoctorModel? _doctor;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialDoctor != null) {
      _doctor = widget.initialDoctor;
      _isLoading = false;
    } else {
      _loadDoctor();
    }
  }

  Future<void> _loadDoctor() async {
    try {
      final doc = await _doctorService.fetchById(widget.doctorId);
      if (mounted) {
        setState(() {
          _doctor = doc;
          _isLoading = false;
          if (doc == null) _error = 'Data dokter tidak ditemukan.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat data: $e';
        });
      }
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
      debugPrint('[DetailDokterScreen] Error checking active consultation: $e');
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/konsultasi/pembayaran/${doctor.id}',
      arguments: doctor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConsultationTheme.scaffoldBg,
      appBar: const ConsultationHeader(
        title: 'Detail Dokter',
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ConsultationTheme.primary),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: ConsultationTheme.secondaryText,
                        ),
                      ),
                    ),
                  )
                : _buildContent(context, _doctor!),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DoctorModel doctor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          // ── Foto Dokter ──────────────────────────────────────────────
          DoctorAvatar(
            doctor: doctor,
            size: 96,
            borderRadius: 24,
            showVerificationBadge: true,
            isVerified: false,
            badgeSize: 24,
          ),
          const SizedBox(height: 14),

          // ── Nama Dokter ───────────────────────────────────────────────
          Text(
            doctor.name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ConsultationTheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // ── Spesialisasi + Pengalaman ─────────────────────────────────
          Text(
            doctor.specialtyDisplay,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: ConsultationTheme.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // ── Rating Dokter ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 18,
                color: ConsultationTheme.gold,
              ),
              const SizedBox(width: 4),
              Text(
                doctor.ratingCount > 0
                    ? '${doctor.averageRating.toStringAsFixed(1)} • ${doctor.ratingCount} penilaian'
                    : 'Belum ada penilaian',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: doctor.ratingCount > 0
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: doctor.ratingCount > 0
                      ? ConsultationTheme.primary
                      : ConsultationTheme.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Kotak Harga Sesi Konsultasi ──────────────────────────────
          InfoCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Biaya Sesi Konsultasi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ConsultationTheme.secondaryText,
                  ),
                ),
                Text(
                  formatRupiah(doctor.price),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ConsultationTheme.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Jam Operasional ──────────────────────────────────────────
          if (doctor.operatingHours.isNotEmpty) ...[
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MicroLabel('JAM OPERASIONAL PRAKTIK'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: doctor.operatingHours.map((h) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: ConsultationTheme.softBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: ConsultationTheme.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: ConsultationTheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              h.display,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ConsultationTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Detail Kredensial Info Dokter ─────────────────────────────
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MicroLabel('INFORMASI PRAKTIK & PENDIDIKAN'),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.school_rounded,
                  label: 'Alumni',
                  value: doctor.alumni.isNotEmpty ? doctor.alumni : '-',
                ),
                const SectionDivider(verticalPadding: 8),
                _InfoRow(
                  icon: Icons.local_hospital_rounded,
                  label: 'Tempat Praktik',
                  value: doctor.practiceLocation.isNotEmpty
                      ? doctor.practiceLocation
                      : '-',
                ),
                const SectionDivider(verticalPadding: 8),
                _InfoRow(
                  icon: Icons.badge_rounded,
                  label: 'Nomor STR',
                  value: doctor.strNumber.isNotEmpty ? doctor.strNumber : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Tombol Utama Chat Dokter ───────────────────────────────────
          PrimaryButton(
            text: 'Chat Dokter',
            width: double.infinity,
            onPressed: () => _handleChatTap(doctor),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ConsultationTheme.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: ConsultationTheme.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: ConsultationTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

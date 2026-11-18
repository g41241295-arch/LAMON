import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/consultation_theme.dart';
import '../../../models/doctor_model.dart';
import '../../../utils/currency_formatter.dart';
import 'doctor_avatar.dart';

export 'doctor_avatar.dart';

/// Kartu dokter formal untuk tab "Pilih Dokter" dan "Rekomendasi".
class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTapCard;
  final VoidCallback onTapChatButton;
  final VoidCallback? onTapJamLainnya;
  final bool isRecommended;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTapCard,
    required this.onTapChatButton,
    this.onTapJamLainnya,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryHour = doctor.primaryHour?.display ??
        (doctor.operatingHours.isNotEmpty
            ? doctor.operatingHours.first.display
            : 'Sesuai jadwal');

    final hasMultipleHours = doctor.operatingHours.length > 1 && onTapJamLainnya != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ConsultationTheme.cardBorder,
          width: 1,
        ),
        boxShadow: ConsultationTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTapCard,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── a. Baris Atas: DoctorAvatar + Info Dokter ─────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DoctorAvatar(
                      doctor: doctor,
                      size: 72,
                      borderRadius: 18,
                      showVerificationBadge: false, // Disembunyikan aman karena belum ada field verifikasi di DB
                      isVerified: false,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ConsultationTheme.primary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            doctor.specialty,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: ConsultationTheme.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          if (isRecommended) ...[
                            // Chip Rekomendasi emas
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: ConsultationTheme.goldBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ConsultationTheme.goldBorder,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 13,
                                    color: Color(0xFFF2B544),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Rekomendasi',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: ConsultationTheme.goldText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (doctor.consultationsHandled > 0) ...[
                              const SizedBox(height: 3),
                              Text(
                                '${doctor.consultationsHandled} konsultasi ditangani',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: ConsultationTheme.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                            ],
                          ] else ...[
                            // Status Praktik Hari ini (hijau) bila ada jadwal praktik
                            if (doctor.operatingHours.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: ConsultationTheme.greenDot,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Praktik hari ini',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: ConsultationTheme.green,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── b. Baris Statistik Tiga Kolom dalam kotak #F7F3EB ──────────
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                      // Kolom 1: Rating
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: ConsultationTheme.gold,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  doctor.ratingCount > 0
                                      ? doctor.averageRating.toStringAsFixed(1)
                                      : '—',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: ConsultationTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doctor.ratingCount > 0
                                  ? 'Rating (${doctor.ratingCount})'
                                  : 'Rating',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: ConsultationTheme.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 26,
                        color: ConsultationTheme.divider,
                      ),

                      // Kolom 2: Pengalaman
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${doctor.experienceYears} th',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: ConsultationTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pengalaman',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: ConsultationTheme.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 26,
                        color: ConsultationTheme.divider,
                      ),

                      // Kolom 3: Biaya Sesi
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatRupiah(doctor.price),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ConsultationTheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'per sesi',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: ConsultationTheme.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── c. Baris Jam Operasional ────────────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: ConsultationTheme.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'JAM OPERASIONAL',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: ConsultationTheme.secondaryText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      primaryHour,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ConsultationTheme.primary,
                      ),
                    ),
                    if (hasMultipleHours) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onTapJamLainnya,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            '+Lainnya',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ConsultationTheme.teal,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // ── d. Tombol Utama: Chat Dokter dengan ikon panah putih ────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTapChatButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ConsultationTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Chat Dokter',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

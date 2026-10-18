import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/doctor_model.dart';
import '../../../utils/currency_formatter.dart';
import 'doctor_avatar.dart';

export 'doctor_avatar.dart';

/// Widget kartu dokter untuk tab "Pilih Dokter" dan "Rekomendasi".
/// Memiliki susunan dan tinggi konsisten antar kartu.
class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTapCard;
  final VoidCallback onTapChatButton;
  final VoidCallback? onTapJamLainnya;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTapCard,
    required this.onTapChatButton,
    this.onTapJamLainnya,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCard,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2ECF2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Baris Atas: Foto rounded square + info nama, spesialisasi, harga ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto dokter (76x76, rounded 16)
                  DoctorAvatar(
                    photoUrl: doctor.effectivePhotoUrl,
                    doctorId: doctor.id,
                    doctorName: doctor.name,
                    size: 76,
                    borderRadius: 16,
                  ),
                  const SizedBox(width: 14),

                  // Info dokter
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          doctor.specialtyDisplay,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutralGray,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Chip Harga
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            formatRupiah(doctor.price),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Baris Tengah: Label Jam Operasional saja ──
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.neutralGray,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Jam Operasional',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutralGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Chip jam operasional membentang penuh (Expanded) + kotak Jam Lainnya sejajar
              _buildOperatingHoursRow(),

              const SizedBox(height: 14),

              // ── Baris Bawah: Tombol Chat Dokter lebar penuh, tinggi 48 ──
              Semantics(
                label: 'Chat Dokter ${doctor.name}',
                button: true,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onTapChatButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Chat Dokter',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperatingHoursRow() {
    final hasJamLainnya =
        doctor.operatingHours.length > 1 && onTapJamLainnya != null;
    final hoursToShow =
        doctor.operatingHours.take(hasJamLainnya ? 2 : 3).toList();

    final List<Widget> children = [];

    for (int i = 0; i < hoursToShow.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 8));
      final h = hoursToShow[i];
      children.add(
        Expanded(
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE2ECF2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                h.display,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }

    if (hasJamLainnya) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 8));
      children.add(
        Expanded(
          child: GestureDetector(
            onTap: onTapJamLainnya,
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE2ECF2),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  'Jam Lainnya',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: children);
  }
}


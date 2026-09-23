import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/doctor_model.dart';

/// Widget kartu dokter untuk Daftar Dokter screen.
/// Menampilkan foto, nama, spesialisasi, harga, jam operasional,
/// tombol "Chat Dokter", dan link "Jam Lainnya".
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
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2ECF2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Baris atas: foto + info ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Foto dokter (avatar generik)
                  _DoctorAvatar(photoUrl: doctor.photoUrl, size: 64),
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
                        ),
                        const SizedBox(height: 6),
                        // Harga
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatRupiah(doctor.price),
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

              const SizedBox(height: 12),

              // ── Jam operasional ──
              if (doctor.operatingHours.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: AppColors.neutralGray,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        doctor.operatingHours
                            .map((h) => h.display)
                            .join('  '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutralGray,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // ── Tombol Chat Dokter ──
              Semantics(
                label: 'Chat Dokter ${doctor.name}',
                button: true,
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
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

              // ── Link "Jam Lainnya" ──
              if (doctor.operatingHours.length > 1 && onTapJamLainnya != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GestureDetector(
                    onTap: onTapJamLainnya,
                    child: const Text(
                      'Jam Lainnya',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primaryLight,
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

  String _formatRupiah(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer('Rp');
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
      count++;
    }
    return String.fromCharCodes(buffer.toString().codeUnits.reversed);
  }
}

/// Avatar dokter: tampilkan foto dari URL jika ada,
/// atau ikon generik jika URL kosong/gagal load.
class _DoctorAvatar extends StatelessWidget {
  final String photoUrl;
  final double size;

  const _DoctorAvatar({required this.photoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.lightGray,
      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      onBackgroundImageError: photoUrl.isNotEmpty
          ? (_, _) {}
          : null,
      child: photoUrl.isEmpty
          ? Icon(
              Icons.person_rounded,
              size: size * 0.55,
              color: AppColors.neutralGray,
            )
          : null,
    );
  }
}

/// Widget avatar dokter yang dapat dipakai di layar lain.
class DoctorAvatar extends StatelessWidget {
  final String photoUrl;
  final double size;

  const DoctorAvatar({
    super.key,
    required this.photoUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.lightGray,
      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      onBackgroundImageError: photoUrl.isNotEmpty ? (_, _) {} : null,
      child: photoUrl.isEmpty
          ? Icon(
              Icons.person_rounded,
              size: size * 0.55,
              color: AppColors.neutralGray,
            )
          : null,
    );
  }
}

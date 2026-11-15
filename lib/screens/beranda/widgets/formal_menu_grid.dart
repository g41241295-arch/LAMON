import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../../pengingat_jam_makan/screens/pilih_kondisi_screen.dart';

class FormalMenuGrid extends StatelessWidget {
  final double hPad;

  const FormalMenuGrid({
    super.key,
    this.hPad = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: "Menu Utama" ala "My Journal" di referensi
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu Utama',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEBE3D0),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Grid 2x2 ala Referensi
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            children: [
              Row(
                children: [
                  // Card 1: Catat Makanan
                  Expanded(
                    child: _FormalCard(
                      title: 'Catat Makanan',
                      badgeLabel: 'Catat Asupan',
                      badgeIcon: Icons.local_fire_department_rounded,
                      badgeBgColor: const Color(0xFFFFF3E0),
                      badgeTextColor: const Color(0xFFD97706),
                      assetPath: 'assets/images/menu-catat1_crop.png',
                      accentColor: const Color(0xFFFFF7ED),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.catatMakanan);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Card 2: Pengingat Jam Makan
                  Expanded(
                    child: _FormalCard(
                      title: 'Pengingat Jam Makan',
                      badgeLabel: 'Jadwal Teratur',
                      badgeIcon: Icons.alarm_rounded,
                      badgeBgColor: const Color(0xFFE0F2FE),
                      badgeTextColor: const Color(0xFF0284C7),
                      assetPath: 'assets/images/menu-pengingat1_crop.png',
                      accentColor: const Color(0xFFF0F9FF),
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PilihKondisiScreen(),
                          ),
                        );
                        if (result == true && context.mounted) {
                          Navigator.pushReplacementNamed(context, '/beranda');
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // Card 3: Prediksi Penyakit
                  Expanded(
                    child: _FormalCard(
                      title: 'Prediksi Penyakit',
                      badgeLabel: 'Cek Lambung',
                      badgeIcon: Icons.health_and_safety_rounded,
                      badgeBgColor: const Color(0xFFECFDF5),
                      badgeTextColor: const Color(0xFF059669),
                      assetPath: 'assets/images/menu-prediksi1_crop.png',
                      accentColor: const Color(0xFFF0FDF4),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.diseasePrediction);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Card 4: Konsultasi Dokter
                  Expanded(
                    child: _FormalCard(
                      title: 'Konsultasi Dokter',
                      badgeLabel: 'Chat Spesialis',
                      badgeIcon: Icons.chat_bubble_outline_rounded,
                      badgeBgColor: const Color(0xFFFEF3C7),
                      badgeTextColor: const Color(0xFFB45309),
                      assetPath: 'assets/images/menu-konsul1_crop.png',
                      accentColor: const Color(0xFFFFFBEB),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.konsultasi);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Banner Card Ringkasan Makanan
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.ringkasanMakanan);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFEBE3D0),
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
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/images/menu-ringkasan1_crop.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.bar_chart_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Nutrisi Harian',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Lihat laporan riwayat makan & kalori Anda',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.neutralGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormalCard extends StatelessWidget {
  final String title;
  final String badgeLabel;
  final IconData badgeIcon;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final String assetPath;
  final Color accentColor;
  final VoidCallback onTap;

  const _FormalCard({
    required this.title,
    required this.badgeLabel,
    required this.badgeIcon,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.assetPath,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFEBE3D0),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Container with soft tinted background
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      badgeIcon,
                      size: 40,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Pill Badge ala Referensi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          badgeIcon,
                          size: 11,
                          color: badgeTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badgeLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: badgeTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


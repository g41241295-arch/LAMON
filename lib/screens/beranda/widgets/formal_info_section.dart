import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';

class FormalInfoSection extends StatelessWidget {
  final VoidCallback onGastropediaTap;
  final VoidCallback onBeritaTap;
  final double hPad;

  const FormalInfoSection({
    super.key,
    required this.onGastropediaTap,
    required this.onBeritaTap,
    this.hPad = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edukasi & Informasi',
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
                  Icons.menu_book_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Dua Kartu Informasi Berjejer Vertikal
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            children: [
              _InfoCardFormal(
                title: 'Gastropedia',
                description: 'Panduan lengkap makanan yang aman, dianjurkan, dan pantangan bagi penderita lambung.',
                badgeLabel: 'Katalog Makanan',
                badgeBg: const Color(0xFFE0F2FE),
                badgeText: const Color(0xFF0369A1),
                accentColor: const Color(0xFFEBF5FA),
                assetPath: 'assets/images/info-gastro1.png',
                iconFallback: Icons.restaurant_menu_rounded,
                onTap: onGastropediaTap,
              ),
              const SizedBox(height: 12),
              _InfoCardFormal(
                title: 'Berita Kesehatan',
                description: 'Artikel terpercaya seputar kesehatan pencernaan, pencegahan GERD, dan tips gaya hidup.',
                badgeLabel: 'Artikel Medis',
                badgeBg: const Color(0xFFFEF3C7),
                badgeText: const Color(0xFFB45309),
                accentColor: const Color(0xFFFFFBEB),
                assetPath: 'assets/images/info-berita1.png',
                iconFallback: Icons.newspaper_rounded,
                onTap: onBeritaTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCardFormal extends StatelessWidget {
  final String title;
  final String description;
  final String badgeLabel;
  final Color badgeBg;
  final Color badgeText;
  final Color accentColor;
  final String assetPath;
  final IconData iconFallback;
  final VoidCallback onTap;

  const _InfoCardFormal({
    required this.title,
    required this.description,
    required this.badgeLabel,
    required this.badgeBg,
    required this.badgeText,
    required this.accentColor,
    required this.assetPath,
    required this.iconFallback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            // Thumbnail / Icon Image
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  iconFallback,
                  size: 32,
                  color: badgeText,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: badgeText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutralGray,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Chevron Arrow
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4EB),
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
    );
  }
}


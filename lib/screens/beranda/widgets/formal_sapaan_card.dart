import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';

class FormalSapaanCard extends StatelessWidget {
  final String userName;
  final String? customGreeting;
  final String? customTitle;
  final String? customSubtitle;

  const FormalSapaanCard({
    super.key,
    required this.userName,
    this.customGreeting,
    this.customTitle,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = userName.trim().split(' ').first;

    return Container(
      width: double.infinity,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Decorative subtle background gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFDF5),
                      Color(0xFFFFFBE8),
                      Color(0xFFFAF3D4),
                    ],
                  ),
                ),
              ),
            ),

            // Content text
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 16, bottom: 16, right: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    customGreeting ?? 'Halo, $displayName !',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9E652B), // Brown accent LAMON
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    customTitle ?? 'Sehatkan Lambung,\nMulai dari Hari ini',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    customSubtitle ??
                        'Yuk, jaga pola makan dan pantau kesehatan lambungmu setiap hari',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B5839),
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Maskot lambung di sebelah kanan
            Positioned(
              right: 8,
              bottom: 4,
              top: 4,
              child: Center(
                child: Image.asset(
                  'assets/images/mascot-header.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 96),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoCardsSection extends StatelessWidget {
  final VoidCallback onGastropediaTap;
  final VoidCallback onBeritaTap;

  const InfoCardsSection({
    super.key,
    required this.onGastropediaTap,
    required this.onBeritaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6), // glass effect
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.assignment_ind_rounded, color: Color(0xFF6F3F1E), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Seputar Informasi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6F3F1E),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _InfoCard(
                title: 'Gastropedia',
                description: 'Cari tahu lebih banyak tentang pola makan sehat',
                bgPath: 'assets/images/info_gastropedia_bg.png',
                assetPath: 'assets/images/info-gastro1.png',
                isBlue: true,
                onTap: onGastropediaTap,
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Berita Kesehatan',
                description: 'Dapatkan informasi terbaru seputar kesehatan lambung dan gaya hidup sehat',
                bgPath: 'assets/images/info_berita_bg.png',
                assetPath: 'assets/images/info-berita1.png',
                isBlue: false,
                onTap: onBeritaTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final String bgPath;
  final String assetPath;
  final bool isBlue;
  final VoidCallback onTap;

  const _InfoCard({
    required this.title,
    required this.description,
    required this.bgPath,
    required this.assetPath,
    required this.isBlue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: AssetImage(bgPath),
            fit: BoxFit.cover,
            onError: (e, s) {},
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 120, top: 14, bottom: 14, right: 54),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF134563),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF134563),
                      height: 1.25,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Illustration
            Positioned(
              left: 10,
              bottom: 0,
              child: Image.asset(
                assetPath,
                width: 100,
                height: 90,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 90,
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: kDebugMode ? Text(
                      assetPath.split('/').last,
                      style: const TextStyle(fontSize: 8, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ) : const SizedBox(),
                  );
                },
              ),
            ),
            // Button arrow
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: isBlue ? const Color(0xFFCBE5F6) : const Color(0xFFFDE899),
                  child: const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF134563)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

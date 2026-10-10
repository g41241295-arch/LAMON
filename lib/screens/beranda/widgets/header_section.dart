import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderChip extends StatelessWidget {
  final String userName;
  final VoidCallback onTap;

  const HeaderChip({super.key, required this.userName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6), // Soft glass
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF134563),
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              userName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF53311C),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF53311C)),
          ],
        ),
      ),
    );
  }
}

class SapaanCard extends StatelessWidget {
  final String userName;

  const SapaanCard({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final displayName = userName.trim().split(' ').first;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = 138.0;
        final mascotWidth = cardWidth * 0.35;
        final mascotHeight = cardHeight * 0.85;

        return SizedBox(
          height: cardHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                height: cardHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/card_sapaan_bg.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: cardWidth * 0.58,
                        child: Text(
                          'Halo, $displayName !',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8D5B20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: cardWidth * 0.58,
                        child: Text(
                          'Sehatkan Lambung,\nMulai dari Hari ini',
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF134563),
                            height: 1.2,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: cardWidth * 0.58,
                        child: Text(
                          'Yuk, jaga pola makan dan\npantau kesehatan lambungmu setiap hari',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF625232),
                            height: 1.2,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: 0,
                child: Image.asset(
                  'assets/images/mascot-header.png',
                  width: mascotWidth,
                  height: mascotHeight,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: mascotWidth,
                      height: mascotHeight,
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: kDebugMode 
                          ? const Text('mascot-header.png', style: TextStyle(fontSize: 8, color: Colors.black54))
                          : const SizedBox(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

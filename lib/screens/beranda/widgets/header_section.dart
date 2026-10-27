import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderChip extends StatelessWidget {
  final String userName;
  final String? photoUrl;
  final VoidCallback onTap;

  const HeaderChip({
    super.key,
    required this.userName,
    this.photoUrl,
    required this.onTap,
  });

  Widget _buildDefaultAvatar() {
    return const CircleAvatar(
      radius: 14,
      backgroundColor: Color(0xFF134563),
      child: Icon(Icons.person, size: 16, color: Colors.white),
    );
  }

  Widget _buildAvatar() {
    final cleanUrl = (photoUrl ?? '').trim();
    if (cleanUrl.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 28,
          height: 28,
          child: Image.network(
            cleanUrl,
            width: 28,
            height: 28,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 28,
                height: 28,
                color: const Color(0xFF134563).withValues(alpha: 0.2),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
          ),
        ),
      );
    }
    return _buildDefaultAvatar();
  }

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
            _buildAvatar(),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF53311C),
                ),
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
  final String? customGreeting;
  final String? customTitle;
  final String? customSubtitle;

  const SapaanCard({
    super.key,
    required this.userName,
    this.customGreeting,
    this.customTitle,
    this.customSubtitle,
  });

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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: cardWidth * 0.58,
                        child: Text(
                          customGreeting ?? 'Halo, $displayName !',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8D5B20),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: cardWidth * 0.58,
                        child: Text(
                          customTitle ?? 'Sehatkan Lambung,\nMulai dari Hari ini',
                          style: GoogleFonts.poppins(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF134563),
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: cardWidth * 0.58,
                        child: Text(
                          customSubtitle ??
                              'Yuk, jaga pola makan dan pantau kesehatan lambungmu setiap hari',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF625232),
                            height: 1.22,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
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

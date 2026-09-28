import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Section "Seputar Informasi" dengan 2 kartu memanjang (Gastropedia & Berita Kesehatan)
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Badge Judul "Seputar Informasi"
        _buildSectionBadge('Seputar Informasi'),
        const SizedBox(height: 14),

        // 2. Kartu 1: Gastropedia
        _InfoBannerCard(
          title: 'Gastropedia',
          assetPath: 'assets/images/info-gastro1.png',
          illustrationLeft: -8,
          illustrationTop: -10,
          illustrationWidth: 125,
          onTap: onGastropediaTap,
        ),
        const SizedBox(height: 14),

        // 3. Kartu 2: Berita Kesehatan
        _InfoBannerCard(
          title: 'Berita Kesehatan',
          assetPath: 'assets/images/info-berita1.png',
          illustrationLeft: -8,
          illustrationTop: -14,
          illustrationWidth: 120,
          onTap: onBeritaTap,
        ),
      ],
    );
  }

  Widget _buildSectionBadge(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5.5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFDF5),
            Color(0xFFF7EAC4),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD8C496),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6F3F1E).withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF6F3F1E),
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// Kartu memanjang untuk info dengan interaksi sentuh scale 1.04 dan teks kontras
class _InfoBannerCard extends StatefulWidget {
  final String title;
  final String assetPath;
  final double illustrationLeft;
  final double illustrationTop;
  final double illustrationWidth;
  final VoidCallback onTap;

  const _InfoBannerCard({
    required this.title,
    required this.assetPath,
    required this.illustrationLeft,
    required this.illustrationTop,
    required this.illustrationWidth,
    required this.onTap,
  });

  @override
  State<_InfoBannerCard> createState() => _InfoBannerCardState();
}

class _InfoBannerCardState extends State<_InfoBannerCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    // Jeda sejenak agar animasi sentuh terlihat oleh pengguna
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) {
        widget.onTap();
      }
    });
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 1.04 : 1.0;
    final textColor = _isPressed
        ? const Color(0xFF1E5A8C)
        : const Color(0xFF0C1923);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: double.infinity,
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // 1. Kotak Persegi Panjang Bergradasi Biru Muda ke Putih
              Container(
                width: double.infinity,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFCBE5F6),
                      Color(0xFFF3F9FD),
                      Color(0xFFFFFFFF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFD0E5F3),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(right: 18),
                child: Row(
                  children: [
                    // Ruang kosong untuk memberi jalan pada ilustrasi di sebelah kiri
                    const SizedBox(width: 122),

                    // Judul Artikel/Info
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.poppins(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.2,
                        ),
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Ikon Panah ">" Tebal
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.black,
                      size: 34,
                    ),
                  ],
                ),
              ),

              // 2. Gambar Ilustrasi yang SEDIKIT KELUAR dari batas kiri/atas
              Positioned(
                left: widget.illustrationLeft,
                top: widget.illustrationTop,
                bottom: -4,
                width: widget.illustrationWidth,
                child: Image.asset(
                  widget.assetPath,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

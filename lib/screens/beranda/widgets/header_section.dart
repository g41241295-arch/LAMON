import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_assets.dart';

/// Widget teks sapaan pada bagian atas Beranda
class HeaderGreeting extends StatelessWidget {
  final String userName;

  const HeaderGreeting({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    // Ambil nama panggilan/nama depan bila terlalu panjang
    final firstName = userName.trim().split(' ').first;
    final displayName = firstName.isNotEmpty ? firstName : 'Pengguna';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Sapaan Halo
        Text(
          'Halo, $displayName !',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF8D5B20),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 5),

        // 2. Judul Tebal 2 Baris
        Text(
          'Sehatkan Lambung,\nMulai dari Hari ini',
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF134563),
            height: 1.18,
          ),
        ),
        const SizedBox(height: 5),

        // 3. Subteks Pendukung
        Text(
          'Yuk, jaga pola makan dan pantau kesehatan lambungmu setiap hari',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF625232),
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

/// Maskot lambung animasi dengan efek glow berpendar dan melayang
class AnimatedMascotLogo extends StatefulWidget {
  final double size;

  const AnimatedMascotLogo({
    super.key,
    this.size = 148,
  });

  @override
  State<AnimatedMascotLogo> createState() => _AnimatedMascotLogoState();
}

class _AnimatedMascotLogoState extends State<AnimatedMascotLogo>
    with TickerProviderStateMixin {
  late final AnimationController _floatingController;
  late final Animation<double> _floatingAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScaleAnimation;
  late final Animation<double> _pulseOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Animasi melayang naik-turun perlahan (±6 dp, durasi 4.5 detik, Curves.easeInOut)
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    _floatingAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOut,
      ),
    );
    _floatingController.repeat(reverse: true);

    // 2. Animasi pulse glow di belakang logo (durasi 2.8 detik)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _pulseScaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseOpacityAnimation = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // A. Lingkaran radial gradient kuning lembut berpendar (Pulse Glow)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: _pulseOpacityAnimation.value,
                child: Transform.scale(
                  scale: _pulseScaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: _buildGlowLayer(),
          ),

          // B. Gambar Maskot Lambung Melayang Naik-Turun (Floating)
          AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: child,
              );
            },
            child: Image.asset(
              AppAssets.mascotHeader,
              width: widget.size * 0.96,
              height: widget.size * 0.96,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowLayer() {
    return Container(
      width: widget.size * 0.82,
      height: widget.size * 0.82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFFEA79).withValues(alpha: 0.75),
            const Color(0xFFFFDF66).withValues(alpha: 0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.65, 1.0],
        ),
      ),
    );
  }
}

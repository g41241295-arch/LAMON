import 'package:flutter/material.dart';

/// Avatar anak laki-laki untuk opsi "Pria"
class BoyAvatar extends StatelessWidget {
  final double size;
  const BoyAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFECC8),
        border: Border.all(color: const Color(0xFFE2B483), width: 1.5),
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Baju biru
            Positioned(
              bottom: 0,
              child: Container(
                width: size * 0.72,
                height: size * 0.32,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
            // Wajah
            Positioned(
              top: size * 0.22,
              child: Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDAB0),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Rambut laki-laki hitam/coklat tua
            Positioned(
              top: size * 0.12,
              child: Container(
                width: size * 0.56,
                height: size * 0.35,
                decoration: const BoxDecoration(
                  color: Color(0xFF2C241E),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                    bottom: Radius.circular(8),
                  ),
                ),
              ),
            ),
            // Mata
            Positioned(
              top: size * 0.38,
              left: size * 0.35,
              child: Container(
                width: size * 0.08,
                height: size * 0.08,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: size * 0.38,
              right: size * 0.35,
              child: Container(
                width: size * 0.08,
                height: size * 0.08,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Senyum
            Positioned(
              top: size * 0.50,
              child: Container(
                width: size * 0.16,
                height: size * 0.07,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF8B4513), width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar anak perempuan untuk opsi "Wanita"
class GirlAvatar extends StatelessWidget {
  final double size;
  const GirlAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFE8E8),
        border: Border.all(color: const Color(0xFFE4AEAE), width: 1.5),
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Baju pink/ungu
            Positioned(
              bottom: 0,
              child: Container(
                width: size * 0.72,
                height: size * 0.32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEC4899),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
            // Rambut belakang panjang coklat
            Positioned(
              top: size * 0.16,
              child: Container(
                width: size * 0.65,
                height: size * 0.65,
                decoration: const BoxDecoration(
                  color: Color(0xFF5D3A24),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            // Wajah
            Positioned(
              top: size * 0.22,
              child: Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE0BD),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Poni rambut depan
            Positioned(
              top: size * 0.14,
              child: Container(
                width: size * 0.52,
                height: size * 0.22,
                decoration: const BoxDecoration(
                  color: Color(0xFF5D3A24),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                    bottom: Radius.circular(4),
                  ),
                ),
              ),
            ),
            // Mata
            Positioned(
              top: size * 0.38,
              left: size * 0.35,
              child: Container(
                width: size * 0.08,
                height: size * 0.08,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: size * 0.38,
              right: size * 0.35,
              child: Container(
                width: size * 0.08,
                height: size * 0.08,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Senyum
            Positioned(
              top: size * 0.50,
              child: Container(
                width: size * 0.16,
                height: size * 0.07,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFC2410C), width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar tenaga medis / dokter untuk opsi "Iya"
class DoctorAvatar extends StatelessWidget {
  final double size;
  const DoctorAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE0F2FE),
        border: Border.all(color: const Color(0xFF7DD3FC), width: 1.5),
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Baju medis biru toska
            Positioned(
              bottom: 0,
              child: Container(
                width: size * 0.75,
                height: size * 0.34,
                decoration: const BoxDecoration(
                  color: Color(0xFF0284C7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
            // Wajah
            Positioned(
              top: size * 0.22,
              child: Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDAB0),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Topi bedah / scrub cap biru
            Positioned(
              top: size * 0.08,
              child: Container(
                width: size * 0.6,
                height: size * 0.35,
                decoration: const BoxDecoration(
                  color: Color(0xFF0284C7),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.circular(8),
                  ),
                ),
              ),
            ),
            // Masker medis putih/hijau muda
            Positioned(
              top: size * 0.44,
              child: Container(
                width: size * 0.38,
                height: size * 0.22,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF0284C7), width: 1),
                ),
              ),
            ),
            // Mata dokter
            Positioned(
              top: size * 0.34,
              left: size * 0.35,
              child: Container(
                width: size * 0.08,
                height: size * 0.08,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: size * 0.34,
              right: size * 0.35,
              child: Container(
                width: size * 0.08,
                height: size * 0.08,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar orang biasa untuk opsi "Tidak"
class PersonAvatar extends StatelessWidget {
  final double size;
  const PersonAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF3E8FF),
        border: Border.all(color: const Color(0xFFD8B4FE), width: 1.5),
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Baju ungu
            Positioned(
              bottom: 0,
              child: Container(
                width: size * 0.72,
                height: size * 0.32,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
            // Wajah
            Positioned(
              top: size * 0.22,
              child: Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDAB0),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Rambut coklat sedang
            Positioned(
              top: size * 0.12,
              child: Container(
                width: size * 0.56,
                height: size * 0.32,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A3525),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                    bottom: Radius.circular(8),
                  ),
                ),
              ),
            ),
            // Mata
            Positioned(
              top: size * 0.38,
              left: size * 0.35,
              child: Container(
                width: size * 0.08,
                height: size * 0.08,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: size * 0.38,
              right: size * 0.35,
              child: Container(
                width: size * 0.08,
                height: size * 0.08,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Senyum
            Positioned(
              top: size * 0.50,
              child: Container(
                width: size * 0.16,
                height: size * 0.07,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF6B21A8), width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3D Green sphere checkmark badge untuk Step 4 (Halaman Sukses)
class GreenCheckmark3DBadge extends StatelessWidget {
  final double size;
  const GreenCheckmark3DBadge({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.35),
          radius: 0.85,
          colors: [
            Color(0xFF8CE93D),
            Color(0xFF58C822),
            Color(0xFF389F12),
            Color(0xFF267509),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF359410).withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: 4,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: size * 0.58,
        ),
      ),
    );
  }
}

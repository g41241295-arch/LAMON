import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Item data untuk Menu Utama Beranda
class BerandaMenuItem {
  final String id;
  final String title;
  final String assetPath;
  final String route;
  final String description;

  const BerandaMenuItem({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.route,
    required this.description,
  });
}

/// Daftar 5 kartu Menu Utama horizontal (full-bleed ke tepi layar)
class MainMenuList extends StatelessWidget {
  final void Function(BerandaMenuItem item) onMenuTap;

  const MainMenuList({
    super.key,
    required this.onMenuTap,
  });

  static const List<BerandaMenuItem> items = [
    BerandaMenuItem(
      id: 'pengingat-jam-makan',
      title: 'Pengingat\nJam Makan',
      assetPath: 'assets/images/menu-pengingat1.png',
      route: '/pengingat-jam-makan',
      description: 'Atur jadwal pengingat makan teratur untuk menjaga asam lambung tetap stabil.',
    ),
    BerandaMenuItem(
      id: 'catat-makananmu',
      title: 'Catat\nMakananmu',
      assetPath: 'assets/images/menu-catat1.png',
      route: '/catat-makananmu',
      description: 'Catat asupan makanan harian Anda untuk melacak pemicu maag atau GERD.',
    ),
    BerandaMenuItem(
      id: 'ringkasan-makanan',
      // Menggunakan file _trim: padding transparan besar di-crop agar piringan selebar kartu
      title: 'Ringkasan\nmakanan',
      assetPath: 'assets/images/menu-ringkasan1_trim.png',
      route: '/ringkasan-makanan',
      description: 'Laporan ringkasan konsumsi dan evaluasi nutrisi ramah lambung.',
    ),
    BerandaMenuItem(
      id: 'prediksi-penyakit',
      title: 'Prediksi\nPenyakit',
      assetPath: 'assets/images/menu-prediksi1.png',
      route: '/prediksi-penyakit',
      description: 'Cek gejala lambung dan analisis kemungkinan gangguan kesehatan lambung.',
    ),
    BerandaMenuItem(
      id: 'konsul-dokter',
      title: 'Konsul\nDokter',
      assetPath: 'assets/images/menu-konsul1.png',
      route: '/konsultasi',
      description: 'Konsultasi langsung dengan dokter spesialis lambung dan pencernaan.',
    ),
  ];

  /// Map konfigurasi rasio lebar gambar terhadap lebar kartu W (W = 118 dp).
  ///
  /// Formula render:
  ///   lebar visual imgW = W * ratio
  ///   posisi left = (W - imgW) / 2
  ///   posisi bottom = labelH
  ///
  /// Batas Keras (Langkah 3):
  ///   - Lebar tampilan <= 1.30 * W
  ///   - Tonjolan ke atas dari batas atas kartu <= 0.12 * W (<= 14.16 dp)
  ///   - Gambar tidak boleh menyentuh judul "Menu Utama"
  ///
  /// Nilai akhir:
  ///   - menu-pengingat1.png      : 1.00  (imgW = 1.00W, tonjolan = -2.4 dp)
  ///   - menu-catat1.png          : 1.14  (imgW = 1.14W, tonjolan = 12.6 dp <= 0.12W)
  ///   - menu-ringkasan1.png      : 1.00  (fallback jika memakai file asli)
  ///   - menu-ringkasan1_trim.png : 1.00  (imgW = 1.00W, tonjolan = 6.5 dp <= 0.12W)
  ///   - menu-prediksi1.png       : 1.16  (imgW = 1.16W, tonjolan = 13.4 dp <= 0.12W, diturunkan dari 1.24)
  ///   - menu-konsul1.png         : 1.00  (imgW = 1.00W, tonjolan = -2.4 dp)
  static const Map<String, double> menuImageWidthRatio = {
    'menu-pengingat1.png': 1.00,
    'menu-catat1.png': 1.14,
    'menu-ringkasan1.png': 1.00,
    'menu-ringkasan1_trim.png': 1.00,
    'menu-prediksi1.png': 1.16,
    'menu-konsul1.png': 1.00,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Badge Judul "Menu Utama" (dengan padding kiri 20 dp)
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: _buildSectionBadge('Menu Utama'),
        ),
        const SizedBox(height: 10),

        // 2. Horizontal ListView Kartu Menu (Full-Bleed ke Tepi Layar Kanan)
        // clipBehavior: Clip.none agar gambar yang menonjol atas/samping tidak terpotong
        // Tinggi SizedBox: tinggi kartu (185.3) + padding atas (24) = 209.3 dp (~210 dp)
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            // padding atas 24 dp: ruang aman untuk tonjolan gambar di atas kartu
            padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
            itemCount: items.length,
            // Jarak antar kartu >= 0.3 * W = 35 dp
            separatorBuilder: (_, _) => const SizedBox(width: 35),
            itemBuilder: (context, index) {
              final item = items[index];
              final filename = item.assetPath.split('/').last;
              final ratio = menuImageWidthRatio[filename] ?? 1.00;

              return _MenuCard(
                item: item,
                widthRatio: ratio,
                onTap: () => onMenuTap(item),
              );
            },
          ),
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

/// Kartu menu dengan animasi sentuh (scale 1.05 / 1.08 dan warna teks kontras #1E5A8C)
class _MenuCard extends StatefulWidget {
  final BerandaMenuItem item;
  final double widthRatio;
  final VoidCallback onTap;

  const _MenuCard({
    required this.item,
    required this.widthRatio,
    required this.onTap,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _isTouched = false;
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isTouched = true;
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isTouched = false;
      _isPressed = false;
    });
    // Delay sedikit agar efek scale dan perubahan warna terlihat oleh pengguna
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) {
        widget.onTap();
      }
    });
  }

  void _handleTapCancel() {
    setState(() {
      _isTouched = false;
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed ? 1.08 : (_isTouched ? 1.05 : 1.0);
    final Color textColor =
        _isPressed ? const Color(0xFF1E5A8C) : const Color(0xFF53311C);

    // Dimensi kartu sesuai desain:
    //   W = 118 dp (lebar kartu)
    //   H ≈ 1.57 × W ≈ 185.3 dp
    //   Area label putih ≈ 35% H ≈ 64.9 dp
    //   Area biru-abu   ≈ 65% H ≈ 120.4 dp
    const double cardW = 118.0;
    const double cardH = cardW * 1.57;   // ≈ 185.3 dp
    const double labelH = cardH * 0.35;  // ≈ 64.9 dp

    final double imgW = cardW * widget.widthRatio;
    final double imgLeft = (cardW - imgW) / 2;

    // Batas Keras (Langkah 3 validation)
    assert(widget.widthRatio <= 1.30, 'Lebar gambar tidak boleh melebihi 1.30 * W');

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: cardW,
          height: cardH,
          child: Stack(
            clipBehavior: Clip.none, // gambar boleh menonjol keluar kartu
            children: [
              // Layer 1: Kotak Kartu (background + border + shadow)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7BA2BA),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Area Atas: latar biru-abu muda (65% tinggi kartu)
                      Expanded(
                        flex: 65,
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF5F8),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                          ),
                        ),
                      ),

                      // Area Bawah: label teks putih (35% tinggi kartu)
                      SizedBox(
                        height: labelH,
                        child: Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(15),
                            ),
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              height: 1.15,
                            ),
                            child: Text(
                              widget.item.title,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Layer 2: Gambar Menu (Berbasis Lebar Tampilan Tanpa Transform Scale)
              // Posisi: bottom = labelH (alas tepat di batas garis label),
              //         left = (W - imgW) / 2 (terpusat horizontal)
              Positioned(
                bottom: labelH,
                left: imgLeft,
                width: imgW,
                child: Image.asset(
                  widget.item.assetPath,
                  width: imgW,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

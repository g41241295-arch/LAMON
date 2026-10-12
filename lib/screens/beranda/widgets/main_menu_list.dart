import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ubah nilai ini untuk memperbesar/memperkecil semua kartu Menu Utama sekaligus.
const double kMenuCardScale = 1.15;

class BerandaMenuItem {
  final String id;
  final String title;
  final String assetPath;
  final String bgPath;
  final String route;
  final String description;
  final bool isBlueBg;

  const BerandaMenuItem({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.bgPath,
    required this.route,
    required this.description,
    required this.isBlueBg,
  });
}

class MainMenuList extends StatelessWidget {
  final void Function(BerandaMenuItem item) onMenuTap;

  const MainMenuList({super.key, required this.onMenuTap});

  static const List<BerandaMenuItem> items = [
    BerandaMenuItem(
      id: 'pengingat-jam-makan',
      title: 'Pengingat\nJam Makan',
      assetPath: 'assets/images/menu-pengingat1_crop.png',
      bgPath: 'assets/images/menu_card_bg_oranye.png',
      route: '/pengingat-jam-makan',
      description: 'Atur jadwal pengingat makan teratur.',
      isBlueBg: false,
    ),
    BerandaMenuItem(
      id: 'catat-makananmu',
      title: 'Catat\nMakan',
      assetPath: 'assets/images/menu-catat1_crop.png',
      bgPath: 'assets/images/menu_card_bg_biru.png',
      route: '/catat-makananmu',
      description: 'Catat asupan makanan harian Anda.',
      isBlueBg: true,
    ),
    BerandaMenuItem(
      id: 'ringkasan-makanan',
      title: 'Ringkasan\nMakan',
      assetPath: 'assets/images/menu-ringkasan1_crop.png',
      bgPath: 'assets/images/menu_card_bg_oranye.png',
      route: '/ringkasan-makanan',
      description: 'Laporan ringkasan konsumsi.',
      isBlueBg: false,
    ),
    BerandaMenuItem(
      id: 'prediksi-penyakit',
      title: 'Prediksi\nLambung',
      assetPath: 'assets/images/menu-prediksi1_crop.png',
      bgPath: 'assets/images/menu_card_bg_biru.png',
      route: '/prediksi-penyakit',
      description: 'Cek gejala lambung.',
      isBlueBg: true,
    ),
    BerandaMenuItem(
      id: 'konsul-dokter',
      title: 'Konsultasi\nDokter',
      assetPath: 'assets/images/menu-konsul1_crop.png',
      bgPath: 'assets/images/menu_card_bg_oranye.png',
      route: '/konsultasi',
      description: 'Konsultasi langsung dengan dokter spesialis.',
      isBlueBg: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    final s = W / 390;
    final cardW = W * 0.374 * kMenuCardScale;
    final cardH = W * 0.28 * kMenuCardScale;
    final gap = W * 0.0385;
    final listPad = 20.0; // sama dengan padding kiri label "Menu Utama"

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label "Menu Utama"
        Padding(
          padding: EdgeInsets.symmetric(horizontal: listPad),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.grid_view_rounded, color: Color(0xFF6F3F1E), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Menu Utama',
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
        const SizedBox(height: 12),
        // Daftar kartu
        SizedBox(
          height: cardH + 12, // +12 untuk ruang bayangan
          child: ListView.separated(
            padding: EdgeInsets.only(left: listPad, right: listPad, bottom: 12),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, index) => SizedBox(width: gap),
            itemBuilder: (context, index) {
              return _MenuCard(
                item: items[index],
                cardW: cardW,
                cardH: cardH,
                s: s,
                W: W,
                onTap: () => onMenuTap(items[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final BerandaMenuItem item;
  final double cardW;
  final double cardH;
  final double s;
  final double W;
  final VoidCallback onTap;

  const _MenuCard({
    required this.item,
    required this.cardW,
    required this.cardH,
    required this.s,
    required this.W,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Strip = 38% dari tinggi kartu
    final stripH = cardH * 0.38;
    // Area ilustrasi = 62% tinggi kartu (dari atas sampai batas strip)
    final illusAreaH = cardH * 0.62;
    // Padding kiri-kanan ilustrasi
    final illusPad = W * 0.015 * kMenuCardScale;
    // Ukuran tombol & padding
    final btnSize = 20.0 * s * kMenuCardScale;
    final btnPadR = W * 0.026 * kMenuCardScale;
    final radius = 16.0 * s * kMenuCardScale;
    // Font
    final fontSize = 11.0 * s * kMenuCardScale;
    final txtPadL = W * 0.032 * kMenuCardScale;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardW,
        height: cardH,
        child: Stack(
          clipBehavior: Clip.none, // bayangan tidak terpotong
          children: [
            // Card clipped untuk konten
            ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: SizedBox(
                width: cardW,
                height: cardH,
                child: Stack(
                  children: [
                    // 1. Latar (sudah include strip kaca)
                    Positioned.fill(
                      child: Image.asset(
                        item.bgPath,
                        fit: BoxFit.fill,
                        errorBuilder: (context, error, stack) =>
                            const ColoredBox(color: Color(0xFFEEEEEE)),
                      ),
                    ),

                    // 2. Ilustrasi: area 62% atas, tidak menimpa strip
                    Positioned(
                      top: 0,
                      left: illusPad,
                      right: illusPad,
                      height: illusAreaH,
                      child: Image.asset(
                        item.assetPath,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (context, error, stack) {
                          return Center(
                            child: kDebugMode
                                ? Text(
                                    item.assetPath.split('/').last,
                                    style: const TextStyle(
                                        fontSize: 7, color: Colors.black45),
                                    textAlign: TextAlign.center,
                                  )
                                : const SizedBox(),
                          );
                        },
                      ),
                    ),

                    // 3. Strip: judul + tombol (38% bawah)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: stripH,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: txtPadL),
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.poppins(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                color: item.isBlueBg
                                    ? const Color(0xFF1E4A6B)
                                    : const Color(0xFF6B4423),
                                height: 1.12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: btnSize + btnPadR,
                            child: Padding(
                              padding: EdgeInsets.only(right: btnPadR),
                              child: Center(
                                child: Container(
                                  width: btnSize,
                                  height: btnSize,
                                  decoration: BoxDecoration(
                                    color: item.isBlueBg
                                        ? const Color(0xFFA9CBE6)
                                        : const Color(0xFFFFE59A),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    size: 11 * s,
                                    color: const Color(0xFF1E4A6B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bayangan lembut di luar ClipRRect
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
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

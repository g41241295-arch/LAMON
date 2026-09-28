// lib/screens/berita/berita_list_screen.dart
// Halaman daftar "Berita Terkini" LAMON.
// Berita pertama tampil sebagai kartu besar, sisanya sebagai kartu horizontal.

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/berita_article_model.dart';
import '../../services/berita/berita_repository.dart';
import '../../widgets/berita/berita_header.dart';
import '../../widgets/berita/berita_image.dart';
import '../../widgets/berita/berita_category_chip.dart';
import '../../widgets/berita/berita_card_small.dart';
import '../../routes/app_routes.dart';

class BeritaListScreen extends StatelessWidget {
  const BeritaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final articles = BeritaRepository.getAll();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgGradientTop,
              AppColors.bgGradientBottom,
            ],
          ),
        ),
        child: Column(
          children: [
            // ── Header tetap di atas, tidak ikut scroll ───────────────────
            const BeritaHeader(),

            // ── Konten yang bisa di-scroll ────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (articles.isNotEmpty) ...[
                      // Kartu besar untuk berita pertama (paling baru)
                      _BeritaCardHero(
                        article: articles[0],
                        onTap: () => _openDetail(context, articles[0].id),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Kartu horizontal untuk berita ke-2 dan seterusnya
                    ...articles.skip(1).map((article) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: BeritaCardSmall(
                          article: article,
                          onTap: () => _openDetail(context, article.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, String id) {
    Navigator.pushNamed(
      context,
      AppRoutes.beritaDetail,
      arguments: id,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu besar (hero) untuk berita pertama
// ─────────────────────────────────────────────────────────────────────────────
class _BeritaCardHero extends StatelessWidget {
  final BeritaArticle article;
  final VoidCallback? onTap;

  const _BeritaCardHero({required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tanggal = _formatTanggal(article.tanggal);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar lebar rasio ~3:1
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: BeritaImage(
                  assetPath: article.gambarAsset,
                  borderRadius: 0,
                  aspectRatio: 8 / 3,
                ),
              ),

              // Konten di bawah gambar
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chip kategori
                    BeritaCategoryChip(label: article.kategori),
                    const SizedBox(height: 8),

                    // Judul kartu
                    Text(
                      article.judulKartu,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4E7A),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Baris tanggal • kategori
                    Row(
                      children: [
                        Text(
                          tanggal,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2F80A8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '•',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2F80A8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          article.kategori,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2F80A8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTanggal(DateTime dt) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }
}

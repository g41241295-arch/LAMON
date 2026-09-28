// lib/screens/berita/berita_detail_screen.dart
// Halaman detail artikel berita LAMON.
// Menerima id berita sebagai argument dari route.
// Bagian "Baca juga" menggunakan pushReplacement agar tombol kembali
// selalu kembali ke halaman daftar berita.

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/berita_article_model.dart';
import '../../services/berita/berita_repository.dart';
import '../../widgets/berita/berita_header.dart';
import '../../widgets/berita/berita_image.dart';
import '../../widgets/berita/berita_category_chip.dart';
import '../../widgets/berita/berita_content_block.dart';
import '../../widgets/berita/berita_card_small.dart';
import '../../routes/app_routes.dart';

class BeritaDetailScreen extends StatelessWidget {
  final String articleId;

  const BeritaDetailScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context) {
    final article = BeritaRepository.getById(articleId);

    if (article == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
            ),
          ),
          child: const Column(
            children: [
              BeritaHeader(),
              Expanded(
                child: Center(
                  child: Text(
                    'Artikel tidak ditemukan.',
                    style: TextStyle(color: Color(0xFF1D4E7A)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tanggal = _formatTanggal(article.tanggal);

    // Ambil data "Baca juga"
    final bacaJugaArticles = article.bacaJuga
        .map((id) => BeritaRepository.getById(id))
        .whereType<BeritaArticle>()
        .toList();

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
            // ── Header tetap di atas ──────────────────────────────────────
            const BeritaHeader(),

            // ── Konten scrollable ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Gambar hero ────────────────────────────────────────
                    BeritaImage(
                      assetPath: article.gambarAsset,
                      borderRadius: 24,
                      aspectRatio: 8 / 3,
                    ),
                    const SizedBox(height: 12),

                    // ── Chip kategori ──────────────────────────────────────
                    BeritaCategoryChip(label: article.kategori),
                    const SizedBox(height: 10),

                    // ── Judul detail ───────────────────────────────────────
                    Text(
                      article.judulDetail,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D4E7A),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // ── Baris tanggal • kategori ───────────────────────────
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
                    const SizedBox(height: 12),

                    // ── Garis pemisah tipis ────────────────────────────────
                    Divider(
                      color: Colors.black.withValues(alpha: 0.08),
                      thickness: 1,
                    ),
                    const SizedBox(height: 12),

                    // ── Isi berita per blok ────────────────────────────────
                    ...article.konten.map(
                      (block) => BeritaContentBlock(block: block),
                    ),

                    // ── Sumber (opsional) ──────────────────────────────────
                    if (article.sumber != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Sumber: ${article.sumber}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7A9BB5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    // ── Bagian "Baca juga" ─────────────────────────────────
                    if (bacaJugaArticles.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Baca juga',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2F80A8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...bacaJugaArticles.map((related) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: BeritaCardSmall(
                            article: related,
                            onTap: () => _openRelated(context, related.id),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Buka detail berita terkait dengan pushReplacement agar tombol kembali
  /// selalu menuju halaman daftar berita.
  void _openRelated(BuildContext context, String id) {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.beritaDetail,
      arguments: id,
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

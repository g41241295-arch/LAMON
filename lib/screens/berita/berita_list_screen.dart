import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/berita_article_model.dart';
import '../../services/berita/berita_repository.dart';
import '../../widgets/berita/berita_header.dart';
import '../../widgets/berita/berita_category_chip.dart';
import '../../widgets/berita/berita_card_small.dart';
import '../../widgets/berita/berita_image.dart';

class BeritaListScreen extends StatelessWidget {
  const BeritaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final articles = BeritaRepository.getAll();

    // ── Latar belakang gradasi kuning (sama dengan AppScaffold / CatatMakanan) ──
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgGradientTop,    // 0xFFFFF4A8
            AppColors.bgGradientMiddle, // 0xFFFAF4C8
            AppColors.bgGradientBottom, // 0xFFFFFDE8
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const BeritaHeader(),

            // Jarak 12 px di bawah header (sama dengan CatatMakanan)
            const SizedBox(height: 12),

            Expanded(
              child: articles.isEmpty
                  ? _buildEmpty()
                  : _buildList(context, articles),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pesan kosong ──────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: AppColors.primaryLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada berita tersedia',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nantikan berita kesehatan lambung\nterbaru di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primaryText.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Daftar berita ─────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context, List<BeritaArticle> articles) {
    final firstArticle = articles.first;
    final otherArticles = articles.skip(1).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        // ── Kartu Besar (Berita Utama) ──────────────────────────────────────
        _buildFeaturedCard(context, firstArticle),

        // ── Kartu Kecil (Berita Lainnya) ────────────────────────────────────
        ...otherArticles.map((article) {
          return BeritaCardSmall(
            article: article,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/berita/detail',
                arguments: article.id,
              );
            },
          );
        }),
      ],
    );
  }

  // ── Kartu besar (berita pertama) ──────────────────────────────────────────
  Widget _buildFeaturedCard(BuildContext context, BeritaArticle article) {
    // Format tanggal; null jika tidak tersedia
    String? formattedDate;
    if (article.tanggal != null) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      final d = article.tanggal!;
      formattedDate =
          '${d.day} ${months[d.month - 1]} ${d.year} • ${article.kategori}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/berita/detail',
                arguments: article.id,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar hero rasio ~3:1
                Semantics(
                  label: 'Gambar berita: ${article.judul}',
                  child: BeritaImage(
                    assetPath: article.gambarAsset,
                    width: double.infinity,
                    height: 160,
                    borderRadius: 24,
                    alignment: article.gambarAlignment,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BeritaCategoryChip(category: article.kategori),
                      const SizedBox(height: 10),
                      Text(
                        article.judul,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4E7A),
                          height: 1.4,
                        ),
                      ),
                      // Baris meta: hanya tampil jika tanggal tersedia,
                      // agar kategori tidak dobel dengan chip di atas
                      if (formattedDate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2F80A8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

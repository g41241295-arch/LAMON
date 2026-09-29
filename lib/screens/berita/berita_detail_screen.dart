import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../services/berita/berita_repository.dart';
import '../../widgets/berita/berita_header.dart';
import '../../widgets/berita/berita_image.dart';
import '../../widgets/berita/berita_category_chip.dart';
import '../../widgets/berita/berita_content_block.dart';
import '../../widgets/berita/berita_card_small.dart';

class BeritaDetailScreen extends StatelessWidget {
  final String articleId;

  const BeritaDetailScreen({super.key, required this.articleId});

  // ── Gradasi kuning (sama dengan AppScaffold / BeritaListScreen) ───────────
  static const _gradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.bgGradientTop,    // 0xFFFFF4A8
        AppColors.bgGradientMiddle, // 0xFFFAF4C8
        AppColors.bgGradientBottom, // 0xFFFFFDE8
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final article = BeritaRepository.getAll()
        .where((e) => e.id == articleId)
        .firstOrNull;

    // ── Artikel tidak ditemukan ───────────────────────────────────────────
    if (article == null) {
      return Container(
        decoration: _gradient,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const BeritaHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
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
                          'Berita tidak ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Artikel yang Anda cari mungkin sudah\ntidak tersedia atau terjadi kesalahan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryText.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Kembali'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
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

    // ── Format tanggal; null jika tidak tersedia ───────────────────────────
    String? formattedDate;
    if (article.tanggal != null) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      final d = article.tanggal!;
      formattedDate = '${d.day} ${months[d.month - 1]} ${d.year}';
    }

    return Container(
      decoration: _gradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const BeritaHeader(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 48),
                children: [
                  // ── Gambar Hero (rasio ~3:1) ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Semantics(
                      label: 'Gambar berita: ${article.judul}',
                      child: BeritaImage(
                        assetPath: article.gambarAsset,
                        width: double.infinity,
                        height: 160,
                        borderRadius: 24,
                        alignment: article.gambarAlignment,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Chip Kategori + Tanggal ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        BeritaCategoryChip(category: article.kategori),
                        if (formattedDate != null) ...[
                          const SizedBox(width: 10),
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

                  const SizedBox(height: 14),

                  // ── Judul ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      article.judul,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4E7A),
                        height: 1.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Garis pemisah ───────────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(
                      color: Color(0xFFE2ECF2),
                      thickness: 1,
                      height: 1,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Isi Berita ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: article.konten.map((block) {
                        return BeritaContentBlockWidget(block: block);
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Baris Sumber ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sumber: ${article.sumberNama}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2F80A8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Touch area minimal 48 px (WCAG tap target)
                        InkWell(
                          onTap: () async {
                            final Uri url = Uri.parse(article.sumberUrl);
                            if (!await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            )) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Tidak dapat membuka tautan'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Baca artikel asli',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2F80A8),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.open_in_new,
                                  size: 14,
                                  color: Color(0xFF2F80A8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Baca Juga ───────────────────────────────────────────
                  if (article.bacaJuga.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Baca juga',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F80A8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: article.bacaJuga.map((id) {
                          final related = BeritaRepository.getById(id);
                          return BeritaCardSmall(
                            article: related,
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/berita/detail',
                                arguments: related.id,
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/berita/berita_repository.dart';
import '../../widgets/berita/berita_header.dart';
import '../../widgets/berita/berita_image.dart';
import '../../widgets/berita/berita_category_chip.dart';
import '../../widgets/berita/berita_card_small.dart';

class BeritaListScreen extends StatelessWidget {
  const BeritaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final articles = BeritaRepository.getAll();
    if (articles.isEmpty) return const Scaffold(body: Center(child: Text('Tidak ada berita')));

    final firstArticle = articles.first;
    final otherArticles = articles.skip(1).toList();

    String formattedDateFirst = '';
    if (firstArticle.tanggal != null) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      formattedDateFirst = '${firstArticle.tanggal!.day} ${months[firstArticle.tanggal!.month - 1]} ${firstArticle.tanggal!.year} • ';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // light background
      body: Column(
        children: [
          const BeritaHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Kartu Besar (Berita Utama)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.pushNamed(context, '/berita/detail', arguments: firstArticle.id);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BeritaImage(
                            assetPath: firstArticle.gambarAsset,
                            width: double.infinity,
                            height: 140, // rasio kira-kira 3:1
                            borderRadius: 24,
                            alignment: firstArticle.gambarAlignment,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BeritaCategoryChip(category: firstArticle.kategori),
                                const SizedBox(height: 12),
                                Text(
                                  firstArticle.judul,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D4E7A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$formattedDateFirst${firstArticle.kategori}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2F80A8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // List Berita Lainnya
                ...otherArticles.map((article) {
                  return BeritaCardSmall(
                    article: article,
                    onTap: () {
                      Navigator.pushNamed(context, '/berita/detail', arguments: article.id);
                    },
                  );
                }),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

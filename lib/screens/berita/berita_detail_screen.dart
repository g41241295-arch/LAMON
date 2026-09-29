import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/berita/berita_repository.dart';
import '../../widgets/berita/berita_header.dart';
import '../../widgets/berita/berita_image.dart';
import '../../widgets/berita/berita_category_chip.dart';
import '../../widgets/berita/berita_content_block.dart';
import '../../widgets/berita/berita_card_small.dart';

class BeritaDetailScreen extends StatelessWidget {
  final String articleId;

  const BeritaDetailScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context) {
    final article = BeritaRepository.getAll().where((e) => e.id == articleId).firstOrNull;

    if (article == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const BeritaHeader(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Berita tidak ditemukan.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    String formattedDate = '';
    if (article.tanggal != null) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      formattedDate = '${article.tanggal!.day} ${months[article.tanggal!.month - 1]} ${article.tanggal!.year} • ';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const BeritaHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                // Gambar Hero
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: BeritaImage(
                    assetPath: article.gambarAsset,
                    width: double.infinity,
                    height: 180,
                    borderRadius: 24,
                    alignment: article.gambarAlignment,
                  ),
                ),
                
                // Chip Kategori & Tanggal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      BeritaCategoryChip(category: article.kategori),
                      const SizedBox(width: 12),
                      if (formattedDate.isNotEmpty)
                        Text(
                          formattedDate.substring(0, formattedDate.length - 3), // Hapus ' • '
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2F80A8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Judul
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
                
                const SizedBox(height: 16),
                
                // Garis pemisah tipis
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(color: Color(0xFFE2ECF2), thickness: 1, height: 1),
                ),
                
                const SizedBox(height: 20),
                
                // Isi Berita
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
                
                // Baris Sumber
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
                      InkWell(
                        onTap: () async {
                          final Uri url = Uri.parse(article.sumberUrl);
                          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tidak dapat membuka tautan')),
                              );
                            }
                          }
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Baca Juga
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
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: article.bacaJuga.map((id) {
                        final related = BeritaRepository.getById(id);
                        return BeritaCardSmall(
                          article: related,
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/berita/detail', arguments: related.id);
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
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/berita_article_model.dart';
import 'berita_image.dart';

class BeritaCardSmall extends StatelessWidget {
  final BeritaArticle article;
  final VoidCallback onTap;

  const BeritaCardSmall({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String formattedDate = '';
    if (article.tanggal != null) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      formattedDate = '${article.tanggal!.day} ${months[article.tanggal!.month - 1]} ${article.tanggal!.year} • ';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BeritaImage(
                  assetPath: article.gambarAsset,
                  width: 84,
                  height: 80,
                  borderRadius: 16,
                  alignment: article.gambarAlignment,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.judul,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4E7A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$formattedDate${article.kategori}',
                        style: const TextStyle(
                          fontSize: 11,
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
    );
  }
}

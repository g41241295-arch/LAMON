// lib/widgets/berita/berita_card_small.dart
// Kartu berita horizontal kecil untuk daftar sekunder dan bagian "Baca juga".

import 'package:flutter/material.dart';
import '../../models/berita_article_model.dart';
import 'berita_image.dart';

/// Format tanggal manual dengan singkatan bulan Indonesia
/// tanpa bergantung pada locale intl.
String formatTanggalBerita(DateTime dt) {
  const bulan = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return '${dt.day} ${bulan[dt.month]} ${dt.year}';
}

class BeritaCardSmall extends StatelessWidget {
  final BeritaArticle article;
  final VoidCallback? onTap;

  const BeritaCardSmall({
    super.key,
    required this.article,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Thumbnail ──────────────────────────────────────────────
                SizedBox(
                  width: 84,
                  height: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BeritaImage(
                      assetPath: article.gambarAsset,
                      borderRadius: 0,
                      aspectRatio: 84 / 80,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ── Konten teks ────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.judulKartu,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4E7A),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            formatTanggalBerita(article.tanggal),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2F80A8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '•',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2F80A8),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              article.kategori,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2F80A8),
                                fontWeight: FontWeight.w500,
                              ),
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
      ),
    );
  }
}

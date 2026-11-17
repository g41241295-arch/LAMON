import 'package:flutter/material.dart';
import '../../models/berita_article_model.dart';
import 'berita_image.dart';

class BeritaCardSmall extends StatelessWidget {
  final BeritaArticle article;
  final VoidCallback onTap;

  const BeritaCardSmall({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Format tanggal
    String? formattedDate;
    if (article.tanggal != null) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      final d = article.tanggal!;
      formattedDate = '${d.day} ${months[d.month - 1]} ${d.year}';
    }

    final sourceText = article.sumberNama.isNotEmpty
        ? article.sumberNama
        : 'LAMON';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ─── Teks Berita di Sebelah Kiri (Sesuai Referensi) ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Judul Berita
                    Text(
                      article.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C4E68),
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Sumber & Tanggal
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sourceText,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B8797),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (formattedDate != null) ...[
                          const Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF9CB3C2),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9CB3C2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // ─── Thumbnail Kotak Rounded di Sebelah Kanan (Sesuai Referensi) ───
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: BeritaImage(
                    gambarUrl: article.gambarUrl.isNotEmpty
                        ? article.gambarUrl
                        : null,
                    gambarAsset: article.gambarAsset.isNotEmpty
                        ? article.gambarAsset
                        : null,
                    width: 76,
                    height: 76,
                    borderRadius: 14,
                    alignment: article.gambarAlignment,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


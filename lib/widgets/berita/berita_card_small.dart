import 'package:flutter/material.dart';
import '../../models/berita_article_model.dart';
import 'berita_image.dart';

class BeritaCardSmall extends StatelessWidget {
  final BeritaArticle article;
  final VoidCallback onTap;

  const BeritaCardSmall({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        // Material sebagai pembungkus terluar agar InkWell mendapat hit-test yang benar
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  Semantics(
                    label: 'Gambar berita: ${article.judul}',
                    child: BeritaImage(
                      assetPath: article.gambarAsset,
                      width: 84,
                      height: 80,
                      borderRadius: 16,
                      alignment: article.gambarAlignment,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Teks
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            article.judul,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D4E7A),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (formattedDate != null)
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2F80A8),
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            Text(
                              article.kategori,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2F80A8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

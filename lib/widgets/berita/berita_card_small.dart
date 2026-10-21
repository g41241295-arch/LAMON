import 'package:flutter/material.dart';
import '../../models/berita_article_model.dart';
import 'berita_image.dart';

class BeritaCardSmall extends StatefulWidget {
  final BeritaArticle article;
  final VoidCallback onTap;

  const BeritaCardSmall({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  State<BeritaCardSmall> createState() => _BeritaCardSmallState();
}

class _BeritaCardSmallState extends State<BeritaCardSmall> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? const Color(0xFF1D4E7A).withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: _isHovered ? 16 : 10,
              offset: Offset(0, _isHovered ? 6 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF1F8FA),
                  Color(0xFFDCEEF5),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onHover: (hovered) {
                if (_isHovered != hovered) {
                  setState(() => _isHovered = hovered);
                }
              },
              onTap: widget.onTap,
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
      ),
    );
  }
}

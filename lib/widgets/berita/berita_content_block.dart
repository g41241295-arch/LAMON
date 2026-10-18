import 'package:flutter/material.dart';
import '../../models/berita_article_model.dart';

class BeritaContentBlockWidget extends StatelessWidget {
  final BeritaBlock block;

  const BeritaContentBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    if (block is BeritaBlockParagraph) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          (block as BeritaBlockParagraph).text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.6,
            color: Color(0xFF1D4E7A),
          ),
          textAlign: TextAlign.left,
        ),
      );
    } else if (block is BeritaBlockSubjudul) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          (block as BeritaBlockSubjudul).text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D4E7A),
          ),
        ),
      );
    } else if (block is BeritaBlockButirAngka) {
      final b = block as BeritaBlockButirAngka;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${b.nomor}. ${b.judul}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D4E7A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              b.isi,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: Color(0xFF1D4E7A),
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      );
    } else if (block is BeritaBlockBulletList) {
      final b = block as BeritaBlockBulletList;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: b.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: Color(0xFF1D4E7A),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: Color(0xFF1D4E7A),
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    } else if (block is BeritaBlockTips) {
      final b = block as BeritaBlockTips;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  color: const Color(0xFF2F80A8), // strip biru tebal
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF1D4E7A),
                          fontFamily: 'Poppins', // Opsional, mengikuti tema
                        ),
                        children: [
                          const TextSpan(
                            text: 'Tips: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F80A8),
                            ),
                          ),
                          TextSpan(text: b.isi),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (block is BeritaBlockTandaBahaya) {
      final b = block as BeritaBlockTandaBahaya;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2D5B4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: b.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFD62828),
                        size: 16,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB3261E),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

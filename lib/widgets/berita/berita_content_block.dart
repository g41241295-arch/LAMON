// lib/widgets/berita/berita_content_block.dart
// Renderer untuk setiap blok konten artikel berita.
// Setiap tipe BeritaBlock di-map ke widget yang sesuai.

import 'package:flutter/material.dart';
import '../../models/berita_article_model.dart';

class BeritaContentBlock extends StatelessWidget {
  final BeritaBlock block;

  const BeritaContentBlock({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      BeritaBlockParagraph b => _buildParagraph(b.text),
      BeritaBlockSubjudul b => _buildSubjudul(b.text),
      BeritaBlockJudulBagian b => _buildJudulBagian(b.text),
      BeritaBlockButirAngka b => _buildButirAngka(b),
      BeritaBlockBulletList b => _buildBulletList(b.items),
      BeritaBlockArrowList b => _buildArrowList(b.items),
      BeritaBlockTips b => _buildTips(b.isi),
      BeritaBlockPerbandingan b => _buildPerbandingan(b),
      BeritaBlockTandaBahaya b => _buildTandaBahaya(b),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Paragraf
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Color(0xFF1D4E7A),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Subjudul bold
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSubjudul(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          height: 1.35,
          color: Color(0xFF1D4E7A),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Judul bagian (warna aksen biru, lebih besar)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildJudulBagian(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2F80A8),
          height: 1.3,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Butir berangka
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildButirAngka(BeritaBlockButirAngka b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${b.nomor}. ${b.judul}',
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D4E7A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            b.isi,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF1D4E7A),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bullet list "•"
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBulletList(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1D4E7A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF1D4E7A),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Arrow list ">"
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildArrowList(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '> ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2F80A8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF1D4E7A),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Kotak tips
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTips(String isi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Strip biru tebal di sisi kiri (~6px)
              Container(
                width: 6,
                color: const Color(0xFF2F80A8),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: Color(0xFF1D4E7A),
                      ),
                      children: [
                        const TextSpan(
                          text: 'Tips: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2F80A8),
                          ),
                        ),
                        TextSpan(text: isi),
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
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dua kartu perbandingan
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPerbandingan(BeritaBlockPerbandingan b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kartu hijau
          Expanded(
            child: _buildPerbandinganCard(
              judul: b.judulHijau,
              isi: b.isiHijau,
              judulColor: const Color(0xFF59B41E),
              borderColor: const Color(0xFFB8E0A0),
            ),
          ),
          const SizedBox(width: 10),
          // Kartu merah
          Expanded(
            child: _buildPerbandinganCard(
              judul: b.judulMerah,
              isi: b.isiMerah,
              judulColor: const Color(0xFFD62828),
              borderColor: const Color(0xFFF5C2C2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerbandinganCard({
    required String judul,
    required String isi,
    required Color judulColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: judulColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isi,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF1D4E7A),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Kotak tanda bahaya
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTandaBahaya(BeritaBlockTandaBahaya b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                  // Ikon segitiga peringatan merah outline
                  const Padding(
                    padding: EdgeInsets.only(top: 1, right: 10),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFD62828),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF8B2000),
                        fontWeight: FontWeight.w500,
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
}

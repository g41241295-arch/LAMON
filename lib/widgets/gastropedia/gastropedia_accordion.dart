import 'package:flutter/material.dart';

/// Card bubble untuk section Deskripsi, Manfaat, dan Kandungan Gizi di Detail Makanan.
/// Ditampilkan permanen terbuka tanpa ikon chevron dan tanpa interaksi collapse.
class GastropediaAccordion extends StatelessWidget {
  final String title;
  final Widget content;
  final bool initialExpanded;

  const GastropediaAccordion({
    super.key,
    required this.title,
    required this.content,
    this.initialExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4EEF5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card (Judul Bold tanpa ikon chevron, latar gradasi krem)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFDE8),
                  Color(0xFFF6E8B6),
                ],
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E5D7D),
                letterSpacing: -0.2,
              ),
            ),
          ),

          // Badan Konten (permanen terbuka dengan border pemisah krem dan padding rapi)
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFDEC99B),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: content,
          ),
        ],
      ),
    );
  }
}


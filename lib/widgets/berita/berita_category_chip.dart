// lib/widgets/berita/berita_category_chip.dart
// Chip kategori pill kecil dengan border tipis abu-biru dan teks biru.

import 'package:flutter/material.dart';

class BeritaCategoryChip extends StatelessWidget {
  final String label;

  const BeritaCategoryChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB8D0DF),
          width: 1.0,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2F80A8),
          height: 1.2,
        ),
      ),
    );
  }
}

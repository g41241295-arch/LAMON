// lib/widgets/berita/berita_image.dart
// Widget gambar berita yang reusable.
// Jika file gambar belum ada, tampilkan placeholder gradasi kuning dengan ikon.
// Gunakan widget ini untuk semua gambar berita agar app tidak error.

import 'package:flutter/material.dart';

class BeritaImage extends StatelessWidget {
  final String assetPath;
  final double borderRadius;
  final double aspectRatio;

  const BeritaImage({
    super.key,
    required this.assetPath,
    this.borderRadius = 20,
    this.aspectRatio = 8 / 3,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Placeholder sementara – gradasi kuning lembut dengan ikon
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF0B3),
                    Color(0xFFFFD966),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.article_rounded,
                  color: Color(0xFF9E8000),
                  size: 48,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

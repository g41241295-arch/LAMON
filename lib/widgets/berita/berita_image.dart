import 'package:flutter/material.dart';

class BeritaImage extends StatelessWidget {
  final String assetPath;
  final double borderRadius;
  final Alignment alignment;
  final double? width;
  final double? height;

  const BeritaImage({
    super.key,
    required this.assetPath,
    this.borderRadius = 0,
    this.alignment = Alignment.center,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: alignment,
        cacheWidth: 1080,
        semanticLabel: 'Gambar Berita',
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading image $assetPath: $error');
          return Container(
            width: width,
            height: height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFCF9E0), Color(0xFFFBE9A1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.article_outlined,
                color: Color(0xFF1D4E7A),
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }
}


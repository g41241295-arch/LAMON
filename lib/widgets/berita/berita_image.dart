import 'dart:convert';
import 'package:flutter/material.dart';

class BeritaImage extends StatelessWidget {
  final String? gambarUrl;
  final String? gambarAsset;
  final String? assetPath;
  final double borderRadius;
  final Alignment alignment;
  final double? width;
  final double? height;
  final BoxFit fit;

  const BeritaImage({
    super.key,
    this.gambarUrl,
    this.gambarAsset,
    this.assetPath,
    this.borderRadius = 0,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = (gambarUrl ?? '').trim();
    final asset = (gambarAsset ?? assetPath ?? '').trim();

    Widget imageWidget;

    // Prioritas 1A: Data URI (Base64 dari fallback offline/direct storage)
    if (url.isNotEmpty && url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64String = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64String);
        debugPrint('[BeritaImage] Merender Image.memory (base64 data URI, ${bytes.length} bytes)');
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('[BeritaImage] Gagal memuat data:image memory: $error');
            return _buildAssetOrFallback(asset);
          },
        );
      } catch (e) {
        debugPrint('[BeritaImage] Error parsing base64 data URI: $e');
        imageWidget = _buildAssetOrFallback(asset);
      }
    }
    // Prioritas 1B: URL Jaringan (Firebase Storage / Web HTTPS)
    else if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
      debugPrint('[BeritaImage] Merender Image.network: $url');
      imageWidget = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF134563),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('[BeritaImage] Gagal memuat Image.network ($url): $error');
          return _buildAssetOrFallback(asset);
        },
      );
    } else {
      imageWidget = _buildAssetOrFallback(asset);
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  Widget _buildAssetOrFallback(String asset) {
    // Prioritas 2: Asset lokal bawaan aplikasi
    if (asset.isNotEmpty && asset.startsWith('assets/')) {
      debugPrint('[BeritaImage] Merender Image.asset: $asset');
      return Image.asset(
        asset,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        cacheWidth: 1080,
        semanticLabel: 'Gambar Berita',
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('[BeritaImage] Gagal memuat Image.asset ($asset): $error');
          return _buildFallback();
        },
      );
    }
    // Prioritas 3: Gambar cadangan default
    return _buildFallback();
  }

  Widget _buildFallback() {
    debugPrint('[BeritaImage] Merender placeholder cadangan');
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
  }
}

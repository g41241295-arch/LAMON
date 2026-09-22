import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gastropedia/gastropedia_header.dart';
import '../../routes/app_routes.dart';

class GastropediaScreen extends StatelessWidget {
  const GastropediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recommendedItem = GastropediaData.getRecommended();

    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Top Bar
            const SizedBox(height: 6),
            const GastropediaHeader(title: 'Gastropedia'),

            const SizedBox(height: 18),

            // 2. Section "Kategori"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Kategori (Pill Putih Border Biru)
                  _buildSectionBadge('Kategori'),

                  const SizedBox(height: 12),

                  // 3 Kartu Kategori
                  Row(
                    children: GastropediaCategory.values.map((category) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.gastropediaCategory,
                                arguments: category,
                              );
                            },
                            child: Container(
                              height: 105,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Gambar Thumbnail Kategori
                                  Image.asset(
                                    category.thumbnailAsset,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: const Color(0xFF639BC6),
                                      child: const Icon(
                                        Icons.restaurant_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),

                                  // Overlay Gelap Lembut
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.2),
                                          Colors.black.withValues(alpha: 0.55),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Teks Kategori di Tengah
                                  Center(
                                    child: Text(
                                      category.badgeText,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black54,
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
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
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 3. Section "Rekomendasi Topik"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Rekomendasi Topik
                  _buildSectionBadge('Rekomendasi Topik'),

                  const SizedBox(height: 14),

                  // Baris Kartu Rekomendasi & Tombol Panah
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Indikator Panah Kiri Samping
                      Container(
                        width: 28,
                        height: 20,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF639BC6),
                            width: 1.2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 14,
                            color: Color(0xFF1E5D7D),
                          ),
                        ),
                      ),

                      // Kartu Besar Brokoli Chicken
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.gastropediaDetail,
                              arguments: recommendedItem,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF639BC6),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Foto Utama Brokoli Chicken
                                SizedBox(
                                  height: 160,
                                  child: Image.asset(
                                    recommendedItem.imageAsset,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: const Color(0xFFEBF3F8),
                                      child: const Icon(
                                        Icons.image_outlined,
                                        size: 48,
                                        color: Color(0xFF639BC6),
                                      ),
                                    ),
                                  ),
                                ),

                                // Label Judul di Bawah
                                Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    recommendedItem.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E5D7D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Badge Pill Bergaris Biru (Sesuai Mockup)
  Widget _buildSectionBadge(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF639BC6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1E5D7D),
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

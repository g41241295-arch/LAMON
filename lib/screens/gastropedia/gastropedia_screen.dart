import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gastropedia/gastropedia_header.dart';
import '../../widgets/gastropedia/category_item.dart';
import '../../widgets/gastropedia/recommendation_card.dart';
import '../../widgets/gastropedia/popular_food_card.dart';
import '../../routes/app_routes.dart';

class GastropediaScreen extends StatelessWidget {
  const GastropediaScreen({super.key});

  // ── Data Rekomendasi: ambil semua item yg isRecommended=true,
  //    fallback ke 2 item pertama agar horizontal scroll selalu terisi.
  static List<GastropediaItem> _getRecommendedItems() {
    final recommended =
        GastropediaData.items.where((i) => i.isRecommended).toList();
    if (recommended.isEmpty) {
      return GastropediaData.items.take(2).toList();
    }
    // Pastikan minimal 2 item untuk efek scroll terlihat
    if (recommended.length < 2) {
      final extras = GastropediaData.items
          .where((i) => !i.isRecommended)
          .take(2 - recommended.length);
      return [...recommended, ...extras];
    }
    return recommended;
  }

  // ── Data Makanan Populer Dummy ──
  static List<PopularFoodItem> _getPopularItems() {
    return [
      PopularFoodItem(
        name: "Salad Sayur Segar",
        imageAsset: "assets/images/gastropedia/food_1.png", // Akan menggunakan errorBuilder jika tidak ada
        rating: 4.8,
        ratingCount: 124,
      ),
      PopularFoodItem(
        name: "Sup Ayam Diet",
        imageAsset: "assets/images/gastropedia/food_2.png",
        rating: 4.5,
        ratingCount: 89,
      ),
      PopularFoodItem(
        name: "Smoothie Bowl Buah Naga",
        imageAsset: "assets/images/gastropedia/food_3.png",
        rating: 4.9,
        ratingCount: 230,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final recommendedItems = _getRecommendedItems();

    return AppScaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════
            // 1. Header (tidak diubah)
            // ═══════════════════════════════════════════
            const SizedBox(height: 6),
            const GastropediaHeader(title: 'Gastropedia'),

            const SizedBox(height: 28),

            // ═══════════════════════════════════════════
            // 2. Section "Kategori"
            // ═══════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul heading rata kiri (bukan pill badge)
                  _SectionHeading(title: 'Kategori'),

                  const SizedBox(height: 16),

                  // 3 kategori sejajar dalam satu baris, jarak merata
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: GastropediaCategory.values.map((category) {
                      return CategoryItem(
                        category: category,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.gastropediaCategory,
                            arguments: category,
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ═══════════════════════════════════════════
            // 3. Section "Rekomendasi Topik"
            // ═══════════════════════════════════════════
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeading(
                title: 'Rekomendasi Topik',
              ),
            ),

            const SizedBox(height: 14),

            // Horizontal scroll list kartu rekomendasi
            SizedBox(
              height: 185, // tinggi tetap sesuai konten kartu
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                // Padding kiri = 20dp, kanan = 20dp (via padding pada item terakhir)
                padding: const EdgeInsets.only(left: 20, right: 8),
                itemCount: recommendedItems.length,
                itemBuilder: (context, index) {
                  final item = recommendedItems[index];
                  return Padding(
                    // Jarak antar kartu 12dp; kartu terakhir ada extra 12dp di kanan
                    padding: EdgeInsets.only(
                      right: index == recommendedItems.length - 1 ? 12 : 12,
                    ),
                    child: RecommendationCard(
                      item: item,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.gastropediaDetail,
                          arguments: item,
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // ═══════════════════════════════════════════
            // 4. Section "Makanan Populer"
            // ═══════════════════════════════════════════
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeading(
                title: 'Makanan Populer',
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: _getPopularItems().map((item) {
                  return PopularFoodCard(
                    item: item,
                    onTap: () {
                      // Tindakan saat diklik (bisa dikosongkan untuk sementara)
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widget Helper: Judul Section heading tebal rata kiri
// ─────────────────────────────────────────────────────────────
class _SectionHeading extends StatelessWidget {
  final String title;

  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E5D7D),
        letterSpacing: -0.3,
      ),
    );
  }
}


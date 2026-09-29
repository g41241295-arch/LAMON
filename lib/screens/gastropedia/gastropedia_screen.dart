import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gastropedia/gastropedia_header.dart';
import '../../widgets/gastropedia/category_item.dart';
import '../../widgets/gastropedia/recommendation_card.dart';
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeadingWithLink(
                title: 'Rekomendasi Topik',
                linkText: 'Lihat Semua >',
                onLinkTap: () {
                  // Navigasi ke halaman daftar semua rekomendasi
                  // (saat ini menuju kategori makanan sebagai default)
                  Navigator.pushNamed(
                    context,
                    AppRoutes.gastropediaCategory,
                    arguments: GastropediaCategory.makanan,
                  );
                },
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

// ─────────────────────────────────────────────────────────────
// Widget Helper: Judul Section + link "Lihat Semua >" di kanan
// ─────────────────────────────────────────────────────────────
class _SectionHeadingWithLink extends StatelessWidget {
  final String title;
  final String linkText;
  final VoidCallback? onLinkTap;

  const _SectionHeadingWithLink({
    required this.title,
    required this.linkText,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E5D7D),
            letterSpacing: -0.3,
          ),
        ),
        GestureDetector(
          onTap: onLinkTap,
          child: Text(
            linkText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF639BC6),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}

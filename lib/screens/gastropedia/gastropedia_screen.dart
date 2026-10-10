import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gastropedia/gastropedia_header.dart';
import '../../widgets/gastropedia/category_item.dart';
import '../../widgets/gastropedia/recommendation_card.dart';
import '../../widgets/gastropedia/popular_food_card.dart';
import '../../routes/app_routes.dart';

class GastropediaScreen extends StatefulWidget {
  const GastropediaScreen({super.key});

  @override
  State<GastropediaScreen> createState() => _GastropediaScreenState();
}

class _GastropediaScreenState extends State<GastropediaScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data Rekomendasi: ambil semua item yg isRecommended=true,
  //    fallback ke 2 item pertama agar selalu terisi.
  static List<GastropediaItem> _getRecommendedItems() {
    final recommended =
        GastropediaData.items.where((i) => i.isRecommended).toList();
    if (recommended.isEmpty) {
      return GastropediaData.items.take(2).toList();
    }
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
        imageAsset:
            "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200",
        rating: 4.8,
        ratingCount: 124,
      ),
      PopularFoodItem(
        name: "Sup Ayam Diet",
        imageAsset:
            "https://images.unsplash.com/photo-1547592166-23ac45744acd?w=200",
        rating: 4.5,
        ratingCount: 89,
      ),
      PopularFoodItem(
        name: "Smoothie Bowl Buah Naga",
        imageAsset:
            "https://images.unsplash.com/photo-1496412705862-e0088f16f791?w=200",
        rating: 4.9,
        ratingCount: 230,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final isSearching = query.isNotEmpty;
    final searchResults = isSearching
        ? GastropediaData.items
            .where((item) => item.name.toLowerCase().contains(query))
            .toList()
        : <GastropediaItem>[];

    final recommendedItems = _getRecommendedItems();

    return AppScaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════
            // 1. Header (Tombol kembali bulat + pill judul)
            // ═══════════════════════════════════════════
            const SizedBox(height: 6),
            const GastropediaHeader(title: 'Gastropedia'),

            const SizedBox(height: 14),

            // ═══════════════════════════════════════════
            // 2. Kolom Pencarian (Rounded Pill)
            // ═══════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFE2ECF2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF7C8E97),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E5D7D),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Cari makanan atau buah...',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CB3C2),
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (isSearching)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2ECF2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xFF1E5D7D),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════
            // 3. Tampilan Hasil Pencarian (jika aktif)
            // ═══════════════════════════════════════════
            if (isSearching) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionHeading(
                          title: 'Hasil Pencarian ("${_searchController.text.trim()}")',
                        ),
                        Text(
                          '${searchResults.length} ditemukan',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7C8E97),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (searchResults.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFFBEA),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.search_off_rounded,
                                  size: 32,
                                  color: Color(0xFFE5983A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Makanan tidak ditemukan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E5D7D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Coba kata kunci lain seperti bayam, apel, brokoli...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF7C8E97),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final item = searchResults[index];
                          return RecommendationCard(
                            item: item,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.gastropediaDetail,
                                arguments: item,
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ] else ...[
              // ═══════════════════════════════════════════
              // 4. Section "Kategori" (3 Kartu Kotak Sejajar)
              // ═══════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeading(title: 'Kategori'),
                    const SizedBox(height: 14),

                    // 3 kartu kotak sejajar dalam satu baris, lebar dibagi rata
                    Row(
                      children: GastropediaCategory.values.map((category) {
                        final isLast =
                            category == GastropediaCategory.values.last;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : 10),
                            child: CategoryItem(
                              category: category,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.gastropediaCategory,
                                  arguments: category,
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ═══════════════════════════════════════════
              // 5. Section "Rekomendasi" (2 Kartu Berdampingan)
              // ═══════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionHeading(title: 'Rekomendasi'),
                    Semantics(
                      button: true,
                      label: 'Lihat Semua Rekomendasi',
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.gastropediaCategory,
                            arguments: 'rekomendasi',
                          );
                        },
                        child: const Text(
                          'Lihat Semua >',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF276F8F),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2 kartu Rekomendasi berdampingan (grid 2 kolom seimbang)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: RecommendationCard(
                        item: recommendedItems[0],
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.gastropediaDetail,
                            arguments: recommendedItems[0],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RecommendationCard(
                        item: recommendedItems[1],
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.gastropediaDetail,
                            arguments: recommendedItems[1],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ═══════════════════════════════════════════
              // 6. Section "Makanan Populer"
              // ═══════════════════════════════════════════
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _SectionHeading(title: 'Makanan Populer'),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: _getPopularItems().map((item) {
                    return PopularFoodCard(
                      item: item,
                      onTap: () {
                        // Buka detail jika nama cocok dengan katalog data
                        final matched = GastropediaData.items.firstWhere(
                          (g) =>
                              item.name
                                  .toLowerCase()
                                  .contains(g.name.toLowerCase()) ||
                              g.name
                                  .toLowerCase()
                                  .contains(item.name.toLowerCase()),
                          orElse: () => GastropediaData.items.first,
                        );
                        Navigator.pushNamed(
                          context,
                          AppRoutes.gastropediaDetail,
                          arguments: matched,
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
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


import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gastropedia/gastropedia_header.dart';
import '../../routes/app_routes.dart';

class GastropediaCategoryScreen extends StatelessWidget {
  final GastropediaCategory? category;
  final bool isRecommendationMode;

  const GastropediaCategoryScreen({
    super.key,
    this.category,
    this.isRecommendationMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = isRecommendationMode
        ? 'Rekomendasi'
        : (category?.label ?? 'Makanan');

    final String subtitle;
    if (isRecommendationMode) {
      subtitle = 'Pilihan makanan sehat';
    } else {
      switch (category) {
        case GastropediaCategory.makanan:
          subtitle = 'Pilih kategori makanan';
          break;
        case GastropediaCategory.buah:
          subtitle = 'Pilih buah favoritmu';
          break;
        case GastropediaCategory.sayuran:
          subtitle = 'Pilih sayuran segar ramah lambung';
          break;
        case null:
          subtitle = 'Pilihan makanan sehat';
          break;
      }
    }

    final List<GastropediaItem> items;
    if (isRecommendationMode) {
      items = GastropediaData.items.where((i) => i.isRecommended).toList();
    } else if (category != null) {
      items = GastropediaData.getByCategory(category!);
    } else {
      items = GastropediaData.items;
    }

    return AppScaffold(
      body: Column(
        children: [
          const SizedBox(height: 6),

          // 1. Header Top Bar
          GastropediaHeader(title: title),

          // 2. Subjudul kecil di bawah header
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF527F97),
                letterSpacing: -0.1,
              ),
            ),
          ),

          // 3. Grid 2 Kolom (Card List)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return Semantics(
                  button: true,
                  label: item.name,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.gastropediaDetail,
                        arguments: item,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2ECF2),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Foto Makanan Mengisi Bagian Atas
                          Expanded(
                            child: Image.asset(
                              item.imageAsset,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, _, _) => Container(
                                color: const Color(0xFFEBF3F8),
                                child: const Icon(
                                  Icons.restaurant_rounded,
                                  color: Color(0xFF639BC6),
                                  size: 36,
                                ),
                              ),
                            ),
                          ),

                          // Bar Bawah: Judul Makanan + Tombol Chevron Bulat Berlatar Kuning
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E5D7D),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6E8B6),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFDEC99B),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: Color(0xFF1E5D7D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';
import '../../services/ensiklopedia_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gastropedia/gastropedia_header.dart';
import '../../widgets/gastropedia/recommendation_card.dart';
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
      subtitle = 'Pilihan makanan sehat & ramah lambung';
    } else {
      switch (category) {
        case GastropediaCategory.makanan:
          subtitle = 'Pilihan olahan & lauk sehat ramah lambung';
          break;
        case GastropediaCategory.buah:
          subtitle = 'Pilihan buah segar alami kaya antioksidan';
          break;
        case GastropediaCategory.sayuran:
          subtitle = 'Pilihan sayuran berserat lembut untuk pencernaan';
          break;
        case null:
          subtitle = 'Pilihan makanan sehat ramah lambung';
          break;
      }
    }

    return AppScaffold(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFCFBF7),
          Color(0xFFF7F4EB),
          Color(0xFFF2EEDB),
        ],
      ),
      body: StreamBuilder<List<GastropediaItem>>(
        stream: EnsiklopediaService().streamPublishedGastropedia(),
        builder: (context, snapshot) {
          final allItems = snapshot.data ?? GastropediaData.items;
          final List<GastropediaItem> items;
          if (isRecommendationMode) {
            items = allItems.where((i) => i.isRecommended).toList();
          } else if (category != null) {
            items = allItems.where((i) => i.category == category).toList();
          } else {
            items = allItems;
          }

          return Column(
            children: [
              const SizedBox(height: 6),

              // 1. Header Top Bar
              GastropediaHeader(title: title),

              // 2. Subjudul kecil di bawah header dalam pill halus
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEBE3D0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Color(0xFF276F8F),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF527F97),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Grid 2 Kolom (Card List modern)
              Expanded(
                child: items.isEmpty
                    ? Center(
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
                                Icons.restaurant_menu_rounded,
                                size: 32,
                                color: Color(0xFFE5983A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada makanan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1C4E68),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.76,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
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
              ),
            ],
          );
        },
      ),
    );
  }
}

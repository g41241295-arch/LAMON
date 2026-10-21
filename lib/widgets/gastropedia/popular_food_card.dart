import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/gastropedia_item_model.dart';

class PopularFoodItem {
  final String name;
  final String imageAsset;
  final double rating;
  final int ratingCount;
  final GastropediaItem gastropediaItem;

  PopularFoodItem({
    required this.name,
    required this.imageAsset,
    required this.rating,
    required this.ratingCount,
    required this.gastropediaItem,
  });
}

class PopularFoodCard extends StatelessWidget {
  final PopularFoodItem item;
  final VoidCallback onTap;

  const PopularFoodCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  Widget _fallbackIcon() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFEBF3F8),
      child: const Icon(Icons.fastfood_rounded, color: Color(0xFF639BC6), size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.name}, rating ${item.rating}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.gastropediaCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gastropediaCardBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // ─── Thumbnail Kotak Rounded Konsisten (64x64) ───
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: item.imageAsset.startsWith('http')
                          ? Image.network(
                              item.imageAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _fallbackIcon(),
                            )
                          : Image.asset(
                              item.imageAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _fallbackIcon(),
                            ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ─── Info Makanan: Nama Tebal + Rating Bintang & Ulasan ───
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E5D7D),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Render rating stars
                            ...List.generate(
                              5,
                              (index) => Icon(
                                index < item.rating.floor()
                                    ? Icons.star_rounded
                                    : index < item.rating
                                        ? Icons.star_half_rounded
                                        : Icons.star_outline_rounded,
                                size: 16,
                                color: const Color(0xFFF2B705),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${item.rating}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7C8E97),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ─── Ikon Chevron di Ujung Kanan Baris ───
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF7C8E97),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

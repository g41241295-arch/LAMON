import 'package:flutter/material.dart';

class PopularFoodItem {
  final String name;
  final String imageAsset;
  final double rating;
  final int ratingCount;

  PopularFoodItem({
    required this.name,
    required this.imageAsset,
    required this.rating,
    required this.ratingCount,
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
      width: 80,
      height: 80,
      color: const Color(0xFFEBF3F8),
      child: const Icon(Icons.fastfood, color: Color(0xFF639BC6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gambar di sisi kiri
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageAsset.startsWith('http')
                  ? Image.network(
                      item.imageAsset,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
                    )
                  : Image.asset(
                      item.imageAsset,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
                    ),
            ),
            const SizedBox(width: 16),
            // Info makanan di sisi kanan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E5D7D),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Render rating stars
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < item.rating.floor()
                              ? Icons.star
                              : index < item.rating
                                  ? Icons.star_half
                                  : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "(${item.ratingCount})",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
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
}

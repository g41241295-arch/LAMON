import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';

/// Widget item kategori bergaya lingkaran foto + label di bawah.
/// Meniru gaya referensi Gambar 2: circle image, white border, soft shadow,
/// label semi-bold di bawah, animasi scale saat ditekan.
class CategoryItem extends StatefulWidget {
  final GastropediaCategory category;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) async {
    await Future.delayed(const Duration(milliseconds: 80));
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Foto Lingkaran ───
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5), // Bingkai putih sebagai padding
              child: ClipOval(
                child: Image.asset(
                  widget.category.thumbnailAsset,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF639BC6),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ─── Label di Bawah Lingkaran ───
            Text(
              widget.category.badgeText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E5D7D),
                letterSpacing: 0.3,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

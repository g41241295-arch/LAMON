import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';

/// Kartu rekomendasi bergaya horizontal scroll card.
/// Meniru gaya referensi Gambar 2: kartu putih sudut besar, foto lingkaran
/// di tengah atas, judul bold biru tua di bawah, shadow mengambang.
/// Animasi scale ringan saat ditekan (efek press).
class RecommendationCard extends StatefulWidget {
  final GastropediaItem item;
  final VoidCallback onTap;

  const RecommendationCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard>
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
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    await Future.delayed(const Duration(milliseconds: 90));
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
        child: Container(
          // Lebar card dikurangi sedikit agar proporsional
          width: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 14,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ─── Foto Lingkaran ───
              Container(
                width: 95, // Lebih besar sedikit dari lingkaran kategori (88)
                height: 95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    widget.item.imageAsset,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFEBF3F8),
                      child: const Icon(
                        Icons.image_outlined,
                        size: 36,
                        color: Color(0xFF639BC6),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ─── Judul Makanan ───
              Expanded(
                child: Center(
                  child: Text(
                    widget.item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E5D7D),
                      height: 1.2,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

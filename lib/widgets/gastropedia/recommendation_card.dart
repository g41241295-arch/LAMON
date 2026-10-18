import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';

/// Kartu rekomendasi makanan dengan gambar mengisi bagian atas
/// dan baris bawah berisi judul makanan (kiri) + ikon chevron bulat berlatar aksen (kanan).
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
    await Future.delayed(const Duration(milliseconds: 70));
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Rekomendasi ${widget.item.name}',
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnim.value, child: child),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Foto Makanan Mengisi Bagian Atas ───
                SizedBox(
                  height: 105,
                  child: widget.item.imageAsset.startsWith('http')
                      ? Image.network(
                          widget.item.imageAsset,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFFEBF3F8),
                            child: const Icon(
                              Icons.image_outlined,
                              size: 36,
                              color: Color(0xFF639BC6),
                            ),
                          ),
                        )
                      : Image.asset(
                          widget.item.imageAsset,
                          fit: BoxFit.cover,
                          width: double.infinity,
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

                // ─── Baris Bawah: Judul Makanan + Chevron Bulat Akses ───
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Judul Makanan di sisi kiri
                      Expanded(
                        child: Text(
                          widget.item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E5D7D),
                            height: 1.2,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Ikon chevron bulat kecil berlatar aksen krem-kuning
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
                              color: Colors.black.withValues(alpha: 0.04),
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
      ),
    );
  }
}

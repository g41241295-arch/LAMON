import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class PopularFoodCard extends StatefulWidget {
  final PopularFoodItem item;
  final VoidCallback onTap;

  const PopularFoodCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<PopularFoodCard> createState() => _PopularFoodCardState();
}

class _PopularFoodCardState extends State<PopularFoodCard> {
  late double _currentRating;
  late int _currentCount;
  int? _userRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.item.rating;
    _currentCount = widget.item.ratingCount;
    _loadSavedRating();
  }

  Future<void> _loadSavedRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'gastropedia_user_rating_${widget.item.gastropediaItem.id}';
      final saved = prefs.getInt(key);
      if (saved != null && mounted) {
        setState(() {
          _userRating = saved;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRating(int newRating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'gastropedia_user_rating_${widget.item.gastropediaItem.id}';
      await prefs.setInt(key, newRating);
    } catch (_) {}

    if (mounted) {
      setState(() {
        if (_userRating == null) {
          _currentCount += 1;
        }
        _userRating = newRating;
        // Hitung rating baru secara proporsional
        _currentRating = ((widget.item.rating * widget.item.ratingCount) + newRating) /
            _currentCount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terima kasih! Kamu memberikan $newRating bintang untuk ${widget.item.name}.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF1C4E68),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showRatingDialog(BuildContext context) {
    int tempRating = _userRating ?? 5;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            String label;
            switch (tempRating) {
              case 1:
                label = 'Kurang Sesuai';
                break;
              case 2:
                label = 'Cukup Baik';
                break;
              case 3:
                label = 'Enak & Nyaman di Lambung';
                break;
              case 4:
                label = 'Sangat Enak & Segar';
                break;
              case 5:
              default:
                label = 'Luar Biasa & Sangat Ramah Lambung!';
                break;
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEA),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF2D184),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF2B705),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Beri Nilai Bintang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C4E68),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pilih bintang penilaian untuk ${widget.item.name}:',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF527F97),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ─── 5 Bintang Interaktif ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isSelected = starValue <= tempRating;

                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            tempRating = starValue;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            isSelected
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 38,
                            color: isSelected
                                ? const Color(0xFFF2B705)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 12),

                  // Keterangan teks rating
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4EB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFEBE3D0),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9E652B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Tombol Aksi Batal & Simpan
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(
                              color: Color(0xFFD4E3ED),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: Color(0xFF6B8797),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            _saveRating(tempRating);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF276F8F),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Simpan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImage() {
    try {
      final b64 = widget.item.gastropediaItem.imageBase64;
      if (b64.isNotEmpty) {
        return Image.memory(
          base64Decode(b64),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
        );
      }
    } catch (_) {}

    if (widget.item.imageAsset.startsWith('http')) {
      return Image.network(
        widget.item.imageAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
      );
    }

    return Image.asset(
      widget.item.imageAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      color: const Color(0xFFF2F6F8),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: Color(0xFF8BA7B8),
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.item.name}, rating ${_currentRating.toStringAsFixed(1)}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gastropediaCardBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1C4E68).withValues(alpha: 0.05),
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // ─── Thumbnail Foto Kotak Rounded Konsisten (78x78) ───
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 78,
                      height: 78,
                      child: _buildImage(),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ─── Info Makanan: Kategori, Rating Interaktif, Nama, Kalori & Gizi ───
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Baris Atas: Kategori Pill + Bintang Rating Interaktif
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F6F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFD4E3ED),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                widget.item.gastropediaItem.category.badgeText,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF276F8F),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const Spacer(),

                            // ─── Fitur Memilih Bintang (Tap untuk Beri Nilai) ───
                            InkWell(
                              onTap: () => _showRatingDialog(context),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEA),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFF2D184),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: Color(0xFFF2B705),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _currentRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1C4E68),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '($_currentCount)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF8BA7B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Nama Makanan
                        Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C4E68),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        // Baris Bawah: Kalori + Gizi Ringkas
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFED7AA),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 11,
                                    color: Color(0xFFE5983A),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${widget.item.gastropediaItem.calories} Kcal',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF8C5110),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '•  ${widget.item.gastropediaItem.protein}g protein',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B8797),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ─── Tombol Lingkaran Aksen Panah ───
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4EB),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEBE3D0),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF276F8F),
                      ),
                    ),
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

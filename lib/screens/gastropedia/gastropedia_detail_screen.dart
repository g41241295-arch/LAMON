import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../models/gastropedia_item_model.dart';
import '../../services/rating_monitoring_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gastropedia/gastropedia_accordion.dart';

class GastropediaDetailScreen extends StatelessWidget {
  final GastropediaItem item;

  const GastropediaDetailScreen({
    super.key,
    required this.item,
  });

  Widget _buildHeroImage() {
    try {
      final b64 = item.imageBase64;
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

    if (item.imageAsset.startsWith('http')) {
      return Image.network(
        item.imageAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return Image.asset(
      item.imageAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFFF2F6F8),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 54,
          color: Color(0xFF8BA7B8),
        ),
      ),
    );
  }

  String _formatNutrient(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            // ═══════════════════════════════════════════
            // 1. Header Top Bar (Back Button + Judul Pill Tengah + Balancer)
            // ═══════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEBE3D0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1C4E68).withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF1C4E68),
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  // Judul Pill Tengah
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFEBE3D0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1C4E68).withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Detail Pangan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C4E68),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),

                  // Penyeimbang Lebar di Sisi Kanan
                  const SizedBox(
                    width: 40,
                    height: 40,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ═══════════════════════════════════════════
            // 2. Banner Foto Utama Item + Judul & Tag
            // ═══════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.gastropediaCardBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1C4E68).withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gambar Utama dengan Floating Badges
                    SizedBox(
                      height: 220,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildHeroImage(),
                          // Gradient transparan di bawah gambar
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 50,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.25),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Badge Kategori di Kiri Atas
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFEBE3D0),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                item.category.badgeText,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF276F8F),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Nama Makanan & Kategori
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C4E68),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F4EB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFEBE3D0),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Kategori ${item.category.label}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1C4E68),
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

            const SizedBox(height: 14),

            // ═══════════════════════════════════════════
            // Rating Interaktif (Pilih Bintang)
            // ═══════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DetailRatingCard(item: item),
            ),

            const SizedBox(height: 16),

            // ═══════════════════════════════════════════
            // 3. Info Gizi (Modern Quick-Stats 4 Kartu)
            // ═══════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 18,
                              color: Color(0xFF276F8F),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Informasi Nilai Gizi',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1C4E68),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Grid 4 Kotak Stat Nilai Gizi (Kalori, Protein, Karbo, Lemak)
                    Row(
                      children: [
                        Expanded(
                          child: _buildNutrientStatBox(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: const Color(0xFFE5983A),
                            bgColor: const Color(0xFFFFF7ED),
                            borderColor: const Color(0xFFFED7AA),
                            value: '${item.calories}',
                            unit: 'Kcal',
                            label: 'Kalori',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNutrientStatBox(
                            icon: Icons.set_meal_rounded,
                            iconColor: const Color(0xFF276F8F),
                            bgColor: const Color(0xFFF0F8FA),
                            borderColor: const Color(0xFFCFE8EE),
                            value: '${_formatNutrient(item.protein)}g',
                            unit: 'gram',
                            label: 'Protein',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNutrientStatBox(
                            icon: Icons.grass_rounded,
                            iconColor: const Color(0xFF38B249),
                            bgColor: const Color(0xFFF2F9F4),
                            borderColor: const Color(0xFFD1EEDB),
                            value: '${_formatNutrient(item.carbs)}g',
                            unit: 'gram',
                            label: 'Karbo',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNutrientStatBox(
                            icon: Icons.water_drop_rounded,
                            iconColor: const Color(0xFF4A90E2),
                            bgColor: const Color(0xFFF0F5FB),
                            borderColor: const Color(0xFFD3E4F6),
                            value: '${_formatNutrient(item.fat)}g',
                            unit: 'gram',
                            label: 'Lemak',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ═══════════════════════════════════════════
            // 4. Accordion Section (Deskripsi, Manfaat, Kandungan)
            // ═══════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Bagian 1: Deskripsi
                  GastropediaAccordion(
                    title: 'Deskripsi Makanan',
                    content: Text(
                      item.deskripsi,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.6,
                        color: Color(0xFF2C495E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bagian 2: Manfaat
                  GastropediaAccordion(
                    title: 'Manfaat untuk Lambung',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.manfaat.asMap().entries.map((entry) {
                        final text = entry.value;
                        final isLast = entry.key == item.manfaat.length - 1;

                        return Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFDFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEBE3D0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDEF7EA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Color(0xFF27AE60),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    text,
                                    textAlign: TextAlign.justify,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Color(0xFF2C495E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bagian 3: Kandungan Gizi
                  GastropediaAccordion(
                    title: 'Kandungan Gizi',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.kandungan.asMap().entries.map((entry) {
                        final text = entry.value;
                        final isLast = entry.key == item.kandungan.length - 1;

                        return Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFDFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEBE3D0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF0F6F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.science_outlined,
                                      size: 13,
                                      color: Color(0xFF276F8F),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    text,
                                    textAlign: TextAlign.justify,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Color(0xFF2C495E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientStatBox({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String value,
    required String unit,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C4E68),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B8797),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widget Rating Interaktif di Halaman Detail Pangan
// ─────────────────────────────────────────────────────────────
class _DetailRatingCard extends StatefulWidget {
  final GastropediaItem item;

  const _DetailRatingCard({required this.item});

  @override
  State<_DetailRatingCard> createState() => _DetailRatingCardState();
}

class _DetailRatingCardState extends State<_DetailRatingCard> {
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('gastropedia_user_rating_${widget.item.id}');
      if (saved != null && mounted) {
        setState(() {
          _rating = saved;
        });
        RatingMonitoringService.instance.ensureLocalGastropediaRatingSynced(
          item: widget.item,
          localRating: saved,
        );
      } else {
        final remoteRating = await RatingMonitoringService.instance
            .fetchUserGastropediaRating(widget.item.id);
        if (remoteRating != null && mounted) {
          setState(() {
            _rating = remoteRating;
          });
          await prefs.setInt(
              'gastropedia_user_rating_${widget.item.id}', remoteRating);
        }
      }
      RatingMonitoringService.instance
          .syncAllLocalGastropediaRatingsForCurrentUser();
    } catch (_) {}
  }

  Future<void> _saveRating(int star) async {
    setState(() {
      _rating = star;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('gastropedia_user_rating_${widget.item.id}', star);
    } catch (_) {}

    // Simpan secara aditif ke Firestore untuk pemantauan admin
    RatingMonitoringService.instance.saveGastropediaRating(
      item: widget.item,
      rating: star,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Penilaian $star bintang untuk ${widget.item.name} berhasil disimpan!',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gastropediaCardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C4E68).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Beri Penilaian',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C4E68),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _rating > 0
                      ? 'Nilai Anda: $_rating Bintang ⭐'
                      : 'Ketuk bintang untuk menilai',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _rating > 0
                        ? const Color(0xFF9E652B)
                        : const Color(0xFF7C8E97),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isFilled = starValue <= _rating;
              return GestureDetector(
                onTap: () => _saveRating(starValue),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    isFilled
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 26,
                    color: isFilled
                        ? const Color(0xFFF2B705)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

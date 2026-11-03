import 'dart:convert';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/gastropedia_item_model.dart';
import '../../widgets/app_scaffold.dart';

import '../../widgets/gastropedia/gastropedia_accordion.dart';

class GastropediaDetailScreen extends StatelessWidget {
  final GastropediaItem item;

  const GastropediaDetailScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            // 1. Header Top Bar (Hanya Back Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF1E5D7D),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Banner Foto Utama Item + Judul
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.gastropediaCardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.gastropediaCardBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gambar Utama
                    SizedBox(
                      height: 220,
                      child: (() {
                        try {
                          final b64 = item.imageBase64;
                          if (b64.isNotEmpty) {
                            return Image.memory(
                              base64Decode(b64),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              gaplessPlayback: true,
                            );
                          }
                        } catch (_) {}
                        if (item.imageAsset.startsWith('http')) {
                          return Image.network(
                            item.imageAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFEBF3F8),
                              child: const Icon(
                                Icons.restaurant_rounded,
                                size: 48,
                                color: Color(0xFF639BC6),
                              ),
                            ),
                          );
                        }
                        return Image.asset(
                          item.imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFEBF3F8),
                              child: const Icon(
                                Icons.restaurant_rounded,
                                size: 48,
                                color: Color(0xFF639BC6),
                              ),
                            ),
                        );
                      })(),
                    ),
                    // Nama Item di bawah gambar (rata tengah)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      child: Center(
                        child: Text(
                          item.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E5D7D),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Info Gizi (Nutrition Info)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gastropediaCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gastropediaCardBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Informasi Nilai Gizi",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E5D7D),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2ECF2).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.servingUnit,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF639BC6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFE2ECF2)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildNutritionItem(Icons.local_fire_department, "Kalori", "${item.calories} Kcal")),
                        Expanded(child: _buildNutritionItem(Icons.set_meal, "Protein", "${_formatNutrient(item.protein)}g")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildNutritionItem(Icons.grass, "Karbo", "${_formatNutrient(item.carbs)}g")),
                        Expanded(child: _buildNutritionItem(Icons.opacity, "Lemak", "${_formatNutrient(item.fat)}g")),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. Tiga Accordion Independen (Deskripsi, Manfaat, Kandungan)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Accordion 1: Deskripsi
                  GastropediaAccordion(
                    title: 'Deskripsi',
                    initialExpanded: true,
                    content: Text(
                      item.deskripsi,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        color: Color(0xFF2C495E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Accordion 2: Manfaat
                  GastropediaAccordion(
                    title: 'Manfaat',
                    initialExpanded: true,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.manfaat.map((text) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            text,
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.5,
                              color: Color(0xFF2C495E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Accordion 3: Kandungan
                  GastropediaAccordion(
                    title: 'Kandungan Gizi',
                    initialExpanded: true,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.kandungan.map((text) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            text,
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.5,
                              color: Color(0xFF2C495E),
                              fontWeight: FontWeight.w500,
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

  String _formatNutrient(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  Widget _buildNutritionItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF639BC6)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2C495E),
              ),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

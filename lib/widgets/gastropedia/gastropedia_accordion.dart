import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Card bubble untuk section Deskripsi, Manfaat, dan Kandungan Gizi di Detail Makanan.
/// Ditampilkan dengan latar krem lembut yang senada dan nyaman di mata.
class GastropediaAccordion extends StatelessWidget {
  final String title;
  final Widget content;
  final bool initialExpanded;

  const GastropediaAccordion({
    super.key,
    required this.title,
    required this.content,
    this.initialExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card (Judul Bold dengan latar gradasi krem lembut)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.gastropediaAccordionHeaderStart,
                  AppColors.gastropediaAccordionHeaderEnd,
                ],
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E5D7D),
                letterSpacing: -0.2,
              ),
            ),
          ),

          // Badan Konten (latar krem lembut dengan border pemisah krem)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.gastropediaCardBg,
              border: Border(
                top: BorderSide(
                  color: AppColors.gastropediaAccordionBorder,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: content,
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Card seksi untuk Deskripsi, Manfaat, dan Kandungan Gizi di Detail Makanan.
/// Menampilkan header menyatu dengan batasan atas berlatar gradasi lembut,
/// ikon representatif dan teks judul berwarna biru khas LAMON tanpa tombol panah.
class GastropediaAccordion extends StatelessWidget {
  final String title;
  final Widget content;
  final IconData? icon;

  const GastropediaAccordion({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    bool initialExpanded = true,
  });

  IconData _resolveIcon() {
    if (icon != null) return icon!;
    final lower = title.toLowerCase();
    if (lower.contains('deskripsi')) return Icons.description_outlined;
    if (lower.contains('manfaat')) return Icons.health_and_safety_outlined;
    if (lower.contains('kandungan')) return Icons.science_outlined;
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final headerIcon = _resolveIcon();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gastropediaCardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C4E68).withValues(alpha: 0.05),
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
          // ─── Header Card (Menyatu dengan Batasan Atas Berlatar Gradasi Krem) ───
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
            child: Row(
              children: [
                Icon(
                  headerIcon,
                  color: const Color(0xFF1E5D7D),
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
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
              ],
            ),
          ),

          // ─── Badan Konten (Border Pemisah Halus + Konten Bersih) ───
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
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

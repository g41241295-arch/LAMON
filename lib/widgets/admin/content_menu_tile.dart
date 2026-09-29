import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

/// Konstanta dimensi tile kelola konten (sesuai Figma 390dp frame).
class ContentMenuDims {
  static const double tileRadius = 14;
  static const double tilePadding = 12;
  static const double iconBoxSize = 40;
  static const double iconBoxRadius = 10;
  static const double iconSize = 22;
  static const double titleFontSize = 15;
  static const double subtitleFontSize = 11;
}

/// Tile menu "Kelola Konten".
///
/// [icon]      – ikon dalam kotak biru muda membulat
/// [title]     – teks judul biru semi-bold
/// [subtitle]  – teks kecil cokelat kemerahan (subteks)
/// [onTap]     – null = nonaktif (placeholder)
class ContentMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const ContentMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.adminTileBg,
      borderRadius: BorderRadius.circular(ContentMenuDims.tileRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ContentMenuDims.tileRadius),
        child: Container(
          padding: const EdgeInsets.all(ContentMenuDims.tilePadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ContentMenuDims.tileRadius),
            border: Border.all(
              color: AppColors.adminTileBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Ikon dalam kotak biru muda
              Container(
                width: ContentMenuDims.iconBoxSize,
                height: ContentMenuDims.iconBoxSize,
                decoration: BoxDecoration(
                  color: AppColors.adminBlueLight,
                  borderRadius:
                      BorderRadius.circular(ContentMenuDims.iconBoxRadius),
                ),
                child: Icon(
                  icon,
                  color: AppColors.adminBlue,
                  size: ContentMenuDims.iconSize,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: ContentMenuDims.titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.adminBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: ContentMenuDims.subtitleFontSize,
                        fontWeight: FontWeight.w400,
                        color: AppColors.adminStatLabel,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.adminBlue,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

/// Konstanta dimensi tombol aksi cepat (sesuai Figma 390dp frame).
class QuickActionDims {
  static const double buttonHeight = 84;
  static const double buttonRadius = 18;
  static const double iconBoxSize = 30;
  static const double iconBoxRadius = 8;
  static const double iconSize = 16;
  static const double labelFontSize = 13;
}

/// Tombol Aksi Cepat.
///
/// [label]     – teks di bawah ikon
/// [icon]      – ikon di dalam kotak kecil membulat
/// [isPrimary] – true = biru solid (Tambah Berita)
///               false = krem + border biru (Tambah Ensiklopedia)
/// [onTap]     – aksi saat ditekan
class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.isPrimary = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isPrimary ? AppColors.adminBlue : AppColors.adminTileBg;
    final fgColor = isPrimary ? Colors.white : AppColors.adminBlue;
    final iconBoxColor =
        isPrimary ? Colors.white.withValues(alpha: 0.2) : AppColors.adminBlueLight;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: QuickActionDims.buttonHeight,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius:
                BorderRadius.circular(QuickActionDims.buttonRadius),
            border: isPrimary
                ? null
                : Border.all(color: AppColors.adminBlue, width: 1),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.adminBlue.withValues(alpha: 0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon dalam kotak kecil membulat
              Container(
                width: QuickActionDims.iconBoxSize,
                height: QuickActionDims.iconBoxSize,
                decoration: BoxDecoration(
                  color: iconBoxColor,
                  borderRadius:
                      BorderRadius.circular(QuickActionDims.iconBoxRadius),
                ),
                child: Icon(
                  icon,
                  color: fgColor,
                  size: QuickActionDims.iconSize,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: QuickActionDims.labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

/// Konstanta dimensi kartu statistik (sesuai Figma 390dp frame).
class StatCardDims {
  static const double cardRadius = 18;
  static const double cardHeight = 120;
  static const double cardPadding = 16;
  static const double iconBoxSize = 36;
  static const double iconBoxRadius = 10;
  static const double iconSize = 20;
  static const double statFontSize = 30;
  static const double labelFontSize = 13;
  static const double badgeFontSize = 11;
}

/// Kartu statistik beranda admin.
///
/// [icon]       – ikon di kiri atas
/// [statValue]  – angka besar (null = loading shimmer)
/// [label]      – teks di bawah angka
/// [badgeText]  – teks pill badge kanan atas (null = sembunyi)
class StatCard extends StatelessWidget {
  final IconData icon;
  final String? statValue;
  final String label;
  final String? badgeText;

  const StatCard({
    super.key,
    required this.icon,
    required this.statValue,
    required this.label,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: StatCardDims.cardHeight,
      padding: const EdgeInsets.all(StatCardDims.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StatCardDims.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: ikon kiri, badge kanan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikon dalam kotak biru muda
              Container(
                width: StatCardDims.iconBoxSize,
                height: StatCardDims.iconBoxSize,
                decoration: BoxDecoration(
                  color: AppColors.adminBlueLight,
                  borderRadius:
                      BorderRadius.circular(StatCardDims.iconBoxRadius),
                ),
                child: Icon(
                  icon,
                  color: AppColors.adminBlue,
                  size: StatCardDims.iconSize,
                ),
              ),
              const Spacer(),
              // Badge pill (hanya tampil jika badgeText != null)
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.adminBadgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText!,
                    style: GoogleFonts.poppins(
                      fontSize: StatCardDims.badgeFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.adminBadgeText,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          // Angka besar atau shimmer
          statValue == null
              ? _StatShimmer()
              : Text(
                  statValue!,
                  style: GoogleFonts.poppins(
                    fontSize: StatCardDims.statFontSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.adminBlue,
                    height: 1.0,
                  ),
                ),
          const SizedBox(height: 2),
          // Label
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: StatCardDims.labelFontSize,
              fontWeight: FontWeight.w500,
              color: AppColors.adminStatLabel,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer sederhana saat data belum termuat.
class _StatShimmer extends StatefulWidget {
  @override
  State<_StatShimmer> createState() => _StatShimmerState();
}

class _StatShimmerState extends State<_StatShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(
        opacity: _anim.value,
        child: Container(
          height: 28,
          width: 60,
          decoration: BoxDecoration(
            color: AppColors.adminBlueLight,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

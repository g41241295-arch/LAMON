import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/reflux_prediction_model.dart';

/// Item faktor yang paling berpengaruh dengan horizontal progress bar
class FactorContributionBar extends StatelessWidget {
  final FactorContribution factor;
  final int rank; // 1, 2, 3

  const FactorContributionBar({
    super.key,
    required this.factor,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final percentText = '${(factor.contributionScore * 100).toInt()}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEBE3D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C4E68).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5EE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEBE3D0),
                    width: 1.0,
                  ),
                ),
                child: factor.imagePath != null && factor.imagePath!.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(7.0),
                        child: Image.asset(
                          factor.imagePath!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.insights_rounded,
                            size: 18,
                            color: Color(0xFF1C4E68),
                          ),
                        ),
                      )
                    : Icon(
                        factor.icon,
                        size: 20,
                        color: const Color(0xFF1C4E68),
                      ),
              ),
              const SizedBox(width: 12),

              // Judul & Keterangan Jawaban
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      factor.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C4E68),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pilihanmu: ${factor.userValueDescription}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B8797),
                      ),
                    ),
                  ],
                ),
              ),

              // Skor Persen Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD4E5EE),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  percentText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF276F8F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Track Latar
                Container(
                  height: 6,
                  width: double.infinity,
                  color: const Color(0xFFF2EEDB),
                ),

                // Fill Bar
                FractionallySizedBox(
                  widthFactor: factor.contributionScore.clamp(0.05, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF276F8F),
                          Color(0xFF1C4E68),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

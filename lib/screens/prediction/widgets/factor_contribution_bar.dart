import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              // Icon bulat
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEDF7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  factor.icon,
                  size: 20,
                  color: AppColors.primary,
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pilihanmu: ${factor.userValueDescription}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.brownSubtext,
                      ),
                    ),
                  ],
                ),
              ),

              // Skor Persen
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  percentText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Track Latar
                Container(
                  height: 8,
                  width: double.infinity,
                  color: const Color(0xFFEBF1F5),
                ),

                // Fill Bar Animasi
                FractionallySizedBox(
                  widthFactor: factor.contributionScore.clamp(0.05, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryLight,
                          AppColors.primary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
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

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Slider diskrit 5 level (0–4) dengan label mengambang di atas thumb
/// 0: Tidak pernah, 1: Jarang, 2: Kadang, 3: Sering, 4: Setiap hari
class DiscreteLevelSlider extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final ValueChanged<int> onChanged;

  static const List<String> levelLabels = [
    'Tidak pernah',
    'Jarang',
    'Kadang',
    'Sering',
    'Setiap hari',
  ];

  const DiscreteLevelSlider({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeLabel = levelLabels[value.clamp(0, 4)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Pertanyaan
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),

          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.brownSubtext,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Floating Label Badge di atas Slider
          LayoutBuilder(
            builder: (context, constraints) {
              final double trackWidth = constraints.maxWidth - 24;
              final double fraction = value / 4.0;
              // Geser posisi badge mengikuti thumb
              final double badgeLeft =
                  (fraction * trackWidth).clamp(0.0, trackWidth - 70);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Ruang tinggi untuk badge
                  const SizedBox(height: 32, width: double.infinity),

                  Positioned(
                    left: badgeLeft,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        activeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Slider Diskrit
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFFE2EDF3),
              trackHeight: 6.0,
              thumbColor: AppColors.primary,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10.0,
                elevation: 3.0,
              ),
              overlayColor: AppColors.primary.withValues(alpha: 0.16),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3.5),
              activeTickMarkColor: Colors.white,
              inactiveTickMarkColor: const Color(0xFFBACFD9),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 4,
              divisions: 4,
              onChanged: (double val) {
                onChanged(val.round());
              },
            ),
          ),

          // Teks Skala Bawah (0 sampai 4)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '0 (Tidak pernah)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                          value == 0 ? FontWeight.w700 : FontWeight.w500,
                      color: value == 0
                          ? AppColors.primaryDark
                          : const Color(0xFF8CA4B3),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Level $value/4',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '4 (Setiap hari)',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                          value == 4 ? FontWeight.w700 : FontWeight.w500,
                      color: value == 4
                          ? AppColors.primaryDark
                          : const Color(0xFF8CA4B3),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Slider diskrit 5 level (0–4) dengan desain profesional & modern
/// 0: Tidak pernah, 1: Jarang, 2: Kadang, 3: Sering, 4: Setiap hari
class DiscreteLevelSlider extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final int value;
  final ValueChanged<int> onChanged;

  static const List<String> levelLabels = [
    'Tidak pernah',
    'Jarang',
    'Kadang',
    'Sering',
    'Setiap hari',
  ];

  static const List<String> shortLabels = [
    'Tidak',
    'Jarang',
    'Kadang',
    'Sering',
    'Harian',
  ];

  const DiscreteLevelSlider({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0, 4);
    final activeLabel = levelLabels[clampedValue];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEBE3D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C4E68).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Icon + Title & Subtitle + Badge Status ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEBE3D0),
                    width: 1.0,
                  ),
                ),
                child: Image.asset(
                  imagePath,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.fastfood_rounded,
                    size: 20,
                    color: Color(0xFF1C4E68),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C4E68),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B8797),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ─── Active Level Status Pill ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD4E5EE),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF276F8F),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Frekuensi: $activeLabel',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C4E68),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$clampedValue / 4',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF276F8F),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ─── Slider Modern ───
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF276F8F),
              inactiveTrackColor: const Color(0xFFE8E2D2),
              trackHeight: 5.0,
              thumbColor: const Color(0xFF1C4E68),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 9.0,
                elevation: 2.0,
              ),
              overlayColor: const Color(0xFF276F8F).withValues(alpha: 0.12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2.5),
              activeTickMarkColor: Colors.white,
              inactiveTickMarkColor: const Color(0xFFC9C1AE),
            ),
            child: Slider(
              value: clampedValue.toDouble(),
              min: 0,
              max: 4,
              divisions: 4,
              onChanged: (double val) {
                onChanged(val.round());
              },
            ),
          ),

          // ─── Interactive 5-Stop Labels Row ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final isSelected = index == clampedValue;
                return InkWell(
                  onTap: () => onChanged(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Column(
                      children: [
                        Text(
                          '$index',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF1C4E68)
                                : const Color(0xFF9CB3C2),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          shortLabels[index],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF276F8F)
                                : const Color(0xFF9CB3C2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

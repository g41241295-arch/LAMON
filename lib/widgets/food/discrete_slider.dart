import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Slider 5 tahap diskrit (snapping ke nilai 0–4).
///
/// - Label di atas track berubah sesuai posisi aktif.
/// - Ikon kecil ditampilkan di sebelah kiri judul pertanyaan.
/// - Default posisi paling kiri (nilai 0).
/// - Mendukung mode read-only.
class DiscreteSlider extends StatefulWidget {
  /// Judul pertanyaan, misal "Apakah makanan Anda pedas?"
  final String label;

  /// Ikon kecil di sebelah kiri judul
  final IconData icon;

  /// Warna ikon (opsional, default primary)
  final Color? iconColor;

  /// Emoji ikon sebagai alternatif [icon]
  final String? iconEmoji;

  /// 5 label untuk tahap 0–4
  final List<String> stepLabels;

  /// Nilai awal (0–4)
  final int value;

  /// Callback saat nilai berubah
  final ValueChanged<int>? onChanged;

  /// Tampilkan state error
  final bool hasError;

  const DiscreteSlider({
    super.key,
    required this.label,
    this.icon = Icons.tune_rounded,
    this.iconColor,
    this.iconEmoji,
    required this.stepLabels,
    required this.value,
    this.onChanged,
    this.hasError = false,
  }) : assert(stepLabels.length == 5, 'stepLabels harus tepat 5 elemen');

  @override
  State<DiscreteSlider> createState() => _DiscreteSliderState();
}

class _DiscreteSliderState extends State<DiscreteSlider> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.value.toDouble();
  }

  @override
  void didUpdateWidget(DiscreteSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _sliderValue = widget.value.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = widget.onChanged == null;
    final activeLabel = widget.stepLabels[_sliderValue.round().clamp(0, 4)];
    final iconColor = widget.iconColor ?? AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Judul dengan ikon ──────────────────────────────────────
        Row(
          children: [
            if (widget.iconEmoji != null)
              Text(
                widget.iconEmoji!,
                style: const TextStyle(fontSize: 18),
              )
            else
              Icon(widget.icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.hasError
                      ? Colors.red.shade700
                      : AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // ── Label aktif ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            activeLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.hasError
                  ? Colors.red.shade700
                  : AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 4),

        // ── Slider Track ──────────────────────────────────────────
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.lightGray,
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 3,
            ),
            trackHeight: 5,
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
            activeTickMarkColor: Colors.white.withValues(alpha: 0.6),
            inactiveTickMarkColor: AppColors.primary.withValues(alpha: 0.35),
          ),
          child: Slider(
            value: _sliderValue,
            min: 0,
            max: 4,
            divisions: 4,
            onChanged: isReadOnly
                ? null
                : (v) {
                    setState(() => _sliderValue = v);
                    widget.onChanged?.call(v.round());
                  },
          ),
        ),

        // ── Label ujung kiri/kanan ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.stepLabels.first,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.neutralGray,
                ),
              ),
              Text(
                widget.stepLabels.last,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.neutralGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

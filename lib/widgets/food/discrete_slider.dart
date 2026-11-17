import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

/// Slider 5 tahap diskrit (snapping ke nilai 0–4) berdesain modern LAMON.
///
/// - Indikator nilai aktif tampil dalam badge pill yang jelas.
/// - Ikon di samping pertanyaan dalam bingkai halus.
/// - Slider track bergradasi / warna teal dengan thumb yang mudah disentuh.
/// - Label batas minimal (kiri) dan maksimal (kanan) di bawah slider.
/// - Mendukung mode read-only.
class DiscreteSlider extends StatefulWidget {
  /// Judul pertanyaan, misal "Apakah makanan yang Anda makan pedas?"
  final String label;

  /// Ikon kecil di sebelah kiri judul
  final IconData icon;

  /// Warna ikon (opsional, default primary)
  final Color? iconColor;

  /// Emoji ikon sebagai alternatif [icon]
  final String? iconEmoji;

  /// Custom widget untuk ikon (misalnya Image.asset)
  final Widget? customIcon;

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
    this.customIcon,
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

  Widget _buildIconBadge() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF276F8F).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF276F8F).withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Center(
        child: widget.customIcon ??
            (widget.iconEmoji != null
                ? Text(
                    widget.iconEmoji!,
                    style: const TextStyle(fontSize: 18),
                  )
                : Icon(
                    widget.icon,
                    color: widget.iconColor ?? const Color(0xFF276F8F),
                    size: 18,
                  )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = widget.onChanged == null;
    final int stepIndex = _sliderValue.round().clamp(0, 4);
    final activeLabel = widget.stepLabels[stepIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Baris Judul & Ikon ─────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIconBadge(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: widget.hasError
                      ? Colors.red.shade700
                      : const Color(0xFF1C4E68),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Badge Nilai Aktif ──────────────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF276F8F).withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF276F8F).withValues(alpha: 0.22),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stepIndex == 0
                          ? const Color(0xFF7C8E97)
                          : const Color(0xFF276F8F),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    activeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C4E68),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // ── Slider Track Modern ────────────────────────────────────────────
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF276F8F),
            inactiveTrackColor: const Color(0xFFEBE3D0),
            thumbColor: Colors.white,
            overlayColor: const Color(0xFF276F8F).withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 3,
            ),
            trackHeight: 6,
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3.5),
            activeTickMarkColor: Colors.white,
            inactiveTickMarkColor: const Color(0xFF276F8F).withValues(alpha: 0.35),
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

        // ── Label Batas Bawah & Atas ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.stepLabels.first,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7C8E97),
                ),
              ),
              Text(
                widget.stepLabels.last,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7C8E97),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

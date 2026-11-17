import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Toggle biner Iya/Tidak berdesain tombol pilihan modern berorientasi tengah tanpa ikon centang.
///
/// Dua kartu pilihan berdampingan:
/// - Terpilih: Latar teal LAMON (0xFF276F8F), teks putih bold centered.
/// - Belum terpilih: Latar krem lembut (0xFFFAFAF7), border krem (0xFFEBE3D0), teks navy centered.
class ToggleYesNo extends StatelessWidget {
  final String label;

  /// `true` = Iya, `false` = Tidak, `null` = belum dipilih
  final bool? value;

  final ValueChanged<bool>? onChanged;
  final bool hasError;

  const ToggleYesNo({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final isReadOnly = onChanged == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: hasError ? Colors.red.shade700 : const Color(0xFF1C4E68),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ToggleButton(
                label: 'Iya',
                isSelected: value == true,
                onTap: isReadOnly ? null : () => onChanged?.call(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToggleButton(
                label: 'Tidak',
                isSelected: value == false,
                onTap: isReadOnly ? null : () => onChanged?.call(false),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 14, color: Colors.red.shade600),
              const SizedBox(width: 5),
              Text(
                'Pilih salah satu jawaban',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF276F8F) : const Color(0xFFFAFAF7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1C4E68)
                : const Color(0xFFEBE3D0),
            width: isSelected ? 1.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF276F8F).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF1C4E68),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Toggle biner Iya/Tidak (single-select).
///
/// Dua tombol pill berdampingan:
/// - Terpilih: latar biru navy, teks putih bold
/// - Tidak terpilih: latar putih, border tipis
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: hasError ? Colors.red.shade700 : AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ToggleButton(
                label: 'Iya',
                isSelected: value == true,
                onTap: isReadOnly ? null : () => onChanged?.call(true),
              ),
            ),
            const SizedBox(width: 8),
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
          const SizedBox(height: 6),
          Text(
            'Pilih salah satu jawaban',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
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
      child: AnimatedContainer(
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFD0DCE4),
            width: 1.4,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}

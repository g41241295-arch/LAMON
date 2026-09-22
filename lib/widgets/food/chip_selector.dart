import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Multi-select chip/pill selector.
///
/// Pengguna dapat memilih satu atau lebih opsi sekaligus.
/// Chip yang terpilih berlatar biru navy dengan teks putih bold.
/// Chip yang tidak terpilih berlatar putih dengan border tipis.
///
/// Mendukung layout dua kolom (grid) jika [useGrid] = true.
class ChipSelector extends StatelessWidget {
  /// Judul pertanyaan
  final String label;

  /// Semua opsi yang tersedia
  final List<String> options;

  /// Set opsi yang sedang dipilih
  final Set<String> selected;

  /// Callback ketika pilihan berubah
  final ValueChanged<Set<String>>? onChanged;

  /// Gunakan grid 2 kolom (untuk protein & sayuran)
  final bool useGrid;

  /// Tampilkan tanda error (border merah pada kartu)
  final bool hasError;

  const ChipSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.useGrid = false,
    this.hasError = false,
  });

  void _toggle(String option) {
    if (onChanged == null) return;
    final newSet = Set<String>.from(selected);
    if (newSet.contains(option)) {
      newSet.remove(option);
    } else {
      newSet.add(option);
    }
    onChanged!(newSet);
  }

  Widget _buildChip(String option) {
    final isSelected = selected.contains(option);
    return GestureDetector(
      onTap: () => _toggle(option),
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
          option,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.primaryText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.5,
          children: options.map(_buildChip).toList(),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            'Pilih minimal satu opsi',
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

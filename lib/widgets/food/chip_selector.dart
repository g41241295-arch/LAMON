import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Multi-select modern selectable card / chip selector.
///
/// Pengguna dapat memilih satu atau lebih opsi sekaligus.
/// - Terpilih: Latar teal LAMON (0xFF276F8F), teks putih bold centered.
/// - Belum terpilih: Latar krem lembut (0xFFFAFAF7), border krem lembut (0xFFEBE3D0), teks navy centered.
/// Tanpa ikon centang/lingkaran agar tata letak teks simetris dan rapi di tengah button.
class ChipSelector extends StatelessWidget {
  /// Judul pertanyaan
  final String label;

  /// Kategori atau ikon kecil pembantu (opsional)
  final String? categoryBadge;

  /// Semua opsi yang tersedia
  final List<String> options;

  /// Set opsi yang sedang dipilih
  final Set<String> selected;

  /// Callback ketika pilihan berubah
  final ValueChanged<Set<String>>? onChanged;

  /// Gunakan grid 2 kolom
  final bool useGrid;

  /// Tampilkan tanda error
  final bool hasError;

  const ChipSelector({
    super.key,
    required this.label,
    this.categoryBadge,
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

  Widget _buildOptionTile(String option) {
    final isSelected = selected.contains(option);
    final isReadOnly = onChanged == null;

    return GestureDetector(
      onTap: isReadOnly ? null : () => _toggle(option),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
          option,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF1C4E68),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Pertanyaan ──────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: hasError ? Colors.red.shade700 : const Color(0xFF1C4E68),
                  height: 1.35,
                ),
              ),
            ),
            if (categoryBadge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF276F8F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  categoryBadge!,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF276F8F),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // ── Grid Opsi Pilihan ───────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.0,
          children: options.map(_buildOptionTile).toList(),
        ),

        // ── State Error ────────────────────────────────────────────────────
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 14, color: Colors.red.shade600),
              const SizedBox(width: 5),
              Text(
                'Pilih minimal satu opsi jawaban',
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

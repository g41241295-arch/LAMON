import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

/// Editor teks dengan toolbar format Markdown (Tebal, Miring, Daftar Butir, Daftar Bernomor).
/// Sesuai dengan desain toolbar pada form artikel berita.
class AdminMarkdownEditorField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int minLines;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool showMarkdownHint;

  const AdminMarkdownEditorField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.minLines = 4,
    this.maxLines = 8,
    this.errorText,
    this.onChanged,
    this.showMarkdownHint = true,
  });

  void _insertMarkdown(String syntax) {
    final ctrl = controller;
    final sel = ctrl.selection;
    final text = ctrl.text;

    if (!sel.isValid) {
      ctrl.text = text + syntax;
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
      onChanged?.call(ctrl.text);
      return;
    }

    final selected = sel.textInside(text);
    String replacement;
    int cursorOffset;

    if (syntax == '**') {
      replacement = '**$selected**';
      cursorOffset = sel.start + replacement.length - 2;
    } else if (syntax == '_') {
      replacement = '_${selected}_';
      cursorOffset = sel.start + replacement.length - 1;
    } else if (syntax == '- ') {
      final before = text.substring(0, sel.start);
      final after = text.substring(sel.end);
      final newLine = before.endsWith('\n') || before.isEmpty ? '' : '\n';
      replacement = '$before$newLine- $selected$after';
      ctrl.text = replacement;
      ctrl.selection = TextSelection.collapsed(
        offset: sel.start + newLine.length + 2 + selected.length,
      );
      onChanged?.call(ctrl.text);
      return;
    } else if (syntax == '1. ') {
      final before = text.substring(0, sel.start);
      final after = text.substring(sel.end);
      final newLine = before.endsWith('\n') || before.isEmpty ? '' : '\n';
      replacement = '$before${newLine}1. $selected$after';
      ctrl.text = replacement;
      ctrl.selection = TextSelection.collapsed(
        offset: sel.start + newLine.length + 3 + selected.length,
      );
      onChanged?.call(ctrl.text);
      return;
    } else {
      replacement = selected;
      cursorOffset = sel.start;
    }

    ctrl.text = text.substring(0, sel.start) + replacement + text.substring(sel.end);
    ctrl.selection = TextSelection.collapsed(offset: cursorOffset);
    onChanged?.call(ctrl.text);
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withOpacity(0.75),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? AppColors.adminRed : AppColors.softBlue,
              width: hasError ? 1.5 : 1.2,
            ),
          ),
          child: Column(
            children: [
              // Toolbar format teks (menyatu dengan latar softBlue)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                ),
                child: Row(
                  children: [
                    _buildToolbarButton(
                      icon: Icons.format_bold_rounded,
                      tooltip: 'Tebal (**teks**)',
                      onTap: () => _insertMarkdown('**'),
                    ),
                    const SizedBox(width: 6),
                    _buildToolbarButton(
                      icon: Icons.format_italic_rounded,
                      tooltip: 'Miring (_teks_)',
                      onTap: () => _insertMarkdown('_'),
                    ),
                    const SizedBox(width: 6),
                    _buildToolbarButton(
                      icon: Icons.format_list_bulleted_rounded,
                      tooltip: 'Daftar butir (- butir)',
                      onTap: () => _insertMarkdown('- '),
                    ),
                    const SizedBox(width: 6),
                    _buildToolbarButton(
                      icon: Icons.format_list_numbered_rounded,
                      tooltip: 'Daftar bernomor (1. butir)',
                      onTap: () => _insertMarkdown('1. '),
                    ),
                    if (showMarkdownHint) ...[
                      const Spacer(),
                      Text(
                        'Markdown didukung',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Area input teks
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: TextField(
                  controller: controller,
                  maxLines: maxLines,
                  minLines: minLines,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.adminRed,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

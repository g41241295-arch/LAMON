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

  const AdminMarkdownEditorField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.minLines = 4,
    this.maxLines = 8,
    this.errorText,
    this.onChanged,
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
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4FB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF134563)),
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
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError ? AppColors.adminRed : AppColors.inputBorder,
              width: hasError ? 1.6 : 1.4,
            ),
          ),
          child: Column(
            children: [
              // Toolbar format teks
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    _buildToolbarButton(
                      icon: Icons.format_bold_rounded,
                      tooltip: 'Tebal (**teks**)',
                      onTap: () => _insertMarkdown('**'),
                    ),
                    const SizedBox(width: 4),
                    _buildToolbarButton(
                      icon: Icons.format_italic_rounded,
                      tooltip: 'Miring (_teks_)',
                      onTap: () => _insertMarkdown('_'),
                    ),
                    const SizedBox(width: 4),
                    _buildToolbarButton(
                      icon: Icons.format_list_bulleted_rounded,
                      tooltip: 'Daftar butir (- butir)',
                      onTap: () => _insertMarkdown('- '),
                    ),
                    const SizedBox(width: 4),
                    _buildToolbarButton(
                      icon: Icons.format_list_numbered_rounded,
                      tooltip: 'Daftar bernomor (1. butir)',
                      onTap: () => _insertMarkdown('1. '),
                    ),
                    const Spacer(),
                    Text(
                      'Markdown didukung',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.neutralGray),
                    ),
                  ],
                ),
              ),
              // Area input teks
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: TextField(
                  controller: controller,
                  maxLines: maxLines,
                  minLines: minLines,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.primaryText,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.inputPlaceholder,
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
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.adminRed),
            ),
          ),
        ],
      ],
    );
  }
}

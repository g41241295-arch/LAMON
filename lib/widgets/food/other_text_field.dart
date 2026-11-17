import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

/// Input teks bebas berdesain formal yang muncul secara dinamis ketika opsi "Lainnya"
/// dipilih pada [ChipSelector].
class OtherTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool hasError;
  final bool enabled;

  const OtherTextField({
    super.key,
    required this.controller,
    this.hint = 'Tuliskan jenis lainnya di sini...',
    this.hasError = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFFAFAF7) : const Color(0xFFF2ECE1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError
                    ? Colors.red.shade400
                    : const Color(0xFFEBE3D0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: enabled ? const Color(0xFF1C4E68) : const Color(0xFF7C8E97),
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF276F8F),
                  size: 20,
                ),
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9CB3C2),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 13, color: Colors.red.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Mohon isi keterangan lainnya',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

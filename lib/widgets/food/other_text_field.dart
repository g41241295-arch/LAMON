import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Input teks bebas yang muncul secara kondisional ketika opsi "Lainnya"
/// dipilih pada [ChipSelector].
class OtherTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool hasError;
  final bool enabled;

  const OtherTextField({
    super.key,
    required this.controller,
    this.hint = 'Tuliskan di sini...',
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
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              fontSize: 13,
              color: enabled ? AppColors.primaryText : AppColors.inputPlaceholder,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.inputPlaceholder,
              ),
              filled: true,
              fillColor: enabled ? AppColors.inputBackground : AppColors.lightGray,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red.shade400
                      : AppColors.inputBorder,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.inputBorderFocus,
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Text(
              'Mohon isi keterangan lainnya',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

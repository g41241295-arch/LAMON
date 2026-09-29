import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

// ============================================================
// Latar gradasi kuning lembut khas admin
// ============================================================
class AdminGradientBackground extends StatelessWidget {
  final Widget child;
  const AdminGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF4A8),
            Color(0xFFFAF4C8),
            Color(0xFFFFFDE8),
          ],
        ),
      ),
      child: child,
    );
  }
}

// ============================================================
// AppBar custom admin: tombol back + judul Poppins + aksi kanan
// ============================================================
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  final bool showBack;

  const AdminAppBar({
    super.key,
    required this.title,
    this.trailing,
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF4A8), Color(0xFFFAF4C8)],
        ),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: AppColors.adminBlue,
              onPressed: () => Navigator.of(context).pop(),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.adminBlue,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ============================================================
// Chip filter A-D / E-M / N-Z
// ============================================================
class AdminFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const AdminFilterChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.adminChipActive : AppColors.adminChipInactive,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.adminChipActive : AppColors.adminBlue.withValues(alpha: 0.5),
            width: 1.4,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: AppColors.adminBlue.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.adminBlue,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Search bar admin
// ============================================================
class AdminSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const AdminSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primaryText),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.inputPlaceholder,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.inputIcon, size: 22),
        ),
      ),
    );
  }
}

// ============================================================
// Input field admin (label + field rounded)
// ============================================================
class AdminInputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final bool readOnly;

  const AdminInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
  });

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
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? AppColors.adminRed : AppColors.inputBorder,
              width: hasError ? 1.6 : 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: 1,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onChanged: onChanged,
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primaryText),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.inputPlaceholder,
              ),
            ),
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

// ============================================================
// Dialog konfirmasi hapus reusable
// ============================================================
class DeleteConfirmDialog extends StatelessWidget {
  final String entryName;
  final bool isLoading;
  final VoidCallback onDelete;

  const DeleteConfirmDialog({
    super.key,
    required this.entryName,
    required this.isLoading,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon tempat sampah dalam lingkaran merah
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.adminRedLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.adminRed.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.adminRed,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hapus entri ini ?',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$entryName"',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.adminBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Entri yang sudah dihapus tidak dapat dikembalikan dan akan langsung hilang dari aplikasi user.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.neutralGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.neutralGray),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralGray,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Ya, Hapus',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

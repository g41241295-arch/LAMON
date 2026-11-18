import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/bg_admin_beranda.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFFBFAE6)),
          ),
        ),
        child,
      ],
    );
  }
}

// ============================================================
// Scaffold khusus admin untuk menghilangkan area hitam
// ============================================================
class AdminScaffold extends StatelessWidget {
  final Widget? header;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;

  const AdminScaffold({
    super.key,
    this.header,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
    this.backgroundGradient,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor ?? Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        floatingActionButton: floatingActionButton,
        body: Stack(
          children: [
            Positioned.fill(
              child: backgroundGradient != null
                  ? Container(
                      decoration: BoxDecoration(gradient: backgroundGradient),
                    )
                  : backgroundColor != null
                      ? ColoredBox(color: backgroundColor!)
                      : Image.asset(
                          'assets/images/bg_admin_beranda.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: const Color(0xFFFBFAE6)),
                        ),
            ),
            SafeArea(
              child: Column(
                children: [
                  ?header,
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// AppBar custom admin: tombol back + judul Poppins + aksi kanan
// ============================================================
class AdminAppBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: const Color(0xFF1E3A8A),
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
                color: const Color(0xFF1E3A8A),
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
// Chip filter kategori
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.textPrimary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.textPrimary : AppColors.softBlue,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : AppColors.textPrimary,
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
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softBlue, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.normal,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
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
  final String? suffixText;

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
    this.suffixText,
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
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: 1,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.surfaceCard,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.adminRed
                    : AppColors.softBlue.withOpacity(0.5),
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.adminRed
                    : AppColors.softBlue.withOpacity(0.5),
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppColors.adminRed : AppColors.softBlue,
                width: 1.5,
              ),
            ),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.normal,
              color: AppColors.textSecondary,
            ),
            suffixText: suffixText,
            suffixStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
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
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon tempat sampah dalam lingkaran softBlue
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.softBlue, width: 1.5),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hapus entri ini ?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '"$entryName"',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Entri yang sudah dihapus tidak dapat dikembalikan dan akan langsung hilang dari aplikasi user.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.textPrimary, width: 1.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Ya, Hapus',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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

// ============================================================
// Container dengan border dashed (putus-putus) untuk area upload gambar
// ============================================================
class AdminDashedBorderBox extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color backgroundColor;
  final double borderRadius;
  final double strokeWidth;

  const AdminDashedBorderBox({
    super.key,
    required this.child,
    this.borderColor = AppColors.softBlue,
    this.backgroundColor = AppColors.surfaceCard,
    this.borderRadius = 16.0,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
        color: borderColor,
        radius: borderRadius,
        strokeWidth: strokeWidth,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(strokeWidth / 2);

    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

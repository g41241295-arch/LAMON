import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Header bergaya pill/chip: tombol kembali lingkaran putih di kiri,
/// judul dalam badge krem di tengah, dan aksi opsional di kanan.
///
/// Dapat dipakai sebagai [PreferredSizeWidget] langsung di slot [appBar]
/// **AppScaffold** maupun sebagai widget biasa di dalam body layar.
///
/// Contoh pemakaian di AppScaffold:
/// ```dart
/// AppScaffold(
///   appBar: AppHeaderPill(title: 'Ringkasan Pembayaran'),
///   body: …,
/// )
/// ```
class AppHeaderPill extends StatelessWidget implements PreferredSizeWidget {
  /// Judul yang ditampilkan di pill/chip tengah.
  final String title;

  /// Widget opsional di sisi kanan. Jika null → placeholder invisible
  /// (40×40) agar judul tetap benar-benar center.
  final Widget? rightAction;

  /// Callback kustom untuk tombol kembali. Default: [Navigator.pop].
  final VoidCallback? onBack;

  const AppHeaderPill({
    super.key,
    required this.title,
    this.rightAction,
    this.onBack,
  });

  // ── PreferredSizeWidget ──────────────────────────────────────────────────
  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return _AppHeaderPillBody(
      title: title,
      rightAction: rightAction,
      onBack: onBack,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Implementasi internal (shared antara PreferredSizeWidget & body widget)
// ─────────────────────────────────────────────────────────────────────────────

class _AppHeaderPillBody extends StatelessWidget {
  final String title;
  final Widget? rightAction;
  final VoidCallback? onBack;

  const _AppHeaderPillBody({
    required this.title,
    this.rightAction,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBack = onBack ?? () => Navigator.of(context).pop();

    // Tombol kembali lingkaran putih
    final backButton = InkWell(
      onTap: effectiveBack,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD6E2E8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );

    // Badge / pill judul
    final titlePill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE8DCAB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryText,
          letterSpacing: 0.2,
        ),
      ),
    );

    // Sisi kanan: aksi kustom ATAU invisible placeholder agar judul tetap center
    final right = rightAction ??
        const SizedBox(width: 40, height: 40); // invisible placeholder

    return Container(
      // Transparan agar gradient latar dari AppScaffold/body tetap terlihat
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            backButton,
            titlePill,
            right,
          ],
        ),
      ),
    );
  }
}

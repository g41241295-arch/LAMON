import 'package:flutter/material.dart';

/// Kartu section formal berstandar LAMON (putih solid, border krem lembut, bayangan halus)
/// sebagai wadah tiap kelompok pertanyaan di halaman Catat Makanan.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Border? border;

  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: border ??
            Border.all(
              color: const Color(0xFFEBE3D0),
              width: 1.2,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

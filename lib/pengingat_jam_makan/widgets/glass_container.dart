import 'package:flutter/material.dart';

/// Container dengan efek glassmorphism lembut sesuai tema LAMON
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final List<BoxShadow>? shadows;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.backgroundColor,
    this.border,
    this.onTap,
    this.width,
    this.height,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? Colors.white.withValues(alpha: 0.75);
    final effectiveBorder = border ??
        Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1.2,
        );

    final boxDecoration = BoxDecoration(
      color: effectiveBgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: effectiveBorder,
      boxShadow: shadows ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
    );

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: boxDecoration,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

import 'package:flutter/material.dart';

class AdminBackground extends StatelessWidget {
  final Widget child;

  const AdminBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/bg_admin_beranda.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFFFF9E5)),
          ),
        ),
        child,
      ],
    );
  }
}

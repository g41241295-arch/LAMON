import 'package:flutter/material.dart';

class BeritaCategoryChip extends StatelessWidget {
  final String category;

  const BeritaCategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA), // putih/abu sangat muda
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB0C4DE), width: 0.8), // abu-biru
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Color(0xFF2F80A8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

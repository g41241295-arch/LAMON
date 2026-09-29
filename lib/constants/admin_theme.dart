import 'package:flutter/material.dart';

class AdminTheme {
  // Blue gradient for specific elements (cards, header, buttons)
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB7D1DF), Color(0xFFFFFFFF)],
  );

  // Background color for cards/boxes
  static const Color cardColor = Color(0xFFFBFAE6);

  // Main text color for readability over gradient and cards
  static const Color navyText = Color(0xFF1E3A8A);

  // Secondary text or borders if needed
  static const Color borderBlue = Color(0xFFB7D1DF);
}

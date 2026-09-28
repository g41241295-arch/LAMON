// lib/widgets/berita/berita_header.dart
// Header "Berita Terkini" yang digunakan oleh halaman daftar maupun detail.
// Menggunakan Stack agar judul selalu tepat di tengah layar
// walaupun panah kiri ada di sisi kiri.

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class BeritaHeader extends StatelessWidget {
  const BeritaHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Judul pill di tengah ──────────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFDE8),
                      Color(0xFFF6E8B6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFDEC99B),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 2,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
                child: const Text(
                  'Berita Terkini',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryText,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),

            // ── Panah kembali di sisi kiri ───────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.primaryText,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Header halaman Berita.
/// Dibuat identik dengan header CatatMakananmu:
///   - Back button: wadah putih bundar, ikon arrow_back_rounded ukuran 20
///   - Pill judul: padding (h:18, v:8), radius 24, warna 0xFFFFF7D6,
///     border 0xFFE8DCAB 1.2 px, shadow kecil
///   - Font judul: 14 w800 letterSpacing 0.2 warna AppColors.primaryText
///   - Container padding: fromLTRB(16, 12, 16, 0)  — sama dengan CatatMakanan
///
/// Catatan: BeritaListScreen/BeritaDetailScreen memakai Scaffold biasa
/// (bukan AppScaffold), sehingga SafeArea tetap diperlukan di sini.
class BeritaHeader extends StatelessWidget {
  const BeritaHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        // Padding sama persis dengan CatatMakananmu._buildHeader()
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Tombol kembali (kiri) ──────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFEBE3D0),
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
                    color: AppColors.primaryText,
                    size: 20,
                  ),
                ),
              ),
            ),

            // ── Pill judul (tengah) ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFEBE3D0),
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
              child: const Text(
                'Berita Kesehatan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

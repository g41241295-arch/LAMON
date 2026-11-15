import 'package:flutter/material.dart';

/// Header bergaya pill krem-emas dengan tombol kembali lingkaran putih.
/// Dipakai di Profil Admin, Kelola Gastropedia, Tambah/Edit Gastropedia.
///
/// - [title] : teks judul di dalam pill.
/// - [onBack] : callback tombol kembali (default: Navigator.maybePop).
/// - [trailing] : widget opsional di sisi kanan (contoh: tombol cloud).
///   Widget ini dibungkus SizedBox(width:40, height:40) agar judul tetap
///   benar-benar di tengah layar.
class GastropediaHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  const GastropediaHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Tombol Kembali ──────────────────────────────────────────────
          InkWell(
            onTap: onBack ?? () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF1E5D7D),
                  size: 22,
                ),
              ),
            ),
          ),

          // ── Judul Pill (selalu di tengah karena Expanded + Center) ──────
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E5D7D),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),

          // ── Sisi kanan: trailing atau penyeimbang lebar ─────────────────
          SizedBox(
            width: 40,
            height: 40,
            child: trailing,
          ),
        ],
      ),
    );
  }
}

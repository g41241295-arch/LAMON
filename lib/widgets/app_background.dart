import 'package:flutter/material.dart';

/// Widget latar belakang LAMON: menampilkan [bg_beranda_polos.png] memenuhi
/// layar di belakang [child]. Latar bersifat tetap (tidak ikut scroll) dan
/// tidak terpengaruh oleh keyboard (widget ini dipasang di luar Scaffold).
///
/// Gunakan sebagai pembungkus tertinggi di setiap layar yang membutuhkan
/// latar bersama, atau lewat [AppScaffold] / [ScreeningScaffold] yang sudah
/// menggunakannya secara otomatis.
class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  /// Fallback gradient bila gambar gagal dimuat.
  static const _fallbackGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFDE88A), // kuning atas
      Color(0xFFFFF8DC), // krem bawah
    ],
  );

  bool _imageError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache agar tidak berkedip saat pertama kali muncul.
    precacheImage(
      const AssetImage('assets/images/bg_beranda_polos.png'),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Layer latar: tetap di belakang, tidak ikut scroll ──────────────
        Positioned.fill(
          child: RepaintBoundary(
            child: _imageError
                ? Container(
                    decoration: const BoxDecoration(gradient: _fallbackGradient),
                  )
                : Image.asset(
                    'assets/images/bg_beranda_polos.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      // Tandai error agar frame berikutnya memakai gradient.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _imageError = true);
                      });
                      return Container(
                        decoration:
                            const BoxDecoration(gradient: _fallbackGradient),
                      );
                    },
                  ),
          ),
        ),

        // ── Konten layar ───────────────────────────────────────────────────
        widget.child,
      ],
    );
  }
}

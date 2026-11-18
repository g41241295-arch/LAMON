import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/consultation_theme.dart';

/// Layar transisi setelah pembayaran berhasil (SIMULASI).
/// Menampilkan animasi sukses selama ~2 detik lalu otomatis navigasi ke chat.
class PaymentSuccessScreen extends StatefulWidget {
  final String consultationId;

  const PaymentSuccessScreen({super.key, required this.consultationId});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    // Auto-navigate setelah 2.2 detik
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/konsultasi/chat/${widget.consultationId}',
          (route) => route.settings.name == '/beranda' || route.isFirst,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConsultationTheme.scaffoldBg,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon centang animasi
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: ConsultationTheme.greenBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 72,
                    color: ConsultationTheme.green,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Teks sukses
              Text(
                'PEMBAYARAN BERHASIL',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ConsultationTheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'Menghubungkan Anda dengan dokter...',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: ConsultationTheme.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(ConsultationTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

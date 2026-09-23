import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Layar transisi setelah pembayaran berhasil (SIMULASI).
/// Menampilkan animasi sukses selama ~2 detik lalu otomatis navigasi ke chat.
///
/// TODO(payment-gateway): Layar ini adalah simulasi semata. Dalam implementasi
/// sungguhan, transisi ke halaman chat hanya boleh terjadi setelah menerima
/// konfirmasi pembayaran dari webhook payment gateway yang valid.
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
        // Replace seluruh stack navigasi konsultasi ke halaman chat
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
      backgroundColor: Colors.white,
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
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Teks sukses
              const Text(
                'PEMBAYARAN',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryText,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'SUKSES',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.successGreen,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Menghubungkan Anda dengan dokter...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.neutralGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'widgets/screening_avatars.dart';

class ScreeningSuccessScreen extends StatefulWidget {
  const ScreeningSuccessScreen({super.key});

  @override
  State<ScreeningSuccessScreen> createState() => _ScreeningSuccessScreenState();
}

class _ScreeningSuccessScreenState extends State<ScreeningSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _navigateTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    // Tahan 2.2 detik kemudian transisi halus ke /beranda
    _navigateTimer = Timer(const Duration(milliseconds: 2200), _goToBeranda);
  }

  void _goToBeranda() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _navigateTimer?.cancel();
    Navigator.pushNamedAndRemoveUntil(context, '/beranda', (route) => false);
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.desktopBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goToBeranda,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 520;
            final contentWidget = _buildSuccessBody();

            if (isLargeScreen) {
              final maxH = constraints.maxHeight.isFinite
                  ? constraints.maxHeight.clamp(0.0, 880.0)
                  : 860.0;
              return Center(
                child: Container(
                  width: 420,
                  height: maxH,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.12),
                      width: 3,
                    ),
                  ),
                  child: contentWidget,
                ),
              );
            }

            return contentWidget;
          },
        ),
      ),
    );
  }

  Widget _buildSuccessBody() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgGradientTop,
            AppColors.bgGradientMiddle,
            AppColors.bgGradientBottom,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon lingkaran hijau besar 3D dengan checkmark putih
                      const GreenCheckmark3DBadge(size: 130),
                      const SizedBox(height: 32),

                      // Teks DATA BERHASIL DISIMPAN
                      const Text(
                        'DATA BERHASIL\nDISIMPAN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF389F12),
                          letterSpacing: 2.0,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

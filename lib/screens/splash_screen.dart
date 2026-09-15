import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

/// SplashScreen — animasi pembuka LAMON sebelum halaman Login.
///
/// Urutan animasi (total ±13 detik):
///   0.0s – 2.1s → Tahap 1: Logo meluncur masuk dari luar batas atas layar ke posisi tengah
///   2.1s – 4.3s → Tahap 2: Logo membesar (scale-up 1.0 → 1.35) sebagai penekanan di tengah
///   4.3s – 5.4s → Tahap 3: Logo memudar keluar (exit) hingga tuntas sebelum teks muncul
///   5.4s – 8.7s → Tahap 4: Teks "LAMON" scramble-in berurutan setelah logo selesai
///   8.7s – 10.9s → Tahap 5: Subtitle "LAMBUNG AWARENESS & MONITORING" fade & slide-in
///   10.9s – 13.3s → Tahap 6: "WELCOME" tampil (hitam, bold) menggantikan teks sebelumnya
///   13.3s → Pindah ke halaman /login (bisa di-tap kapan saja untuk lewati)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Phase controllers ───────────────────────────────────────────────────
  late final AnimationController _logoSlideCtrl;
  late final AnimationController _logoScaleCtrl;
  late final AnimationController _logoExitCtrl;
  late final AnimationController _scrambleCtrl;
  late final AnimationController _subtitleCtrl;
  late final AnimationController _welcomeCtrl;

  // ── Derived animations ──────────────────────────────────────────────────
  // Tahap 1: Meluncur dari atas ke tengah
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoSlideOpacity;

  // Tahap 2: Membesar di tengah
  late final Animation<double> _logoScale;

  // Tahap 3: Memudar sebelum teks mulai
  late final Animation<double> _logoExitOpacity;
  late final Animation<double> _logoExitScale;

  // Tahap 4: Text scramble LAMON
  late final Animation<double> _scrambleProgress;
  late final Animation<double> _lamonOpacity;

  // Tahap 5: Subtitle
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  // Tahap 6: WELCOME
  late final Animation<double> _welcomeOpacity;
  late final Animation<double> _prevTextOpacity;

  // ── Text scramble state ─────────────────────────────────────────────────
  static const _target = 'LAMON';
  static const _charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  String _displayText = 'LAMON';
  final _rng = Random();

  // ── Phase flag ─────────────────────────────────────────────────────────
  // 0 = slide in, 1 = scale up, 2 = exit logo, 3 = scramble LAMON, 4 = subtitle, 5 = welcome
  int _phase = 0;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // ── Tahap 1: Logo slide-in dari batas atas layar (1800ms) ─────────────
    _logoSlideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0.0, -2.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoSlideCtrl, curve: Curves.easeOutCubic),
    );
    _logoSlideOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoSlideCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // ── Tahap 2: Logo scale-up di tengah sebagai penekanan (1200ms) ────────
    _logoScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _logoScaleCtrl, curve: Curves.easeOutBack),
    );

    // ── Tahap 3: Logo exit fade-out sebelum teks muncul (800ms) ────────────
    _logoExitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoExitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _logoExitCtrl, curve: Curves.easeInOut),
    );
    _logoExitScale = Tween<double>(begin: 1.35, end: 1.15).animate(
      CurvedAnimation(parent: _logoExitCtrl, curve: Curves.easeInOut),
    );

    // ── Tahap 4: Text scramble LAMON (2500ms) ──────────────────────────────
    _scrambleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _scrambleProgress = CurvedAnimation(
      parent: _scrambleCtrl,
      curve: Curves.easeInOut,
    );
    _lamonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scrambleCtrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );
    _scrambleCtrl.addListener(_onScrambleTick);

    // ── Tahap 5: Subtitle fade & subtle slide-in (1000ms) ──────────────────
    _subtitleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _subtitleOpacity = CurvedAnimation(
      parent: _subtitleCtrl,
      curve: Curves.easeOut,
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _subtitleCtrl, curve: Curves.easeOutCubic),
    );

    // ── Tahap 6: WELCOME fade-in + LAMON fade-out (800ms) ──────────────────
    _welcomeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _welcomeOpacity = CurvedAnimation(
      parent: _welcomeCtrl,
      curve: Curves.easeOut,
    );
    _prevTextOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _welcomeCtrl, curve: Curves.easeIn),
    );

    _runSequence();
  }

  /// Menjalankan animasi acak karakter "LAMON"
  void _onScrambleTick() {
    final p = _scrambleProgress.value; // 0..1
    final settledCount = (p * _target.length).round().clamp(0, _target.length);
    final buf = StringBuffer();
    for (int i = 0; i < _target.length; i++) {
      if (i < settledCount) {
        buf.write(_target[i]);
      } else {
        buf.write(_charset[_rng.nextInt(_charset.length)]);
      }
    }
    if (mounted) setState(() => _displayText = buf.toString());
  }

  /// Jalankan rangkaian urutan animasi (total ±13 detik)
  Future<void> _runSequence() async {
    // ── Tahap 1: Logo meluncur masuk dari luar batas atas ke tengah (1.8s + 0.3s)
    setState(() => _phase = 0);
    await _logoSlideCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // ── Tahap 2: Logo membesar di tengah sebagai penekanan (1.2s + 1.0s hold)
    setState(() => _phase = 1);
    await _logoScaleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // ── Tahap 3: Logo fade-out tuntas sebelum teks mulai (0.8s + 0.3s buffer)
    setState(() => _phase = 2);
    await _logoExitCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // ── Tahap 4: Teks LAMON scramble setelah logo tuntas (2.5s + 0.8s hold)
    setState(() => _phase = 3);
    await _scrambleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // ── Tahap 5: Subtitle fade-in berurutan (1.0s + 1.2s hold)
    setState(() => _phase = 4);
    await _subtitleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // ── Tahap 6: WELCOME crossfade (0.8s + 1.6s hold)
    setState(() => _phase = 5);
    await _welcomeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    // ── Selesai: Masuk ke login
    _skipToLogin();
  }

  @override
  void dispose() {
    _logoSlideCtrl.dispose();
    _logoScaleCtrl.dispose();
    _logoExitCtrl.dispose();
    _scrambleCtrl.dispose();
    _subtitleCtrl.dispose();
    _welcomeCtrl.dispose();
    super.dispose();
  }

  void _skipToLogin() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Wrap di dalam Scaffold + Material memastikan tidak ada default underline kuning pada Text
    return Scaffold(
      backgroundColor: AppColors.desktopBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipToLogin,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 520;

            Widget content = Material(
              color: Colors.transparent,
              child: _buildContent(),
            );

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
                  child: content,
                ),
              );
            }

            return content;
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoSlideCtrl,
        _logoScaleCtrl,
        _logoExitCtrl,
        _scrambleCtrl,
        _subtitleCtrl,
        _welcomeCtrl,
      ]),
      builder: (context, _) {
        // Logo hanya tampil pada fase 0, 1, dan 2
        final showLogo = _phase <= 2;
        // Teks LAMON & Subtitle tampil pada fase 3, 4, 5
        final showTextPhase = _phase >= 3;

        // Skala gabungan untuk logo (tahap 1 normal scale, tahap 2 membesar, tahap 3 exit)
        double currentLogoScale;
        double currentLogoOpacity;

        if (_phase == 0) {
          currentLogoScale = 1.0;
          currentLogoOpacity = _logoSlideOpacity.value;
        } else if (_phase == 1) {
          currentLogoScale = _logoScale.value;
          currentLogoOpacity = 1.0;
        } else {
          currentLogoScale = _logoExitScale.value;
          currentLogoOpacity = _logoExitOpacity.value;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Base gradient background (kuning khas LAMON) ───────────
            Container(
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
            ),

            // ── TAHAP 1-2-3: LOGO ANIMASI ─────────────────────────────
            if (showLogo)
              Center(
                child: SlideTransition(
                  position: _logoSlide,
                  child: Opacity(
                    opacity: currentLogoOpacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: currentLogoScale,
                      child: Image.asset(
                        AppAssets.logo,
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

            // ── TAHAP 4 & 5: LAMON SCRAMBLE & SUBTITLE ─────────────────
            // Baru mulai muncul setelah logo tuntas (showTextPhase)
            if (showTextPhase)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main LAMON text (tanpa underline/garis apapun)
                    FadeTransition(
                      opacity: _phase == 5
                          ? _prevTextOpacity
                          : _lamonOpacity,
                      child: Text(
                        _displayText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB8630A),
                          letterSpacing: 10,
                          height: 1.0,
                          decoration: TextDecoration.none, // Hilangkan underline
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Subtitle "LAMBUNG AWARENESS & MONITORING"
                    if (_phase >= 4)
                      SlideTransition(
                        position: _subtitleSlide,
                        child: FadeTransition(
                          opacity: _phase == 5
                              ? _prevTextOpacity
                              : _subtitleOpacity,
                          child: const Text(
                            'LAMBUNG AWARENESS & MONITORING',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB8630A),
                              letterSpacing: 3.5,
                              height: 1.0,
                              decoration: TextDecoration.none, // Hilangkan underline
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // ── TAHAP 6: WELCOME TEXT ─────────────────────────────────
            if (_phase == 5)
              Center(
                child: FadeTransition(
                  opacity: _welcomeOpacity,
                  child: const Text(
                    'WELCOME',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: 6,
                      decoration: TextDecoration.none, // Hilangkan underline
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

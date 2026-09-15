import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

/// SplashScreen — animasi pembuka LAMON sebelum halaman Login.
///
/// Urutan animasi (total ±3.5 detik):
///   0.0s → Logo fade/scale-in di background gradient kuning
///   1.2s → Crossfade ke background oranye solid; logo hilang
///   1.8s → Teks LAMON scramble-in di atas background kuning kembali
///   2.6s → Subtitle "LAMBUNG AWARENESS & MONITORING" fade-in
///   3.4s → Crossfade ke "WELCOME" (hitam, bold)
///   4.2s → Navigate ke /login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Phase controllers ───────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _orangeCtrl;
  late final AnimationController _scrambleCtrl;
  late final AnimationController _subtitleCtrl;
  late final AnimationController _welcomeCtrl;

  // ── Derived animations ──────────────────────────────────────────────────
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _orangeOpacity;
  late final Animation<double> _scrambleProgress; // 0..1 drives text-scramble
  late final Animation<double> _textOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _welcomeOpacity;
  late final Animation<double> _prevTextOpacity; // hides LAMON when WELCOME arrives

  // ── Text scramble state ─────────────────────────────────────────────────
  static const _target = 'LAMON';
  static const _charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  String _displayText = 'LAMON';
  final _rng = Random();

  // ── Phase flag ─────────────────────────────────────────────────────────
  // 0 = logo, 1 = orange overlay, 2 = text scramble, 3 = welcome
  int _phase = 0;

  @override
  void initState() {
    super.initState();

    // Phase 0: logo fade+scale-in (0→1.2s)
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoOpacity = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );

    // Phase 1: orange overlay crossfade (1.2→1.8s)
    _orangeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _orangeOpacity = CurvedAnimation(parent: _orangeCtrl, curve: Curves.easeInOut);

    // Phase 2a: text opacity fade-in (1.8→2.2s), within scramble window
    _scrambleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scrambleProgress = CurvedAnimation(parent: _scrambleCtrl, curve: Curves.easeInOut);
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scrambleCtrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Phase 2b: subtitle fade-in (2.6→3.0s)
    _subtitleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _subtitleOpacity = CurvedAnimation(parent: _subtitleCtrl, curve: Curves.easeOut);

    // Phase 3: welcome fade-in + LAMON fade-out (3.4→3.9s)
    _welcomeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _welcomeOpacity = CurvedAnimation(parent: _welcomeCtrl, curve: Curves.easeOut);
    _prevTextOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _welcomeCtrl, curve: Curves.easeIn),
    );

    // Wire up scramble ticker
    _scrambleCtrl.addListener(_onScrambleTick);

    _runSequence();
  }

  /// Drives the letter-shuffle effect based on [_scrambleProgress].
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

  Future<void> _runSequence() async {
    // Phase 0: logo fade-in
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    // Phase 1: orange crossfade (logo fades with it via opacity)
    setState(() => _phase = 1);
    await _orangeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Phase 2: orange fades out, text scramble starts
    setState(() => _phase = 2);
    _orangeCtrl.reverse();
    await Future.delayed(const Duration(milliseconds: 100));
    await _scrambleCtrl.forward();

    // Show subtitle
    await Future.delayed(const Duration(milliseconds: 100));
    await _subtitleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 900));

    // Phase 3: WELCOME
    setState(() => _phase = 3);
    _welcomeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1000));

    // Navigate to login
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _orangeCtrl.dispose();
    _scrambleCtrl.dispose();
    _subtitleCtrl.dispose();
    _welcomeCtrl.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _skipToLogin,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 520;

          Widget content = _buildContent();

          if (isLargeScreen) {
            final maxH = constraints.maxHeight.isFinite
                ? constraints.maxHeight.clamp(0.0, 880.0)
                : 860.0;
            return Scaffold(
              backgroundColor: AppColors.desktopBackground,
              body: Center(
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
              ),
            );
          }

          return content;
        },
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoCtrl,
        _orangeCtrl,
        _scrambleCtrl,
        _subtitleCtrl,
        _welcomeCtrl,
      ]),
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Base gradient background (yellow) ──────────────────────
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

            // ── Phase 0 & 1: Logo ─────────────────────────────────────
            if (_phase == 0 || _phase == 1)
              Center(
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Image.asset(
                      AppAssets.logo,
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

            // ── Phase 1: Orange overlay crossfade ─────────────────────
            FadeTransition(
              opacity: _orangeOpacity,
              child: Container(
                color: const Color(0xFFF5A623),
              ),
            ),

            // ── Phase 2: LAMON scramble text ──────────────────────────
            if (_phase == 2 || _phase == 3)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main LAMON text
                    FadeTransition(
                      opacity: _phase == 3
                          ? _prevTextOpacity
                          : _textOpacity,
                      child: Text(
                        _displayText,
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB8630A),
                          letterSpacing: 10,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Subtitle
                    FadeTransition(
                      opacity: _phase == 3
                          ? _prevTextOpacity
                          : _subtitleOpacity,
                      child: const Text(
                        'LAMBUNG AWARENESS & MONITORING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB8630A),
                          letterSpacing: 3.5,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Phase 3: WELCOME text ─────────────────────────────────
            if (_phase == 3)
              Center(
                child: FadeTransition(
                  opacity: _welcomeOpacity,
                  child: const Text(
                    'WELCOME',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: 6,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _skipToLogin() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

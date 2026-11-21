import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth/biometric_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

/// SplashScreen — Animasi pembuka LAMON berurutan (Total 3.8 detik).
///
/// Urutan Frame:
///   Frame 1 (0.0s – 0.35s) : Logo langsung meluncur turun cepat dari atas ke tengah + halo bulat.
///   Frame 2 (0.35s – 0.75s): Logo zoom dramatis CEPAT + crossfade oranye solid bersih.
///   Frame 3 (0.75s – 1.35s): Teks "NOMAL" muncul font Bebas Neue warna oranye tua.
///   Frame 4 (1.35s – 2.05s): Flip 3D per-huruf cepat "NOMAL" -> "OMALN" (stagger antar huruf).
///   Frame 5 (2.05s – 2.75s): Flip 3D per-huruf cepat "OMALN" -> "LAMON".
///   Frame 6 (2.75s – 3.40s): Subtitle "LAMBUNG AWARENESS & MONITORING" fade-in di bawah "LAMON".
///   Frame 7 (3.40s – 3.80s): Crossfade ke teks "WELCOME" singkat & langsung pindah ke login tanpa delay.
///   Transisi ke /login     : Masuk ke halaman login seketika. Tap kapan saja untuk skip langsung.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _masterCtrl;

  // ── Interval Animations ─────────────────────────────────────────────────────
  // Timeline diatur dalam controller 3800ms (3400ms Opening + 400ms Welcome Screen)

  // Frame 1: Logo slide from top + halo glow (0ms – 350ms : 0.000..0.092)
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoSlideOpacity;
  late final Animation<double> _haloOpacity;

  // Frame 2: Zoom + Orange (350ms – 750ms : 0.092..0.197)
  late final Animation<double> _logoDramaticScale;
  late final Animation<double> _logoExitOpacity;
  late final Animation<double> _orangeBgOpacity;

  // Frame 3: Teks "NOMAL" muncul (750ms – 1350ms : 0.197..0.355)
  late final Animation<double> _nomalOpacity;

  // Frame 4: Flip "NOMAL" -> "OMALN" (1350ms – 2050ms : 0.355..0.539)
  late final Animation<double> _flipToOmaln;

  // Frame 5: Flip "OMALN" -> "LAMON" (2050ms – 2750ms : 0.539..0.724)
  late final Animation<double> _flipToLamon;

  // Frame 6: Subtitle muncul (2750ms – 3400ms : 0.724..0.895)
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  // Frame 7: WELCOME crossfade (3400ms – 3800ms : 0.895..1.000 -> transisi instan)
  late final Animation<double> _lamonGroupOutOpacity;
  late final Animation<double> _welcomeInOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Total duration: 3800ms
    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    // ── FRAME 1: Logo slide + halo (0.000 – 0.092) — Gerakan cepat & instan dari atas
    _logoSlide = Tween<Offset>(
      begin: const Offset(0.0, -2.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.000, 0.092, curve: Curves.easeOutCubic),
    ));

    _logoSlideOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.000, 0.050, curve: Curves.easeOut),
      ),
    );

    _haloOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.025, 0.092, curve: Curves.easeIn),
      ),
    );

    // ── FRAME 2: Logo dramatic zoom CEPAT + oranye bersih (0.092 – 0.197) ───
    _logoDramaticScale = Tween<double>(begin: 1.0, end: 4.5).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.092, 0.197, curve: Curves.easeInCubic),
      ),
    );

    _logoExitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.092, 0.145, curve: Curves.easeIn),
      ),
    );

    // Background oranye crossfade
    _orangeBgOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 25),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.092, 0.224),
    ));

    // ── FRAME 3: "NOMAL" muncul (0.197 – 0.355) ─────────────────────────────
    _nomalOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.197, 0.355, curve: Curves.easeOut),
      ),
    );

    // ── FRAME 4: Flip NOMAL -> OMALN (0.355 – 0.539) ────────────────────────
    _flipToOmaln = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.355, 0.539, curve: Curves.easeInOut),
      ),
    );

    // ── FRAME 5: Flip OMALN -> LAMON (0.539 – 0.724) ────────────────────────
    _flipToLamon = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.539, 0.724, curve: Curves.easeInOut),
      ),
    );

    // ── FRAME 6: Subtitle muncul (0.724 – 0.895) ─────────────────────────────
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.724, 0.850, curve: Curves.easeOut),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.724, 0.850, curve: Curves.easeOutCubic),
    ));

    // ── FRAME 7: WELCOME crossfade (0.895 – 1.000 : singkat & langsung masuk) ─
    _lamonGroupOutOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.895, 0.930, curve: Curves.easeIn),
      ),
    );

    _welcomeInOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.910, 0.955, curve: Curves.easeOut),
      ),
    );

    _masterCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _skipToLogin();
    });

    _masterCtrl.forward();
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    super.dispose();
  }

  Future<void> _skipToLogin() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    _masterCtrl.stop();

    final handled = await BiometricService.instance.handleSplashNavigation(context);
    if (handled || !mounted) return;

    // Navigasi ke halaman login seketika tanpa jeda
    Navigator.pushReplacementNamed(context, '/login');

    // Proses sign-out dijalankan di background secara asinkron tanpa memblokir transisi UI
    unawaited(FirebaseAuth.instance.signOut().catchError((_) {}));
    unawaited(GoogleSignIn.instance.signOut().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.desktopBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipToLogin,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 520;
            final content = Material(
              color: Colors.transparent,
              child: _buildAnimatedContent(),
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

  Widget _buildAnimatedContent() {
    return AnimatedBuilder(
      animation: _masterCtrl,
      builder: (context, _) {
        final p = _masterCtrl.value;

        // Fase visibilitas (Total timeline 3.8s)
        final showLogo = p < 0.197;
        final showWordPhase = p >= 0.197 && p < 0.940;
        final showWelcome = p >= 0.895;

        // Opacity logo: saat zoom, gunakan exit opacity
        final logoOpacity = (p >= 0.092
                ? _logoExitOpacity.value
                : _logoSlideOpacity.value)
            .clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Background kuning gradient khas LAMON ──────────────────────
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

            // ── Layer oranye solid (Frame 2, tanpa kotak — full screen overlay) ──
            if (_orangeBgOpacity.value > 0.001)
              Opacity(
                opacity: _orangeBgOpacity.value.clamp(0.0, 1.0),
                child: Container(color: const Color(0xFFFFA827)),
              ),

            // ── FRAME 1 & 2: LOGO + HALO LINGKARAN BULAT ──────────────────
            if (showLogo)
              Center(
                child: SlideTransition(
                  position: _logoSlide,
                  child: Opacity(
                    opacity: logoOpacity,
                    child: Transform.scale(
                      scale: p >= 0.092 ? _logoDramaticScale.value : 1.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Halo glow lingkaran transparan — BUKAN kotak
                          Opacity(
                            opacity: _haloOpacity.value.clamp(0.0, 1.0),
                            child: Container(
                              width: 230,
                              height: 230,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Color(0x80FFFFFF), // putih 50% di tengah
                                    Color(0x40FFFACC), // kuning pucat 25%
                                    Colors.transparent, // transparan di tepi
                                  ],
                                  stops: [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // Logo maskot LAMON — PNG transparan, langsung di atas gradient
                          Image.asset(
                            AppAssets.logo,
                            width: 160,
                            height: 160,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── FRAME 3, 4, 5, 6: FLIP WORD + SUBTITLE ────────────────────
            if (showWordPhase)
              Center(
                child: Opacity(
                  opacity: (p >= 0.895
                          ? _lamonGroupOutOpacity.value
                          : _nomalOpacity.value)
                      .clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Per-letter flip 3D dengan stagger
                      _buildFlipWordRow(),
                      const SizedBox(height: 16),

                      // Frame 6: Subtitle
                      if (p >= 0.724)
                        SlideTransition(
                          position: _subtitleSlide,
                          child: Opacity(
                            opacity: _subtitleOpacity.value.clamp(0.0, 1.0),
                            child: const Text(
                              'LAMBUNG AWARENESS & MONITORING',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'BebasNeue',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFB8630A),
                                letterSpacing: 4.0,
                                height: 1.0,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // ── FRAME 8: WELCOME ───────────────────────────────────────────
            if (showWelcome)
              Center(
                child: Opacity(
                  opacity: _welcomeInOpacity.value.clamp(0.0, 1.0),
                  child: const Text(
                    'WELCOME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // BUG 4 FIX: Bebas Neue
                      fontFamily: 'BebasNeue',
                      fontSize: 56,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      letterSpacing: 8,
                      decoration: TextDecoration.none,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Render baris kata dengan efek flip 3D per-karakter + stagger
  Widget _buildFlipWordRow() {
    const w1 = 'NOMAL';
    const w2 = 'OMALN';
    const w3 = 'LAMON';

    final p1to2 = _flipToOmaln.value;
    final p2to3 = _flipToLamon.value;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        String fromChar;
        String toChar;
        double charProgress;

        // BUG 3 FIX: Stagger per huruf dengan Interval berbeda-beda
        // Tiap huruf mulai berputar sedikit setelah huruf sebelumnya (20ms per step)
        const staggerFrac = 0.12; // selisih start antar huruf dalam 0..1
        const flipWindowFrac = 0.55; // lebar window flip tiap huruf

        if (p2to3 > 0.0) {
          fromChar = w2[i];
          toChar = w3[i];
          final start = i * staggerFrac;
          final end = start + flipWindowFrac;
          charProgress = end <= 1.0
              ? ((p2to3 - start) / flipWindowFrac).clamp(0.0, 1.0)
              : (p2to3 - start).clamp(0.0, 1.0);
        } else if (p1to2 > 0.0) {
          fromChar = w1[i];
          toChar = w2[i];
          final start = i * staggerFrac;
          final end = start + flipWindowFrac;
          charProgress = end <= 1.0
              ? ((p1to2 - start) / flipWindowFrac).clamp(0.0, 1.0)
              : (p1to2 - start).clamp(0.0, 1.0);
        } else {
          fromChar = w1[i];
          toChar = w1[i];
          charProgress = 0.0;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.5),
          child: _FlipCharWidget(
            fromChar: fromChar,
            toChar: toChar,
            progress: charProgress,
          ),
        );
      }),
    );
  }
}

/// Flip-clock 3D character: rotasi sumbu X dengan perspektif, Curves.easeInOut
class _FlipCharWidget extends StatelessWidget {
  final String fromChar;
  final String toChar;
  final double progress; // 0.0 .. 1.0

  const _FlipCharWidget({
    required this.fromChar,
    required this.toChar,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (fromChar == toChar || progress <= 0.0) {
      return _char(fromChar);
    }
    if (progress >= 1.0) {
      return _char(toChar);
    }

    // Paruh pertama (0.0 – 0.5): karakter lama berotasi 0° → -90° (menghilang)
    // Paruh kedua (0.5 – 1.0): karakter baru berotasi dari 90° → 0° (muncul)
    // Kurva easeInOut: awal & akhir halus, tengah cepat (efek snap kalender)
    final eased = _easeInOut(progress);
    final isFirstHalf = eased < 0.5;
    final displayChar = isFirstHalf ? fromChar : toChar;

    // Angle: paruh pertama 0 → -π/2, paruh kedua π/2 → 0
    final angle = isFirstHalf
        ? -eased * pi         // 0 → -π/2
        : (1.0 - eased) * pi; // π/2 → 0

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.003) // perspektif 3D
        ..rotateX(angle),
      child: _char(displayChar),
    );
  }

  static double _easeInOut(double t) {
    // Sinusoidal ease-in-out untuk gerakan halus seperti kalender flip
    return -(cos(pi * t) - 1) / 2;
  }

  Widget _char(String ch) {
    return Text(
      ch,
      style: const TextStyle(
        // BUG 4 FIX: Bebas Neue untuk NOMAL, OMALN, LAMON
        fontFamily: 'BebasNeue',
        fontSize: 58,
        fontWeight: FontWeight.w400,
        color: Color(0xFFB8630A),
        height: 1.0,
        decoration: TextDecoration.none,
      ),
    );
  }
}

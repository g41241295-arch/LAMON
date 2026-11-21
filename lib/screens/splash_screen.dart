import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

/// SplashScreen — Animasi pembuka LAMON berurutan (Total 5.3 detik).
///
/// Urutan Frame:
///   Frame 1 (0.0s – 1.25s): Logo meluncur turun dari atas ke tengah + halo bulat (meluncur tenang & halus).
///   Frame 1b (1.25s – 1.85s): Logo singgah tenang di tengah (memberi jeda nyaman, tidak tiba-tiba berganti).
///   Frame 2 (1.85s – 2.25s): Logo zoom membesar halus + crossfade oranye solid bersih.
///   Frame 3 (2.25s – 2.75s): Teks "NOMAL" muncul font Bebas Neue warna oranye tua.
///   Frame 4 (2.75s – 3.50s): Flip 3D per-huruf halus "NOMAL" -> "OMALN" (stagger berurutan).
///   Frame 5 (3.60s – 4.35s): Flip 3D per-huruf halus "OMALN" -> "LAMON".
///   Frame 6 (4.45s – 4.95s): Subtitle "LAMBUNG AWARENESS & MONITORING" fade-in di bawah "LAMON".
///   Frame 7 (4.95s – 5.30s): Crossfade ke teks "WELCOME" singkat & langsung pindah ke login tanpa delay.
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
  // Timeline diatur dalam controller 5300ms (4950ms Opening + 350ms Welcome Screen)

  // Frame 1: Logo slide from top + halo glow (0ms – 1250ms : 0.0000..0.2358)
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoSlideOpacity;
  late final Animation<double> _haloOpacity;

  // Frame 2: Zoom + Orange (1850ms – 2250ms : 0.3491..0.4245)
  late final Animation<double> _logoDramaticScale;
  late final Animation<double> _logoExitOpacity;
  late final Animation<double> _orangeBgOpacity;

  // Frame 3: Teks "NOMAL" muncul (2250ms – 2750ms : 0.4245..0.5189)
  late final Animation<double> _nomalOpacity;

  // Frame 4: Flip "NOMAL" -> "OMALN" (2750ms – 3500ms : 0.5189..0.6604)
  late final Animation<double> _flipToOmaln;

  // Frame 5: Flip "OMALN" -> "LAMON" (3600ms – 4350ms : 0.6792..0.8208)
  late final Animation<double> _flipToLamon;

  // Frame 6: Subtitle muncul (4450ms – 4950ms : 0.8396..0.9340)
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  // Frame 7: WELCOME crossfade (4950ms – 5300ms : 0.9340..1.0000 -> transisi instan)
  late final Animation<double> _lamonGroupOutOpacity;
  late final Animation<double> _welcomeInOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Total duration: 5300ms
    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5300),
    );

    // ── FRAME 1: Logo slide + halo (0.0000 – 0.2358 : 1250ms) — Meluncur lebih santai & halus
    _logoSlide = Tween<Offset>(
      begin: const Offset(0.0, -2.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0000, 0.2358, curve: Curves.easeOutCubic),
    ));

    _logoSlideOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.0000, 0.0849, curve: Curves.easeOut),
      ),
    );

    _haloOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.0340, 0.2358, curve: Curves.easeIn),
      ),
    );

    // ── FRAME 2: Logo dramatic zoom halus + oranye bersih (0.3491 – 0.4245) ───
    _logoDramaticScale = Tween<double>(begin: 1.0, end: 4.5).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.3491, 0.4245, curve: Curves.easeInOutCubic),
      ),
    );

    _logoExitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.3491, 0.4000, curve: Curves.easeIn),
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
      curve: const Interval(0.3491, 0.4450),
    ));

    // ── FRAME 3: "NOMAL" muncul (0.4245 – 0.5189) ─────────────────────────────
    _nomalOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.4245, 0.5189, curve: Curves.easeOut),
      ),
    );

    // ── FRAME 4: Flip NOMAL -> OMALN (0.5189 – 0.6604) ────────────────────────
    _flipToOmaln = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.5189, 0.6604, curve: Curves.linear),
      ),
    );

    // ── FRAME 5: Flip OMALN -> LAMON (0.6792 – 0.8208) ────────────────────────
    _flipToLamon = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.6792, 0.8208, curve: Curves.linear),
      ),
    );

    // ── FRAME 6: Subtitle muncul (0.8396 – 0.9340) ─────────────────────────────
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.8396, 0.9000, curve: Curves.easeOut),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.8396, 0.9000, curve: Curves.easeOutCubic),
    ));

    // ── FRAME 7: WELCOME crossfade (0.9340 – 1.0000 : singkat & langsung masuk) ─
    _lamonGroupOutOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.9340, 0.9600, curve: Curves.easeIn),
      ),
    );

    _welcomeInOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.9450, 0.9800, curve: Curves.easeOut),
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

  void _skipToLogin() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _masterCtrl.stop();

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

        // Fase visibilitas (Total timeline 5.3s)
        final showLogo = p < 0.4245;
        final showWordPhase = p >= 0.4245 && p < 0.9650;
        final showWelcome = p >= 0.9340;

        // Opacity logo: saat zoom (mulai p >= 0.3491), gunakan exit opacity
        final logoOpacity = (p >= 0.3491
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
                      scale: p >= 0.3491 ? _logoDramaticScale.value : 1.0,
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
                  opacity: (p >= 0.9340
                          ? _lamonGroupOutOpacity.value
                          : _nomalOpacity.value)
                      .clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Per-letter flip 3D dengan stagger halus
                      _buildFlipWordRow(),
                      const SizedBox(height: 16),

                      // Frame 6: Subtitle
                      if (p >= 0.8396)
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

            // ── FRAME 7: WELCOME ───────────────────────────────────────────
            if (showWelcome)
              Center(
                child: Opacity(
                  opacity: _welcomeInOpacity.value.clamp(0.0, 1.0),
                  child: const Text(
                    'WELCOME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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

  /// Render baris kata dengan efek flip 3D per-karakter + stagger halus
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

        // Stagger per huruf: jeda antar huruf presisi agar bergelombang halus
        const staggerFrac = 0.08; // selisih start antar huruf
        const flipWindow = 0.60;  // jendela flip per huruf (selesai tuntas <= 1.0)

        if (p2to3 > 0.0) {
          fromChar = w2[i];
          toChar = w3[i];
          final start = i * staggerFrac;
          charProgress = ((p2to3 - start) / flipWindow).clamp(0.0, 1.0);
        } else if (p1to2 > 0.0) {
          fromChar = w1[i];
          toChar = w2[i];
          final start = i * staggerFrac;
          charProgress = ((p1to2 - start) / flipWindow).clamp(0.0, 1.0);
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
    // Kurva easeInOut sinusoidal: awal & akhir halus alami
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
        ..setEntry(3, 2, 0.0015) // perspektif 3D halus & tajam tanpa distorsi berlebih
        ..rotateX(angle),
      child: _char(displayChar),
    );
  }

  static double _easeInOut(double t) {
    // Sinusoidal ease-in-out untuk gerakan halus alami
    return -(cos(pi * t) - 1) / 2;
  }

  Widget _char(String ch) {
    return Text(
      ch,
      style: const TextStyle(
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

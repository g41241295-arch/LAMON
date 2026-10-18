import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

/// SplashScreen — Animasi pembuka LAMON 8 Frame berurutan (Total 8.0 detik).
///
/// Urutan Frame:
///   Frame 1 (0.0s – 0.4s)  : Halaman kosong background gradient kuning lembut.
///   Frame 2 (0.4s – 1.6s)  : Logo meluncur turun dari atas ke tengah + halo bulat (tanpa kotak).
///   Frame 3 (1.6s – 2.1s)  : Logo zoom dramatis CEPAT + crossfade oranye solid bersih.
///   Frame 4 (2.1s – 2.7s)  : Teks "NOMAL" muncul font Bebas Neue warna oranye tua.
///   Frame 5 (2.7s – 3.4s)  : Flip 3D per-huruf cepat "NOMAL" -> "OMALN" (stagger antar huruf).
///   Frame 6 (3.4s – 4.1s)  : Flip 3D per-huruf cepat "OMALN" -> "LAMON".
///   Frame 7 (4.1s – 5.0s)  : Subtitle "LAMBUNG AWARENESS & MONITORING" fade-in di bawah "LAMON".
///   Frame 8 (5.0s – 8.0s)  : Crossfade ke teks "WELCOME" (tampil tepat 3 detik sebelum masuk login).
///   Transisi ke /login     : Masuk ke halaman login setelah Welcome selesai. Tap kapan saja untuk skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _masterCtrl;

  // ── Interval Animations ─────────────────────────────────────────────────────
  // Timeline diatur dalam controller 8000ms (5000ms Opening + 3000ms Welcome Screen)

  // Frame 2: Logo slide from top + halo glow (400ms – 1600ms : 0.050..0.200)
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoSlideOpacity;
  late final Animation<double> _haloOpacity;

  // Frame 3: Zoom + Orange (1600ms – 2100ms : 0.200..0.263)
  late final Animation<double> _logoDramaticScale;
  late final Animation<double> _logoExitOpacity;
  late final Animation<double> _orangeBgOpacity;

  // Frame 4: Teks "NOMAL" muncul (2100ms – 2600ms : 0.263..0.325)
  late final Animation<double> _nomalOpacity;

  // Frame 5: Flip "NOMAL" -> "OMALN" (2700ms – 3400ms : 0.338..0.425)
  late final Animation<double> _flipToOmaln;

  // Frame 6: Flip "OMALN" -> "LAMON" (3400ms – 4100ms : 0.425..0.513)
  late final Animation<double> _flipToLamon;

  // Frame 7: Subtitle muncul (4100ms – 5000ms : 0.513..0.625)
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  // Frame 8: WELCOME crossfade (5000ms – 8000ms : 0.625..1.000 -> 3 detik penuh)
  late final Animation<double> _lamonGroupOutOpacity;
  late final Animation<double> _welcomeInOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Total duration: 8000ms (5.0s opening + 3.0s welcome screen)
    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    // ── FRAME 2: Logo slide + halo (0.050 – 0.200) ──────────────────────────
    _logoSlide = Tween<Offset>(
      begin: const Offset(0.0, -2.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.050, 0.200, curve: Curves.easeOutCubic),
    ));

    _logoSlideOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.050, 0.113, curve: Curves.easeOut),
      ),
    );

    _haloOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.088, 0.200, curve: Curves.easeIn),
      ),
    );

    // ── FRAME 3: Logo dramatic zoom CEPAT + oranye bersih (0.200 – 0.263) ───
    _logoDramaticScale = Tween<double>(begin: 1.0, end: 4.5).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.200, 0.263, curve: Curves.easeInCubic),
      ),
    );

    _logoExitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.200, 0.231, curve: Curves.easeIn),
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
      curve: const Interval(0.200, 0.300),
    ));

    // ── FRAME 4: "NOMAL" muncul (0.263 – 0.325) ─────────────────────────────
    _nomalOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.263, 0.325, curve: Curves.easeOut),
      ),
    );

    // ── FRAME 5: Flip NOMAL -> OMALN (0.338 – 0.425) ────────────────────────
    _flipToOmaln = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.338, 0.425, curve: Curves.easeInOut),
      ),
    );

    // ── FRAME 6: Flip OMALN -> LAMON (0.425 – 0.513) ────────────────────────
    _flipToLamon = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.425, 0.513, curve: Curves.easeInOut),
      ),
    );

    // ── FRAME 7: Subtitle muncul (0.513 – 0.625) ─────────────────────────────
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.513, 0.600, curve: Curves.easeOut),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.513, 0.600, curve: Curves.easeOutCubic),
    ));

    // ── FRAME 8: WELCOME crossfade (0.625 – 1.000 : tepat 3 detik) ───────────
    _lamonGroupOutOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.625, 0.669, curve: Curves.easeIn),
      ),
    );

    _welcomeInOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.650, 0.700, curve: Curves.easeOut),
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

  void _skipToLogin() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    _masterCtrl.stop();
    
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
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

        // Fase visibilitas
        final showLogo = p < 0.263;
        final showWordPhase = p >= 0.263 && p < 0.669;
        final showWelcome = p >= 0.625;

        // Opacity logo: saat zoom, gunakan exit opacity
        final logoOpacity = (p >= 0.200
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

            // ── Layer oranye solid (Frame 3, tanpa kotak — full screen overlay) ──
            if (_orangeBgOpacity.value > 0.001)
              Opacity(
                opacity: _orangeBgOpacity.value.clamp(0.0, 1.0),
                child: Container(color: const Color(0xFFFFA827)),
              ),

            // ── FRAME 2 & 3: LOGO + HALO LINGKARAN BULAT ──────────────────
            // BUG 1 FIX: Logo PNG transparan ditempel langsung di atas background.
            // Tidak ada Container/Card/BoxDecoration dengan background solid atau shadow.
            // Hanya RadialGradient berbentuk lingkaran (BoxShape.circle) transparan.
            if (showLogo)
              Center(
                child: SlideTransition(
                  position: _logoSlide,
                  child: Opacity(
                    opacity: logoOpacity,
                    child: Transform.scale(
                      // BUG 2 FIX: Scale langsung ke 4.5 dalam ~700ms (cepat, bersih)
                      scale: p >= 0.200 ? _logoDramaticScale.value : 1.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Halo glow lingkaran transparan — BUKAN kotak
                          // BoxShape.circle + gradient dari putih ke transparent
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
                            // filterQuality tinggi agar tidak blur saat zoom
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── FRAME 4, 5, 6, 7: FLIP WORD + SUBTITLE ────────────────────
            if (showWordPhase)
              Center(
                child: Opacity(
                  opacity: (p >= 0.625
                          ? _lamonGroupOutOpacity.value
                          : _nomalOpacity.value)
                      .clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // BUG 3 FIX: Per-letter flip 3D dengan stagger
                      _buildFlipWordRow(),
                      const SizedBox(height: 16),

                      // Frame 7: Subtitle
                      if (p >= 0.513)
                        SlideTransition(
                          position: _subtitleSlide,
                          child: Opacity(
                            opacity: _subtitleOpacity.value.clamp(0.0, 1.0),
                            child: const Text(
                              'LAMBUNG AWARENESS & MONITORING',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                // BUG 4 FIX: Bebas Neue
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

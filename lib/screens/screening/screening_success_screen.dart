import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state.dart';
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

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    // Otomatis transisi ke /beranda setelah 2.6 detik
    _navigateTimer = Timer(const Duration(milliseconds: 2600), _goToBeranda);
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final appState = AppState.of(context);

    final genderText = appState.draftGender ?? 'Pengguna';
    final hasHistoryText = appState.draftHasHistory == true ? 'Ada Riwayat' : 'Tidak Ada Riwayat';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCFBF7),
              Color(0xFFF7F4EB),
              Color(0xFFF2EEDB),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = constraints.maxWidth > 520;
              final contentWidget = _buildSuccessContent(genderText, hasHistoryText, bottomInset);

              if (isLargeScreen) {
                final maxH = constraints.maxHeight.isFinite
                    ? constraints.maxHeight.clamp(0.0, 880.0)
                    : 860.0;
                return Center(
                  child: Container(
                    width: 440,
                    height: maxH,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.08),
                        width: 2.5,
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
      ),
    );
  }

  Widget _buildSuccessContent(String genderText, String hasHistoryText, double bottomInset) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _goToBeranda,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 28 + bottomInset),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Card Sukses Melayang
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: const Color(0xFFEBE3D0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1C4E68).withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 3D Green Checkmark Badge
                          const GreenCheckmark3DBadge(size: 110),

                          const SizedBox(height: 22),

                          Text(
                            'Skrining Selesai!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1C4E68),
                              letterSpacing: -0.4,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Data profil kesehatan lambung Anda berhasil disimpan. Rekomendasi nutrisi & pemantauan harian kini siap digunakan.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF5A7184),
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Summary Pills
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF4F8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFBED8ED), width: 1.0),
                                ),
                                child: Text(
                                  genderText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1C4E68),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7D6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE8D7A5), width: 1.0),
                                ),
                                child: Text(
                                  hasHistoryText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1C4E68),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const Spacer(),

            // Tombol Langsung Masuk Beranda
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _goToBeranda,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF276F8F),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF276F8F).withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Buka Beranda Utama',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

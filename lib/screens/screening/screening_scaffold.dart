import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreeningScaffold extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String? subtitle;
  final Widget content;
  final String buttonText;
  final VoidCallback? onNext;
  final bool isButtonEnabled;
  final bool isLoading;
  final bool showBottomBar;

  const ScreeningScaffold({
    super.key,
    this.currentStep = 1,
    this.totalSteps = 3,
    required this.title,
    this.subtitle,
    required this.content,
    this.buttonText = 'Lanjutkan',
    this.onNext,
    this.isButtonEnabled = true,
    this.isLoading = false,
    this.showBottomBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
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
                final bodyContent = _buildScaffoldContent(context, bottomInset);

                if (isLargeScreen) {
                  final maxH = constraints.maxHeight.isFinite
                      ? constraints.maxHeight.clamp(0.0, 900.0)
                      : 880.0;
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
                      child: bodyContent,
                    ),
                  );
                }

                return bodyContent;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScaffoldContent(BuildContext context, double bottomInset) {
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);

    return Column(
      children: [
        // ── TOP BAR: Capsule Progress Bar Murni ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 7,
              width: double.infinity,
              color: const Color(0xFFE2E8F0),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF276F8F), Color(0xFF3897BD)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ),

        const Divider(color: Color(0xFFEBE3D0), thickness: 1, height: 1),

        // ── KONTEN TENGAH DENGAN SCROLL ─────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Judul Pertanyaan Skrining
                if (title.isNotEmpty)
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C4E68),
                      letterSpacing: -0.3,
                      height: 1.3,
                    ),
                  ),

                // Deskripsi subtitle hanya ditampilkan jika tidak null dan tidak kosong
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5A7184),
                      height: 1.45,
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Dynamic Interactive Content
                content,
              ],
            ),
          ),
        ),

        // ── BOTTOM BAR: Disclaimer + Action Button ─────────────────────────────
        if (showBottomBar)
          Container(
            padding: EdgeInsets.fromLTRB(24, 14, 24, 24 + bottomInset),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              border: const Border(
                top: BorderSide(color: Color(0xFFEBE3D0), width: 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Privacy Reassurance
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: Color(0xFF7A8B99),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Data kesehatan Anda disimpan secara rahasia & aman.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF7A8B99),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tombol Lanjutkan
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (isButtonEnabled && !isLoading) ? onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF276F8F),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF276F8F).withValues(alpha: 0.35),
                      disabledForegroundColor: Colors.white70,
                      elevation: isButtonEnabled ? 2 : 0,
                      shadowColor: const Color(0xFF276F8F).withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            buttonText,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

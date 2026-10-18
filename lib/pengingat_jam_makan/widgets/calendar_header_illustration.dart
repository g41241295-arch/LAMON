import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_reminder_plan.dart';
import 'glass_container.dart';

/// Komponen Header Ilustrasi Kalender dengan transisi halus dan tombol back adaptif
class CalendarHeaderIllustration extends StatelessWidget {
  final MealCondition condition;
  final int monthNumber; // 1 = Januari, 12 = Desember
  final VoidCallback onBack;
  final double height;

  const CalendarHeaderIllustration({
    super.key,
    required this.condition,
    required this.monthNumber,
    required this.onBack,
    required this.height,
  });

  /// Mengambil path asset berdasarkan indeks = (nomor bulan - 1) % 3
  String get assetPath {
    final index = (monthNumber - 1) % 3;
    final isHealthy = condition == MealCondition.sehat;

    if (isHealthy) {
      switch (index) {
        case 0:
          return 'assets/images/header_sehat_1_piknik.png';
        case 1:
          return 'assets/images/header_sehat_2_masak.png';
        case 2:
        default:
          return 'assets/images/header_sehat_3_salad.png';
      }
    } else {
      switch (index) {
        case 0:
          return 'assets/images/header_sakit_1_piknik.png';
        case 1:
          return 'assets/images/header_sakit_2_masak.png';
        case 2:
        default:
          return 'assets/images/header_sakit_3_istirahat.png';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHealthy = condition == MealCondition.sehat;
    final conditionLabel = isHealthy ? 'Baik-baik saja' : 'Sakit';
    final instructionLabel =
        isHealthy ? 'Pilih tanggal' : 'Pilih tanggal untuk istirahat';
    final topPadding = MediaQuery.of(context).padding.top;

    // Deteksi apakah ilustrasi yang sedang tampil adalah tema piknik (Jan, Apr, Jul, Okt)
    final bool isPicnic = (monthNumber - 1) % 3 == 0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ilustrasi Gambar dengan AnimatedSwitcher fade singkat saat berganti bulan
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: SizedBox(
              key: ValueKey<String>(assetPath),
              width: double.infinity,
              height: height,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackIllustration(isHealthy);
                },
              ),
            ),
          ),

          // 2. Overlay gradient halus di atas gambar untuk estetika
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                    isHealthy
                        ? const Color(0xFFFFF9DB).withValues(alpha: 0.25)
                        : const Color(0xFFC7D2FE).withValues(alpha: 0.25),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 3. Tombol Back Adaptif & Pill "Jadwal Harian" (Top-Left)
          Positioned(
            top: topPadding + 6,
            left: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol Back dengan area sentuh >= 44x44dp dan warna adaptif khusus ilustrasi piknik
                GestureDetector(
                  onTap: onBack,
                  behavior: HitTestBehavior.opaque,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isPicnic
                            ? const Icon(
                                Icons.arrow_back_rounded,
                                key: ValueKey<String>('back_picnic'),
                                color: Color(0xFFFFF8E1), // Krem cerah untuk kontras di atas piknik
                                size: 26,
                                shadows: [
                                  Shadow(
                                    color: Color(0x59000000), // Hitam alpha 35%
                                    blurRadius: 6,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              )
                            : const Icon(
                                Icons.arrow_back,
                                key: ValueKey<String>('back_normal'),
                                color: Color(0xFF1E3A8A), // Biru tua standar LAMON
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Pill "Jadwal Harian"
                GlassContainer(
                  borderRadius: 20,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                  backgroundColor:
                      const Color(0xFFFFF7D6).withValues(alpha: 0.88),
                  child: Text(
                    'Jadwal Harian',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Pill Kondisi ("Baik-baik saja" / "Sakit")
          Positioned(
            top: topPadding + 54,
            left: 56,
            child: GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              backgroundColor: isHealthy
                  ? const Color(0xFFFFFBEB).withValues(alpha: 0.9)
                  : const Color(0xFFFEF3C7).withValues(alpha: 0.9),
              child: Text(
                conditionLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ),
          ),

          // 5. Pill Instruksi ("Pilih tanggal" / "Pilih tanggal untuk istirahat")
          Positioned(
            bottom: 38,
            left: 16,
            child: GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              backgroundColor: Colors.white.withValues(alpha: 0.88),
              child: Text(
                instructionLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isHealthy
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFF7C2D12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder visual polos hanya bila file asset gagal dimuat
  Widget _buildFallbackIllustration(bool isHealthy) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isHealthy
              ? [
                  const Color(0xFFFEF08A),
                  const Color(0xFFBAE6FD),
                  const Color(0xFF86EFAC),
                ]
              : [
                  const Color(0xFFDDD6FE),
                  const Color(0xFFC7D2FE),
                  const Color(0xFFFED7AA),
                ],
        ),
      ),
    );
  }
}

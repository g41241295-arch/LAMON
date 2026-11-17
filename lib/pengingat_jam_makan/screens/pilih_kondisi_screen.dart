import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_background.dart';
import '../debug/alarm_debug.dart';
import '../models/meal_reminder_plan.dart';
import 'kalender_jadwal_screen.dart';

/// Layar 1: Pemilihan kondisi ("Baik-baik saja" atau "Sakit")
/// Redesain bergaya aesthetic, profesional, dan interaktif (Pinterest wellness vibe).
class PilihKondisiScreen extends StatefulWidget {
  const PilihKondisiScreen({super.key});

  @override
  State<PilihKondisiScreen> createState() => _PilihKondisiScreenState();
}

class _PilihKondisiScreenState extends State<PilihKondisiScreen> {
  MealCondition? _pressedCondition;

  Future<void> _handleConditionSelect(MealCondition condition) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KalenderJadwalScreen(condition: condition),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ── Konten Utama (Scrollable) ──────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  children: [
                    // ── Header Bar: Tombol Back & Pill Judul ───────────────
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFEBE3D0),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF1C4E68),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7D6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFE8D7A5),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Pengingat Jam Makan',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C4E68),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Hero Greeting Card / Narrative ────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFEBE3D0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF276F8F)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.eco_rounded,
                                  size: 14,
                                  color: Color(0xFF276F8F),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'PANDUAN POLA MAKAN',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF276F8F),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Bagaimana kondisi lambungmu hari ini?',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C4E68),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pilih kondisi tubuhmu saat ini agar kami dapat menyesuaikan rekomendasi jadwal makan terbaik untukmu.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7C8E97),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Card 1: Baik-baik Saja (MealCondition.sehat) ───────
                    _buildAestheticCard(
                      condition: MealCondition.sehat,
                      title: 'Baik-baik saja',
                      badgeText: 'Pola Normal',
                      badgeBgColor: const Color(0xFFECFDF5),
                      badgeTextColor: const Color(0xFF059669),
                      icon: Icons.sentiment_satisfied_alt_rounded,
                      iconBgColor: const Color(0xFFD1FAE5),
                      iconColor: const Color(0xFF059669),
                      description:
                          'Kondisi lambung prima. Jadwal makan teratur 3 kali sehari dengan rentang waktu yang nyaman dan fleksibel.',
                      tags: const [
                        '🥗 3x Jam Makan',
                        '⏰ Rentang Fleksibel',
                        '🗓️ 1 - 30 Hari',
                      ],
                      buttonLabel: 'Atur Jadwal Sehat',
                      buttonGradient: const [
                        Color(0xFF276F8F),
                        Color(0xFF1C4E68),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ── Card 2: Sakit (MealCondition.sakit) ───────────────
                    _buildAestheticCard(
                      condition: MealCondition.sakit,
                      title: 'Sakit',
                      badgeText: 'Pemulihan',
                      badgeBgColor: const Color(0xFFFFF1F2),
                      badgeTextColor: const Color(0xFFE11D48),
                      icon: Icons.healing_rounded,
                      iconBgColor: const Color(0xFFFFE4E6),
                      iconColor: const Color(0xFFE11D48),
                      description:
                          'Lambung sedang sensitif atau kambuh. Jadwal makan dipandu ketat per jam dilengkapi pengingat waktu tidur.',
                      tags: const [
                        '🥣 Waktu Makan Ketat',
                        '🌙 Atur Jam Tidur',
                        '🗓️ Pemulihan 7 Hari',
                      ],
                      buttonLabel: 'Atur Jadwal Pemulihan',
                      buttonGradient: const [
                        Color(0xFFE5983A),
                        Color(0xFFB45309),
                      ],
                    ),

                    // ── Diagnostik kDebugMode: Tombol "Alarm terjadwal" ───
                    if (kDebugMode) ...[
                      const SizedBox(height: 24),
                      const Center(
                        child: AlarmDebugButton(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAestheticCard({
    required MealCondition condition,
    required String title,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String description,
    required List<String> tags,
    required String buttonLabel,
    required List<Color> buttonGradient,
  }) {
    final isPressed = _pressedCondition == condition;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedCondition = condition),
      onTapUp: (_) {
        setState(() => _pressedCondition = null);
        _handleConditionSelect(condition);
      },
      onTapCancel: () => setState(() => _pressedCondition = null),
      child: AnimatedScale(
        scale: isPressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFEBE3D0),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: isPressed
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: isPressed ? 8 : 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Ikon & Badge Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Judul Kondisi
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C4E68),
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 6),

              // Deskripsi
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7C8E97),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 14),

              // Highlight Feature Tags (Pills)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4EB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFEBE3D0),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C4E68),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Tombol Aksi di Bawah Card
              Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: buttonGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: buttonGradient.first.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

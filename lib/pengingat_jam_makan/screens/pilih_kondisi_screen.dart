import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_reminder_plan.dart';
import '../widgets/glass_container.dart';
import 'kalender_jadwal_screen.dart';

/// Layar 1: Pemilihan kondisi ("Baik-baik saja" atau "Sakit")
class PilihKondisiScreen extends StatelessWidget {
  const PilihKondisiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Latar Belakang Gradasi Butter Yellow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFEF08A), // Butter yellow
                    Color(0xFFFEF9C3),
                    Color(0xFFFFFBEB), // Soft cream
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 2. Blob Dekoratif Lingkaran Halus
          Positioned(
            top: size.height * 0.15,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBAE6FD).withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.18,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF86EFAC).withValues(alpha: 0.18),
              ),
            ),
          ),

          // 3. Pill "Jadwal Harian" di Tengah Horizontal Layar & Tombol Back di Kiri Atas
          Positioned(
            top: topPadding + 12,
            left: 0,
            right: 0,
            child: Center(
              child: GlassContainer(
                borderRadius: 22,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                backgroundColor: const Color(0xFFFFF7D6).withValues(alpha: 0.85),
                child: Text(
                  'Jadwal Harian',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: topPadding + 12,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF1E3A8A),
                  size: 24,
                ),
              ),
            ),
          ),

          // 4. Dua Tombol Glass Besar di Tengah
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol "Baik-baik saja"
                  _buildConditionButton(
                    context: context,
                    label: 'Baik-baik saja',
                    condition: MealCondition.sehat,
                  ),
                  const SizedBox(height: 22),
                  // Tombol "Sakit"
                  _buildConditionButton(
                    context: context,
                    label: 'Sakit',
                    condition: MealCondition.sakit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionButton({
    required BuildContext context,
    required String label,
    required MealCondition condition,
  }) {
    return GlassContainer(
      borderRadius: 22,
      height: 52,
      width: double.infinity,
      backgroundColor: const Color(0xFFFFF8D6).withValues(alpha: 0.88),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.95),
        width: 1.5,
      ),
      shadows: [
        BoxShadow(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => KalenderJadwalScreen(condition: condition),
          ),
        );
        if (result == true && context.mounted) {
          // Berhasil disimpan, teruskan sinyal refresh ke Beranda
          Navigator.pop(context, true);
        }
      },
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E3A8A),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

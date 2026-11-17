import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_background.dart';
import '../debug/alarm_debug.dart';
import '../models/meal_reminder_plan.dart';
import 'kalender_jadwal_screen.dart';

/// Layar 1: Pemilihan kondisi ("Baik-baik saja" atau "Sakit")
class PilihKondisiScreen extends StatelessWidget {
  const PilihKondisiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. Pill "Pengingat Jam Makan" di Tengah Horizontal Layar & Tombol Back di Kiri Atas
            Positioned(
              top: topPadding + 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
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
                  child: Text(
                    'Pengingat Jam Makan',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C4E68),
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

            // 2. Dua Tombol Besar di Tengah
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

            // 3. Diagnostik kDebugMode: Tombol "Alarm terjadwal"
            if (kDebugMode)
              const Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: AlarmDebugButton(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionButton({
    required BuildContext context,
    required String label,
    required MealCondition condition,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => KalenderJadwalScreen(condition: condition),
          ),
        );
        if (result == true && context.mounted) {
          Navigator.pop(context, true);
        }
      },
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFEBE3D0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C4E68),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

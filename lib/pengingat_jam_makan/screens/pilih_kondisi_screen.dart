import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../debug/alarm_debug.dart';
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
          // 1. Latar Belakang Gradasi Formal LAMON
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFCFBF7),
                    Color(0xFFF7F4EB),
                    Color(0xFFF2EEDB),
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
                color: const Color(0xFF276F8F).withValues(alpha: 0.05),
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
                color: const Color(0xFFE5983A).withValues(alpha: 0.05),
              ),
            ),
          ),

          // 3. Pill "Pengingat Jam Makan" di Tengah Horizontal Layar & Tombol Back di Kiri Atas
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

          // 5. Diagnostik kDebugMode: Tombol "Alarm terjadwal"
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

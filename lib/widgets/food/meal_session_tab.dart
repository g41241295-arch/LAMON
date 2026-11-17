import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/food_entry_model.dart';

/// Segmented control modern berbentuk pill dengan 3 tab sesi makan:
/// - Sarapan (06.00 - 09.29)
/// - Makan Siang (10.00 - 15.59)
/// - Makan Malam (16.00 - 20.00)
///
/// Tab aktif: Kartu putih solid, border lembut, bayangan halus, teks navy bold.
/// Tab non-aktif: Transparan, teks abu-abu lembut.
class MealSessionTab extends StatelessWidget {
  final MealSession activeSession;
  final ValueChanged<MealSession> onSessionChanged;

  /// Map status sesi yang sudah diisi hari ini (key: MealSession, value: true/false)
  final Map<MealSession, bool> submittedMap;

  const MealSessionTab({
    super.key,
    required this.activeSession,
    required this.onSessionChanged,
    this.submittedMap = const {},
  });

  /// Deteksi tab aktif default berdasarkan jam perangkat saat ini.
  static MealSession detectCurrentSession() {
    final hour = DateTime.now().hour;
    final minute = DateTime.now().minute;
    final totalMinutes = hour * 60 + minute;

    // Sarapan: 06.00–09.29 → 360–569 menit
    if (totalMinutes >= 360 && totalMinutes < 570) {
      return MealSession.sarapan;
    }
    // Makan Siang: 10.00–15.59 → 600–959 menit
    if (totalMinutes >= 600 && totalMinutes < 960) {
      return MealSession.makanSiang;
    }
    // Makan Malam: 16.00–20.00 → 960–1200 menit
    if (totalMinutes >= 960 && totalMinutes <= 1200) {
      return MealSession.makanMalam;
    }
    // Default fallback (di luar jam yang ditentukan)
    if (totalMinutes < 360) return MealSession.sarapan;
    return MealSession.makanMalam;
  }

  String _getTimeRange(MealSession session) {
    switch (session) {
      case MealSession.sarapan:
        return '06.00-09.29';
      case MealSession.makanSiang:
        return '10.00-15.59';
      case MealSession.makanMalam:
        return '16.00-20.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2ECE1),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFEBE3D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: MealSession.values.map((session) {
          final isActive = session == activeSession;

          return Expanded(
            child: GestureDetector(
              onTap: () => onSessionChanged(session),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  border: isActive
                      ? Border.all(
                          color: const Color(0xFFEBE3D0),
                          width: 1.2,
                        )
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF276F8F).withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session.label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF1C4E68)
                            : const Color(0xFF7C8E97),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getTimeRange(session),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF276F8F)
                            : const Color(0xFF9CB3C2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

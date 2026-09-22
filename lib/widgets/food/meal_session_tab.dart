import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/food_entry_model.dart';

/// Segmented control berbentuk pill dengan 3 tab sesi makan.
///
/// - Tab aktif: latar putih + shadow tipis
/// - Tab non-aktif: transparan
/// - Diinisialisasi otomatis dari jam perangkat, tapi dapat diklik manual
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: MealSession.values.map((session) {
          final isActive = session == activeSession;
          final isDone = submittedMap[session] == true;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSessionChanged(session),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  session.label,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isActive
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: isActive
                                        ? AppColors.primaryText
                                        : AppColors.neutralGray,
                                  ),
                                ),
                              ),
                              if (isDone) ...[
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: AppColors.successGreen,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            _getTimeRange(session),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? AppColors.primaryText.withValues(alpha: 0.7)
                                  : AppColors.neutralGray.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
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

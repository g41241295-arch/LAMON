import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_schedule_model.dart';

/// Service lokal pengelola jadwal makan dan status harian untuk Beranda
class BerandaMealService {
  static const String keyMealSchedule = 'lamon_meal_schedule';
  static const String keyMealStatusPrefix = 'lamon_meal_status_';

  Timer? _alarmTimer;
  bool _isAlarmRinging = false;
  bool get isAlarmRinging => _isAlarmRinging;

  /// Variabel override waktu khusus mode debug untuk pengujian alarm
  DateTime? debugNow;

  /// Waktu aktif saat ini (mendukung override debugNow saat kDebugMode)
  DateTime get now {
    if (kDebugMode && debugNow != null) {
      return debugNow!;
    }
    return DateTime.now();
  }

  /// Daftar jadwal bawaan
  static const List<MealScheduleItem> defaultSchedules = [
    MealScheduleItem(
      id: 'breakfast',
      title: 'Sarapan',
      displayTitle: 'Jam sarapan',
      startHour: 6,
      startMinute: 0,
      endHour: 8,
      endMinute: 0,
      reminderNote: 'Jangan lupa sarapan sehat !',
    ),
    MealScheduleItem(
      id: 'lunch',
      title: 'Makan siang',
      displayTitle: 'Jam makan siang',
      startHour: 12,
      startMinute: 0,
      endHour: 13,
      endMinute: 0,
      reminderNote: 'Jangan lupa makan !',
    ),
    MealScheduleItem(
      id: 'dinner',
      title: 'Makan malam',
      displayTitle: 'Jam makan malam',
      startHour: 18,
      startMinute: 0,
      endHour: 19,
      endMinute: 0,
      reminderNote: 'Jangan lupa makan malam tepat waktu !',
    ),
  ];

  /// Mengambil daftar jadwal jam makan dari SharedPreferences
  Future<List<MealScheduleItem>> loadSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(keyMealSchedule);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonString);
        return list.map((item) => MealScheduleItem.fromJson(item)).toList();
      }
    } catch (_) {
      // Fallback ke default
    }
    return defaultSchedules;
  }

  /// Format key status per tanggal (YYYY-MM-DD)
  String _dateKey(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$keyMealStatusPrefix$year-$month-$day';
  }

  /// Validasi apakah waktu aktual berada dalam rentang jam makan yang sah
  bool _isActualTimeValidForMeal(String mealId, String? actualTime) {
    if (actualTime == null || actualTime.isEmpty) return false;
    final parts = actualTime.split('.');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;

    final totalMinutes = hour * 60 + minute;
    switch (mealId) {
      case 'breakfast':
        return totalMinutes >= 6 * 60 && totalMinutes <= 8 * 60;
      case 'lunch':
        return totalMinutes >= 12 * 60 && totalMinutes <= 13 * 60;
      case 'dinner':
        return totalMinutes >= 18 * 60 && totalMinutes <= 19 * 60;
      default:
        return false;
    }
  }

  /// Mengambil status selesai tiap jam makan untuk tanggal tertentu dengan validasi ketat
  Future<Map<String, MealDailyStatus>> loadDailyStatus(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _dateKey(date);
      final jsonString = prefs.getString(key);

      Map<String, MealDailyStatus> statusMap = {};

      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        decoded.forEach((k, v) {
          statusMap[k] = MealDailyStatus.fromJson(v as Map<String, dynamic>);
        });

        // VALIDASI STATUS: Buang status selesai yang waktu pencatatannya tidak sah (di luar jam makan)
        bool hasChanges = false;
        for (final entry in statusMap.entries.toList()) {
          final mealId = entry.key;
          final status = entry.value;

          if (status.isCompleted) {
            // Khusus Sarapan: jika jam sudah lewat sarapan dan actualTime adalah 08.00 (bawaan desain), izinkan
            if (mealId == 'breakfast' && status.actualTime == '08.00') {
              continue;
            }
            if (!_isActualTimeValidForMeal(mealId, status.actualTime)) {
              statusMap[mealId] = const MealDailyStatus(isCompleted: false, actualTime: null);
              hasChanges = true;
            }
          }
        }

        if (hasChanges) {
          await saveDailyStatus(date, statusMap);
        }
      } else {
        // Inisialisasi awal default sesuai mockup desain
        statusMap = {
          'breakfast': const MealDailyStatus(isCompleted: true, actualTime: '08.00'),
          'lunch': const MealDailyStatus(isCompleted: false, actualTime: null),
          'dinner': const MealDailyStatus(isCompleted: false, actualTime: null),
        };
        await saveDailyStatus(date, statusMap);
      }

      return statusMap;
    } catch (_) {
      return {
        'breakfast': const MealDailyStatus(isCompleted: true, actualTime: '08.00'),
        'lunch': const MealDailyStatus(isCompleted: false, actualTime: null),
        'dinner': const MealDailyStatus(isCompleted: false, actualTime: null),
      };
    }
  }

  /// Menyimpan status selesai jam makan
  Future<void> saveDailyStatus(
    DateTime date,
    Map<String, MealDailyStatus> statusMap,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dateKey(date);
    final mapToSave = statusMap.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(key, jsonEncode(mapToSave));
  }

  /// Menandai jadwal tertentu telah selesai pada waktu saat ini
  Future<Map<String, MealDailyStatus>> markMealCompleted({
    required DateTime date,
    required String mealId,
    required DateTime completedTime,
  }) async {
    final statusMap = await loadDailyStatus(date);
    final formattedTime =
        '${completedTime.hour.toString().padLeft(2, '0')}.${completedTime.minute.toString().padLeft(2, '0')}';

    statusMap[mealId] = MealDailyStatus(
      isCompleted: true,
      actualTime: formattedTime,
    );

    await saveDailyStatus(date, statusMap);
    stopAlarm();
    return statusMap;
  }

  /// Mengecek apakah waktu sekarang berada dalam rentang jadwal makan
  bool isMealInTimeRange(MealScheduleItem schedule) {
    return schedule.isCurrentTimeInRange(now);
  }

  /// Menentukan jadwal mana yang harus ditampilkan kartu alarm saat ini
  MealScheduleItem determineDisplayedSchedule(
    List<MealScheduleItem> schedules,
    Map<String, MealDailyStatus> dailyStatus,
  ) {
    final current = now;

    // 1. Cek apakah ada jadwal yang saat ini sedang berlangsung
    for (final schedule in schedules) {
      if (schedule.isCurrentTimeInRange(current)) {
        final isDone = dailyStatus[schedule.id]?.isCompleted ?? false;
        // Jika sedang berlangsung dan belum selesai, tampilkan jadwal ini!
        if (!isDone) {
          return schedule;
        }
      }
    }

    // 2. Jika tidak ada yang sedang berlangsung (atau yang berlangsung sudah selesai),
    // tampilkan jadwal berikutnya yang belum lewat hari ini
    for (final schedule in schedules) {
      final isDone = dailyStatus[schedule.id]?.isCompleted ?? false;
      if (schedule.isUpcoming(current) && !isDone) {
        return schedule;
      }
    }

    // 3. Jika semua jadwal hari ini sudah lewat atau selesai, tampilkan Sarapan besok
    return schedules.first;
  }

  /// Memulai bunyi alarm & haptic getaran (berulang setiap 2.5 detik)
  void startAlarm() {
    if (_isAlarmRinging) return;
    _isAlarmRinging = true;

    _playAlertSoundAndHaptic();

    _alarmTimer?.cancel();
    _alarmTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (_isAlarmRinging) {
        _playAlertSoundAndHaptic();
      }
    });
  }

  /// Mematikan alarm dan timer
  void stopAlarm() {
    _isAlarmRinging = false;
    _alarmTimer?.cancel();
    _alarmTimer = null;
  }

  void _playAlertSoundAndHaptic() {
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    } catch (_) {
      // Abaikan jika platform tidak mendukung
    }
  }

  void dispose() {
    stopAlarm();
  }
}

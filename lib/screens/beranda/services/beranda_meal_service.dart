import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_schedule_model.dart';

/// Service lokal pengelola jadwal makan dan status harian untuk Beranda.
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

  /// Daftar jadwal bawaan jika belum ada jadwal yang disetel
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

  /// Format key status per pengguna dan per tanggal lokal (YYYY-MM-DD)
  String dateUserKey(DateTime date, String? uid) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final userPart = uid != null && uid.isNotEmpty ? uid : 'guest';
    return '$keyMealStatusPrefix${userPart}_$year-$month-$day';
  }

  /// Mengambil status selesai tiap jam makan untuk tanggal dan pengguna tertentu.
  /// Status awal selalu KOSONG (tidak ada data hardcode / contoh Figma).
  Future<Map<String, MealDailyStatus>> loadDailyStatus(
    DateTime date, {
    String? uid,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = dateUserKey(date, uid);
      final jsonString = prefs.getString(key);

      Map<String, MealDailyStatus> statusMap = {};

      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        decoded.forEach((k, v) {
          if (v is Map<String, dynamic>) {
            statusMap[k] = MealDailyStatus.fromJson(v);
          }
        });
      }
      return statusMap;
    } catch (_) {
      return {};
    }
  }

  /// Menyimpan status selesai jam makan untuk tanggal dan pengguna tertentu
  Future<void> saveDailyStatus(
    DateTime date,
    Map<String, MealDailyStatus> statusMap, {
    String? uid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = dateUserKey(date, uid);
    final mapToSave = statusMap.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(key, jsonEncode(mapToSave));
  }

  /// Menandai jadwal tertentu telah selesai pada waktu saat ini
  Future<Map<String, MealDailyStatus>> markMealCompleted({
    required DateTime date,
    required String mealId,
    required DateTime completedTime,
    String? uid,
  }) async {
    final statusMap = await loadDailyStatus(date, uid: uid);
    final formattedTime =
        '${completedTime.hour.toString().padLeft(2, '0')}.${completedTime.minute.toString().padLeft(2, '0')}';

    statusMap[mealId] = MealDailyStatus(
      isCompleted: true,
      actualTime: formattedTime,
    );

    await saveDailyStatus(date, statusMap, uid: uid);
    stopAlarm();
    return statusMap;
  }

  /// Mengecek apakah waktu sekarang berada dalam rentang jadwal makan
  bool isMealInTimeRange(MealScheduleItem schedule) {
    return schedule.isCurrentTimeInRange(now);
  }

  /// Menentukan jadwal mana yang harus ditampilkan kartu alarm saat ini.
  /// Aturan:
  /// 1. Tampilkan makan yang sedang aktif (di dalam window dan belum ditandai).
  /// 2. Jika tidak ada yang aktif, tampilkan makan berikutnya hari ini (upcoming dan belum ditandai).
  /// 3. Jika semua sudah lewat atau selesai, kembalikan null (akan menampilkan "Semua jam makan hari ini sudah selesai").
  MealScheduleItem? determineDisplayedSchedule(
    List<MealScheduleItem> schedules,
    Map<String, MealDailyStatus> dailyStatus,
  ) {
    final current = now;

    // 1. Cek apakah ada jadwal yang saat ini sedang aktif (dalam window dan belum ditandai)
    for (final schedule in schedules) {
      final isDone = dailyStatus[schedule.id]?.isCompleted ?? false;
      if (schedule.isCurrentTimeInRange(current) && !isDone) {
        return schedule;
      }
    }

    // 2. Jika tidak ada yang aktif, cari jadwal berikutnya yang belum lewat hari ini
    for (final schedule in schedules) {
      final isDone = dailyStatus[schedule.id]?.isCompleted ?? false;
      if (schedule.isUpcoming(current) && !isDone) {
        return schedule;
      }
    }

    // 3. Jika semua sudah lewat atau selesai hari ini, kembalikan null
    return null;
  }

  /// Menghitung batas waktu berikutnya (awal/akhir window makan terdekat atau tengah malam)
  /// untuk penjadwalan Timer yang efisien tanpa polling per detik.
  DateTime getNextBoundary(DateTime current, List<MealScheduleItem> schedules) {
    final boundaries = <DateTime>[];

    // Tengah malam (00:00:01 hari berikutnya)
    final tomorrow = DateTime(current.year, current.month, current.day + 1, 0, 0, 1);
    boundaries.add(tomorrow);

    for (final s in schedules) {
      final start = DateTime(current.year, current.month, current.day, s.startHour, s.startMinute);
      if (start.isAfter(current)) {
        boundaries.add(start);
      }
      final end = DateTime(current.year, current.month, current.day, s.endHour, s.endMinute);
      if (end.isAfter(current)) {
        boundaries.add(end);
      }
    }

    boundaries.sort();
    return boundaries.first;
  }

  /// Sinkronkan state alarm suara/haptik lokal jika aktif
  void updateAlarmState(MealScheduleItem? activeSchedule, bool isActiveNow) {
    if (isActiveNow && activeSchedule != null) {
      startAlarm();
    } else {
      stopAlarm();
    }
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

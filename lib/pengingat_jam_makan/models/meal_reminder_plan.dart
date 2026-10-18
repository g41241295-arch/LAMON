import '../../screens/beranda/models/meal_schedule_model.dart';

/// Kondisi kesehatan saat mengatur jadwal jam makan
enum MealCondition {
  sehat,
  sakit,
}

/// Rentang waktu untuk jam makan (pilihan tetap)
class MealTimeOption {
  final int startHour;
  final int endHour;
  final String label;

  const MealTimeOption({
    required this.startHour,
    required this.endHour,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'start': startHour,
        'end': endHour,
      };

  factory MealTimeOption.fromJson(Map<String, dynamic> json) {
    final start = json['start'] as int? ?? 6;
    final end = json['end'] as int? ?? 7;
    return MealTimeOption(
      startHour: start,
      endHour: end,
      label: '${start.toString().padLeft(2, '0')}.00 s/d ${end.toString().padLeft(2, '0')}.00',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealTimeOption &&
          runtimeType == other.runtimeType &&
          startHour == other.startHour &&
          endHour == other.endHour;

  @override
  int get hashCode => startHour.hashCode ^ endHour.hashCode;
}

/// Opsi pilihan tetap jam makan sesuai spesifikasi desain
class MealPresetOptions {
  // Sarapan: 06.00-07.00, 07.00-08.00, 08.00-09.00 (default: 06.00-07.00)
  static const List<MealTimeOption> sarapanOptions = [
    MealTimeOption(startHour: 6, endHour: 7, label: '06.00 s/d 07.00'),
    MealTimeOption(startHour: 7, endHour: 8, label: '07.00 s/d 08.00'),
    MealTimeOption(startHour: 8, endHour: 9, label: '08.00 s/d 09.00'),
  ];

  // Makan siang: 12.00-13.00, 13.00-14.00, 14.00-15.00 (default: 12.00-13.00)
  static const List<MealTimeOption> makanSiangOptions = [
    MealTimeOption(startHour: 12, endHour: 13, label: '12.00 s/d 13.00'),
    MealTimeOption(startHour: 13, endHour: 14, label: '13.00 s/d 14.00'),
    MealTimeOption(startHour: 14, endHour: 15, label: '14.00 s/d 15.00'),
  ];

  // Makan malam: 18.00-19.00, 19.00-20.00, 20.00-21.00 (default: 18.00-19.00)
  static const List<MealTimeOption> makanMalamOptions = [
    MealTimeOption(startHour: 18, endHour: 19, label: '18.00 s/d 19.00'),
    MealTimeOption(startHour: 19, endHour: 20, label: '19.00 s/d 20.00'),
    MealTimeOption(startHour: 20, endHour: 21, label: '20.00 s/d 21.00'),
  ];

  // Jam tidur (khusus sakit): 20.00, 21.00, 22.00 (default: 20.00)
  static const List<int> sleepHourOptions = [20, 21, 22];
}

/// Model rencana jadwal pengingat jam makan
class MealReminderPlan {
  final MealCondition condition;
  final DateTime startDate;
  final DateTime endDate;
  final int repeatDays; // 1 - 30 hari (kondisi sehat)
  final bool isRepeatEnabled;
  final MealTimeOption sarapan;
  final MealTimeOption makanSiang;
  final MealTimeOption makanMalam;
  final int sleepHour; // 20, 21, 22 (khusus kondisi sakit)
  final bool enabled;
  final DateTime updatedAt;

  const MealReminderPlan({
    required this.condition,
    required this.startDate,
    required this.endDate,
    this.repeatDays = 1,
    this.isRepeatEnabled = false,
    this.sarapan = const MealTimeOption(startHour: 6, endHour: 7, label: '06.00 s/d 07.00'),
    this.makanSiang = const MealTimeOption(startHour: 12, endHour: 13, label: '12.00 s/d 13.00'),
    this.makanMalam = const MealTimeOption(startHour: 18, endHour: 19, label: '18.00 s/d 19.00'),
    this.sleepHour = 20,
    this.enabled = true,
    required this.updatedAt,
  });

  /// Format tanggal lokal YYYY-MM-DD
  static String formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Cek apakah suatu tanggal berada di dalam rentang aktif jadwal
  bool isDateActive(DateTime date) {
    if (!enabled) return false;
    final target = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    return (target.isAtSameMomentAs(start) || target.isAfter(start)) &&
        (target.isAtSameMomentAs(end) || target.isBefore(end));
  }

  /// Konversi ke daftar MealScheduleItem yang persis dipahami oleh Beranda
  List<MealScheduleItem> toMealScheduleItems() {
    return [
      MealScheduleItem(
        id: 'breakfast',
        title: 'Sarapan',
        displayTitle: 'Jam sarapan',
        startHour: sarapan.startHour,
        startMinute: 0,
        endHour: sarapan.endHour,
        endMinute: 0,
        reminderNote: 'Jangan lupa sarapan sehat !',
      ),
      MealScheduleItem(
        id: 'lunch',
        title: 'Makan siang',
        displayTitle: 'Jam makan siang',
        startHour: makanSiang.startHour,
        startMinute: 0,
        endHour: makanSiang.endHour,
        endMinute: 0,
        reminderNote: 'Jangan lupa makan !',
      ),
      MealScheduleItem(
        id: 'dinner',
        title: 'Makan malam',
        displayTitle: 'Jam makan malam',
        startHour: makanMalam.startHour,
        startMinute: 0,
        endHour: makanMalam.endHour,
        endMinute: 0,
        reminderNote: 'Jangan lupa makan malam tepat waktu !',
      ),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition == MealCondition.sehat ? 'sehat' : 'sakit',
      'startDate': formatDate(startDate),
      'endDate': formatDate(endDate),
      'repeatDays': repeatDays,
      'isRepeatEnabled': isRepeatEnabled,
      'meals': {
        'sarapan': sarapan.toJson(),
        'makan_siang': makanSiang.toJson(),
        'makan_malam': makanMalam.toJson(),
      },
      'sleepTime': '${sleepHour.toString().padLeft(2, '0')}:00',
      'enabled': enabled,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MealReminderPlan.fromJson(Map<String, dynamic> json) {
    final condStr = json['condition'] as String? ?? 'sehat';
    final condition = condStr == 'sakit' ? MealCondition.sakit : MealCondition.sehat;

    DateTime parseDate(String? str, DateTime fallback) {
      if (str == null || str.isEmpty) return fallback;
      try {
        final parts = str.split('-');
        if (parts.length == 3) {
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (_) {}
      return fallback;
    }

    final now = DateTime.now();
    final startDate = parseDate(json['startDate'] as String?, now);
    final endDate = parseDate(json['endDate'] as String?, startDate);
    final repeatDays = json['repeatDays'] as int? ?? 1;
    final isRepeatEnabled = json['isRepeatEnabled'] as bool? ?? false;

    final meals = json['meals'] as Map<String, dynamic>? ?? {};
    final sarapan = meals['sarapan'] != null
        ? MealTimeOption.fromJson(meals['sarapan'] as Map<String, dynamic>)
        : const MealTimeOption(startHour: 6, endHour: 7, label: '06.00 s/d 07.00');
    final makanSiang = meals['makan_siang'] != null
        ? MealTimeOption.fromJson(meals['makan_siang'] as Map<String, dynamic>)
        : const MealTimeOption(startHour: 12, endHour: 13, label: '12.00 s/d 13.00');
    final makanMalam = meals['makan_malam'] != null
        ? MealTimeOption.fromJson(meals['makan_malam'] as Map<String, dynamic>)
        : const MealTimeOption(startHour: 18, endHour: 19, label: '18.00 s/d 19.00');

    final sleepStr = json['sleepTime'] as String? ?? '20:00';
    int sleepHour = 20;
    try {
      final hourPart = sleepStr.split(':')[0];
      sleepHour = int.tryParse(hourPart) ?? 20;
    } catch (_) {}

    DateTime updated;
    try {
      updated = DateTime.parse(json['updatedAt'] as String);
    } catch (_) {
      updated = DateTime.now();
    }

    return MealReminderPlan(
      condition: condition,
      startDate: startDate,
      endDate: endDate,
      repeatDays: repeatDays,
      isRepeatEnabled: isRepeatEnabled,
      sarapan: sarapan,
      makanSiang: makanSiang,
      makanMalam: makanMalam,
      sleepHour: sleepHour,
      enabled: json['enabled'] as bool? ?? true,
      updatedAt: updated,
    );
  }
}

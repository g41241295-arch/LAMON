/// Model representasi jadwal jam makan dan status selesai harian
class MealScheduleItem {
  final String id;
  final String title;
  final String displayTitle;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final String reminderNote;

  const MealScheduleItem({
    required this.id,
    required this.title,
    required this.displayTitle,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.reminderNote = 'Jangan lupa makan !',
  });

  /// Mengembalikan format string rentang jam seperti "12.00 – 13.00 WIB"
  String get timeRangeString {
    final startH = startHour.toString().padLeft(2, '0');
    final startM = startMinute.toString().padLeft(2, '0');
    final endH = endHour.toString().padLeft(2, '0');
    final endM = endMinute.toString().padLeft(2, '0');
    return '$startH.$startM – $endH.$endM WIB';
  }

  /// Mengecek apakah waktu sekarang berada dalam rentang jadwal makan
  bool isCurrentTimeInRange(DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  /// Mengecek apakah waktu sekarang sudah lewat dari jadwal ini
  bool isPast(DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;
    final endMinutes = endHour * 60 + endMinute;
    return currentMinutes >= endMinutes;
  }

  /// Mengecek apakah waktu sekarang sebelum jadwal ini
  bool isUpcoming(DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60 + startMinute;
    return currentMinutes < startMinutes;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'displayTitle': displayTitle,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'reminderNote': reminderNote,
    };
  }

  factory MealScheduleItem.fromJson(Map<String, dynamic> json) {
    return MealScheduleItem(
      id: json['id'] as String? ?? 'meal',
      title: json['title'] as String? ?? 'Jam Makan',
      displayTitle: json['displayTitle'] as String? ?? 'Jam makan',
      startHour: json['startHour'] as int? ?? 12,
      startMinute: json['startMinute'] as int? ?? 0,
      endHour: json['endHour'] as int? ?? 13,
      endMinute: json['endMinute'] as int? ?? 0,
      reminderNote: json['reminderNote'] as String? ?? 'Jangan lupa makan !',
    );
  }

  MealScheduleItem copyWith({
    String? id,
    String? title,
    String? displayTitle,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    String? reminderNote,
  }) {
    return MealScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      displayTitle: displayTitle ?? this.displayTitle,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      reminderNote: reminderNote ?? this.reminderNote,
    );
  }
}

/// Status jam makan harian
class MealDailyStatus {
  final bool isCompleted;
  final String? actualTime;

  const MealDailyStatus({
    this.isCompleted = false,
    this.actualTime,
  });

  Map<String, dynamic> toJson() => {
        'isCompleted': isCompleted,
        'actualTime': actualTime,
      };

  factory MealDailyStatus.fromJson(Map<String, dynamic> json) =>
      MealDailyStatus(
        isCompleted: json['isCompleted'] as bool? ?? false,
        actualTime: json['actualTime'] as String?,
      );
}

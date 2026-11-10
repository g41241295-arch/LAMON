/// Helper pemformatan tanggal dan waktu standar Indonesia tanpa dependensi eksternal
class AppDateFormatter {
  static const List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _shortDays = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  static const List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _fullMonths = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Format: "15 Sep 2026 • 20:10"
  static String formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString();
    final month = _shortMonths[local.month - 1];
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day $month $year • $hour:$minute';
  }

  /// Format: "15 September 2026, 20:10 WIB"
  static String formatFullDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString();
    final month = _fullMonths[local.month - 1];
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute WIB';
  }

  /// Format: "15 Sep 2026"
  static String formatDateOnly(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString();
    final month = _shortMonths[local.month - 1];
    final year = local.year.toString();

    return '$day $month $year';
  }

  /// Format: "Kamis, 1 Januari 2026"
  static String formatLongDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final dayName = _days[local.weekday - 1];
    final day = local.day.toString();
    final month = _fullMonths[local.month - 1];
    final year = local.year.toString();

    return '$dayName, $day $month $year';
  }

  /// Format: "September 2026"
  static String formatMonthYear(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = _fullMonths[local.month - 1];
    final year = local.year.toString();

    return '$month $year';
  }

  /// Format key tanggal: "2026-09-28"
  static String formatDateKey(DateTime dateTime) {
    final local = dateTime.toLocal();
    final year = local.year.toString();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  /// Format: "25 Sep 2026 - 19.05 WIB"
  static String formatPaymentDeadline(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString();
    final month = _shortMonths[local.month - 1];
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day $month $year - $hour.$minute WIB';
  }

  /// Format jam ringkas: "12.30"
  static String formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }

  /// Format jadwal konsultasi (C.2): "Sel, 3 Nov 2026 • 07.00 - 11.00"
  static String formatScheduledDateTime(DateTime? dateTime, [String? timeRange]) {
    if (dateTime == null) {
      return timeRange ?? '';
    }
    final local = dateTime.toLocal();
    final dayName = _shortDays[local.weekday - 1];
    final day = local.day.toString();
    final month = _shortMonths[local.month - 1];
    final year = local.year.toString();
    final datePart = '$dayName, $day $month $year';
    if (timeRange != null && timeRange.trim().isNotEmpty) {
      return '$datePart • ${timeRange.trim()}';
    }
    return datePart;
  }

  /// Format timestamp di sisi kanan baris daftar Pesan (C.3):
  /// - Hari ini -> jam ("14.48")
  /// - Kemarin -> "Kemarin"
  /// - Lebih lama (tahun sama) -> "3 Nov"
  /// - Beda tahun -> "3 Nov 2025"
  static String formatConversationListTimestamp(DateTime dateTime, [DateTime? nowTime]) {
    final local = dateTime.toLocal();
    final now = (nowTime ?? DateTime.now()).toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(messageDay).inDays;

    if (diffDays == 0) {
      return formatTime(local);
    } else if (diffDays == 1) {
      return 'Kemarin';
    } else if (local.year == now.year) {
      final day = local.day.toString();
      final month = _shortMonths[local.month - 1];
      return '$day $month';
    } else {
      final day = local.day.toString();
      final month = _shortMonths[local.month - 1];
      final year = local.year.toString();
      return '$day $month $year';
    }
  }

  /// Pemisah tanggal antar kelompok pesan di layar chat (C.4):
  /// - Hari ini -> "Hari ini"
  /// - Kemarin -> "Kemarin"
  /// - Tanggal lain -> "3 November 2026"
  static String formatChatDateSeparator(DateTime dateTime, [DateTime? nowTime]) {
    final local = dateTime.toLocal();
    final now = (nowTime ?? DateTime.now()).toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(targetDay).inDays;

    if (diffDays == 0) {
      return 'Hari ini';
    } else if (diffDays == 1) {
      return 'Kemarin';
    } else {
      final day = local.day.toString();
      final month = _fullMonths[local.month - 1];
      final year = local.year.toString();
      return '$day $month $year';
    }
  }

  /// Sapaan dokter sesuai jam perangkat:
  /// Pagi: 04.00 - 10.59
  /// Siang: 11.00 - 14.59
  /// Sore: 15.00 - 17.59
  /// Malam: 18.00 - 03.59
  static String getGreetingWord(DateTime now) {
    final hour = now.hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat pagi,';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat siang,';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat sore,';
    } else {
      return 'Selamat malam,';
    }
  }
}

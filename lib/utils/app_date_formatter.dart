/// Helper pemformatan tanggal dan waktu standar Indonesia tanpa dependensi eksternal
class AppDateFormatter {
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
}

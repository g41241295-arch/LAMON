import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/activity_log_model.dart';

/// Konstanta dimensi item aktivitas (sesuai Figma 390dp frame).
class ActivityItemDims {
  static const double dotSize = 8;
  static const double mainFontSize = 14;
  static const double timeFontSize = 10;
}

/// Satu baris item aktivitas.
///
/// [log] – model dari Firestore.
class ActivityItem extends StatelessWidget {
  final ActivityLogModel log;

  const ActivityItem({super.key, required this.log});

  /// Format waktu relatif: "hari ini, 10:35" / "kemarin, 16:05" / "3 hari lalu"
  static String _formatRelative(DateTime? dt) {
    if (dt == null) return '...';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(logDay).inDays;

    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    if (diff == 0) return 'hari ini, $hh:$mm';
    if (diff == 1) return 'kemarin, $hh:$mm';
    return '$diff hari lalu';
  }

  /// Warna titik berdasarkan aksi.
  static Color _dotColor(String aksi) {
    switch (aksi.toLowerCase()) {
      case 'tambah':
        return AppColors.activityDotAdd;
      case 'ubah':
        return AppColors.activityDotEdit;
      case 'hapus':
        return AppColors.activityDotDelete;
      default:
        return AppColors.neutralGray;
    }
  }

  /// Teks deskripsi: "Menambahkan entri ensiklopedia "GERD""
  static String _buildDescription(ActivityLogModel log) {
    final aksiMap = {
      'tambah': 'Menambahkan',
      'ubah': 'Mengubah',
      'hapus': 'Menghapus',
    };
    final modulMap = {
      'ensiklopedia': 'entri ensiklopedia',
    };
    final aksiText = aksiMap[log.aksi.toLowerCase()] ?? log.aksi;
    final modulText = modulMap[log.modul.toLowerCase()] ?? log.modul;
    return '$aksiText $modulText \u201c${log.judul}\u201d';
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _dotColor(log.aksi);
    final timeText = _formatRelative(log.createdAt);
    final desc = _buildDescription(log);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titik warna
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: ActivityItemDims.dotSize,
            height: ActivityItemDims.dotSize,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                desc,
                style: GoogleFonts.poppins(
                  fontSize: ActivityItemDims.mainFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.adminBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeText,
                style: GoogleFonts.poppins(
                  fontSize: ActivityItemDims.timeFontSize,
                  color: AppColors.neutralGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

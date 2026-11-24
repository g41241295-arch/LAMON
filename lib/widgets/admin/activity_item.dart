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
  final bool showIconCircle;

  const ActivityItem({
    super.key,
    required this.log,
    this.showIconCircle = false,
  });

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

  /// Teks deskripsi: "Menambahkan data gastropedia “GERD”"
  static String _buildDescription(ActivityLogModel log) {
    final aksiMap = {
      'tambah': 'Menambahkan',
      'ubah': 'Mengubah',
      'hapus': 'Menghapus',
    };
    final modulMap = {
      'ensiklopedia': 'data gastropedia',
    };
    final aksiText = aksiMap[log.aksi.toLowerCase()] ?? log.aksi;
    final modulText = modulMap[log.modul.toLowerCase()] ?? log.modul;
    String text = '$aksiText $modulText \u201c${log.judul}\u201d';
    text = text.replaceAll('entri ensiklopedia', 'data gastropedia');
    text = text.replaceAll('Entri ensiklopedia', 'Data gastropedia');
    return text;
  }

  /// Menentukan ikon dan warna latar lingkaran berdasarkan jenis aktivitas (aksi).
  static ({IconData icon, Color bgColor, Color borderColor}) _resolveActionVisual(
    String rawAksi,
  ) {
    final aksi = rawAksi.trim().toLowerCase();
    if (aksi == 'tambah' || aksi.startsWith('tambah') || aksi.startsWith('menambah')) {
      return (
        icon: Icons.add_rounded,
        bgColor: AppColors.softBlue,
        borderColor: AppColors.softBlue,
      );
    }
    if (aksi == 'ubah' ||
        aksi.startsWith('ubah') ||
        aksi.startsWith('edit') ||
        aksi.startsWith('mengubah')) {
      return (
        icon: Icons.edit_outlined,
        bgColor: AppColors.softBlue,
        borderColor: AppColors.softBlue,
      );
    }
    if (aksi == 'hapus' || aksi.startsWith('hapus') || aksi.startsWith('menghapus')) {
      return (
        icon: Icons.delete_outline_rounded,
        bgColor: AppColors.bgAccent,
        borderColor: AppColors.accentGold,
      );
    }
    return (
      icon: Icons.history_rounded,
      bgColor: AppColors.softBlue,
      borderColor: AppColors.softBlue,
    );
  }

  /// Membangun RichText dengan menebalkan nama konten di dalam tanda kutip.
  Widget _buildFormattedDescription(String desc) {
    final baseStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.4,
    );
    final quotedStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.4,
    );

    final startIdx = desc.indexOf('\u201c');
    final endIdx = desc.lastIndexOf('\u201d');
    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      final before = desc.substring(0, startIdx);
      final quoted = desc.substring(startIdx, endIdx + 1);
      final after = desc.substring(endIdx + 1);
      return RichText(
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: baseStyle,
          children: [
            if (before.isNotEmpty) TextSpan(text: before),
            TextSpan(text: quoted, style: quotedStyle),
            if (after.isNotEmpty) TextSpan(text: after),
          ],
        ),
      );
    }

    return Text(
      desc,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: baseStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _formatRelative(log.createdAt);
    final desc = _buildDescription(log);

    if (showIconCircle) {
      final visual = _resolveActionVisual(log.aksi);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: visual.bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: visual.borderColor,
                width: 1.0,
              ),
            ),
            child: Center(
              child: Icon(
                visual.icon,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFormattedDescription(desc),
                const SizedBox(height: 4),
                Text(
                  timeText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final dotColor = _dotColor(log.aksi);

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

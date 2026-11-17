import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/notification_service.dart';

/// Helper log diagnostik jadwal jam makan khusus kDebugMode.
void logAlarmDebug(String message) {
  if (kDebugMode) {
    debugPrint('[AlarmDebug] $message');
  }
}

/// Tombol diagnostik kDebugMode untuk melihat daftar alarm terjadwal dari OS.
class AlarmDebugButton extends StatelessWidget {
  const AlarmDebugButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF1E3A8A),
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF93C5FD).withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      icon: const Icon(Icons.alarm, size: 16, color: Color(0xFF276F8F)),
      label: Text(
        'Alarm terjadwal',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () => showScheduledAlarmsDialog(context),
    );
  }
}

/// Menampilkan dialog berisi daftar alarm terjadwal dari sistem.
Future<void> showScheduledAlarmsDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _ScheduledAlarmsDialog(),
  );
}

class _ScheduledAlarmsDialog extends StatefulWidget {
  const _ScheduledAlarmsDialog();

  @override
  State<_ScheduledAlarmsDialog> createState() => _ScheduledAlarmsDialogState();
}

class _ScheduledAlarmsDialogState extends State<_ScheduledAlarmsDialog> {
  bool _loading = true;
  List<_AlarmItemInfo> _alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    setState(() => _loading = true);
    final pending =
        await NotificationService.instance.getPendingNotifications();

    final items = pending.map((p) {
      tz.TZDateTime? parsedTime;
      if (p.payload != null && p.payload!.isNotEmpty) {
        String timeStr = p.payload!;
        // Ekstrak waktu jika payload bertipe khusus (mis. type=plan_expired;time=...)
        if (timeStr.contains(';')) {
          final parts = timeStr.split(';');
          for (final part in parts) {
            if (part.startsWith('time=')) {
              timeStr = part.substring(5);
              break;
            }
          }
        }
        try {
          final dt = DateTime.tryParse(timeStr);
          if (dt != null) {
            // Konversi ke zona waktu lokal tz.local agar jam tidak bergeser ke UTC
            parsedTime = tz.TZDateTime.from(dt, tz.local);
          }
        } catch (_) {}
      }

      return _AlarmItemInfo(
        id: p.id,
        title: p.title ?? '(Tanpa judul)',
        body: p.body ?? '',
        payload: p.payload ?? '',
        scheduledTime: parsedTime,
      );
    }).toList();

    // Terurut menurut waktu jadwal
    items.sort((a, b) {
      if (a.scheduledTime == null && b.scheduledTime == null) {
        return a.id.compareTo(b.id);
      }
      if (a.scheduledTime == null) return 1;
      if (b.scheduledTime == null) return -1;
      return a.scheduledTime!.compareTo(b.scheduledTime!);
    });

    if (mounted) {
      setState(() {
        _alarms = items;
        _loading = false;
      });
    }
  }

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  _AlarmStyle _getAlarmStyle(String title, bool isExpired) {
    if (isExpired || title.toLowerCase().contains('habis')) {
      return const _AlarmStyle(
        icon: Icons.event_available_rounded,
        iconColor: Color(0xFFD97706),
        iconBg: Color(0xFFFEF3C7),
      );
    }
    final lower = title.toLowerCase();
    if (lower.contains('sarapan')) {
      return const _AlarmStyle(
        icon: Icons.wb_sunny_rounded,
        iconColor: Color(0xFFEA580C),
        iconBg: Color(0xFFFFF7ED),
      );
    } else if (lower.contains('siang')) {
      return const _AlarmStyle(
        icon: Icons.restaurant_rounded,
        iconColor: Color(0xFF059669),
        iconBg: Color(0xFFECFDF5),
      );
    } else if (lower.contains('malam')) {
      return const _AlarmStyle(
        icon: Icons.nights_stay_rounded,
        iconColor: Color(0xFF2563EB),
        iconBg: Color(0xFFEFF6FF),
      );
    } else if (lower.contains('tidur')) {
      return const _AlarmStyle(
        icon: Icons.bedtime_rounded,
        iconColor: Color(0xFF7C3AED),
        iconBg: Color(0xFFF5F3FF),
      );
    }
    return const _AlarmStyle(
      icon: Icons.alarm_rounded,
      iconColor: Color(0xFF276F8F),
      iconBg: Color(0xFFE8F1F5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFCFBF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: Color(0xFFEBE3D0),
          width: 1.2,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Bar ───────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF276F8F).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF276F8F).withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.alarm_on_rounded,
                      color: Color(0xFF276F8F),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Alarm Terjadwal',
                              style: GoogleFonts.poppins(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1C4E68),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7D6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE8D7A5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${_alarms.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1C4E68),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.public_rounded,
                            size: 12,
                            color: Color(0xFF7C8E97),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Zona Waktu: ${tz.local.name}',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF7C8E97),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Muat ulang',
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  color: const Color(0xFF276F8F),
                  onPressed: _loading ? null : _loadAlarms,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Daftar Alarm Terjadwal ───────────────────────────────────
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: CircularProgressIndicator(color: Color(0xFF276F8F)),
                      ),
                    )
                  : _alarms.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 40,
                                  color: const Color(0xFF7C8E97).withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada alarm terjadwal di sistem.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF7C8E97),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _alarms.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _alarms[index];
                            final isExpiredNotif =
                                item.payload.contains('type=plan_expired');
                            final style = _getAlarmStyle(item.title, isExpiredNotif);

                            final timeStr = item.scheduledTime != null
                                ? '${item.scheduledTime!.hour.toString().padLeft(2, '0')}.${item.scheduledTime!.minute.toString().padLeft(2, '0')} WIB'
                                : '--.-- WIB';

                            final dateStr = item.scheduledTime != null
                                ? '${item.scheduledTime!.day} ${_monthNames[item.scheduledTime!.month - 1]} ${item.scheduledTime!.year}'
                                : (item.payload.isNotEmpty ? item.payload : 'Terjadwal');

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEBE3D0),
                                  width: 1.1,
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
                                children: [
                                  // Ikon Kategori
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: style.iconBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: style.iconColor
                                            .withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        style.icon,
                                        size: 19,
                                        color: style.iconColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Judul Waktu Makan & Tanggal (Narasi lama dihapus & digantikan tanggal)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.title,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1C4E68),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_rounded,
                                              size: 11,
                                              color: Color(0xFF7C8E97),
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                dateStr,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF7C8E97),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Bagian Jam di Sisi Kanan (Kotak Bening / Tanpa Warna dengan Border Halus)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF276F8F)
                                            .withValues(alpha: 0.28),
                                        width: 1.1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          size: 13,
                                          color: Color(0xFF276F8F),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          timeStr,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1C4E68),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            const SizedBox(height: 20),

            // ── Tombol Tutup Modern ──────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF276F8F),
                      Color(0xFF1C4E68),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF276F8F).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmStyle {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _AlarmStyle({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class _AlarmItemInfo {
  final int id;
  final String title;
  final String body;
  final String payload;
  final tz.TZDateTime? scheduledTime;

  const _AlarmItemInfo({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    required this.scheduledTime,
  });
}

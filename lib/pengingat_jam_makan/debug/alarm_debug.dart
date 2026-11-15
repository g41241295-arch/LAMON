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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFEFDF8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm_on, color: Color(0xFF276F8F), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alarm Terjadwal (${_alarms.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                color: const Color(0xFF276F8F),
                onPressed: _loading ? null : _loadAlarms,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.public, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                'Zona Waktu: ${tz.local.name}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 380,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF276F8F)),
              )
            : _alarms.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada alarm terjadwal di sistem.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: _alarms.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final item = _alarms[index];
                      final timeStr = item.scheduledTime != null
                          ? '${item.scheduledTime!.year}-${item.scheduledTime!.month.toString().padLeft(2, '0')}-${item.scheduledTime!.day.toString().padLeft(2, '0')} ${item.scheduledTime!.hour.toString().padLeft(2, '0')}:${item.scheduledTime!.minute.toString().padLeft(2, '0')}'
                          : item.payload;

                      final isExpiredNotif =
                          item.payload.contains('type=plan_expired');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isExpiredNotif
                                        ? const Color(0xFFC05621)
                                        : const Color(0xFF1E3A8A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isExpiredNotif
                                      ? const Color(0xFFFEEBC8)
                                      : const Color(0xFFDCEBF5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ID: ${item.id}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isExpiredNotif
                                        ? const Color(0xFFC05621)
                                        : const Color(0xFF276F8F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 13,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeStr.isNotEmpty
                                    ? timeStr
                                    : '(tanpa payload waktu)',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Tutup',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF276F8F),
            ),
          ),
        ),
      ],
    );
  }
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

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../services/notification_service.dart';
import '../screens/pilih_kondisi_screen.dart';
import 'meal_reminder_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PENGATURAN SUARA ALARM
/// ─────────────────────────────────────────────────────────────────────────────
/// Mode 1 (default): URI sistem → nada alarm bawaan HP (volume alarm).
///   sound: UriAndroidNotificationSound('content://settings/system/alarm_alert')
///
/// Mode 2 (cadangan): nada bundled dari res/raw/alarm_lamon.mp3 milik app.
///   Aktifkan dengan set [_kUseBundledAlarmSound] = true.
///   Letakkan file audio di android/app/src/main/res/raw/alarm_lamon.mp3.
///   File mp3 HARUS disediakan manual — tidak di-generate otomatis.
/// ─────────────────────────────────────────────────────────────────────────────

/// Ganti ke `true` untuk pakai nada bundled (res/raw/alarm_lamon.mp3).
/// Biarkan `false` untuk pakai nada alarm sistem (default).
const bool _kUseBundledAlarmSound = false;

/// Nama file audio bundled (tanpa ekstensi). Harus ada di res/raw/.
const String _kBundledAlarmSoundName = 'alarm_lamon';

/// URI nada alarm default sistem Android.
const String _kSystemAlarmUri = 'content://settings/system/alarm_alert';

/// ─────────────────────────────────────────────────────────────────────────────
/// CHANNEL IDs (semua yang pernah dibuat — untuk dihapus saat init)
/// ─────────────────────────────────────────────────────────────────────────────
const List<String> _kOldChannelIds = [
  'lamon_meal_alarm_channel', // v1
  'lamon_meal_alarm_v2',      // v2
  'lamon_meal_alarm_v3',      // v3 (cadangan, belum tentu pernah dibuat)
];

/// Channel aktif saat ini.
const String _kChannelId = 'lamon_meal_alarm_v4';
const String _kChannelName = 'Alarm Jam Makan LAMON';
const String _kChannelDesc =
    'Alarm pengingat jam makan – berbunyi dengan nada alarm, '
    'bergetar, dan tampil di layar kunci';

/// ─────────────────────────────────────────────────────────────────────────────
/// POLA GETAR
/// ─────────────────────────────────────────────────────────────────────────────
// diam 0ms, getar 800ms, jeda 400ms, getar 800ms, jeda 400ms, getar 800ms
final Int64List _kVibrationPattern =
    Int64List.fromList([0, 800, 400, 800, 400, 800]);

/// ─────────────────────────────────────────────────────────────────────────────
/// FLAG INSISTENT (Notification.FLAG_INSISTENT = 4)
/// Bunyi berulang terus sampai notifikasi digeser/dibatalkan.
/// ─────────────────────────────────────────────────────────────────────────────
final Int32List _kInsistentFlag = Int32List.fromList([4]);

/// Timeout alarm otomatis: 5 menit (ms).
const int _kTimeoutAfterMs = 5 * 60 * 1000;

// ─────────────────────────────────────────────────────────────────────────────

/// Layanan lokal penanganan alarm dan notifikasi terjadwal.
///
/// Ketuk notifikasi → buka aplikasi via alur normal (splash/login/biometrik).
/// Tidak ada navigasi langsung; tidak ada navigatorKey.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ── Akses publik ke konstanta channel ────────────────────────────────────
  static String get channelId => _kChannelId;
  static String get channelName => _kChannelName;
  static String get channelDescription => _kChannelDesc;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ── Buat sound object dari konfigurasi ───────────────────────────────────

  AndroidNotificationSound _buildAlarmSound() {
    if (_kUseBundledAlarmSound) {
      if (kDebugMode) {
        debugPrint(
            '[NotifService] Sound mode: BUNDLED (res/raw/$_kBundledAlarmSoundName.mp3)');
      }
      return const RawResourceAndroidNotificationSound(_kBundledAlarmSoundName);
    } else {
      if (kDebugMode) {
        debugPrint(
            '[NotifService] Sound mode: SYSTEM ALARM URI → $_kSystemAlarmUri');
      }
      return const UriAndroidNotificationSound(_kSystemAlarmUri);
    }
  }

  // ── Inisialisasi ──────────────────────────────────────────────────────────

  /// Inisialisasi plugin notifikasi, timezone perangkat, dan MealReminderService.
  /// Aman dari exception (tidak melempar error ke main).
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Inisialisasi database timezone & lokasi lokal perangkat
      tz.initializeTimeZones();
      await updateLocalTimeZone();

      // 2. Inisialisasi flutter_local_notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Buka LAMON',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        // Ketuk notifikasi → sistem membuka app; alur normal splash/login/biometrik.
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: _onBgNotificationTapped,
      );

      // 3. Konfigurasi channel & izin khusus Android
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImpl != null) {
          // ── Hapus channel-channel lama ────────────────────────────────────
          // Channel Android tidak bisa diupdate setelah dibuat; harus hapus & buat ulang.
          for (final oldId in _kOldChannelIds) {
            try {
              await androidImpl.deleteNotificationChannel(channelId: oldId);
              if (kDebugMode) {
                debugPrint('[NotifService] Channel lama dihapus: $oldId');
              }
            } catch (_) {
              // Channel mungkin tidak ada — abaikan
            }
          }

          // ── Buat channel v4 dengan nada alarm ────────────────────────────
          final alarmSound = _buildAlarmSound();

          if (kDebugMode) {
            debugPrint(
                '[NotifService] Membuat channel: id=$_kChannelId, '
                'sound=${alarmSound.sound}, '
                'audioAttrib=alarm, importance=max');
          }

          final androidChannel = AndroidNotificationChannel(
            _kChannelId,
            _kChannelName,
            description: _kChannelDesc,
            importance: Importance.max,
            playSound: true,
            sound: alarmSound,
            enableVibration: true,
            vibrationPattern: _kVibrationPattern,
            showBadge: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          );
          await androidImpl.createNotificationChannel(androidChannel);

          if (kDebugMode) {
            debugPrint(
                '[NotifService] Channel $_kChannelId berhasil dibuat. '
                'URI sound: ${alarmSound.sound}');
          }

          // ── Izin notifikasi runtime (Android 13+) ─────────────────────────
          try {
            final granted =
                await androidImpl.requestNotificationsPermission();
            if (kDebugMode) {
              debugPrint(
                  '[NotifService] POST_NOTIFICATIONS granted=$granted');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '[NotifService] Izin POST_NOTIFICATIONS dilewati: $e');
            }
          }

          // ── Izin exact alarm (Android 12+) ───────────────────────────────
          await _checkAndRequestExactAlarmPermission(androidImpl);
        }
      }

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint(
            '[NotifService] initialize() selesai. '
            'tz.local=${tz.local.name}, '
            'channelId=$_kChannelId, '
            'soundMode=${_kUseBundledAlarmSound ? "BUNDLED" : "SYSTEM_URI"}');
      }

      // 4. Inisialisasi MealReminderService (sinkronisasi jadwal & auth listener)
      await MealReminderService.instance.initialize();
    } catch (e) {
      debugPrint('[NotifService] initialize() mengalami kendala: $e');
    }
  }

  // ── Penanganan klik notifikasi ────────────────────────────────────────────

  void _onNotificationTapped(NotificationResponse details) {
    if (kDebugMode) {
      debugPrint(
          '[NotifService] Notifikasi diklik: id=${details.id}, '
          'action="${details.actionId}", payload=${details.payload}');
    }
    // Jika notifikasi adalah pengingat jadwal habis -> buka layar Pilih Kondisi
    if (details.payload != null &&
        details.payload!.contains('type=plan_expired')) {
      _navigateToPilihKondisi();
    }
  }

  void _navigateToPilihKondisi() {
    void doPush() {
      final nav = ChatInAppNotificationService.navigatorKey.currentState;
      if (nav != null) {
        nav.push(
          MaterialPageRoute(builder: (_) => const PilihKondisiScreen()),
        );
      }
    }

    if (ChatInAppNotificationService.navigatorKey.currentState != null) {
      doPush();
    } else {
      Future.delayed(const Duration(milliseconds: 800), doPush);
    }
  }

  // ── Izin exact alarm ──────────────────────────────────────────────────────

  Future<void> _checkAndRequestExactAlarmPermission(
      AndroidFlutterLocalNotificationsPlugin androidImpl) async {
    try {
      final canExact = await androidImpl.canScheduleExactNotifications();
      if (kDebugMode) {
        debugPrint('[NotifService] canScheduleExactAlarms = $canExact');
      }
      if (canExact == false) {
        await androidImpl.requestExactAlarmsPermission();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotifService] Pengecekan exact alarm dilewati: $e');
      }
    }
  }

  /// Cek apakah izin exact alarm tersedia. Tampilkan dialog jika belum.
  Future<bool> ensureExactAlarmPermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return true;
    try {
      final canExact = await androidImpl.canScheduleExactNotifications();
      if (canExact == false && context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Izin Alarm Diperlukan'),
            content: const Text(
              'Untuk mengirim alarm pengingat jam makan tepat waktu, '
              'LAMON membutuhkan izin "Alarm & Reminder".\n\n'
              'Ketuk "Buka Pengaturan" lalu aktifkan izin tersebut.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Nanti'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await androidImpl.requestExactAlarmsPermission();
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );
        final canNow = await androidImpl.canScheduleExactNotifications();
        return canNow == true;
      }
      return canExact != false;
    } catch (_) {
      return true;
    }
  }

  // ── Timezone ──────────────────────────────────────────────────────────────

  Future<void> updateLocalTimeZone() async {
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final identifier = tzInfo.identifier;
      try {
        tz.setLocalLocation(tz.getLocation(identifier));
        if (kDebugMode) {
          debugPrint('[NotifService] Timezone terpasang: $identifier');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '[NotifService] Identifier "$identifier" tidak ada di tzdb: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotifService] Gagal baca local timezone perangkat: $e');
      }
    }

    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      if (kDebugMode) {
        debugPrint('[NotifService] Fallback timezone: Asia/Jakarta');
      }
    } catch (_) {}
  }

  // ── ID Notifikasi ─────────────────────────────────────────────────────────

  int generateNotificationId({
    required DateTime date,
    required int slotIndex, // 1: sarapan, 2: siang, 3: malam, 4: tidur
  }) {
    final dateCode = date.year * 10000 + date.month * 100 + date.day;
    return (dateCode % 214748360) * 10 + slotIndex;
  }

  // ── Buat AndroidNotificationDetails untuk alarm ───────────────────────────

  AndroidNotificationDetails _buildAlarmDetails({
    required String title,
  }) {
    final alarmSound = _buildAlarmSound();

    if (kDebugMode) {
      debugPrint(
          '[NotifService] AndroidNotificationDetails: '
          'channelId=$_kChannelId, sound=${alarmSound.sound}, '
          'audioAttrib=alarm, importance=max, priority=max, '
          'ongoing=true, autoCancel=false, insistent=FLAG(4), '
          'vibration=${_kVibrationPattern.toList()}, '
          'timeoutAfter=${_kTimeoutAfterMs}ms');
    }

    return AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      // ── Suara alarm ──────────────────────────────────────────────────────
      playSound: true,
      sound: alarmSound,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      // ── Getaran ──────────────────────────────────────────────────────────
      enableVibration: true,
      vibrationPattern: _kVibrationPattern,
      // ── Kategori & visibilitas ────────────────────────────────────────────
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      // ── Perilaku: bunyi berulang sampai digeser/dimatikan ────────────────
      ongoing: true,
      autoCancel: false,
      // FLAG_INSISTENT (4): bunyi berulang terus sampai notifikasi dibatalkan
      additionalFlags: _kInsistentFlag,
      // Otomatis berhenti setelah 5 menit (failsafe)
      timeoutAfter: _kTimeoutAfterMs,
      // ── Tombol aksi "Matikan" ─────────────────────────────────────────────
      actions: const [
        AndroidNotificationAction(
          'dismiss_alarm',
          'Matikan',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
      // ── Tampilan ─────────────────────────────────────────────────────────
      channelShowBadge: true,
      // fullScreenIntent: hanya aktifkan jika izin USE_FULL_SCREEN_INTENT tersedia.
      // Dinonaktifkan karena Android 14+ membatasi izin ini dan bisa menyebabkan
      // SecurityException. Notifikasi tetap muncul sebagai heads-up.
      fullScreenIntent: false,
    );
  }

  // ── Penjadwalan ───────────────────────────────────────────────────────────

  /// Menjadwalkan alarm tepat waktu.
  ///
  /// Menggunakan [AndroidScheduleMode.alarmClock] (prioritas tertinggi, kebal Doze & Samsung Device Care),
  /// dengan cadangan [AndroidScheduleMode.exactAllowWhileIdle] lalu [AndroidScheduleMode.inexactAllowWhileIdle].
  ///
  /// Menerima [scheduledDateTime] bertipe [tz.TZDateTime] yang dibangun langsung
  /// dengan `tz.TZDateTime(tz.local, tahun, bulan, tanggal, jam, menit)`.
  Future<void> scheduleMealReminder({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDateTime,
    String? uid,
    String? payload,
  }) async {
    try {
      final nowTz = tz.TZDateTime.now(tz.local);
      if (scheduledDateTime.isBefore(nowTz)) {
        if (kDebugMode) {
          debugPrint(
              '[NotifService] Skip ID $id: waktu $scheduledDateTime sudah lewat');
        }
        return;
      }

      final androidDetails = _buildAlarmDetails(title: title);

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // Cek izin exact alarm; prioritaskan alarmClock
      AndroidScheduleMode scheduleMode = AndroidScheduleMode.alarmClock;

      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          try {
            final canExact =
                await androidImpl.canScheduleExactNotifications();
            if (canExact == false) {
              scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
              if (kDebugMode) {
                debugPrint(
                    '[NotifService] ⚠️ Izin exact alarm belum ada → inexact mode');
              }
            }
          } catch (_) {
            scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          }
        }
      }

      final isoPayload = payload ?? scheduledDateTime.toIso8601String();

      // Coba jadwalkan dengan mode utama (alarmClock)
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDateTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: scheduleMode,
          payload: isoPayload,
        );
      } catch (e) {
        // Fallback berjenjang bila alarmClock ditolak platform
        if (scheduleMode == AndroidScheduleMode.alarmClock) {
          if (kDebugMode) {
            debugPrint(
                '[NotifService] Fallback ke exactAllowWhileIdle karena: $e');
          }
          try {
            scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
            await _notificationsPlugin.zonedSchedule(
              id: id,
              title: title,
              body: body,
              scheduledDate: scheduledDateTime,
              notificationDetails: notificationDetails,
              androidScheduleMode: scheduleMode,
              payload: isoPayload,
            );
          } catch (e2) {
            if (kDebugMode) {
              debugPrint(
                  '[NotifService] Fallback ke inexactAllowWhileIdle karena: $e2');
            }
            scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
            await _notificationsPlugin.zonedSchedule(
              id: id,
              title: title,
              body: body,
              scheduledDate: scheduledDateTime,
              notificationDetails: notificationDetails,
              androidScheduleMode: scheduleMode,
              payload: isoPayload,
            );
          }
        } else {
          rethrow;
        }
      }

      if (kDebugMode) {
        final soundUri = _kUseBundledAlarmSound
            ? 'res/raw/$_kBundledAlarmSoundName'
            : _kSystemAlarmUri;
        final offset = scheduledDateTime.timeZoneOffset;
        final sign = offset.isNegative ? '-' : '+';
        final offsetStr = '$sign'
            '${offset.inHours.abs().toString().padLeft(2, '0')}:'
            '${(offset.inMinutes.abs() % 60).toString().padLeft(2, '0')}';
        debugPrint(
            '[NotifService] ✅ Alarm dijadwal: ID=$id, "$title", '
            'tz=${tz.local.name} (offset $offsetStr), '
            'waktuLokal=$scheduledDateTime, uid=$uid, '
            'mode=$scheduleMode, sound=$soundUri, payload=$isoPayload');
      }
    } catch (e) {
      debugPrint('[NotifService] ❌ Gagal jadwal notifikasi ID $id: $e');
    }
  }

  /// Mengirim notifikasi instan langsung ke status bar (mis. jadwal habis saat app dibuka/resumed).
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final androidDetails = _buildAlarmDetails(title: title);
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
      if (kDebugMode) {
        debugPrint(
            '[NotifService] 🔔 Notifikasi instan dikirim: ID=$id, "$title", payload=$payload');
      }
    } catch (e) {
      debugPrint('[NotifService] ❌ Gagal kirim notifikasi instan ID $id: $e');
    }
  }

  // ── Pembatalan ────────────────────────────────────────────────────────────

  Future<void> cancelReminder(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
      if (kDebugMode) {
        debugPrint('[NotifService] Alarm ID $id dibatalkan');
      }
    } catch (e) {
      debugPrint('[NotifService] Gagal batalkan notifikasi ID $id: $e');
    }
  }

  Future<void> cancelAllReminders({String? reason}) async {
    try {
      await _notificationsPlugin.cancelAll();
      if (kDebugMode) {
        debugPrint(
            '[NotifService] ❌ SEMUA alarm dibatalkan. '
            'Alasan: ${reason ?? "tidak disebutkan"}');
      }
    } catch (e) {
      debugPrint('[NotifService] Gagal batalkan semua notifikasi: $e');
    }
  }

  // ── Introspeksi ───────────────────────────────────────────────────────────

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending =
          await _notificationsPlugin.pendingNotificationRequests();
      if (kDebugMode) {
        debugPrint(
            '[NotifService] Pending notifications: ${pending.length} item');
        for (final n in pending) {
          debugPrint(
              '  → ID=${n.id}, title="${n.title}", body="${n.body}"');
        }
      }
      return pending;
    } catch (e) {
      debugPrint('[NotifService] Gagal baca pending notifications: $e');
      return [];
    }
  }

}

// ── Top-level background handler (wajib di luar class) ────────────────────
@pragma('vm:entry-point')
void _onBgNotificationTapped(NotificationResponse details) {
  if (kDebugMode) {
    debugPrint(
        '[NotifService] BG tap: id=${details.id}, '
        'action="${details.actionId}", payload=${details.payload}');
  }
}

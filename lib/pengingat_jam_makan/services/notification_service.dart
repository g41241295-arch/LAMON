import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'meal_reminder_service.dart';

/// Layanan lokal penanganan alarm dan notifikasi terjadwal
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'lamon_meal_alarm_channel';
  static const String channelName = 'Pengingat Jam Makan LAMON';
  static const String channelDescription =
      'Notifikasi alarm jadwal jam makan teratur untuk kesehatan lambung';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Inisialisasi plugin notifikasi, timezone perangkat, dan MealReminderService
  /// Aman dari exception (tidak melempar error ke main)
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
        onDidReceiveNotificationResponse: (details) {
          // Tangani respon klik notifikasi jika diperlukan
        },
      );

      // 3. Konfigurasi channel & izin khusus Android
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          const androidChannel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          );
          await androidImplementation.createNotificationChannel(androidChannel);

          // Izin notifikasi runtime (Android 13+)
          try {
            await androidImplementation.requestNotificationsPermission();
          } catch (e) {
            debugPrint('Izin notifikasi POST_NOTIFICATIONS dilewati: $e');
          }

          // Cek & minta izin exact alarm (Android 12+)
          try {
            final canSchedule =
                await androidImplementation.canScheduleExactNotifications();
            if (canSchedule == false) {
              await androidImplementation.requestExactAlarmsPermission();
            }
          } catch (e) {
            debugPrint('Pengecekan exact alarm dilewati: $e');
          }
        }
      }

      _isInitialized = true;

      // 4. Inisialisasi MealReminderService (sinkronisasi jadwal & auth listener)
      await MealReminderService.instance.initialize();
    } catch (e) {
      debugPrint('NotificationService.initialize mengalami kendala: $e');
    }
  }

  /// Memperbarui zona waktu lokal sesuai settingan perangkat pengguna
  Future<void> updateLocalTimeZone() async {
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {}
    }
  }

  /// Menghasilkan ID notifikasi unik deterministik dari tanggal dan slot
  int generateNotificationId({
    required DateTime date,
    required int slotIndex, // 1: sarapan, 2: siang, 3: malam, 4: tidur
  }) {
    final dateCode = date.year * 10000 + date.month * 100 + date.day;
    return (dateCode % 214748360) * 10 + slotIndex;
  }

  /// Menjadwalkan alarm tepat waktu (graceful fallback jika izin exact belum diberikan)
  Future<void> scheduleMealReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
  }) async {
    try {
      if (scheduledDateTime.isBefore(DateTime.now())) return;

      final tzScheduled = tz.TZDateTime.from(scheduledDateTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // Cek ketersediaan izin exact alarm pada Android
      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.exactAllowWhileIdle;

      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          try {
            final canExact =
                await androidImpl.canScheduleExactNotifications();
            if (canExact == false) {
              // Fallback aman tanpa crash SecurityException
              scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
            }
          } catch (_) {
            scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          }
        }
      }

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: notificationDetails,
        androidScheduleMode: scheduleMode,
      );
    } catch (e) {
      debugPrint('Gagal menjadwalkan notifikasi ID $id: $e');
    }
  }

  /// Membatalkan satu notifikasi terjadwal
  Future<void> cancelReminder(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('Gagal membatalkan notifikasi ID $id: $e');
    }
  }

  /// Membatalkan seluruh notifikasi terjadwal aplikasi
  Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Gagal membatalkan seluruh notifikasi: $e');
    }
  }
}

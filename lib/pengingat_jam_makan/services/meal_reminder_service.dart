import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../debug/alarm_debug.dart';
import '../models/meal_reminder_plan.dart';
import '../../screens/beranda/models/meal_schedule_model.dart';
import '../../screens/beranda/services/beranda_meal_service.dart';
import 'notification_service.dart';

/// Layanan sinkronisasi rencana jadwal pengingat jam makan.
///
/// ────────────────────────────────────────────────────────────────────────────
/// KEBIJAKAN PEMBATALAN & REKONSILIASI ALARM
/// ────────────────────────────────────────────────────────────────────────────
/// 1. Seluruh operasi penjadwalan & rekonsiliasi dijalankan lewat antrean serial
///    (serial queue). Tidak ada operasi yang berjalan bersamaan. Pemicu yang
///    datang saat antrean berjalan digabung menjadi satu rekonsiliasi susulan.
/// 2. Rekonsiliasi membandingkan `pendingNotificationRequests` OS dengan daftar
///    alarm yang seharusnya aktif untuk SELURUH rentang tanggal (hingga 31 hari):
///    - Membatalkan hanya alarm usang/tidak berlaku (ID tertentu), tanpa cancelAll.
///    - Menjadwalkan hanya alarm yang belum ada atau waktunya berubah.
/// 3. Notifikasi Pengingat "Jadwal Habis" (ID: [kPlanExpiredNotificationId]):
///    - Dijadwalkan otomatis pada hari setelah tanggal terakhir rencana (H+1)
///      pukul 08:00 waktu lokal.
///    - Dikecualikan dari perhitungan selisih alarm makan.
///    - Diperbarui saat rencana baru disimpan atau dibatalkan saat rencana nonaktif.
///    - Tampil langsung sekali saja saat aplikasi dibuka/resumed jika waktu rencana sudah lewat.
/// 4. Logout eksplisit oleh pengguna tetap membatalkan seluruh alarm via [cancelAlarmsForLogout].
/// ────────────────────────────────────────────────────────────────────────────
class MealReminderService with WidgetsBindingObserver {
  MealReminderService._();
  static final MealReminderService instance = MealReminderService._();

  // ── ID & Kunci Khusus ─────────────────────────────────────────────────────
  /// ID tetap khusus untuk notifikasi pengingat "Jadwal makan sudah habis" (H+1 08:00).
  static const int kPlanExpiredNotificationId = 999999001;

  static const String keyBerandaSchedule = 'lamon_meal_schedule';
  static const String keyUserPlanPrefix = 'lamon_meal_plan_';

  /// UID pemilik alarm aktif yang tersimpan secara persisten.
  static const String _keyAlarmOwnerUid = 'lamon_alarm_owner_uid';

  /// Penanda tanggal rencana terakhir yang notifikasi habisnya sudah pernah ditampilkan.
  static const String _keyPlanExpiredNotifiedKey = 'lamon_plan_expired_notified_key';

  // ── State internal ────────────────────────────────────────────────────────
  Timer? _midnightTimer;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  bool _isInitialized = false;

  // ── Serial Queue (Mutex / Chaining) ───────────────────────────────────────
  Future<void>? _activeSyncOperation;
  bool _pendingSyncRequest = false;

  /// Notifier daftar jadwal jam makan hari ini untuk Beranda
  final ValueNotifier<List<MealScheduleItem>> todaySchedulesNotifier =
      ValueNotifier<List<MealScheduleItem>>(BerandaMealService.defaultSchedules);

  /// Notifier rencana jadwal aktif pengguna
  final ValueNotifier<MealReminderPlan?> activePlanNotifier =
      ValueNotifier<MealReminderPlan?>(null);

  // ── Aksesor UID ───────────────────────────────────────────────────────────
  String? get currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  // ── Inisialisasi ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);

    // 1. Pastikan zona waktu sinkron sebelum perhitungan jadwal
    await NotificationService.instance.updateLocalTimeZone();

    // 2. Sinkronkan jadwal hari ini ke Beranda saat aplikasi dimulai
    await syncTodayScheduleToBeranda();

    // 3. Pasang timer ke tengah malam berikutnya (00:00:01)
    _scheduleMidnightTimer();

    // 4. Pasang pendengar authStateChanges
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_handleAuthChanged);

    // 5. Pasang realtime listener Firestore jika sudah login
    _setupFirestoreListener(currentUid);

    // 6. Rekonsiliasi alarm saat startup secara serial
    await reconcileAlarms(reason: 'Startup app');
  }

  // ── AppLifecycle ──────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        debugPrint('[MealReminder] App resumed — verifikasi alarm & timezone');
      }
      NotificationService.instance.updateLocalTimeZone();
      syncTodayScheduleToBeranda();
      reconcileAlarms(reason: 'App resumed');
    }
  }

  // ── Pengelolaan pemilik alarm ─────────────────────────────────────────────

  Future<String?> _savedAlarmOwnerUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAlarmOwnerUid);
  }

  Future<void> _saveAlarmOwnerUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAlarmOwnerUid, uid);
  }

  Future<void> _clearAlarmOwnerUid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAlarmOwnerUid);
  }

  // ── Handler authStateChanges ──────────────────────────────────────────────

  Future<void> _handleAuthChanged(User? user) async {
    if (user == null) {
      if (kDebugMode) {
        final ownerUid = await _savedAlarmOwnerUid();
        debugPrint(
          '[MealReminder] authStateChanges: user=null — alarm DIPERTAHANKAN. '
          'Pemilik tersimpan: $ownerUid',
        );
      }
      return;
    }

    final newUid = user.uid;
    final savedOwnerUid = await _savedAlarmOwnerUid();

    if (kDebugMode) {
      debugPrint(
        '[MealReminder] authStateChanges: user=$newUid, savedOwner=$savedOwnerUid',
      );
    }

    if (savedOwnerUid != null && savedOwnerUid != newUid) {
      if (kDebugMode) {
        debugPrint(
          '[MealReminder] UID berubah ($savedOwnerUid → $newUid). '
          'Batalkan alarm lama dan bersihkan jadwal.',
        );
      }
      await NotificationService.instance.cancelAllReminders(
        reason: 'Login akun berbeda: $savedOwnerUid → $newUid',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyBerandaSchedule);
      await prefs.remove(_keyPlanExpiredNotifiedKey);
    }

    await _saveAlarmOwnerUid(newUid);

    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    _setupFirestoreListener(newUid);

    await reconcileAlarms(reason: 'Auth changed');
    await syncTodayScheduleToBeranda();
  }

  // ── Listener Firestore ────────────────────────────────────────────────────

  void _setupFirestoreListener(String? uid) {
    if (uid == null) return;
    try {
      _firestoreSubscription?.cancel();
      _firestoreSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meal_schedules')
          .doc('active_plan')
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          final plan = MealReminderPlan.fromJson(snapshot.data()!);
          // Simpan salinan lokal
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              '$keyUserPlanPrefix$uid', jsonEncode(plan.toJson()));
          activePlanNotifier.value = plan;

          // Rekonsiliasi secara aman via serial queue (tanpa cancelAll)
          reconcileAlarms(reason: 'Firestore snapshot update');
          await syncTodayScheduleToBeranda();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  // ── Antrean Serial & Rekonsiliasi Alarm ────────────────────────────────────

  /// Menjalankan rekonsiliasi alarm secara serial (satu per satu).
  /// Pemicu yang datang saat rekonsiliasi berjalan akan digabung (cukup satu rekonsiliasi susulan).
  Future<void> reconcileAlarms({String? reason}) {
    if (_activeSyncOperation != null) {
      _pendingSyncRequest = true;
      if (kDebugMode) {
        debugPrint(
          '[MealReminder] ⏳ Antrean rekonsiliasi aktif. Permintaan susulan dicatat: ${reason ?? "tanpa alasan"}',
        );
      }
      return _activeSyncOperation!;
    }

    final completer = Completer<void>();
    _activeSyncOperation = completer.future;

    () async {
      try {
        do {
          _pendingSyncRequest = false;
          await _performReconciliation(reason: reason);
        } while (_pendingSyncRequest);
      } catch (e) {
        debugPrint('[MealReminder] ❌ Error pada rekonsiliasi alarm: $e');
      } finally {
        _activeSyncOperation = null;
        completer.complete();
      }
    }();

    return _activeSyncOperation!;
  }

  /// Inti logika rekonsiliasi:
  /// - Bandingkan pendingNotificationRequests dengan alarm yang seharusnya aktif.
  /// - Batalkan hanya yang tidak lagi berlaku (id tertentu), tanpa cancelAll.
  /// - Jadwalkan hanya yang belum ada atau yang waktunya berubah.
  /// - Kelola notifikasi "jadwal habis" (ID 999999001).
  /// - Verifikasi dan catat selisihnya di debugPrint.
  Future<void> _performReconciliation({String? reason}) async {
    final uid = currentUid;
    if (uid == null) {
      if (kDebugMode) {
        debugPrint(
            '[MealReminder] _performReconciliation: user belum login, skip ($reason)');
      }
      return;
    }

    logAlarmDebug(
        'Memulai rekonsiliasi alarm (Pemicu: ${reason ?? "tidak disebutkan"})');

    final plan = await loadPlan(uid: uid);
    final notif = NotificationService.instance;
    final prefs = await SharedPreferences.getInstance();
    final nowTz = tz.TZDateTime.now(tz.local);

    final pending = await notif.getPendingNotifications();
    final pendingMap = {for (final p in pending) p.id: p};

    if (plan == null || !plan.enabled) {
      // Tidak ada rencana aktif: batalkan semua alarm jam makan yang tersisa & jadwal habis
      int cancelledCount = 0;
      for (final p in pending) {
        if (_isMealReminderNotification(p) ||
            p.id == kPlanExpiredNotificationId) {
          await notif.cancelReminder(p.id);
          cancelledCount++;
        }
      }
      if (kDebugMode) {
        debugPrint(
            '[MealReminder] Plan nonaktif: $cancelledCount alarm dibatalkan');
      }
      return;
    }

    // Bangun seluruh slot jam makan yang seharusnya aktif untuk seluruh rentang tanggal
    final desiredSlots = _buildAlarmSlots(plan);
    final desiredMap = {for (final s in desiredSlots) s.id: s};

    // 1. Batalkan alarm makan yang ada di pending tetapi TIDAK LAGI berlaku di desiredSlots
    int cancelledCount = 0;
    for (final p in pending) {
      if (_isMealReminderNotification(p) && !desiredMap.containsKey(p.id)) {
        await notif.cancelReminder(p.id);
        cancelledCount++;
        if (kDebugMode) {
          debugPrint(
              '[MealReminder] 🗑️ Batalkan alarm usang ID ${p.id} ("${p.title}")');
        }
      }
    }

    // 2. Jadwalkan alarm makan yang belum ada di pending atau yang waktunya berubah
    int scheduledCount = 0;
    for (final slot in desiredSlots) {
      final existing = pendingMap[slot.id];
      final targetIso = slot.scheduledTime.toIso8601String();

      // Jika belum ada di pending ATAU waktu/payload berbeda -> jadwalkan
      if (existing == null || existing.payload != targetIso) {
        await notif.scheduleMealReminder(
          id: slot.id,
          title: slot.title,
          body: slot.body,
          scheduledDateTime: slot.scheduledTime,
          uid: uid,
          payload: targetIso,
        );
        scheduledCount++;
      }
    }

    // 3. Notifikasi Pengingat "Jadwal Habis" (ID: 999999001)
    // Waktu: hari setelah tanggal terakhir rencana (H+1), pukul 08:00 waktu lokal
    final dayAfterEnd = plan.endDate.add(const Duration(days: 1));
    final expiredNotifTime = tz.TZDateTime(
      tz.local,
      dayAfterEnd.year,
      dayAfterEnd.month,
      dayAfterEnd.day,
      8,
      0,
    );
    final expiredPayload =
        'type=plan_expired;time=${expiredNotifTime.toIso8601String()}';

    if (expiredNotifTime.isAfter(nowTz)) {
      // Jadwal belum habis: pastikan notifikasi terjadwal di hari H+1 pukul 08:00
      final existingExpired = pendingMap[kPlanExpiredNotificationId];
      if (existingExpired == null ||
          existingExpired.payload != expiredPayload) {
        await notif.scheduleMealReminder(
          id: kPlanExpiredNotificationId,
          title: 'Jadwal makan sudah habis',
          body: 'Atur ulang jam makanmu supaya pengingat tetap berjalan.',
          scheduledDateTime: expiredNotifTime,
          uid: uid,
          payload: expiredPayload,
        );
        if (kDebugMode) {
          debugPrint(
              '[MealReminder] 📅 Notifikasi jadwal habis dijadwalkan: $expiredNotifTime');
        }
      }
    } else {
      // Waktu jadwal habis sudah lewat di masa lalu
      if (pendingMap.containsKey(kPlanExpiredNotificationId)) {
        await notif.cancelReminder(kPlanExpiredNotificationId);
      }

      // Pemulihan saat app dibuka/resumed: bila seluruh rentang sudah lewat,
      // tampilkan notifikasi langsung sekali saja (jangan berulang setiap resume).
      final planKey =
          '${MealReminderPlan.formatDate(plan.endDate)}_${plan.updatedAt.millisecondsSinceEpoch}';
      final lastNotified = prefs.getString(_keyPlanExpiredNotifiedKey);
      if (lastNotified != planKey) {
        await prefs.setString(_keyPlanExpiredNotifiedKey, planKey);
        await notif.showInstantNotification(
          id: kPlanExpiredNotificationId,
          title: 'Jadwal makan sudah habis',
          body: 'Atur ulang jam makanmu supaya pengingat tetap berjalan.',
          payload: 'type=plan_expired;time=${nowTz.toIso8601String()}',
        );
        if (kDebugMode) {
          debugPrint(
              '[MealReminder] 📢 Notifikasi jadwal habis instan dikirim (key: $planKey)');
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[MealReminder] Rekonsiliasi selesai ($reason): '
        '$scheduledCount dijadwalkan ulang/baru, '
        '$cancelledCount dibatalkan usang, '
        'total slot makan target=${desiredSlots.length}',
      );
    }

    // 4. Verifikasi: bandingkan jumlah alarm makan yang seharusnya dengan jumlah di pendingNotificationRequests
    // (DIKECUALIKAN kPlanExpiredNotificationId agar selisih tidak salah)
    final afterPending = await notif.getPendingNotifications();
    final activeMealReminders = afterPending
        .where((p) =>
            desiredMap.containsKey(p.id) &&
            p.id != kPlanExpiredNotificationId)
        .toList();
    final expectedCount = desiredSlots.length;
    final actualCount = activeMealReminders.length;
    final diff = expectedCount - actualCount;

    if (kDebugMode) {
      debugPrint(
        '[MealReminder] 🔍 Verifikasi: seharusnya=$expectedCount, '
        'aktif di sistem=$actualCount, selisih=$diff',
      );
    }

    logAlarmDebug(
      'Rekonsiliasi selesai: $scheduledCount dibuat/dipulihkan, $cancelledCount dihapus. '
      'Status: seharusnya=$expectedCount, aktif=$actualCount, selisih=$diff',
    );
  }

  /// Mengecek apakah notifikasi pending merupakan alarm jam makan biasa
  bool _isMealReminderNotification(PendingNotificationRequest p) {
    if (p.id == kPlanExpiredNotificationId) return false;
    if (p.payload != null &&
        (p.payload == 'meal_reminder' ||
            (!p.payload!.contains('type=plan_expired') &&
                DateTime.tryParse(p.payload!) != null))) {
      return true;
    }
    // Cek pola digit ID: minimal 9 digit dan berakhiran 1..4 (slotIndex)
    if (p.id >= 100000000 &&
        p.id <= 2147483647 &&
        p.id != kPlanExpiredNotificationId) {
      final lastDigit = p.id % 10;
      if (lastDigit >= 1 && lastDigit <= 4) return true;
    }
    return false;
  }

  // ── Model internal slot alarm ─────────────────────────────────────────────

  /// Membangun daftar semua slot alarm dari sebuah rencana untuk SELURUH rentang tanggal aktif.
  /// Waktu dibangun langsung dengan [tz.TZDateTime(tz.local, ...)].
  List<_AlarmSlot> _buildAlarmSlots(MealReminderPlan plan) {
    final notif = NotificationService.instance;
    final nowTz = tz.TZDateTime.now(tz.local);

    DateTime current = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );

    final end = DateTime(
      plan.endDate.year,
      plan.endDate.month,
      plan.endDate.day,
    );

    final List<_AlarmSlot> slots = [];
    int count = 0;

    while ((current.isBefore(end) || current.isAtSameMomentAs(end)) &&
        count < 31) {
      final sarapanTime = tz.TZDateTime(
        tz.local,
        current.year,
        current.month,
        current.day,
        plan.sarapan.startHour,
        0,
      );
      if (sarapanTime.isAfter(nowTz)) {
        slots.add(_AlarmSlot(
          id: notif.generateNotificationId(date: current, slotIndex: 1),
          title: 'Sarapan 🌅',
          body: 'Waktunya sarapan sehat! Menjaga lambung tetap nyaman hari ini.',
          scheduledTime: sarapanTime,
        ));
      }

      final siangTime = tz.TZDateTime(
        tz.local,
        current.year,
        current.month,
        current.day,
        plan.makanSiang.startHour,
        0,
      );
      if (siangTime.isAfter(nowTz)) {
        slots.add(_AlarmSlot(
          id: notif.generateNotificationId(date: current, slotIndex: 2),
          title: 'Makan Siang 🍽️',
          body:
              'Jangan lupa makan siang tepat waktu agar asam lambung stabil.',
          scheduledTime: siangTime,
        ));
      }

      final malamTime = tz.TZDateTime(
        tz.local,
        current.year,
        current.month,
        current.day,
        plan.makanMalam.startHour,
        0,
      );
      if (malamTime.isAfter(nowTz)) {
        slots.add(_AlarmSlot(
          id: notif.generateNotificationId(date: current, slotIndex: 3),
          title: 'Makan Malam 🌙',
          body: 'Waktunya makan malam. Hindari makan terlalu larut ya!',
          scheduledTime: malamTime,
        ));
      }

      if (plan.condition == MealCondition.sakit) {
        final tidurTime = tz.TZDateTime(
          tz.local,
          current.year,
          current.month,
          current.day,
          plan.sleepHour,
          0,
        );
        if (tidurTime.isAfter(nowTz)) {
          slots.add(_AlarmSlot(
            id: notif.generateNotificationId(date: current, slotIndex: 4),
            title: 'Jam Tidur 😴',
            body: 'Waktunya istirahat tidur untuk pemulihan lambung optimal.',
            scheduledTime: tidurTime,
          ));
        }
      }

      current = current.add(const Duration(days: 1));
      count++;
    }

    return slots;
  }

  // ── Timer tengah malam ────────────────────────────────────────────────────

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration =
        tomorrow.difference(now) + const Duration(seconds: 1);

    _midnightTimer = Timer(duration, () async {
      await syncTodayScheduleToBeranda();
      reconcileAlarms(reason: 'Tengah malam lewat');
      _scheduleMidnightTimer();
    });
  }

  // ── Kunci SharedPreferences per pengguna ─────────────────────────────────

  String _userKey(String? uid) => '$keyUserPlanPrefix${uid ?? "guest"}';

  // ── Memuat rencana jadwal pengguna ────────────────────────────────────────

  Future<MealReminderPlan?> loadPlan({String? uid}) async {
    try {
      final targetUid = uid ?? currentUid;
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_userKey(targetUid));
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return MealReminderPlan.fromJson(jsonDecode(jsonStr));
      }
    } catch (e) {
      debugPrint('[MealReminder] Error loadPlan: $e');
    }
    return null;
  }

  /// Mengecek apakah pada tanggal tertentu sudah ada rencana jadwal aktif.
  Future<bool> hasExistingScheduleOn(DateTime date) async {
    final plan = await loadPlan();
    if (plan == null || !plan.enabled) return false;
    return plan.isDateActive(date);
  }

  // ── Menyimpan rencana jadwal ──────────────────────────────────────────────

  Future<void> savePlan(MealReminderPlan plan) async {
    final uid = currentUid;
    final prefs = await SharedPreferences.getInstance();

    // Reset penanda notifikasi jadwal habis agar rencana baru kelak bisa memberitahu lagi
    await prefs.remove(_keyPlanExpiredNotifiedKey);
    // Batalkan notifikasi jadwal habis rencana lama agar dijadwalkan ulang mengikuti tanggal baru
    await NotificationService.instance.cancelReminder(kPlanExpiredNotificationId);

    // 1. Simpan ke SharedPreferences lokal
    await prefs.setString(_userKey(uid), jsonEncode(plan.toJson()));

    // 2. Simpan ke Firestore jika login (sinkronisasi cloud)
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('meal_schedules')
            .doc('active_plan')
            .set(plan.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('[MealReminder] Gagal simpan ke Firestore: $e');
      }
      // Simpan UID pemilik alarm
      await _saveAlarmOwnerUid(uid);
    }

    activePlanNotifier.value = plan;

    // 3. Rekonsiliasi alarm secara serial (batalkan yang usang, jadwalkan yang baru)
    await reconcileAlarms(reason: 'Save plan baru');

    // 4. Sinkronkan jadwal hari ini ke Beranda
    await syncTodayScheduleToBeranda();
  }

  // ── Logout eksplisit ──────────────────────────────────────────────────────

  /// Dipanggil HANYA saat user menekan tombol logout secara eksplisit.
  /// Membatalkan semua alarm dan membersihkan penyimpanan lokal.
  Future<void> cancelAlarmsForLogout() async {
    if (kDebugMode) {
      debugPrint(
          '[MealReminder] cancelAlarmsForLogout() — batalkan semua alarm');
    }
    await NotificationService.instance.cancelAllReminders(
      reason: 'Logout eksplisit oleh user',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyBerandaSchedule);
    await prefs.remove(_keyPlanExpiredNotifiedKey);
    await _clearAlarmOwnerUid();
    todaySchedulesNotifier.value = BerandaMealService.defaultSchedules;
    activePlanNotifier.value = null;
  }

  // ── Sinkronisasi ke Beranda ───────────────────────────────────────────────

  Future<void> syncTodayScheduleToBeranda() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final plan = await loadPlan();
      activePlanNotifier.value = plan;

      if (plan != null && plan.enabled && plan.isDateActive(now)) {
        final mealItems = plan.toMealScheduleItems();
        final jsonList = mealItems.map((item) => item.toJson()).toList();
        await prefs.setString(keyBerandaSchedule, jsonEncode(jsonList));
        todaySchedulesNotifier.value = mealItems;
      } else {
        await prefs.remove(keyBerandaSchedule);
        todaySchedulesNotifier.value = BerandaMealService.defaultSchedules;
      }
    } catch (e) {
      debugPrint('[MealReminder] Gagal syncTodayScheduleToBeranda: $e');
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _authSubscription?.cancel();
    _firestoreSubscription?.cancel();
  }
}

// ── Model internal ────────────────────────────────────────────────────────────

class _AlarmSlot {
  final int id;
  final String title;
  final String body;
  final tz.TZDateTime scheduledTime;

  const _AlarmSlot({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
  });
}

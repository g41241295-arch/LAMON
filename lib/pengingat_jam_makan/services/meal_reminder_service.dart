import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_reminder_plan.dart';
import '../../screens/beranda/models/meal_schedule_model.dart';
import '../../screens/beranda/services/beranda_meal_service.dart';
import 'notification_service.dart';

/// Layanan sinkronisasi rencana jadwal pengingat jam makan.
///
/// ────────────────────────────────────────────────────────────────────────────
/// KEBIJAKAN PEMBATALAN ALARM
/// ────────────────────────────────────────────────────────────────────────────
/// Alarm HANYA dibatalkan pada dua kondisi:
///   1. Pengguna menekan tombol Logout secara eksplisit
///      → panggil [cancelAlarmsForLogout].
///   2. Login dengan UID BERBEDA dari pemilik alarm
///      → otomatis batalkan alarm lama, jadwalkan alarm baru.
///
/// Alarm TIDAK dibatalkan saat:
///   • authStateChanges mengirim user=null sementara (startup, biometrik, dsb.)
///   • Login kembali dengan UID yang SAMA
///
/// Saat login ulang dengan UID sama:
///   • Bandingkan alarm yang seharusnya ada vs pendingNotificationRequests.
///   • Jadwalkan ulang HANYA alarm yang hilang (tidak batalkan yang masih ada).
/// ────────────────────────────────────────────────────────────────────────────
class MealReminderService with WidgetsBindingObserver {
  MealReminderService._();
  static final MealReminderService instance = MealReminderService._();

  // ── Kunci SharedPreferences ───────────────────────────────────────────────
  static const String keyBerandaSchedule = 'lamon_meal_schedule';
  static const String keyUserPlanPrefix = 'lamon_meal_plan_';

  /// UID pemilik alarm aktif yang tersimpan secara persisten.
  /// Menjadi referensi keputusan batalkan/pertahankan alarm.
  static const String _keyAlarmOwnerUid = 'lamon_alarm_owner_uid';

  // ── State internal ────────────────────────────────────────────────────────
  Timer? _midnightTimer;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  bool _isInitialized = false;

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

    // 1. Sinkronkan jadwal hari ini ke Beranda saat aplikasi dimulai
    await syncTodayScheduleToBeranda();

    // 2. Pasang timer ke tengah malam berikutnya (00:00:01)
    _scheduleMidnightTimer();

    // 3. Pasang pendengar authStateChanges
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_handleAuthChanged);

    // 4. Pasang realtime listener Firestore jika sudah login
    _setupFirestoreListener(currentUid);

    // 5. Verifikasi alarm saat startup
    await _verifyAndFillMissingAlarms();
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
      _verifyAndFillMissingAlarms();
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
      // ── user == null: JANGAN batalkan alarm ──────────────────────────────
      // Ini bisa terjadi saat startup, kunci biometrik, atau transisi sementara.
      // Alarm tetap aktif; pemilik tersimpan di _keyAlarmOwnerUid.
      if (kDebugMode) {
        final ownerUid = await _savedAlarmOwnerUid();
        debugPrint(
          '[MealReminder] authStateChanges: user=null — alarm DIPERTAHANKAN. '
          'Pemilik tersimpan: $ownerUid',
        );
      }
      // Jangan hapus lamon_meal_schedule — biarkan Beranda tetap menampilkan jadwal.
      return;
    }

    // ── user != null: cek apakah UID berubah ─────────────────────────────
    final newUid = user.uid;
    final savedOwnerUid = await _savedAlarmOwnerUid();

    if (kDebugMode) {
      debugPrint(
        '[MealReminder] authStateChanges: user=$newUid, savedOwner=$savedOwnerUid',
      );
    }

    if (savedOwnerUid != null && savedOwnerUid != newUid) {
      // ── UID BERBEDA → pergantian akun ─────────────────────────────────
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
      // Hapus jadwal Beranda akun lama sebelum mengisi jadwal akun baru
      await prefs.remove(keyBerandaSchedule);
    }
    // else: UID sama atau belum ada pemilik → tidak batalkan apapun

    // Simpan UID pemilik alarm baru
    await _saveAlarmOwnerUid(newUid);

    // Pasang listener Firestore untuk akun ini
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    _setupFirestoreListener(newUid);

    // Muat jadwal dan pastikan alarm aktif (tambahkan yang hilang, tidak batalkan yang ada)
    final plan = await loadPlan(uid: newUid);
    if (plan != null && plan.enabled) {
      await _ensureAlarmsScheduled(plan, uid: newUid);
    }
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
          // Jadwal ulang semua alarm (plan berubah dari perangkat lain)
          await _scheduleAllAlarmsForPlan(plan, uid: uid);
          await syncTodayScheduleToBeranda();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  // ── Verifikasi & isi alarm yang hilang ───────────────────────────────────

  /// Verifikasi alarm yang seharusnya ada, lalu jadwalkan ulang HANYA
  /// yang hilang dari pendingNotificationRequests. Tidak membatalkan yang ada.
  Future<void> _verifyAndFillMissingAlarms() async {
    try {
      final uid = currentUid;
      if (uid == null) {
        if (kDebugMode) {
          debugPrint(
              '[MealReminder] _verifyAndFill: user belum login, skip');
        }
        return;
      }

      final plan = await loadPlan(uid: uid);
      if (plan == null || !plan.enabled) {
        if (kDebugMode) {
          debugPrint('[MealReminder] _verifyAndFill: tidak ada jadwal aktif');
        }
        return;
      }

      final pending =
          await NotificationService.instance.getPendingNotifications();
      final pendingIds = pending.map((n) => n.id).toSet();

      if (kDebugMode) {
        debugPrint(
            '[MealReminder] _verifyAndFill: ${pending.length} alarm pending');
      }

      // Jadwalkan hanya alarm yang hilang
      int scheduled = 0;
      final notif = NotificationService.instance;
      final slots = _buildAlarmSlots(plan);

      for (final slot in slots) {
        if (!pendingIds.contains(slot.id) &&
            slot.scheduledTime.isAfter(DateTime.now())) {
          await notif.scheduleMealReminder(
            id: slot.id,
            title: slot.title,
            body: slot.body,
            scheduledDateTime: slot.scheduledTime,
            uid: uid,
          );
          scheduled++;
        }
      }

      if (kDebugMode) {
        debugPrint(
            '[MealReminder] _verifyAndFill: $scheduled alarm baru dijadwalkan '
            '(dari ${slots.length} total slot)');
      }
    } catch (e) {
      debugPrint('[MealReminder] Error _verifyAndFillMissingAlarms: $e');
    }
  }

  /// Pastikan semua alarm aktif terjadwal.
  /// Jika uid sama dengan pemilik, hanya tambahkan yang hilang.
  Future<void> _ensureAlarmsScheduled(MealReminderPlan plan,
      {required String uid}) async {
    final pending =
        await NotificationService.instance.getPendingNotifications();
    final pendingIds = pending.map((n) => n.id).toSet();

    final slots = _buildAlarmSlots(plan);
    int scheduled = 0;
    final notif = NotificationService.instance;

    for (final slot in slots) {
      if (!pendingIds.contains(slot.id) &&
          slot.scheduledTime.isAfter(DateTime.now())) {
        await notif.scheduleMealReminder(
          id: slot.id,
          title: slot.title,
          body: slot.body,
          scheduledDateTime: slot.scheduledTime,
          uid: uid,
        );
        scheduled++;
      }
    }

    if (kDebugMode) {
      debugPrint(
          '[MealReminder] _ensureAlarmsScheduled: $scheduled alarm ditambahkan '
          '(sudah ada: ${pending.length}, total slot: ${slots.length})');
    }
  }

  // ── Model internal slot alarm ─────────────────────────────────────────────

  /// Membangun daftar semua slot alarm dari sebuah rencana.
  List<_AlarmSlot> _buildAlarmSlots(MealReminderPlan plan) {
    final notif = NotificationService.instance;
    final now = DateTime.now();
    final today =
        DateTime(now.year, now.month, now.day);

    DateTime current = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    // Mulai dari hari ini jika rencana sudah dimulai sebelumnya
    if (current.isBefore(today)) current = today;

    final end = DateTime(
      plan.endDate.year,
      plan.endDate.month,
      plan.endDate.day,
    );

    final List<_AlarmSlot> slots = [];
    int count = 0;

    while ((current.isBefore(end) || current.isAtSameMomentAs(end)) &&
        count < 31) {
      slots.add(_AlarmSlot(
        id: notif.generateNotificationId(date: current, slotIndex: 1),
        title: 'Sarapan 🌅',
        body: 'Waktunya sarapan sehat! Menjaga lambung tetap nyaman hari ini.',
        scheduledTime: DateTime(
            current.year, current.month, current.day, plan.sarapan.startHour),
      ));

      slots.add(_AlarmSlot(
        id: notif.generateNotificationId(date: current, slotIndex: 2),
        title: 'Makan Siang 🍽️',
        body:
            'Jangan lupa makan siang tepat waktu agar asam lambung stabil.',
        scheduledTime: DateTime(current.year, current.month, current.day,
            plan.makanSiang.startHour),
      ));

      slots.add(_AlarmSlot(
        id: notif.generateNotificationId(date: current, slotIndex: 3),
        title: 'Makan Malam 🌙',
        body: 'Waktunya makan malam. Hindari makan terlalu larut ya!',
        scheduledTime: DateTime(current.year, current.month, current.day,
            plan.makanMalam.startHour),
      ));

      if (plan.condition == MealCondition.sakit) {
        slots.add(_AlarmSlot(
          id: notif.generateNotificationId(date: current, slotIndex: 4),
          title: 'Jam Tidur 😴',
          body: 'Waktunya istirahat tidur untuk pemulihan lambung optimal.',
          scheduledTime: DateTime(
              current.year, current.month, current.day, plan.sleepHour),
        ));
      }

      current = current.add(const Duration(days: 1));
      count++;
    }

    return slots;
  }

  // ── Penjadwalan ulang TOTAL (dipakai saat plan berubah) ───────────────────

  /// Batalkan SEMUA alarm lalu jadwalkan ulang dari nol.
  /// Hanya dipanggil saat data plan berubah (simpan/update dari Firestore).
  Future<void> _scheduleAllAlarmsForPlan(MealReminderPlan plan,
      {String? uid}) async {
    await NotificationService.instance.cancelAllReminders(
      reason: 'Plan diperbarui — jadwal ulang dari nol',
    );
    if (!plan.enabled) return;

    final notif = NotificationService.instance;
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

    int count = 0;
    while ((current.isBefore(end) || current.isAtSameMomentAs(end)) &&
        count < 31) {
      final sarapanTime = DateTime(
          current.year, current.month, current.day, plan.sarapan.startHour);
      await notif.scheduleMealReminder(
        id: notif.generateNotificationId(date: current, slotIndex: 1),
        title: 'Sarapan 🌅',
        body: 'Waktunya sarapan sehat! Menjaga lambung tetap nyaman hari ini.',
        scheduledDateTime: sarapanTime,
        uid: uid,
      );

      final siangTime = DateTime(current.year, current.month, current.day,
          plan.makanSiang.startHour);
      await notif.scheduleMealReminder(
        id: notif.generateNotificationId(date: current, slotIndex: 2),
        title: 'Makan Siang 🍽️',
        body:
            'Jangan lupa makan siang tepat waktu agar asam lambung stabil.',
        scheduledDateTime: siangTime,
        uid: uid,
      );

      final malamTime = DateTime(current.year, current.month, current.day,
          plan.makanMalam.startHour);
      await notif.scheduleMealReminder(
        id: notif.generateNotificationId(date: current, slotIndex: 3),
        title: 'Makan Malam 🌙',
        body: 'Waktunya makan malam. Hindari makan terlalu larut ya!',
        scheduledDateTime: malamTime,
        uid: uid,
      );

      if (plan.condition == MealCondition.sakit) {
        final tidurTime = DateTime(
            current.year, current.month, current.day, plan.sleepHour);
        await notif.scheduleMealReminder(
          id: notif.generateNotificationId(date: current, slotIndex: 4),
          title: 'Jam Tidur 😴',
          body: 'Waktunya istirahat tidur untuk pemulihan lambung optimal.',
          scheduledDateTime: tidurTime,
          uid: uid,
        );
      }

      current = current.add(const Duration(days: 1));
      count++;
    }

    if (kDebugMode) {
      await notif.getPendingNotifications();
    }
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

    // 3. Batalkan alarm lama dan jadwalkan ulang (plan berubah)
    await _scheduleAllAlarmsForPlan(plan, uid: uid);

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
  final DateTime scheduledTime;

  const _AlarmSlot({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
  });
}

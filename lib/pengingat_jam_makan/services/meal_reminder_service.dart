import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_reminder_plan.dart';
import 'notification_service.dart';

/// Layanan sinkronisasi rencana jadwal pengingat jam makan dengan Beranda dan Firebase
class MealReminderService with WidgetsBindingObserver {
  MealReminderService._();
  static final MealReminderService instance = MealReminderService._();

  static const String keyBerandaSchedule = 'lamon_meal_schedule';
  static const String keyUserPlanPrefix = 'lamon_meal_plan_';

  Timer? _midnightTimer;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  bool _isInitialized = false;

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Inisialisasi awal sinkronisasi dan observer
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);

    // 1. Sinkronkan jadwal hari ini ke Beranda saat aplikasi dimulai
    await syncTodayScheduleToBeranda();

    // 2. Pasang timer ke tengah malam berikutnya (00:00:01)
    _scheduleMidnightTimer();

    // 3. Pasang pendengar status login/logout pengguna
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) async {
      await _handleAuthChanged(user);
    });

    // 4. Pasang realtime listener jika user sedang login
    _setupFirestoreListener(currentUid);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Saat aplikasi kembali ke foreground, pastikan zona waktu dan jadwal hari ini akurat
      NotificationService.instance.updateLocalTimeZone();
      syncTodayScheduleToBeranda();
    }
  }

  /// Menjadwalkan timer tepat di tengah malam lokal berikutnya
  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight =
        tomorrow.difference(now) + const Duration(seconds: 1);

    _midnightTimer = Timer(durationUntilMidnight, () async {
      await syncTodayScheduleToBeranda();
      _scheduleMidnightTimer(); // Jadwalkan untuk tengah malam berikutnya
    });
  }

  /// Penanganan saat pengguna login, logout, atau berganti akun
  Future<void> _handleAuthChanged(User? user) async {
    // Batalkan listener Firestore sebelumnya
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;

    if (user == null) {
      // Saat logout: batalkan semua alarm terjadwal pengguna lama
      await NotificationService.instance.cancelAllReminders();
      // Hapus kunci 'lamon_meal_schedule' agar pengguna berikutnya tidak melihat jadwal pengguna sebelumnya
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyBerandaSchedule);
      // PENTING: Jangan menyentuh kunci 'lamon_meal_status_*' milik Beranda!
    } else {
      // Saat login: pasang listener realtime Firestore
      _setupFirestoreListener(user.uid);
      // Muat jadwal pengguna dan jadwalkan ulang alarm
      final plan = await loadPlan(uid: user.uid);
      if (plan != null && plan.enabled) {
        await _scheduleAllAlarmsForPlan(plan);
      }
      await syncTodayScheduleToBeranda();
    }
  }

  /// Listener snapshot Firestore untuk sinkronisasi antar-perangkat
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
          final data = snapshot.data()!;
          final plan = MealReminderPlan.fromJson(data);
          // Simpan salinan lokal
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              '$keyUserPlanPrefix$uid', jsonEncode(plan.toJson()));
          // Perbarui jadwal alarm & Beranda
          await _scheduleAllAlarmsForPlan(plan);
          await syncTodayScheduleToBeranda();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  /// Kunci SharedPreferences per pengguna
  String _userKey(String? uid) {
    return '$keyUserPlanPrefix${uid ?? "guest"}';
  }

  /// Memuat rencana jadwal pengguna yang tersimpan
  Future<MealReminderPlan?> loadPlan({String? uid}) async {
    try {
      final targetUid = uid ?? currentUid;
      final prefs = await SharedPreferences.getInstance();
      final key = _userKey(targetUid);
      final jsonStr = prefs.getString(key);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        return MealReminderPlan.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error loadPlan: $e');
    }
    return null;
  }

  /// Mengecek apakah pada tanggal tertentu sudah terdapat rencana jadwal yang aktif
  Future<bool> hasExistingScheduleOn(DateTime date) async {
    final plan = await loadPlan();
    if (plan == null || !plan.enabled) return false;
    return plan.isDateActive(date);
  }

  /// Menyimpan rencana jadwal baru, menjadwalkan alarm, dan menyinkronkan ke Beranda
  Future<void> savePlan(MealReminderPlan plan) async {
    final uid = currentUid;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(plan.toJson());

    // 1. Simpan ke SharedPreferences lokal pengguna aktif
    await prefs.setString(_userKey(uid), jsonString);

    // 2. Simpan ke Firestore jika user sedang login (sinkronisasi cloud)
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('meal_schedules')
            .doc('active_plan')
            .set(plan.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Gagal menyimpan jadwal ke Firestore: $e');
      }
    }

    // 3. Batalkan alarm sebelumnya dan jadwalkan ulang alarm baru
    await _scheduleAllAlarmsForPlan(plan);

    // 4. Sinkronkan jadwal hari ini ke Beranda
    await syncTodayScheduleToBeranda();
  }

  /// Menjadwalkan seluruh alarm untuk rentang hari aktif rencana
  Future<void> _scheduleAllAlarmsForPlan(MealReminderPlan plan) async {
    await NotificationService.instance.cancelAllReminders();
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

    // Batasi maksimum 30 hari untuk efisiensi sistem notifikasi perangkat
    int count = 0;
    while ((current.isBefore(end) || current.isAtSameMomentAs(end)) &&
        count < 31) {
      // 1. Sarapan (berbunyi pada jam mulai)
      final sarapanTime = DateTime(
        current.year,
        current.month,
        current.day,
        plan.sarapan.startHour,
        0,
      );
      await notif.scheduleMealReminder(
        id: notif.generateNotificationId(date: current, slotIndex: 1),
        title: 'Sarapan',
        body: 'Waktunya sarapan sehat! Menjaga lambung tetap nyaman hari ini.',
        scheduledDateTime: sarapanTime,
      );

      // 2. Makan siang
      final siangTime = DateTime(
        current.year,
        current.month,
        current.day,
        plan.makanSiang.startHour,
        0,
      );
      await notif.scheduleMealReminder(
        id: notif.generateNotificationId(date: current, slotIndex: 2),
        title: 'Makan siang',
        body: 'Jangan lupa makan siang tepat waktu agar asam lambung stabil.',
        scheduledDateTime: siangTime,
      );

      // 3. Makan malam
      final malamTime = DateTime(
        current.year,
        current.month,
        current.day,
        plan.makanMalam.startHour,
        0,
      );
      await notif.scheduleMealReminder(
        id: notif.generateNotificationId(date: current, slotIndex: 3),
        title: 'Makan malam',
        body: 'Waktunya makan malam. Hindari makan terlalu larut ya!',
        scheduledDateTime: malamTime,
      );

      // 4. Jam tidur (khusus kondisi sakit)
      if (plan.condition == MealCondition.sakit) {
        final tidurTime = DateTime(
          current.year,
          current.month,
          current.day,
          plan.sleepHour,
          0,
        );
        await notif.scheduleMealReminder(
          id: notif.generateNotificationId(date: current, slotIndex: 4),
          title: 'Jam tidur',
          body: 'Waktunya istirahat tidur untuk pemulihan lambung optimal.',
          scheduledDateTime: tidurTime,
        );
      }

      current = current.add(const Duration(days: 1));
      count++;
    }
  }

  /// SINKRONISASI SADAR TANGGAL KE BERANDA:
  /// Mengisi kunci 'lamon_meal_schedule' HANYA jika hari ini berada dalam rentang jadwal.
  Future<void> syncTodayScheduleToBeranda() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final plan = await loadPlan();

      if (plan != null && plan.enabled && plan.isDateActive(now)) {
        // Hari ini memiliki jadwal aktif dari rencana pengguna!
        final mealItems = plan.toMealScheduleItems();
        final jsonList = mealItems.map((item) => item.toJson()).toList();
        await prefs.setString(keyBerandaSchedule, jsonEncode(jsonList));
      } else {
        // Hari ini tidak ada jadwal khusus yang aktif:
        // Hapus kunci agar Beranda kembali ke defaultSchedules bawaannya dengan aman
        await prefs.remove(keyBerandaSchedule);
      }
    } catch (e) {
      debugPrint('Gagal syncTodayScheduleToBeranda: $e');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _authSubscription?.cancel();
    _firestoreSubscription?.cancel();
  }
}

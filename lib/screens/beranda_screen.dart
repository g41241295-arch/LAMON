import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_state.dart';
import '../pengingat_jam_makan/models/meal_reminder_plan.dart';
import '../pengingat_jam_makan/services/meal_reminder_service.dart';
import 'beranda/models/meal_schedule_model.dart';
import 'beranda/services/beranda_meal_service.dart';
import 'beranda/widgets/formal_header_bar.dart';
import 'beranda/widgets/formal_sapaan_card.dart';
import 'beranda/widgets/formal_hero_card.dart';
import 'beranda/widgets/formal_menu_grid.dart';
import 'beranda/widgets/formal_info_section.dart';
import '../routes/app_routes.dart';

/// Konstanta padding horizontal seragam untuk seluruh bagian Beranda
const double kHPad = 20.0;

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => BerandaScreenState();
}

class BerandaScreenState extends State<BerandaScreen>
    with WidgetsBindingObserver {
  final BerandaMealService _mealService = BerandaMealService();

  BerandaMealService get mealService => _mealService;

  void setDebugTime(DateTime? debugTime) {
    if (!kDebugMode) return;
    setState(() {
      _mealService.debugNow = debugTime;
      final now = _mealService.now;
      _currentDate = now;
      _updateActiveSchedule();
      _scheduleNextBoundaryTimer();
    });
  }

  List<MealScheduleItem> _schedules = BerandaMealService.defaultSchedules;
  Map<String, MealDailyStatus> _dailyStatus = {};

  MealScheduleItem? _displayedSchedule;
  DateTime _currentDate = DateTime.now();
  Timer? _boundaryTimer;
  Timer? _postCompletionTransitionTimer;
  String? _userPhotoUrl;

  Future<void> _loadUserPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String? photo = user.photoURL;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final rawPhoto = (data['photo_url'] ?? data['photoUrl'] ?? '').toString().trim();
        if (rawPhoto.isNotEmpty) {
          photo = rawPhoto;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _userPhotoUrl = photo;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Dengarkan pembaruan realtime dari MealReminderService (ValueNotifier)
    MealReminderService.instance.todaySchedulesNotifier
        .addListener(_onSchedulesChangedFromReminder);
    MealReminderService.instance.activePlanNotifier
        .addListener(_onPlanChangedFromReminder);

    _initializeData();
    _loadUserPhoto();
  }

  @override
  void dispose() {
    MealReminderService.instance.todaySchedulesNotifier
        .removeListener(_onSchedulesChangedFromReminder);
    MealReminderService.instance.activePlanNotifier
        .removeListener(_onPlanChangedFromReminder);
    WidgetsBinding.instance.removeObserver(this);
    _boundaryTimer?.cancel();
    _postCompletionTransitionTimer?.cancel();
    _mealService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = _mealService.now;
      if (now.day != _currentDate.day ||
          now.month != _currentDate.month ||
          now.year != _currentDate.year) {
        _currentDate = now;
        _loadStatusForCurrentDate();
      } else {
        setState(() {
          _updateActiveSchedule();
        });
      }
      _scheduleNextBoundaryTimer();
    }
  }

  void _onSchedulesChangedFromReminder() {
    if (!mounted) return;
    setState(() {
      _schedules =
          MealReminderService.instance.todaySchedulesNotifier.value;
      _updateActiveSchedule();
      _scheduleNextBoundaryTimer();
    });
  }

  void _onPlanChangedFromReminder() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initializeData() async {
    final now = _mealService.now;
    _currentDate = now;

    // Muat jadwal awal
    final loadedSchedules = await _mealService.loadSchedules();
    _schedules = loadedSchedules;

    // Muat status harian per pengguna dan tanggal
    await _loadStatusForCurrentDate();
    _scheduleNextBoundaryTimer();
  }

  String _resolveUid() {
    return MealReminderService.instance.currentUid ??
        (AppState.of(context).currentUser.email.isNotEmpty
            ? AppState.of(context).currentUser.email
            : 'guest');
  }

  Future<void> _loadStatusForCurrentDate() async {
    final now = _mealService.now;
    final uid = _resolveUid();
    final loadedStatus =
        await _mealService.loadDailyStatus(now, uid: uid);

    if (mounted) {
      setState(() {
        _dailyStatus = loadedStatus;
        _updateActiveSchedule();
      });
    }
  }

  void _scheduleNextBoundaryTimer() {
    _boundaryTimer?.cancel();
    final now = _mealService.now;
    final nextBoundary = _mealService.getNextBoundary(now, _schedules);
    final duration =
        nextBoundary.difference(now) + const Duration(milliseconds: 500);

    _boundaryTimer = Timer(duration, () {
      _onBoundaryReached();
    });
  }

  void _onBoundaryReached() {
    final now = _mealService.now;
    if (now.day != _currentDate.day ||
        now.month != _currentDate.month ||
        now.year != _currentDate.year) {
      _currentDate = now;
      _loadStatusForCurrentDate();
    } else {
      if (mounted) {
        setState(() {
          _updateActiveSchedule();
        });
      }
    }
    _scheduleNextBoundaryTimer();
  }

  void _updateActiveSchedule() {
    final determined =
        _mealService.determineDisplayedSchedule(_schedules, _dailyStatus);
    _displayedSchedule = determined;

    final isActiveNow = determined != null &&
        _mealService.isMealInTimeRange(determined) &&
        !(_dailyStatus[determined.id]?.isCompleted ?? false);

    _mealService.updateAlarmState(determined, isActiveNow);
  }

  Future<void> _onMarkMealCompleted() async {
    final active = _displayedSchedule;
    if (active == null) return;
    final now = _mealService.now;
    final uid = _resolveUid();

    final updatedStatus = await _mealService.markMealCompleted(
      date: now,
      mealId: active.id,
      completedTime: now,
      uid: uid,
    );

    if (mounted) {
      setState(() {
        _dailyStatus = updatedStatus;
        _mealService.stopAlarm();
      });

      // Beri jeda 1.4 detik agar pengguna melihat status "Selesai ✓" sebelum beralih
      _postCompletionTransitionTimer?.cancel();
      _postCompletionTransitionTimer =
          Timer(const Duration(milliseconds: 1400), () {
        if (mounted) {
          setState(() {
            _updateActiveSchedule();
            _scheduleNextBoundaryTimer();
          });
        }
      });
    }
  }

  void _showNotMealTimeSnackBar(MealScheduleItem? schedule) {
    if (schedule == null) return;
    final startStr = schedule.startHour.toString().padLeft(2, '0');
    final startMinStr = schedule.startMinute.toString().padLeft(2, '0');
    final timeStr =
        startMinStr == '00' ? '$startStr.00' : '$startStr.$startMinStr';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Belum waktunya makan. Tersedia pukul $timeStr')),
    );
  }

  void _onPreviousDate() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 1));
      _loadStatusForCurrentDate();
    });
  }

  void _onNextDate() {
    final now = _mealService.now;
    final today = DateTime(now.year, now.month, now.day);
    final cur = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
    if (cur.isBefore(today)) {
      setState(() {
        _currentDate = _currentDate.add(const Duration(days: 1));
        _loadStatusForCurrentDate();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat memilih tanggal di masa mendatang.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final user = appState.currentUser;
    final now = _mealService.now;

    // Evaluasi jadwal aktif
    final activeSchedule = _displayedSchedule;
    final isCurrentCompleted = activeSchedule != null &&
        (_dailyStatus[activeSchedule.id]?.isCompleted ?? false);
    final isActiveNow = activeSchedule != null &&
        _mealService.isMealInTimeRange(activeSchedule) &&
        !isCurrentCompleted;

    // Cek apakah semua jadwal hari ini sudah lewat atau selesai
    final isAllDoneOrPast = _schedules.isNotEmpty &&
        _schedules.every(
          (s) =>
              (_dailyStatus[s.id]?.isCompleted ?? false) || s.isPast(now),
        );

    String statusText = '';
    if (_schedules.isEmpty) {
      statusText = 'Belum ada jadwal makan hari ini';
    } else if (isAllDoneOrPast && activeSchedule == null) {
      statusText = 'Semua jam makan hari ini sudah selesai';
    }

    const formalBgStart = Color(0xFFFCFBF7);
    const formalBgEnd = Color(0xFFF7F4EB);
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      backgroundColor: formalBgStart,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 520;

          final effectiveWidth =
              isLargeScreen ? 410.0 : constraints.maxWidth;
          final effectiveHeight = isLargeScreen
              ? (constraints.maxHeight.isFinite
                  ? constraints.maxHeight.clamp(0.0, 920.0)
                  : 880.0)
              : constraints.maxHeight;

          final effectiveTopInset =
              isLargeScreen ? 0.0 : viewPadding.top;

          final mainBody = Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  formalBgStart,
                  formalBgEnd,
                ],
              ),
            ),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: effectiveTopInset + 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Formal Header Bar (Avatar + Tanggal < Hari Ini, 15 Nov > + Lonceng)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: kHPad),
                          child: FormalHeaderBar(
                            userName: user.name,
                            photoUrl: _userPhotoUrl ?? FirebaseAuth.instance.currentUser?.photoURL,
                            currentDate: _currentDate,
                            onPreviousDate: _onPreviousDate,
                            onNextDate: _onNextDate,
                            onProfileTap: () async {
                              await Navigator.pushNamed(context, AppRoutes.userProfile);
                              if (mounted) {
                                _loadUserPhoto();
                              }
                            },
                            onNotificationTap: () {
                              Navigator.pushNamed(context, AppRoutes.userNotifications);
                            },
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Kartu Sapaan Formal (Narasi Halo & Maskot Lambung)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: kHPad),
                          child: FormalSapaanCard(userName: user.name),
                        ),
                        const SizedBox(height: 16),

                        // Formal Hero Card (Arc Meter + 3 Macro-style Meal Bars + Quick Action)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: kHPad),
                          child: FormalHeroCard(
                            schedules: _schedules,
                            dailyStatus: _dailyStatus,
                            activeSchedule: activeSchedule,
                            isActiveNow: isActiveNow,
                            isCurrentCompleted: isCurrentCompleted,
                            isAlarmRinging: _mealService.isAlarmRinging,
                            onMarkCompleted: _onMarkMealCompleted,
                            onDisabledTap: () =>
                                _showNotMealTimeSnackBar(activeSchedule),
                            statusText: statusText,
                            currentDate: now,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Menu Utama Grid 2x2 ala Referensi
                        const FormalMenuGrid(hPad: kHPad),
                        const SizedBox(height: 24),

                        // Seputar Edukasi & Informasi Lambung (Gastropedia & Berita)
                        FormalInfoSection(
                          hPad: kHPad,
                          onGastropediaTap: () {
                            Navigator.pushNamed(context, AppRoutes.gastropedia);
                          },
                          onBeritaTap: () {
                            Navigator.pushNamed(context, '/berita');
                          },
                        ),
                        const SizedBox(height: 48), // Bersih, tanpa bottom navigation bar!
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

          if (isLargeScreen) {
            return Scaffold(
              backgroundColor: const Color(0xFFECE7BE),
              body: Center(
                child: Container(
                  width: effectiveWidth,
                  height: effectiveHeight,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.12),
                      width: 3,
                    ),
                  ),
                  child: mainBody,
                ),
              ),
            );
          }

          return mainBody;
        },
      ),
    );
  }
}

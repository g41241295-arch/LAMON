import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../pengingat_jam_makan/models/meal_reminder_plan.dart';
import '../pengingat_jam_makan/services/meal_reminder_service.dart';
import 'beranda/models/meal_schedule_model.dart';
import 'beranda/services/beranda_meal_service.dart';
import 'beranda/widgets/header_section.dart';
import 'beranda/widgets/meal_alarm_card.dart';
import 'beranda/widgets/daily_summary_card.dart';
import 'beranda/widgets/main_menu_list.dart';
import 'beranda/widgets/info_cards_section.dart';

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

  void _navigateToPlaceholder(String title, String description) {
    Navigator.pushNamed(
      context,
      '/placeholder',
      arguments: {'title': title, 'description': description},
    );
  }

  void _onMainMenuTap(BerandaMenuItem menu) {
    switch (menu.id) {
      case 'catat-makananmu':
        Navigator.pushNamed(context, '/catat-makananmu');
        break;
      case 'ringkasan-makanan':
        Navigator.pushNamed(context, '/ringkasan-makanan');
        break;
      case 'prediksi-penyakit':
        Navigator.pushNamed(context, '/prediksi-penyakit');
        break;
      case 'konsul-dokter':
        Navigator.pushNamed(context, '/konsultasi');
        break;
      case 'pengingat-jam-makan':
      default:
        _navigateToPlaceholder(
          'Pengingat Jam Makan',
          menu.description,
        );
        break;
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

    // Evaluasi apakah pengguna sedang dalam masa istirahat sakit
    final plan = MealReminderService.instance.activePlanNotifier.value;
    final bool isSick = plan != null &&
        plan.enabled &&
        plan.condition == MealCondition.sakit &&
        plan.isDateActive(now);
    final int sleepHour = plan?.sleepHour ?? 20;

    const topYellow = Color(0xFFFDE88A);
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      backgroundColor: topYellow,
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

          final mainBody = Stack(
            children: [
              // 1) Warna dasar kuning
              const Positioned.fill(
                child: ColoredBox(color: topYellow),
              ),

              // 2) Latar polos (gradasi kuning dan blob, TANPA gadis) tetap diam di belakang
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bg_beranda_polos.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),

              // 3) Area scroll konten: CustomScrollView memenuhi seluruh layar
              Positioned.fill(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: effectiveTopInset + 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Chip
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kHPad),
                              child: HeaderChip(
                                userName: user.name,
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Kartu Sapaan
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kHPad),
                              child: SapaanCard(userName: user.name),
                            ),
                            const SizedBox(height: 20),

                            // Kartu Jam Makan Aktif
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kHPad),
                              child: MealAlarmCard(
                                schedule: activeSchedule,
                                isCompleted: isCurrentCompleted,
                                isActiveNow: isActiveNow,
                                isAlarmRinging: _mealService.isAlarmRinging,
                                onMarkCompleted: _onMarkMealCompleted,
                                onDisabledTap: () =>
                                    _showNotMealTimeSnackBar(activeSchedule),
                                statusText: statusText,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Ringkasan Hari Ini
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kHPad),
                              child: DailySummaryCard(
                                dailyStatus: _dailyStatus,
                                schedules: _schedules,
                                currentTime: now,
                                isSick: isSick,
                                sleepHour: sleepHour,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Menu Utama
                            MainMenuList(
                              hPad: kHPad,
                              onMenuTap: _onMainMenuTap,
                            ),
                            const SizedBox(height: 32),

                            // Seputar Informasi (Gastropedia & Berita)
                            InfoCardsSection(
                              hPad: kHPad,
                              onGastropediaTap: () {
                                Navigator.pushNamed(context, '/gastropedia');
                              },
                              onBeritaTap: () {
                                Navigator.pushNamed(context, '/berita');
                              },
                            ),

                          ],
                        ),
                      ),
                    ),
                    // Jarak antara kartu Berita Kesehatan dan kepala gadis ≈ 0.05 × lebar layar
                    SliverToBoxAdapter(
                      child: SizedBox(height: effectiveWidth * 0.05),
                    ),
                    // Ilustrasi gadis: langsung mengikuti konten, lebar penuh, dasar menempel akhir scroll
                    SliverToBoxAdapter(
                      child: Image.asset(
                        'assets/images/beranda_ilustrasi_makan_trim.png',
                        width: effectiveWidth,
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                    // Pada layar sangat tinggi: SliverFillRemaining HANYA sebagai penyangga kosong
                    // (tidak berisi gambar gadis, supaya gadis tetap dekat kartu di layar normal)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
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

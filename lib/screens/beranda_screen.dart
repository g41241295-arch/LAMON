import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import 'beranda/models/meal_schedule_model.dart';
import 'beranda/services/beranda_meal_service.dart';
import 'beranda/widgets/header_section.dart';
import 'beranda/widgets/meal_alarm_card.dart';
import 'beranda/widgets/daily_summary_card.dart';
import 'beranda/widgets/main_menu_list.dart';
import 'beranda/widgets/info_cards_section.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => BerandaScreenState();
}

class BerandaScreenState extends State<BerandaScreen> with WidgetsBindingObserver {
  final BerandaMealService _mealService = BerandaMealService();

  BerandaMealService get mealService => _mealService;

  void setDebugTime(DateTime? debugTime) {
    if (!kDebugMode) return;
    setState(() {
      _mealService.debugNow = debugTime;
      _updateActiveSchedule(_mealService.now);
    });
  }

  List<MealScheduleItem> _schedules = BerandaMealService.defaultSchedules;
  Map<String, MealDailyStatus> _dailyStatus = {};

  MealScheduleItem? _displayedSchedule;
  DateTime _currentDate = DateTime.now();
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();

    _tickerTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _onTick();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerTimer?.cancel();
    _mealService.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final now = _mealService.now;
    final loadedSchedules = await _mealService.loadSchedules();
    final loadedStatus = await _mealService.loadDailyStatus(now);

    if (mounted) {
      setState(() {
        _schedules = loadedSchedules;
        _dailyStatus = loadedStatus;
        _currentDate = now;
        _updateActiveSchedule(now);
      });
    }
  }

  void _onTick() {
    final now = _mealService.now;
    if (now.day != _currentDate.day || now.month != _currentDate.month || now.year != _currentDate.year) {
      _currentDate = now;
      _mealService.loadDailyStatus(now).then((freshStatus) {
        if (mounted) {
          setState(() {
            _dailyStatus = freshStatus;
            _updateActiveSchedule(now);
          });
        }
      });
      return;
    }
    _updateActiveSchedule(now);
  }

  void _updateActiveSchedule(DateTime now) {
    final determined = _mealService.determineDisplayedSchedule(_schedules, _dailyStatus);
    
    // Check all done?
    // Jika current time sudah lewat semua schedule hari ini dan semua sudah selesai atau lewat
    
    setState(() {
      _displayedSchedule = determined;
    });
  }

  Future<void> _onMarkMealCompleted() async {
    final active = _displayedSchedule;
    if (active == null) return;
    final now = _mealService.now;

    final updatedStatus = await _mealService.markMealCompleted(
      date: now,
      mealId: active.id,
      completedTime: now,
    );

    if (mounted) {
      setState(() {
        _dailyStatus = updatedStatus;
        _updateActiveSchedule(now);
      });
    }
  }

  void _showNotMealTimeSnackBar(MealScheduleItem schedule) {
    final startStr = schedule.startHour.toString().padLeft(2, '0');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Belum waktunya makan. Tersedia pukul $startStr.00')),
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
    final activeSchedule = _displayedSchedule ?? _schedules[1];
    final isCurrentCompleted = _dailyStatus[activeSchedule.id]?.isCompleted ?? false;
    final isActiveNow = _mealService.isMealInTimeRange(activeSchedule) && !isCurrentCompleted;

    final now = _mealService.now;
    final isAllDoneOrPast = _schedules.every(
      (s) => (_dailyStatus[s.id]?.isCompleted ?? false) || s.isPast(now),
    );

    String statusText = '';
    if (_schedules.isEmpty) {
      statusText = 'Belum ada jadwal makan hari ini';
    } else if (isAllDoneOrPast) {
      statusText = 'Semua jam makan hari ini sudah selesai';
    }

    const bool isSick = false;

    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    // Gambar dirender 1.25x lebar layar, gadis tetap utuh di sisi kanan
    final bgWidth = screenWidth * 1.25;
    const topYellow = Color(0xFFFDE88A);

    return Scaffold(
      backgroundColor: topYellow,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 520;

          final content = SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // 1) Warna dasar kuning agar tidak ada celah
                  const Positioned.fill(child: ColoredBox(color: topYellow)),

                  // 2) Latar + gadis: 1.25x lebar, menempel di ATAS bar navigasi
                  Positioned(
                    right: 0,
                    bottom: bottomInset,
                    width: bgWidth,
                    child: Image.asset(
                      'assets/images/bg_beranda.png',
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),

                  // 3) Konten utama
                  SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Header Chip
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: HeaderChip(
                            userName: user.name,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Kartu Sapaan
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SapaanCard(userName: user.name),
                        ),
                        const SizedBox(height: 20),

                        // Kartu Jam Makan Aktif
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: MealAlarmCard(
                            schedule: activeSchedule,
                            isCompleted: isCurrentCompleted,
                            isActiveNow: isActiveNow,
                            isAlarmRinging: _mealService.isAlarmRinging,
                            onMarkCompleted: _onMarkMealCompleted,
                            onDisabledTap: () => _showNotMealTimeSnackBar(activeSchedule),
                            statusText: statusText,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Ringkasan Hari Ini
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: DailySummaryCard(
                            dailyStatus: _dailyStatus,
                            activeMealId: activeSchedule.id,
                            isSick: isSick,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Menu Utama
                        MainMenuList(onMenuTap: _onMainMenuTap),
                        const SizedBox(height: 32),

                    // =========================================================
                    // 5. SECTION "SEPUTAR INFORMASI" (GASTROPEDIA & BERITA)
                    // =========================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InfoCardsSection(
                        onGastropediaTap: () {
                          Navigator.pushNamed(context, '/gastropedia');
                        },
                        onBeritaTap: () {
                          Navigator.pushNamed(context, '/berita');
                        },
                      ),
                    ),

                    // Padding bawah cukup ±24 dp + inset sistem (Revisi Poin 2)
                    SizedBox(height: 24 + bottomInset),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

          // Jika dibuka pada browser desktop atau layar lebar, tampilkan bingkai mobile
          if (isLargeScreen) {
            final maxH = constraints.maxHeight.isFinite
                ? constraints.maxHeight.clamp(0.0, 920.0)
                : 880.0;
            return Scaffold(
              backgroundColor: const Color(0xFFECE7BE),
              body: Center(
                child: Container(
                  width: 410,
                  height: maxH,
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
                  child: content,
                ),
              ),
            );
          }

          return content;
        },
      ),
    );
  }
}

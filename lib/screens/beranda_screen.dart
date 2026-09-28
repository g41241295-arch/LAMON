import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_state.dart';
import 'beranda/models/meal_schedule_model.dart';
import 'beranda/services/beranda_meal_service.dart';
import 'beranda/widgets/header_section.dart';
import 'beranda/widgets/meal_alarm_card.dart';
import 'beranda/widgets/daily_summary_card.dart';
import 'beranda/widgets/main_menu_list.dart';
import 'beranda/widgets/info_cards_section.dart';

/// Halaman Beranda utama aplikasi LAMON (Lambung Awareness & Monitoring)
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => BerandaScreenState();
}

class BerandaScreenState extends State<BerandaScreen> {
  final BerandaMealService _mealService = BerandaMealService();

  List<MealScheduleItem> _schedules = BerandaMealService.defaultSchedules;
  Map<String, MealDailyStatus> _dailyStatus = {
    'breakfast': const MealDailyStatus(isCompleted: true, actualTime: '08.00'),
    'lunch': const MealDailyStatus(isCompleted: false, actualTime: null),
    'dinner': const MealDailyStatus(isCompleted: false, actualTime: null),
  };

  MealScheduleItem? _displayedSchedule;
  DateTime _currentDate = DateTime.now();
  Timer? _tickerTimer;
  Timer? _transitionTimer;
  bool _isTransitioningNextMeal = false;

  /// Getter untuk service (berguna untuk testing / debug override)
  BerandaMealService get mealService => _mealService;

  /// Metode pembantu untuk pengujian debug jam alarm
  void setDebugTime(DateTime? debugTime) {
    if (!kDebugMode) return;
    setState(() {
      _mealService.debugNow = debugTime;
      _updateActiveSchedule(_mealService.now);
    });
  }

  @override
  void initState() {
    super.initState();
    _checkRoleGuard();
    _initializeData();

    // Timer per 1 detik untuk memantau jam perangkat secara realtime
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTick();
    });
  }

  /// Redirect dokter ke dashboard dokter jika login sebagai role dokter
  void _checkRoleGuard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final role = doc.data()?['role'] as String?;
          if ((role == 'doctor' || role == 'dokter') && mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/dokter', (route) => false);
          }
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _transitionTimer?.cancel();
    _mealService.dispose();
    super.dispose();
  }

  /// Memuat jadwal dari penyimpanan lokal (shared_preferences) & status harian tervalidasi
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

  /// Pengecekan realtime setiap detik
  void _onTick() {
    final now = _mealService.now;

    // Reset otomatis saat pergantian tanggal (ganti hari)
    if (now.day != _currentDate.day ||
        now.month != _currentDate.month ||
        now.year != _currentDate.year) {
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

  /// Menentukan jadwal yang aktif dan status alarm berdasarkan waktu sekarang
  void _updateActiveSchedule(DateTime now) {
    if (_isTransitioningNextMeal) return;

    final determined = _mealService.determineDisplayedSchedule(_schedules, _dailyStatus);
    final isInRange = _mealService.isMealInTimeRange(determined);
    final isDone = _dailyStatus[determined.id]?.isCompleted ?? false;

    // Alarm dan efek bergetar HANYA aktif saat waktu berada dalam rentang jam makan dan belum ditandai
    if (isInRange && !isDone) {
      if (!_mealService.isAlarmRinging) {
        _mealService.startAlarm();
      }
    } else {
      if (_mealService.isAlarmRinging) {
        _mealService.stopAlarm();
      }
    }

    if (_displayedSchedule?.id != determined.id) {
      setState(() {
        _displayedSchedule = determined;
      });
    }
  }

  /// Aksi ketika pengguna menekan tombol "Tandai selesai"
  Future<void> _onMarkMealCompleted() async {
    final active = _displayedSchedule;
    if (active == null) return;

    final now = _mealService.now;

    // Cek apakah waktu saat ini sah untuk jam makan ini
    if (!_mealService.isMealInTimeRange(active)) {
      _showNotMealTimeSnackBar(active);
      return;
    }

    _mealService.stopAlarm();

    // Simpan status selesai harian
    final updatedStatus = await _mealService.markMealCompleted(
      date: now,
      mealId: active.id,
      completedTime: now,
    );

    if (mounted) {
      setState(() {
        _dailyStatus = updatedStatus;
        _isTransitioningNextMeal = true;
      });

      // Animasi transisi otomatis berpindah ke jadwal jam makan berikutnya
      _transitionTimer?.cancel();
      _transitionTimer = Timer(const Duration(milliseconds: 1400), () {
        if (!mounted) return;

        final nextSchedule = _mealService.determineDisplayedSchedule(
          _schedules,
          updatedStatus,
        );

        setState(() {
          _displayedSchedule = nextSchedule;
          _isTransitioningNextMeal = false;
        });
      });
    }
  }

  /// Tampilkan SnackBar singkat bila tombol ditekan sebelum waktunya
  void _showNotMealTimeSnackBar(MealScheduleItem schedule) {
    final startStr = schedule.startHour.toString().padLeft(2, '0');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Belum waktunya makan. Tersedia pukul $startStr.00',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Navigasi ke placeholder screen
  void _navigateToPlaceholder(String title, String description) {
    Navigator.pushNamed(
      context,
      '/placeholder',
      arguments: {
        'title': title,
        'description': description,
      },
    );
  }

  /// Navigasi untuk kartu-kartu Menu Utama
  void _onMainMenuTap(BerandaMenuItem menu) {
    if (menu.route == '/prediksi-penyakit' || menu.id == 'prediksi-penyakit') {
      Navigator.pushNamed(context, '/prediksi-penyakit');
      return;
    }
    if (menu.route == '/catat-makananmu' || menu.id == 'catat-makananmu') {
      Navigator.pushNamed(context, '/catat-makananmu');
      return;
    }
    if (menu.route == '/ringkasan-makanan' || menu.id == 'ringkasan-makanan') {
      Navigator.pushNamed(context, '/ringkasan-makanan');
      return;
    }
    if (menu.route == '/konsul-dokter' || menu.id == 'konsul-dokter' || menu.route == '/konsultasi') {
      Navigator.pushNamed(context, '/konsultasi');
      return;
    }
    _navigateToPlaceholder(
      menu.title.replaceAll('\n', ' '),
      menu.description,
    );
  }


  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final user = appState.currentUser;
    final activeSchedule = _displayedSchedule ?? _schedules[1];
    final isCurrentCompleted = _dailyStatus[activeSchedule.id]?.isCompleted ?? false;
    final isActiveNow = _mealService.isMealInTimeRange(activeSchedule) && !isCurrentCompleted;

    // Hitung safe area bawah perangkat
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 520;

        Widget content = Container(
          // Background gambar layar penuh sesuai gambar desain yang dilampirkan
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background_beranda.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            // HAPUS bottom navigation bar dari tampilan Beranda sesuai Revisi Poin 1
            body: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // =========================================================
                    // 1 & 2. HEADER SAPAAN + LOGO MASKOT + KARTU ALARM JAM MAKAN
                    // Maskot menumpuk di atas tepi atas kartu alarm (Stack Clip.none)
                    // =========================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Layer 1: Teks Header & Kartu Alarm Jam Makan
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Sapaan Kiri Atas
                              Padding(
                                padding: const EdgeInsets.only(right: 125),
                                child: HeaderGreeting(userName: user.name),
                              ),
                              const SizedBox(height: 14),

                              // Kartu Alarm Jam Makan
                              MealAlarmCard(
                                schedule: activeSchedule,
                                isCompleted: isCurrentCompleted,
                                isActiveNow: isActiveNow,
                                isAlarmRinging: _mealService.isAlarmRinging,
                                onMarkCompleted: _onMarkMealCompleted,
                                onDisabledTap: () => _showNotMealTimeSnackBar(activeSchedule),
                              ),
                            ],
                          ),

                          // Layer 2: Maskot Lambung Beranimasi (Urutan Stack paling atas)
                          const Positioned(
                            top: 2,
                            right: -2,
                            child: AnimatedMascotLogo(size: 152),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =========================================================
                    // 3. KARTU "RINGKASAN HARI INI" (TIMELINE)
                    // =========================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DailySummaryCard(
                        dailyStatus: _dailyStatus,
                        activeMealId: activeSchedule.id,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // =========================================================
                    // 4. SECTION "MENU UTAMA" (HORIZONTAL SCROLL / FULL-BLEED)
                    // Dibiarkan full-width agar kartu terpotong di tepi layar HP
                    // =========================================================
                    MainMenuList(
                      onMenuTap: _onMainMenuTap,
                    ),

                    const SizedBox(height: 22),

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
    );
  }
}

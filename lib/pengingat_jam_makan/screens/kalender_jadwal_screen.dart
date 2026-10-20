import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_reminder_plan.dart';
import '../widgets/calendar_header_illustration.dart';
import '../widgets/glass_container.dart';
import 'atur_jam_makan_screen.dart';

// Konstanta ukuran kalender (skala desain 390dp)
const double kCalCellW = 36; // lebar kotak (dp)
const double kCalCellH = 36; // tinggi kotak
const double kCalRowGapMin = 14; // jarak antar baris minimum
const double kCalRowGapMax = 20; // jarak antar baris maksimum
const double kCalFont = 14; // ukuran angka (sp)
const double kCalRadius = 8; // radius sudut kotak

/// Layar 2: Kalender Jadwal Harian (Proporsi 50/50 Seimbang, Kotak Lega)
class KalenderJadwalScreen extends StatefulWidget {
  final MealCondition condition;

  const KalenderJadwalScreen({
    super.key,
    required this.condition,
  });

  @override
  State<KalenderJadwalScreen> createState() => _KalenderJadwalScreenState();
}

class _KalenderJadwalScreenState extends State<KalenderJadwalScreen>
    with WidgetsBindingObserver {
  late DateTime _currentMonth;
  late DateTime _tomorrow;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate; // Khusus kondisi sakit (rentang tanggal)
  Timer? _midnightTimer;

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _weekDayHeaders = [
    'S',
    'S',
    'R',
    'K',
    'J',
    'S',
    'M'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _updateDates();
    _scheduleMidnightCheck();
  }

  void _updateDates() {
    final now = DateTime.now();
    _tomorrow = DateTime(now.year, now.month, now.day + 1);

    // Otomatis membuka bulan dan tanggal BESOK (hari ini + 1)
    _currentMonth = DateTime(_tomorrow.year, _tomorrow.month, 1);
    _selectedStartDate = _tomorrow;
    if (widget.condition == MealCondition.sakit) {
      _selectedEndDate = _tomorrow;
    }
  }

  void _scheduleMidnightCheck() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final diff = nextMidnight.difference(now) + const Duration(seconds: 1);

    _midnightTimer = Timer(diff, () {
      if (!mounted) return;
      final freshNow = DateTime.now();
      final freshToday = DateTime(freshNow.year, freshNow.month, freshNow.day);

      setState(() {
        _tomorrow = freshToday.add(const Duration(days: 1));

        if (_selectedStartDate != null &&
            !_selectedStartDate!.isAfter(freshToday)) {
          _selectedStartDate = null;
          _selectedEndDate = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tanggal sudah lewat, silakan pilih ulang.'),
            ),
          );
        }
      });
      _scheduleMidnightCheck();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      setState(() {
        _tomorrow = today.add(const Duration(days: 1));
        if (_selectedStartDate != null && !_selectedStartDate!.isAfter(today)) {
          _selectedStartDate = null;
          _selectedEndDate = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tanggal sudah lewat, silakan pilih ulang.'),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _onDateTapped(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!date.isAfter(today)) return;

    if (widget.condition == MealCondition.sehat) {
      setState(() {
        _selectedStartDate = date;
      });
      _navigateToAturJamMakan(startDate: date, endDate: date);
    } else {
      setState(() {
        if (_selectedStartDate == null) {
          _selectedStartDate = date;
          _selectedEndDate = date;
        } else if (_selectedEndDate == null ||
            _selectedStartDate == _selectedEndDate) {
          if (date.isBefore(_selectedStartDate!)) {
            _selectedStartDate = date;
            _selectedEndDate = date;
          } else {
            _selectedEndDate = date;
          }
        } else {
          _selectedStartDate = date;
          _selectedEndDate = date;
        }
      });
    }
  }

  Future<void> _navigateToAturJamMakan({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AturJamMakanScreen(
          condition: widget.condition,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHealthy = widget.condition == MealCondition.sehat;

    final panelBgColors = isHealthy
        ? [const Color(0xFFFEF08A), const Color(0xFFFEF9C3)]
        : [const Color(0xFFC7D2FE), const Color(0xFFDDD6FE)];

    final primaryTextColor =
        isHealthy ? const Color(0xFF1E3A8A) : const Color(0xFF6F3F1E);
    final boxBgColor = isHealthy ? Colors.white : const Color(0xFFFFFBEB);
    final boxTextColor =
        isHealthy ? const Color(0xFF1E3A8A) : const Color(0xFF7C2D12);

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: panelBgColors.last,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final H = constraints.maxHeight;
          final W = constraints.maxWidth;
          final s = W / 390.0;

          // 1. Ukuran Kotak Tanggal Tetap (Terkalibrasi Skala Layar 390dp)
          final double cellW = kCalCellW * s;
          double cellH = kCalCellH * s;
          final double cellRadius = kCalRadius * s;
          final double fontSize = kCalFont * s;

          // 2. Perhitungan Jumlah Baris Minggu Bulan Ini
          final firstDayOfMonth =
              DateTime(_currentMonth.year, _currentMonth.month, 1);
          final daysInMonth =
              DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
          final firstDayWeekdayOffset = firstDayOfMonth.weekday - 1;
          final totalSlots = firstDayWeekdayOffset + daysInMonth;
          final numRows = (totalSlots / 7).ceil();

          // 3. Proporsi Awal 50% Header & Overlap 28dp
          double headerRatio = 0.50;
          const double overlap = 28.0;
          double headerHeight = H * headerRatio;
          double panelHeight = H - headerHeight + overlap;

          // Komponen tetap di dalam panel
          const double panelPaddingTop = 20.0;
          const double monthBarHeight = 44.0;
          const double gap1 = 12.0;
          const double weekdayHeaderHeight = 24.0;
          const double gap2 = 8.0;
          const double topSectionHeight = panelPaddingTop +
              monthBarHeight +
              gap1 +
              weekdayHeaderHeight +
              gap2;

          final double panelPaddingBottom = 16.0 + bottomInset;
          final double extraBottomHeight = (!isHealthy) ? 52.0 : 0.0;

          double availGridH = panelHeight -
              topSectionHeight -
              panelPaddingBottom -
              extraBottomHeight;

          final double minRowGap = kCalRowGapMin * s;
          final double maxRowGap = kCalRowGapMax * s;

          // 4. Adaptasi Layar Sangat Pendek (turunkan header ke 42%, lalu cellH sampai min 32)
          if (availGridH < numRows * cellH + minRowGap * (numRows - 1)) {
            headerRatio = 0.42;
            headerHeight = H * headerRatio;
            panelHeight = H - headerHeight + overlap;
            availGridH = panelHeight -
                topSectionHeight -
                panelPaddingBottom -
                extraBottomHeight;

            if (availGridH < numRows * cellH + minRowGap * (numRows - 1)) {
              cellH = max(
                  32.0 * s, (availGridH - minRowGap * (numRows - 1)) / numRows);
            }
          }

          // 5. Jarak Antar Baris: Mengisi sisa tinggi secara seimbang (clamp minRowGap s/d maxRowGap)
          final double calculatedGap = numRows > 1
              ? (availGridH - numRows * cellH) / (numRows - 1)
              : maxRowGap;
          final double rowGap = calculatedGap.clamp(minRowGap, maxRowGap);

          return Stack(
            children: [
              // 1. Ilustrasi Header (50% tinggi layar, penuh ke tepi atas)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: headerHeight,
                child: CalendarHeaderIllustration(
                  condition: widget.condition,
                  monthNumber: _currentMonth.month,
                  onBack: () => Navigator.pop(context),
                  height: headerHeight,
                ),
              ),

              // 2. Panel Kalender (overlap 28dp, memanjang penuh sampai dasar layar tanpa celah)
              Positioned(
                top: headerHeight - overlap,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: panelBgColors,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 14,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    panelPaddingTop,
                    16,
                    panelPaddingBottom,
                  ),
                  child: Column(
                    children: [
                      // Baris Atas Panel: "Bulan, Tahun" & Tombol Panah
                      SizedBox(
                        height: monthBarHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_monthNames[_currentMonth.month - 1]}, ${_currentMonth.year}',
                              style: GoogleFonts.poppins(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                            Row(
                              children: [
                                _buildArrowButton(
                                  icon: Icons.chevron_left,
                                  onTap: _goToPreviousMonth,
                                  color: primaryTextColor,
                                ),
                                const SizedBox(width: 8),
                                _buildArrowButton(
                                  icon: Icons.chevron_right,
                                  onTap: _goToNextMonth,
                                  color: primaryTextColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: gap1),

                      // Header Hari (S S R K J S M) sejajar persis dengan kolom tanggal
                      SizedBox(
                        height: weekdayHeaderHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _weekDayHeaders.map((day) {
                            return SizedBox(
                              width: cellW,
                              child: Center(
                                child: Text(
                                  day,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5 * s,
                                    fontWeight: FontWeight.w700,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: gap2),

                      // Grid Tanggal Kalender (7 Kolom Rata, Kotak Lega)
                      Expanded(
                        child: _buildCalendarGrid(
                          firstDayWeekdayOffset: firstDayWeekdayOffset,
                          daysInMonth: daysInMonth,
                          numRows: numRows,
                          cellW: cellW,
                          cellH: cellH,
                          cellRadius: cellRadius,
                          rowGap: rowGap,
                          fontSize: fontSize,
                          boxBgColor: boxBgColor,
                          boxTextColor: boxTextColor,
                          isHealthy: isHealthy,
                        ),
                      ),

                      // Tombol "Lanjut" Khusus Varian Sakit
                      if (!isHealthy)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: GlassContainer(
                            borderRadius: 22,
                            height: 44,
                            width: double.infinity,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.92),
                            border: Border.all(
                              color: const Color(0xFFC7D2FE),
                              width: 1.5,
                            ),
                            shadows: [
                              BoxShadow(
                                color: const Color(0xFF7C2D12)
                                    .withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            onTap: () {
                              if (_selectedStartDate != null &&
                                  _selectedEndDate != null) {
                                _navigateToAturJamMakan(
                                  startDate: _selectedStartDate!,
                                  endDate: _selectedEndDate!,
                                );
                              }
                            },
                            child: Center(
                              child: Text(
                                'Lanjut',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7C2D12),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.65),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildCalendarGrid({
    required int firstDayWeekdayOffset,
    required int daysInMonth,
    required int numRows,
    required double cellW,
    required double cellH,
    required double cellRadius,
    required double rowGap,
    required double fontSize,
    required Color boxBgColor,
    required Color boxTextColor,
    required bool isHealthy,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Widget> rowWidgets = [];

    for (int row = 0; row < numRows; row++) {
      List<Widget> cellWidgets = [];
      for (int col = 0; col < 7; col++) {
        final slotIndex = row * 7 + col;
        final dayNumber = slotIndex - firstDayWeekdayOffset + 1;

        if (dayNumber < 1 || dayNumber > daysInMonth) {
          // Kotak kosong penyeimbang kolom
          cellWidgets.add(SizedBox(width: cellW, height: cellH));
        } else {
          final cellDate =
              DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
          final isDisabled = !cellDate.isAfter(today);

          final isSelectedStart = _selectedStartDate != null &&
              cellDate.isAtSameMomentAs(_selectedStartDate!);
          final isSelectedEnd = _selectedEndDate != null &&
              cellDate.isAtSameMomentAs(_selectedEndDate!);
          final isInRange = !isHealthy &&
              _selectedStartDate != null &&
              _selectedEndDate != null &&
              cellDate.isAfter(_selectedStartDate!) &&
              cellDate.isBefore(_selectedEndDate!);

          final isSelected = isSelectedStart || isSelectedEnd || isInRange;

          cellWidgets.add(
            GestureDetector(
              onTap: isDisabled ? null : () => _onDateTapped(cellDate),
              child: Container(
                width: cellW,
                height: cellH,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? boxBgColor.withValues(alpha: 0.42)
                      : (isSelected
                          ? (isHealthy
                              ? const Color(0xFFBAE6FD)
                              : const Color(0xFFFED7AA))
                          : boxBgColor),
                  borderRadius: BorderRadius.circular(cellRadius),
                  border: Border.all(
                    color: isSelected
                        ? (isHealthy
                            ? const Color(0xFF276F8F)
                            : const Color(0xFFC2410C))
                        : (cellDate.isAtSameMomentAs(_tomorrow)
                            ? const Color(0xFF276F8F).withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.9)),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: [
                    if (!isDisabled)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 3,
                        offset: const Offset(0, 1.5),
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: isDisabled
                          ? boxTextColor.withValues(alpha: 0.35)
                          : (isSelected
                              ? (isHealthy
                                  ? const Color(0xFF1E3A8A)
                                  : const Color(0xFF7C2D12))
                              : boxTextColor),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }

      rowWidgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: row < numRows - 1 ? rowGap : 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: cellWidgets,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: rowWidgets,
    );
  }
}

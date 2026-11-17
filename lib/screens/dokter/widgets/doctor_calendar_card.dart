import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/doctor_theme.dart';
import '../../../utils/app_date_formatter.dart';
import '../pilih_jam_praktik_screen.dart';

/// Widget Kalender Bulanan Praktik Dokter bergaya formal, bersih, dan profesional.
class DoctorCalendarCard extends StatefulWidget {
  final String doctorId;
  final Map<String, List<String>> scheduleMap;

  const DoctorCalendarCard({
    super.key,
    required this.doctorId,
    required this.scheduleMap,
  });

  @override
  State<DoctorCalendarCard> createState() => _DoctorCalendarCardState();
}

class _DoctorCalendarCardState extends State<DoctorCalendarCard> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthTitle = AppDateFormatter.formatMonthYear(_currentMonth);

    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1=Senin
    final leadingEmpty = firstDayWeekday - 1; // 0 jika Senin

    return Container(
      decoration: DoctorTheme.cardDecoration(
        color: Colors.white,
        borderColor: DoctorTheme.cardBorder,
        borderRadius: 20,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Header Bulan & Panah Navigasi ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthTitle,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: DoctorTheme.primaryText,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: DoctorTheme.primaryText),
                    onPressed: _previousMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Bulan sebelumnya',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: DoctorTheme.primaryText),
                    onPressed: _nextMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Bulan berikutnya',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Header Nama Hari: S S R K J S M (Mulai Senin) ──
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DayHeader(label: 'S'),
              _DayHeader(label: 'S'),
              _DayHeader(label: 'R'),
              _DayHeader(label: 'K'),
              _DayHeader(label: 'J'),
              _DayHeader(label: 'S'),
              _DayHeader(label: 'M'),
            ],
          ),
          const SizedBox(height: 8),

          // ── Grid Tanggal ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmpty + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmpty) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - leadingEmpty + 1;
              final cellDate = DateTime(
                  _currentMonth.year, _currentMonth.month, dayNumber);
              final isPast = cellDate.isBefore(today);
              final isToday = cellDate.isAtSameMomentAs(today);
              final dateKey = AppDateFormatter.formatDateKey(cellDate);
              final hasSchedule =
                  widget.scheduleMap[dateKey]?.isNotEmpty ?? false;
              final slotCount = widget.scheduleMap[dateKey]?.length ?? 0;

              return GestureDetector(
                onTap: () {
                  if (isPast) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tanggal sudah lewat'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PilihJamPraktikScreen(
                          doctorId: widget.doctorId,
                          date: cellDate,
                          initialSlots:
                              widget.scheduleMap[dateKey] ?? <String>[],
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday
                          ? DoctorTheme.primary
                          : (hasSchedule
                              ? DoctorTheme.primaryLight.withValues(alpha: 0.45)
                              : const Color(0xFFF1F5F9)),
                      width: isToday ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Angka Tanggal
                      Text(
                        '$dayNumber',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isPast
                              ? DoctorTheme.neutralGray.withValues(alpha: 0.4)
                              : (isToday
                                  ? DoctorTheme.primary
                                  : DoctorTheme.primaryText),
                        ),
                      ),

                      // Penanda Titik / Indikator Slot
                      if (hasSchedule)
                        Positioned(
                          bottom: 4,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              slotCount.clamp(1, 3),
                              (i) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: DoctorTheme.accentOrange, // Aksen oranye tenang
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;
  const _DayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: DoctorTheme.secondaryText,
          ),
        ),
      ),
    );
  }
}

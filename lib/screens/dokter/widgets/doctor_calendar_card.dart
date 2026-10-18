import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/app_date_formatter.dart';
import '../pilih_jam_praktik_screen.dart';

/// Widget Kalender Bulanan Praktik Dokter buatan sendiri tanpa dependency eksternal.
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
      decoration: BoxDecoration(
        color: const Color(0xFFE2F0F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7E2F2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: AppColors.primaryText),
                    onPressed: _previousMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Bulan sebelumnya',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primaryText),
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
                          ? AppColors.primary
                          : (hasSchedule
                              ? const Color(0xFF76A8D0)
                              : Colors.transparent),
                      width: isToday ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
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
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isPast
                              ? AppColors.neutralGray.withValues(alpha: 0.4)
                              : (isToday
                                  ? AppColors.primary
                                  : AppColors.primaryText),
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
                                  color: Color(0xFFE5983A), // Aksen oranye
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.summaryCardSubtext,
          ),
        ),
      ),
    );
  }
}

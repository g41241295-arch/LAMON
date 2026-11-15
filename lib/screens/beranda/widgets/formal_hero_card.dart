import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../models/meal_schedule_model.dart';

class FormalHeroCard extends StatefulWidget {
  final List<MealScheduleItem> schedules;
  final Map<String, MealDailyStatus> dailyStatus;
  final MealScheduleItem? activeSchedule;
  final bool isActiveNow;
  final bool isCurrentCompleted;
  final bool isAlarmRinging;
  final VoidCallback onMarkCompleted;
  final VoidCallback onDisabledTap;
  final String statusText;
  final DateTime currentDate;

  const FormalHeroCard({
    super.key,
    required this.schedules,
    required this.dailyStatus,
    required this.activeSchedule,
    required this.isActiveNow,
    required this.isCurrentCompleted,
    required this.isAlarmRinging,
    required this.onMarkCompleted,
    required this.onDisabledTap,
    this.statusText = '',
    required this.currentDate,
  });

  @override
  State<FormalHeroCard> createState() => _FormalHeroCardState();
}

class _FormalHeroCardState extends State<FormalHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _wobbleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _wobbleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.12)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.12, end: -0.12)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.12, end: 0.12)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.12, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 70,
      ),
    ]).animate(_controller);

    if (widget.isActiveNow) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(FormalHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveNow != oldWidget.isActiveNow) {
      if (widget.isActiveNow) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hitung total dan jumlah makan yang selesai
    final totalMeals = widget.schedules.isNotEmpty ? widget.schedules.length : 3;
    final completedCount = widget.schedules.where((s) {
      return widget.dailyStatus[s.id]?.isCompleted ?? false;
    }).length;

    final progressRatio = totalMeals > 0 ? (completedCount / totalMeals) : 0.0;

    // Evaluasi 3 sesi utama (Sarapan, Siang, Malam)
    final breakfastSchedule = widget.schedules.firstWhere(
      (s) => s.id == 'breakfast',
      orElse: () => const MealScheduleItem(
        id: 'breakfast',
        title: 'Sarapan',
        displayTitle: 'Jam sarapan',
        startHour: 6,
        startMinute: 0,
        endHour: 8,
        endMinute: 0,
      ),
    );

    final lunchSchedule = widget.schedules.firstWhere(
      (s) => s.id == 'lunch',
      orElse: () => const MealScheduleItem(
        id: 'lunch',
        title: 'Makan siang',
        displayTitle: 'Jam makan siang',
        startHour: 12,
        startMinute: 0,
        endHour: 13,
        endMinute: 0,
      ),
    );

    final dinnerSchedule = widget.schedules.firstWhere(
      (s) => s.id == 'dinner',
      orElse: () => const MealScheduleItem(
        id: 'dinner',
        title: 'Makan malam',
        displayTitle: 'Jam makan malam',
        startHour: 18,
        startMinute: 0,
        endHour: 19,
        endMinute: 0,
      ),
    );

    final isAllCompleted = completedCount == totalMeals && totalMeals > 0;
    final active = widget.activeSchedule;
    final showAllDone = isAllCompleted || (widget.statusText.isNotEmpty && active == null);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B556E), // Deep Teal LAMON
            Color(0xFF276F8F), // Primary Teal LAMON
            Color(0xFF3885A8), // Light Teal LAMON
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B556E).withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        children: [
          // Row 1: Arc Progress Gauge (Kiri) + 3 Meal Sessions Breakdown (Kanan)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Arc Progress Gauge ala Referensi
              SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(104, 104),
                      painter: _ArcGaugePainter(
                        progress: progressRatio,
                        trackColor: Colors.white.withValues(alpha: 0.18),
                        progressColor: isAllCompleted
                            ? const Color(0xFF4EBFB3) // Mint lambung
                            : const Color(0xFFFFF092), // Warm soft gold
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$completedCount/$totalMeals',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAllCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.local_fire_department_rounded,
                              size: 11,
                              color: isAllCompleted
                                  ? const Color(0xFF7DE6D6)
                                  : const Color(0xFFFFCC66),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isAllCompleted ? 'Lengkap' : 'Jadwal',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 18),

              // Sisi Kanan: Bar Sesi Sarapan, Siang, Malam (ala Macro Bar di Referensi)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMealSessionRow(
                      name: 'Sarapan',
                      time: breakfastSchedule.timeRangeString,
                      isDone: widget.dailyStatus[breakfastSchedule.id]?.isCompleted ?? false,
                      isActive: breakfastSchedule.isCurrentTimeInRange(widget.currentDate),
                    ),
                    const SizedBox(height: 10),
                    _buildMealSessionRow(
                      name: 'Makan Siang',
                      time: lunchSchedule.timeRangeString,
                      isDone: widget.dailyStatus[lunchSchedule.id]?.isCompleted ?? false,
                      isActive: lunchSchedule.isCurrentTimeInRange(widget.currentDate),
                    ),
                    const SizedBox(height: 10),
                    _buildMealSessionRow(
                      name: 'Makan Malam',
                      time: dinnerSchedule.timeRangeString,
                      isDone: widget.dailyStatus[dinnerSchedule.id]?.isCompleted ?? false,
                      isActive: dinnerSchedule.isCurrentTimeInRange(widget.currentDate),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider halus
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),

          const SizedBox(height: 12),

          // Row 2: Status Jam Makan & Tombol Aksi Cepat
          if (showAllDone) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF86EFAC),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Semua jadwal makan hari ini telah selesai.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (active != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _wobbleAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: widget.isActiveNow ? _wobbleAnimation.value : 0.0,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alarm_rounded,
                        color: Color(0xFFFDE88A),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active.displayTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          active.timeRangeString,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Aksi "Tandai Selesai"
                  GestureDetector(
                    onTap: widget.isCurrentCompleted
                        ? null
                        : (widget.isActiveNow
                            ? widget.onMarkCompleted
                            : widget.onDisabledTap),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isCurrentCompleted
                            ? const Color(0xFF27AE60)
                            : (widget.isActiveNow
                                ? AppColors.orangeAccent
                                : Colors.white.withValues(alpha: 0.35)),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: widget.isActiveNow
                            ? [
                                BoxShadow(
                                  color: AppColors.orangeAccent.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isCurrentCompleted) ...[
                            const Icon(Icons.check, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            widget.isCurrentCompleted
                                ? 'Selesai ✓'
                                : (widget.isActiveNow
                                    ? 'Tandai Selesai'
                                    : 'Belum Waktunya'),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealSessionRow({
    required String name,
    required String time,
    required bool isDone,
    required bool isActive,
  }) {
    Color barColor;
    Color statusTextColor;
    String statusLabel;

    if (isDone) {
      barColor = const Color(0xFF4EBFB3); // Mint LAMON
      statusTextColor = const Color(0xFF86EFAC); // Soft green
      statusLabel = 'Selesai ✓';
    } else if (isActive) {
      barColor = AppColors.orangeAccent;
      statusTextColor = const Color(0xFFFFD599);
      statusLabel = 'Aktif Sekarang';
    } else {
      barColor = Colors.white.withValues(alpha: 0.22);
      statusTextColor = Colors.white.withValues(alpha: 0.65);
      statusLabel = time;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              statusLabel,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: statusTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: isDone ? 1.0 : (isActive ? 0.65 : 0.0),
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Painter untuk Arc Gauge 240 derajat
class _ArcGaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _ArcGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = 135 * (math.pi / 180);
    const sweepAngleTotal = 270 * (math.pi / 180);

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngleTotal,
      false,
      trackPaint,
    );

    // Active Arc
    final clampedProgress = progress.clamp(0.0, 1.0);
    if (clampedProgress > 0) {
      final activePaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngleTotal * clampedProgress,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}


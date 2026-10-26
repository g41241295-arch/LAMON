import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_schedule_model.dart';

class MealAlarmCard extends StatefulWidget {
  final MealScheduleItem? schedule;
  final bool isCompleted;
  final bool isActiveNow;
  final bool isAlarmRinging;
  final VoidCallback onMarkCompleted;
  final VoidCallback onDisabledTap;
  final String statusText;

  const MealAlarmCard({
    super.key,
    required this.schedule,
    required this.isCompleted,
    required this.isActiveNow,
    required this.isAlarmRinging,
    required this.onMarkCompleted,
    required this.onDisabledTap,
    this.statusText = '',
  });

  @override
  State<MealAlarmCard> createState() => _MealAlarmCardState();
}

class _MealAlarmCardState extends State<MealAlarmCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _wobbleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Rotasi kecil bolak-balik ±8 derajat (±0.14 radian), berulang tiap ±1,5 detik
    _wobbleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.14)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.14, end: -0.14)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.14, end: 0.14)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.14, end: -0.14)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.14, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 60, // jeda diam
      ),
    ]).animate(_controller);

    if (widget.isActiveNow) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(MealAlarmCard oldWidget) {
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
    final schedule = widget.schedule;
    final showAllDone = widget.statusText.isNotEmpty || schedule == null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/card_jam_aktif_bg.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _wobbleAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: widget.isActiveNow ? _wobbleAnimation.value : 0.0,
                child: child,
              );
            },
            child: Image.asset(
              'assets/images/clock-card1.png',
              width: 64,
              height: 64,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.alarm, color: Colors.white, size: 64),
            ),
          ),
          const SizedBox(width: 12),
          // Judul & Jam / Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showAllDone) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.statusText.isNotEmpty
                        ? widget.statusText
                        : 'Semua jam makan hari ini sudah selesai',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF134563),
                    ),
                  ),
                ] else ...[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      schedule.displayTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF134563),
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      schedule.timeRangeString,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF134563),
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    schedule.reminderNote,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF134563),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Tombol di Kanan Atas
          if (!showAllDone)
            GestureDetector(
              onTap: widget.isCompleted
                  ? null
                  : (widget.isActiveNow
                      ? widget.onMarkCompleted
                      : widget.onDisabledTap),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isCompleted
                      ? Colors.green.shade600
                      : (widget.isActiveNow
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.isCompleted ? 'Selesai ✓' : 'Tandai selesai',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.isCompleted
                        ? Colors.white
                        : const Color(0xFF134563),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

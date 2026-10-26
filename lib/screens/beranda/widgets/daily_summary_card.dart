import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_schedule_model.dart';

enum MealNodeState {
  selesai,
  aktif,
  akanDatang,
  terlewat,
}

class DailySummaryCard extends StatelessWidget {
  final Map<String, MealDailyStatus> dailyStatus;
  final List<MealScheduleItem> schedules;
  final DateTime currentTime;
  final bool isSick;
  final int sleepHour;

  const DailySummaryCard({
    super.key,
    required this.dailyStatus,
    required this.schedules,
    required this.currentTime,
    this.isSick = false,
    this.sleepHour = 20,
  });

  @override
  Widget build(BuildContext context) {
    // Cari jadwal sarapan, makan siang, makan malam dari schedules
    final breakfastSchedule = schedules.firstWhere(
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

    final lunchSchedule = schedules.firstWhere(
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

    final dinnerSchedule = schedules.firstWhere(
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

    MealNodeState resolveState(MealScheduleItem schedule) {
      final status = dailyStatus[schedule.id];
      if (status?.isCompleted ?? false) {
        return MealNodeState.selesai;
      }
      if (schedule.isCurrentTimeInRange(currentTime)) {
        return MealNodeState.aktif;
      }
      if (schedule.isUpcoming(currentTime)) {
        return MealNodeState.akanDatang;
      }
      return MealNodeState.terlewat;
    }

    final breakfastState = resolveState(breakfastSchedule);
    final lunchState = resolveState(lunchSchedule);
    final dinnerState = resolveState(dinnerSchedule);

    final breakfastActual = dailyStatus['breakfast']?.actualTime;
    final lunchActual = dailyStatus['lunch']?.actualTime;
    final dinnerActual = dailyStatus['dinner']?.actualTime;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Color(0xFF134563)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ringkasan hari ini',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF134563),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeline(
            breakfastState: breakfastState,
            lunchState: lunchState,
            dinnerState: dinnerState,
            breakfastActual: breakfastActual,
            lunchActual: lunchActual,
            dinnerActual: dinnerActual,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline({
    required MealNodeState breakfastState,
    required MealNodeState lunchState,
    required MealNodeState dinnerState,
    required String? breakfastActual,
    required String? lunchActual,
    required String? dinnerActual,
  }) {
    final int nodeCount = isSick ? 4 : 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = constraints.maxWidth / nodeCount;
        const circleSize = 24.0;

        Color lineColor(MealNodeState precedingState) {
          if (precedingState == MealNodeState.selesai) {
            return Colors.green;
          }
          if (precedingState == MealNodeState.terlewat) {
            return Colors.grey.shade400;
          }
          return Colors.amber.shade400;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Garis 1 (Breakfast to Lunch)
            Positioned(
              top: (circleSize / 2) - 1,
              left: (colWidth * 0.5) + (circleSize / 2) - 2,
              width: colWidth - circleSize + 4,
              child: Container(
                height: 2,
                color: lineColor(breakfastState),
              ),
            ),
            // Garis 2 (Lunch to Dinner)
            Positioned(
              top: (circleSize / 2) - 1,
              left: (colWidth * 1.5) + (circleSize / 2) - 2,
              width: colWidth - circleSize + 4,
              child: Container(
                height: 2,
                color: lineColor(lunchState),
              ),
            ),
            // Garis 3 (Dinner to Sleep - Khusus Sakit)
            if (isSick)
              Positioned(
                top: (circleSize / 2) - 1,
                left: (colWidth * 2.5) + (circleSize / 2) - 2,
                width: colWidth - circleSize + 4,
                child: Container(
                  height: 2,
                  color: lineColor(dinnerState),
                ),
              ),

            // Node-node
            Row(
              children: [
                Expanded(
                  child: _TimelineNode(
                    title: 'Sarapan',
                    actualTime: breakfastActual,
                    state: breakfastState,
                  ),
                ),
                Expanded(
                  child: _TimelineNode(
                    title: 'Makan siang',
                    actualTime: lunchActual,
                    state: lunchState,
                  ),
                ),
                Expanded(
                  child: _TimelineNode(
                    title: 'Makan malam',
                    actualTime: dinnerActual,
                    state: dinnerState,
                  ),
                ),
                if (isSick)
                  Expanded(
                    child: _TimelineNode(
                      title: 'Jam tidur',
                      actualTime: '${sleepHour.toString().padLeft(2, '0')}.00',
                      state: currentTime.hour >= sleepHour
                          ? MealNodeState.aktif
                          : MealNodeState.akanDatang,
                      isSleepNode: true,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final String title;
  final String? actualTime;
  final MealNodeState state;
  final bool isSleepNode;

  const _TimelineNode({
    required this.title,
    this.actualTime,
    required this.state,
    this.isSleepNode = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = state == MealNodeState.selesai;
    final bool isMuted = state == MealNodeState.terlewat;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCircle(),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isMuted ? FontWeight.w500 : FontWeight.w600,
            color: isMuted ? const Color(0xFF7A8B99) : const Color(0xFF134563),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 16,
          child: (isCompleted && actualTime != null && actualTime!.isNotEmpty)
              ? Text(
                  actualTime!,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF134563),
                  ),
                )
              : (isSleepNode && actualTime != null && actualTime!.isNotEmpty)
                  ? Text(
                      actualTime!,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7A8B99),
                      ),
                    )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCircle() {
    const double size = 24.0;
    switch (state) {
      case MealNodeState.selesai:
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        );
      case MealNodeState.aktif:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isSleepNode ? const Color(0xFF4A7298) : const Color(0xFFF59E0B),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isSleepNode ? const Color(0xFF4A7298) : const Color(0xFFF59E0B))
                    .withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: isSleepNode
              ? const Icon(Icons.bedtime_rounded, color: Colors.white, size: 13)
              : null,
        );
      case MealNodeState.akanDatang:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSleepNode ? const Color(0xFF4A7298) : Colors.amber.shade600,
              width: 2,
            ),
          ),
          child: isSleepNode
              ? const Icon(Icons.bedtime_outlined, color: Color(0xFF4A7298), size: 12)
              : null,
        );
      case MealNodeState.terlewat:
        // Redup/outline, tanpa centang
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.shade400,
              width: 1.5,
            ),
          ),
        );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_schedule_model.dart';

class DailySummaryCard extends StatelessWidget {
  final Map<String, MealDailyStatus> dailyStatus;
  final String activeMealId;
  final bool isSick;

  const DailySummaryCard({
    super.key,
    required this.dailyStatus,
    required this.activeMealId,
    this.isSick = false, // Bisa di-pass dari parent jika memungkinkan
  });

  @override
  Widget build(BuildContext context) {
    final breakfastStatus = dailyStatus['breakfast'] ?? const MealDailyStatus();
    final lunchStatus = dailyStatus['lunch'] ?? const MealDailyStatus();
    final dinnerStatus = dailyStatus['dinner'] ?? const MealDailyStatus();

    final isBreakfastActive = !breakfastStatus.isCompleted;
    final isLunchActive = !lunchStatus.isCompleted && (breakfastStatus.isCompleted || activeMealId == 'lunch');
    final isDinnerActive = !dinnerStatus.isCompleted && (lunchStatus.isCompleted || activeMealId == 'dinner');

    // Menentukan status tiap titik (0 = belum, 1 = aktif, 2 = selesai, 3 = terlewat)
    // Untuk simplifikasi, asumsikan yang terlewat adalah yang bukan selesai tapi jadwalnya sudah lewat. 
    // Tapi karena tidak ada info "isPast" di sini, kita gunakan aktif/selesai/belum.
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5).withValues(alpha: 0.85), // Krem semi-transparan
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
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
              Text(
                'Ringkasan hari ini',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF134563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeline(
            breakfastStatus: breakfastStatus,
            lunchStatus: lunchStatus,
            dinnerStatus: dinnerStatus,
            isBreakfastActive: isBreakfastActive,
            isLunchActive: isLunchActive,
            isDinnerActive: isDinnerActive,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline({
    required MealDailyStatus breakfastStatus,
    required MealDailyStatus lunchStatus,
    required MealDailyStatus dinnerStatus,
    required bool isBreakfastActive,
    required bool isLunchActive,
    required bool isDinnerActive,
  }) {
    final int nodeCount = isSick ? 4 : 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = constraints.maxWidth / nodeCount;
        const circleSize = 24.0;

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
                color: breakfastStatus.isCompleted ? Colors.green : Colors.amber,
              ),
            ),
            // Garis 2 (Lunch to Dinner)
            Positioned(
              top: (circleSize / 2) - 1,
              left: (colWidth * 1.5) + (circleSize / 2) - 2,
              width: colWidth - circleSize + 4,
              child: Container(
                height: 2,
                color: lunchStatus.isCompleted ? Colors.green : Colors.amber,
              ),
            ),
            // Garis 3 (Dinner to Sleep - Only if Sick)
            if (isSick)
              Positioned(
                top: (circleSize / 2) - 1,
                left: (colWidth * 2.5) + (circleSize / 2) - 2,
                width: colWidth - circleSize + 4,
                child: Container(
                  height: 2,
                  color: dinnerStatus.isCompleted ? Colors.green : Colors.amber,
                ),
              ),

            // Nodes
            Row(
              children: [
                Expanded(
                  child: _TimelineNode(
                    title: 'Sarapan',
                    time: breakfastStatus.actualTime,
                    isCompleted: breakfastStatus.isCompleted,
                    isActive: isBreakfastActive,
                  ),
                ),
                Expanded(
                  child: _TimelineNode(
                    title: 'Makan siang',
                    time: lunchStatus.actualTime,
                    isCompleted: lunchStatus.isCompleted,
                    isActive: isLunchActive,
                  ),
                ),
                Expanded(
                  child: _TimelineNode(
                    title: 'Makan malam',
                    time: dinnerStatus.actualTime,
                    isCompleted: dinnerStatus.isCompleted,
                    isActive: isDinnerActive,
                  ),
                ),
                if (isSick)
                  Expanded(
                    child: _TimelineNode(
                      title: 'Jam tidur',
                      time: null,
                      isCompleted: false,
                      isActive: false, // Sementara false
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
  final String? time;
  final bool isCompleted;
  final bool isActive;

  const _TimelineNode({
    required this.title,
    this.time,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
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
            fontWeight: FontWeight.w600,
            color: const Color(0xFF134563),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 16,
          child: (isCompleted && time != null && time!.isNotEmpty)
              ? Text(
                  time!,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF134563),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCircle() {
    const double size = 24.0;
    if (isCompleted) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
    }
    if (isActive) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.amber,
          shape: BoxShape.circle,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.amber, width: 2),
      ),
    );
  }
}

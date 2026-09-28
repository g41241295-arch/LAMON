import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_schedule_model.dart';

/// Kartu "Ringkasan hari ini" dengan timeline 3 titik simetris dan animasi sinkron
class DailySummaryCard extends StatelessWidget {
  final Map<String, MealDailyStatus> dailyStatus;
  final String activeMealId;

  const DailySummaryCard({
    super.key,
    required this.dailyStatus,
    required this.activeMealId,
  });

  @override
  Widget build(BuildContext context) {
    final breakfastStatus = dailyStatus['breakfast'] ?? const MealDailyStatus();
    final lunchStatus = dailyStatus['lunch'] ?? const MealDailyStatus();
    final dinnerStatus = dailyStatus['dinner'] ?? const MealDailyStatus();

    // Tentukan status aktif (kuning solid) jika belum selesai
    final isBreakfastActive = !breakfastStatus.isCompleted;
    final isLunchActive = !lunchStatus.isCompleted &&
        (breakfastStatus.isCompleted || activeMealId == 'lunch');
    final isDinnerActive = !dinnerStatus.isCompleted &&
        (lunchStatus.isCompleted || activeMealId == 'dinner');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFC3E3F7),
            Color(0xFFF3F9FE),
            Color(0xFFFFFFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFA5D5F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF134563).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Judul Kartu
          Text(
            'Ringkasan hari ini',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E5D7D),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),

          // Timeline 3 Titik Simetris (Masing-masing kolom dibungkus Expanded)
          LayoutBuilder(
            builder: (context, constraints) {
              const circleSize = 28.0;
              final colWidth = constraints.maxWidth / 3;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Layer 1: Garis Penghubung antar lingkaran
                  // Garis 1: dari tengah node 1 ke tengah node 2
                  Positioned(
                    top: (circleSize / 2) - 1.25,
                    left: (colWidth * 0.5) + (circleSize / 2) - 2,
                    width: colWidth - circleSize + 4,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0.0,
                        end: breakfastStatus.isCompleted ? 1.0 : 0.0,
                      ),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Container(
                          height: 2.5,
                          color: breakfastStatus.isCompleted
                              ? const Color(0xFF38B249)
                              : const Color(0xFFF6BC27),
                        );
                      },
                    ),
                  ),

                  // Garis 2: dari tengah node 2 ke tengah node 3
                  Positioned(
                    top: (circleSize / 2) - 1.25,
                    left: (colWidth * 1.5) + (circleSize / 2) - 2,
                    width: colWidth - circleSize + 4,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0.0,
                        end: lunchStatus.isCompleted ? 1.0 : 0.0,
                      ),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Container(
                          height: 2.5,
                          color: lunchStatus.isCompleted
                              ? const Color(0xFF38B249)
                              : const Color(0xFFF6BC27),
                        );
                      },
                    ),
                  ),

                  // Layer 2: Tiga Node Simetris Bersebelahan (Expanded)
                  Row(
                    children: [
                      // Node 1: Sarapan
                      Expanded(
                        child: _TimelineNode(
                          title: 'Sarapan',
                          time: breakfastStatus.isCompleted
                              ? breakfastStatus.actualTime
                              : null,
                          isCompleted: breakfastStatus.isCompleted,
                          isActive: isBreakfastActive,
                        ),
                      ),

                      // Node 2: Makan Siang
                      Expanded(
                        child: _TimelineNode(
                          title: 'Makan siang',
                          time: lunchStatus.isCompleted
                              ? lunchStatus.actualTime
                              : null,
                          isCompleted: lunchStatus.isCompleted,
                          isActive: isLunchActive,
                        ),
                      ),

                      // Node 3: Makan Malam
                      Expanded(
                        child: _TimelineNode(
                          title: 'Makan malam',
                          time: dinnerStatus.isCompleted
                              ? dinnerStatus.actualTime
                              : null,
                          isCompleted: dinnerStatus.isCompleted,
                          isActive: isDinnerActive,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Komponen node individual dalam timeline
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
        // 1. Lingkaran Status (Centang Hijau / Kuning Solid / Kuning Outline)
        _buildCircle(),

        const SizedBox(height: 7),

        // 2. Judul Makan (Lengkap, FittedBox agar tidak terpotong)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF235C7E),
                height: 1.15,
              ),
            ),
          ),
        ),

        const SizedBox(height: 2),

        // 3. Jam Aktual (HANYA tampil jika makan itu sudah ditandai selesai)
        SizedBox(
          height: 18,
          child: (isCompleted && time != null && time!.isNotEmpty)
              ? Text(
                  time!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF235C7E),
                    height: 1.1,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCircle() {
    const circleSize = 28.0;

    // A. Status Selesai: Lingkaran hijau dengan centang putih & ripple glow
    if (isCompleted) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.7, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: const Color(0xFF38B249),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38B249).withValues(alpha: 0.45),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          );
        },
      );
    }

    // B. Status Sedang Berjalan / Jadwal Berikutnya: Lingkaran kuning solid
    if (isActive) {
      return Container(
        width: circleSize,
        height: circleSize,
        decoration: const BoxDecoration(
          color: Color(0xFFF6BC27),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x33F6BC27),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      );
    }

    // C. Status Belum: Lingkaran putih dengan outline kuning
    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFF6BC27),
          width: 2.2,
        ),
      ),
    );
  }
}

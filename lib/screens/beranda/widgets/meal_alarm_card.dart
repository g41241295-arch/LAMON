import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_schedule_model.dart';

/// Kartu pengingat alarm jam makan harian
class MealAlarmCard extends StatefulWidget {
  final MealScheduleItem schedule;
  final bool isCompleted;
  final bool isActiveNow;
  final bool isAlarmRinging;
  final VoidCallback onMarkCompleted;
  final VoidCallback onDisabledTap;

  const MealAlarmCard({
    super.key,
    required this.schedule,
    required this.isCompleted,
    required this.isActiveNow,
    required this.isAlarmRinging,
    required this.onMarkCompleted,
    required this.onDisabledTap,
  });

  @override
  State<MealAlarmCard> createState() => _MealAlarmCardState();
}

class _MealAlarmCardState extends State<MealAlarmCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Animasi getar jam saat alarm berbunyi (rotasi ±0.1 rad cepat berulang)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _shakeAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isAlarmRinging) {
      _shakeController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MealAlarmCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAlarmRinging != oldWidget.isAlarmRinging) {
      if (widget.isAlarmRinging) {
        if (!_shakeController.isAnimating) {
          _shakeController.repeat(reverse: true);
        }
      } else {
        _shakeController.stop();
        _shakeController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF639BC6),
            Color(0xFF86B9DE),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF78A9CE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF134563).withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Kotak Ikon Jam (Semi-transparan + efek getar & glow saat alarm aktif)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: widget.isAlarmRinging ? 0.85 : 0.35,
                ),
                width: 1.2,
              ),
              boxShadow: widget.isAlarmRinging
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.55),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: widget.isAlarmRinging
                ? AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _shakeAnimation.value,
                        child: child,
                      );
                    },
                    child: _buildClockImage(),
                  )
                : _buildClockImage(),
          ),

          const SizedBox(width: 16),

          // 2. Teks Informasi & Tombol Selesai
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Judul dinamis (misal "Jam makan siang")
                Text(
                  widget.schedule.displayTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF134563),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),

                // Rentang Jam (misal "12.00 – 13.00 WIB")
                Text(
                  widget.schedule.timeRangeString,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF134563),
                    height: 1.15,
                  ),
                ),

                // Pesan Pengingat (misal "Jangan lupa makan !")
                Text(
                  widget.schedule.reminderNote,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF134563),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 9),

                // Tombol "Tandai selesai" / "Selesai ✓"
                _buildActionButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    // 1. Sudah ditandai selesai
    if (widget.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6.5),
        decoration: BoxDecoration(
          color: const Color(0xFF38B249),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Text(
          'Selesai ✓',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    // 2. Sedang dalam rentang jam makan -> Tombol AKTIF
    if (widget.isActiveNow) {
      return GestureDetector(
        onTap: widget.onMarkCompleted,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Text(
            'Tandai selesai',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF246D91),
            ),
          ),
        ),
      );
    }

    // 3. Belum masuk waktunya -> Tombol NONAKTIF (pudar / disabled)
    return GestureDetector(
      onTap: widget.onDisabledTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6.5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          'Tandai selesai',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF134563).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildClockImage() {
    return Image.asset(
      'assets/images/clock-card1.png',
      width: 48,
      height: 48,
      fit: BoxFit.contain,
    );
  }
}

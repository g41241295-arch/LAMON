import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../services/profile_photo_service.dart';

class FormalHeaderBar extends StatelessWidget {
  final String userName;
  final String? photoUrl;
  final DateTime currentDate;
  final VoidCallback onProfileTap;
  final VoidCallback? onPreviousDate;
  final VoidCallback? onNextDate;
  final VoidCallback? onNotificationTap;

  const FormalHeaderBar({
    super.key,
    required this.userName,
    this.photoUrl,
    required this.currentDate,
    required this.onProfileTap,
    this.onPreviousDate,
    this.onNextDate,
    this.onNotificationTap,
  });

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      return 'Hari Ini, ${date.day} ${months[date.month]}';
    }
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  Widget _buildAvatar() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        return RealtimeHeaderAvatar(
          collection: 'users',
          docId: uid,
          size: 38,
          borderRadius: 19,
          fallback: _buildLegacyAvatar(),
        );
      }
    } catch (_) {}
    return _buildLegacyAvatar();
  }

  Widget _buildLegacyAvatar() {
    final cleanUrl = (photoUrl ?? '').trim();
    if (cleanUrl.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 38,
          height: 38,
          child: Image.network(
            cleanUrl,
            width: 38,
            height: 38,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
          ),
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.person, size: 20, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar Profil + Teks LAMON
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: _buildAvatar(),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onProfileTap,
              child: Text(
                'LAMON',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),

        const Spacer(),

        // Date Pill di Samping Notifikasi: Pure Tanggal (tanpa tombol < dan >)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEBE3D0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(currentDate),
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Lonceng Notifikasi di Kanan
        GestureDetector(
          onTap: onNotificationTap ??
              () {
                Navigator.pushNamed(context, AppRoutes.userNotifications);
              },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFEBE3D0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: AppColors.primaryText,
                ),
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final VoidCallback? onChatTap;
  final VoidCallback? onHomeTap;
  final VoidCallback? onProfileTap;

  const BottomNavBar({
    super.key,
    this.onChatTap,
    this.onHomeTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Main Navigation Bar Container
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.navBarBg.withValues(alpha: 0.96),
              border: const Border(
                top: BorderSide(
                  color: AppColors.navBarBorder,
                  width: 1.2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Chat / Konsultasi Button (Left)
                IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.black87,
                    size: 26,
                  ),
                  tooltip: 'Pesan & Konsultasi',
                  onPressed: onChatTap ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Halaman Pesan & Konsultasi akan segera hadir pada pembaruan berikutnya.',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                ),

                // Center Spacer for elevated Home button
                const SizedBox(width: 56),

                // Profile Button (Right)
                IconButton(
                  icon: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.black87,
                    size: 28,
                  ),
                  tooltip: 'Profil Pengguna',
                  onPressed: onProfileTap ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Halaman Profil Pengguna akan segera hadir pada pembaruan berikutnya.',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                ),
              ],
            ),
          ),

          // Raised Center Home Button
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onHomeTap,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.navBarBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.navBarHomeBorder,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.home_rounded,
                    color: Colors.black87,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

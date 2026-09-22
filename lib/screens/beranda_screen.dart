import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../models/menu_item_model.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bottom_nav_bar.dart';

class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key});

  void _onMenuClick(BuildContext context, String title, String description) {
    Navigator.pushNamed(
      context,
      '/placeholder',
      arguments: {
        'title': title,
        'description': description,
      },
    );
  }

  void _onMainMenuClick(BuildContext context, MainMenuItem menu) {
    if (menu.route == '/prediksi-penyakit' || menu.id == 'prediksi-penyakit') {
      Navigator.pushNamed(context, '/prediksi-penyakit');
      return;
    }
    if (menu.route == '/catat-makananmu' || menu.id == 'catat-makananmu') {
      Navigator.pushNamed(context, '/catat-makananmu');
      return;
    }
    if (menu.route == '/ringkasan-makanan' || menu.id == 'ringkasan-makanan') {
      Navigator.pushNamed(context, '/ringkasan-makanan');
      return;
    }
    _onMenuClick(context, menu.shortTitle, menu.description);
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final user = appState.currentUser;
    final lunchDone = appState.lunchDone;

    return AppScaffold(
      bottomNavigationBar: BottomNavBar(
        onHomeTap: () {
          // Already on home
        },
        onChatTap: () {
          _onMenuClick(
            context,
            'Pesan & Konsultasi',
            'Fitur pesan langsung dengan dokter dan asisten kesehatan lambung sedang dikembangkan.',
          );
        },
        onProfileTap: () {
          _onMenuClick(
            context,
            'Profil Pengguna',
            'Halaman pengaturan profil pengguna, data medis, dan riwayat kesehatan lambung.',
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tombol logout disembunyikan sementara sesuai permintaan
            // =========================================================
            // A. HEADER SAPAAN & MASKOT BERANDA
            // =========================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${user.name} !',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brownAccent,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sehatkan Lambung,\nMulai dari Hari ini',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Yuk, jaga pola makan dan pantau kesehatan lambungmu setiap hari',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.brownSubtext,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),

                // Mascot with radial glow
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFE566).withValues(alpha: 0.65),
                              blurRadius: 28,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        AppAssets.mascotHeader,
                        width: 110,
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // =========================================================
            // B. CARD "JAM MAKAN SIANG"
            // =========================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.lunchCardGradientStart,
                    AppColors.lunchCardGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.lunchCardBorder,
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
                children: [
                  // Clock Container
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      AppAssets.clockCard,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Text & Button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jam makan siang',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.lunchCardText,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '12.00 – 13.00 WIB',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lunchCardText,
                          ),
                        ),
                        const Text(
                          'Jangan lupa makan !',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lunchCardText,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Toggle Finished Button
                        InkWell(
                          onTap: () {
                            appState.toggleLunchDone();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  !lunchDone
                                      ? 'Jam makan siang telah ditandai selesai! Bagus!'
                                      : 'Status makan siang direset.',
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: lunchDone
                                  ? AppColors.successGreen
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              lunchDone ? 'Telah Selesai ✓' : 'Tandai selesai',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: lunchDone
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =========================================================
            // C. CARD "RINGKASAN HARI INI" (TIMELINE)
            // =========================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.summaryCardBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.summaryCardBorder,
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan hari ini',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.summaryCardText,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3-Stage Timeline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Node 1: Sarapan (Done)
                      _buildTimelineNode(
                        title: 'Sarapan',
                        time: '08.00',
                        isCompleted: true,
                        isActive: false,
                      ),

                      // Connecting Line 1-2
                      Expanded(
                        child: Container(
                          height: 2.5,
                          color: AppColors.successGreen,
                          margin: const EdgeInsets.only(bottom: 32),
                        ),
                      ),

                      // Node 2: Makan Siang (Active or Done)
                      _buildTimelineNode(
                        title: 'Makan siang',
                        time: '12.30',
                        isCompleted: lunchDone,
                        isActive: !lunchDone,
                      ),

                      // Connecting Line 2-3
                      Expanded(
                        child: Container(
                          height: 2.5,
                          color: lunchDone
                              ? AppColors.successGreen
                              : const Color(0xFFD7BE7B),
                          margin: const EdgeInsets.only(bottom: 32),
                        ),
                      ),

                      // Node 3: Makan Malam (Upcoming)
                      _buildTimelineNode(
                        title: 'Makan malam',
                        time: '19.00',
                        isCompleted: false,
                        isActive: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // =========================================================
            // D. SECTION "MENU UTAMA" (HORIZONTAL SCROLL)
            // =========================================================
            _buildSectionBadge('Menu utama'),
            const SizedBox(height: 12),

            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: AppMenus.mainMenus.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final menu = AppMenus.mainMenus[index];
                  return GestureDetector(
                    onTap: () => _onMainMenuClick(
                      context,
                      menu,
                    ),
                    child: Container(
                      width: 134,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF7FA4BA),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Illustration container
                          Container(
                            width: double.infinity,
                            height: 110,
                            color: const Color(0xFFF2F7FA),
                            child: Image.asset(
                              menu.assetPath,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // Title Container
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Text(
                                menu.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brownText,
                                  height: 1.15,
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
            ),

            const SizedBox(height: 18),

            // =========================================================
            // E. SECTION "SEPUTAR INFORMASI" (VERTICAL STACK)
            // =========================================================
            _buildSectionBadge('Seputar Informasi'),
            const SizedBox(height: 12),

            ...AppMenus.infoMenus.map((info) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _onMenuClick(
                    context,
                    info.title,
                    info.description,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE2ECF2),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left Thumbnail
                        Container(
                          width: 80,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            info.assetPath,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Title
                        Expanded(
                          child: Text(
                            info.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        // Chevron Right
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.black87,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Section Badge Pill Widget
  Widget _buildSectionBadge(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.badgeBgStart,
            AppColors.badgeBgEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.badgeBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppColors.brownDark,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  // Node for 3-Stage Timeline Widget
  Widget _buildTimelineNode({
    required String title,
    required String time,
    required bool isCompleted,
    required bool isActive,
  }) {
    Widget iconCircle;

    if (isCompleted) {
      iconCircle = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.successGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 18,
        ),
      );
    } else if (isActive) {
      iconCircle = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.warningYellow,
          shape: BoxShape.circle,
        ),
      );
    } else {
      iconCircle = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.warningYellow,
            width: 2.2,
          ),
        ),
      );
    }

    return Column(
      children: [
        iconCircle,
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.summaryCardText,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.summaryCardSubtext,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

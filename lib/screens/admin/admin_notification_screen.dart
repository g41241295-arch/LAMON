import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_notification_service.dart';
import '../../widgets/admin/admin_widgets.dart';
import '../dashboard_admin_screen.dart';

class AdminNotificationScreen extends StatefulWidget {
  final String adminName;
  final String adminId;

  const AdminNotificationScreen({
    super.key,
    this.adminName = 'Admin',
    this.adminId = '',
  });

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final AdminNotificationService _service = AdminNotificationService.instance;

  Future<void> _onTapNotification(AdminNotificationItem item) async {
    await _service.markAsRead(item.id);
    if (!mounted) return;

    switch (item.type) {
      case AdminNotificationType.penilaianBaru:
        Navigator.pushNamed(context, AppRoutes.adminPenilaian);
        break;
      case AdminNotificationType.draftBerita:
        Navigator.pushNamed(
          context,
          AppRoutes.adminBerita,
          arguments: {
            'adminName': widget.adminName,
            'adminId': widget.adminId,
          },
        );
        break;
      case AdminNotificationType.aktivitasAdminLain:
        if (item.targetModule == 'berita') {
          Navigator.pushNamed(
            context,
            AppRoutes.adminBerita,
            arguments: {
              'adminName': widget.adminName,
              'adminId': widget.adminId,
            },
          );
        } else if (item.targetModule == 'ensiklopedia') {
          Navigator.pushNamed(context, AppRoutes.adminEnsiklopedia);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ActivityHistoryScreen(),
            ),
          );
        }
        break;
      case AdminNotificationType.kelengkapanGastropedia:
        Navigator.pushNamed(context, AppRoutes.adminEnsiklopedia);
        break;
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Kembali (bulat putih)
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.softBlue, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ),

          // Pill Judul: gaya sama seperti halaman admin lainnya
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7D6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE8D7A5),
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
                child: Text(
                  'Notifikasi',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C4E68),
                  ),
                ),
              ),
            ),
          ),

          // Penyeimbang kanan agar pill tetap di tengah
          const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.bgGradientTop,
          AppColors.bgGradientMiddle,
          AppColors.bgGradientBottom,
        ],
      ),
      header: _buildHeader(),
      body: StreamBuilder<List<AdminNotificationItem>>(
        stream: _service.watchAdminNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.textPrimary,
                strokeWidth: 2.5,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return _buildEmptyState();
          }

          final unreadCount = items.where((e) => !e.isRead).length;
          final grouped = _groupNotificationsByDate(items);

          return Column(
            children: [
              // Bar info jumlah belum dibaca + tombol "Tandai semua dibaca"
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      unreadCount > 0
                          ? '$unreadCount belum dibaca'
                          : 'Semua notifikasi sudah dibaca',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: unreadCount > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: unreadCount > 0
                          ? () => _service.markAllAsRead(items)
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(
                        Icons.done_all_rounded,
                        size: 16,
                        color: unreadCount > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      label: Text(
                        'Tandai semua dibaca',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: unreadCount > 0
                              ? AppColors.textPrimary
                              : AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  itemCount: grouped.length,
                  itemBuilder: (context, sectionIndex) {
                    final section = grouped[sectionIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sectionIndex > 0) const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, left: 2),
                          child: Text(
                            section.label,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        for (int i = 0; i < section.items.length; i++) ...[
                          _buildNotificationCard(section.items[i]),
                          if (i < section.items.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AdminNotificationItem item) {
    final IconData iconData;
    switch (item.type) {
      case AdminNotificationType.penilaianBaru:
        iconData = Icons.star_rounded;
        break;
      case AdminNotificationType.draftBerita:
        iconData = Icons.description_outlined;
        break;
      case AdminNotificationType.aktivitasAdminLain:
        iconData = Icons.history_rounded;
        break;
      case AdminNotificationType.kelengkapanGastropedia:
        iconData = Icons.info_outline_rounded;
        break;
    }

    final Color circleColor =
        item.isLowRating ? AppColors.bgAccent : AppColors.softBlue;
    final Color borderColor = item.isLowRating
        ? AppColors.accentGold
        : (item.isRead
            ? AppColors.softBlue.withValues(alpha: 0.7)
            : AppColors.softBlue);

    return GestureDetector(
      onTap: () => _onTapNotification(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: (!item.isRead || item.isLowRating) ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kiri: Ikon dalam lingkaran softBlue (atau bgAccent untuk penilaian rendah)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  iconData,
                  size: 21,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Tengah: Judul semibold/bold navy + badge penilaian rendah (jika ada) + keterangan textSecondary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.isLowRating) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgAccent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accentGold,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Perlu Perhatian • ${item.ratingValue ?? 1} Bintang',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight:
                          item.isRead ? FontWeight.w600 : FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Kanan: Waktu relatif (12sp) + titik indikator belum dibaca
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatRelativeTime(item.timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        item.isRead ? FontWeight.w400 : FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (!item.isRead) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.softBlue, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.softBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 28,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Belum ada notifikasi',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Penilaian pengguna baru, pengingat draft, dan aktivitas konten akan tampil di sini.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.softBlue, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 32,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat notifikasi',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<({String label, List<AdminNotificationItem> items})>
      _groupNotificationsByDate(List<AdminNotificationItem> items) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final todayList = <AdminNotificationItem>[];
    final yesterdayList = <AdminNotificationItem>[];
    final olderList = <AdminNotificationItem>[];

    for (final item in items) {
      final itemDay = DateTime(
        item.timestamp.year,
        item.timestamp.month,
        item.timestamp.day,
      );
      if (!itemDay.isBefore(todayStart)) {
        todayList.add(item);
      } else if (!itemDay.isBefore(yesterdayStart)) {
        yesterdayList.add(item);
      } else {
        olderList.add(item);
      }
    }

    final sections = <({String label, List<AdminNotificationItem> items})>[];
    if (todayList.isNotEmpty) {
      sections.add((label: 'Hari ini', items: todayList));
    }
    if (yesterdayList.isNotEmpty) {
      sections.add((label: 'Kemarin', items: yesterdayList));
    }
    if (olderList.isNotEmpty) {
      sections.add((label: 'Sebelumnya', items: olderList));
    }
    return sections;
  }

  String _formatRelativeTime(DateTime dt) {
    if (dt.millisecondsSinceEpoch <= 0) return 'Baru saja';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 30) return '${diff.inDays} hari lalu';
    final months = (diff.inDays / 30).floor();
    return '$months bulan lalu';
  }
}

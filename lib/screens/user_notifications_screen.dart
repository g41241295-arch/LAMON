import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/doctor_theme.dart';
import '../models/consultation_model.dart';
import '../routes/app_routes.dart';
import '../services/consultation_service.dart';
import '../utils/app_date_formatter.dart';
import 'konsultasi/chat_dokter_screen.dart';

/// Halaman Notifikasi Pengguna LAMON (Modern & Formal Design System)
/// Memuat notifikasi:
/// 1. Alarm Pengingat Jam Makan
/// 2. Waktunya Catat Makanan
/// 3. Notifikasi Balasan dari Chat Dokter
class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  final ConsultationService _consultationService = ConsultationService();
  Set<String> _readNotifIds = {};
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _loadReadStatus();
  }

  Future<void> _loadReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('user_read_notifs_$_uid') ?? [];
      if (mounted) {
        setState(() {
          _readNotifIds = list.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllAsRead(List<_UserNotificationItem> allItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedSet = {..._readNotifIds};
      for (final item in allItems) {
        updatedSet.add(item.id);
      }
      await prefs.setStringList(
        'user_read_notifs_$_uid',
        updatedSet.toList(),
      );
      if (mounted) {
        setState(() {
          _readNotifIds = updatedSet;
        });
      }
    } catch (e) {
      debugPrint('[UserNotifications] Error marking all read: $e');
    }
  }

  Future<void> _markSingleAsRead(String id) async {
    if (_readNotifIds.contains(id)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedSet = {..._readNotifIds, id};
      await prefs.setStringList(
        'user_read_notifs_$_uid',
        updatedSet.toList(),
      );
      if (mounted) {
        setState(() {
          _readNotifIds = updatedSet;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const bgStart = Color(0xFFFCFBF7);
    const bgEnd = Color(0xFFF7F4EB);

    return Scaffold(
      backgroundColor: bgStart,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<ConsultationModel>>(
            stream: _consultationService.watchAllPatientConsultations(
              patientUid: _uid,
            ),
            builder: (context, snapshot) {
              final consultations = snapshot.data ?? [];
              final items = _buildNotificationItems(consultations);

              final unreadItems = items
                  .where((item) =>
                      !item.isAlwaysPrevious && !_readNotifIds.contains(item.id))
                  .toList();
              final previousItems = items
                  .where((item) =>
                      item.isAlwaysPrevious || _readNotifIds.contains(item.id))
                  .toList();

              return Column(
                children: [
                  _buildHeader(context, items, unreadItems.isNotEmpty),
                  Expanded(
                    child: items.isEmpty
                        ? _buildEmptyState()
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                            children: [
                              if (unreadItems.isNotEmpty) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 4, bottom: 10),
                                  child: Text(
                                    'Baru',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1C4E68),
                                    ),
                                  ),
                                ),
                                ...unreadItems.map((item) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _buildNotificationCard(
                                        context,
                                        item,
                                        isUnread: true,
                                      ),
                                    )),
                                const SizedBox(height: 10),
                              ],
                              if (previousItems.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 4, top: 4, bottom: 10),
                                  child: Text(
                                    'Sebelumnya',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF6B8190),
                                    ),
                                  ),
                                ),
                                ...previousItems.map((item) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _buildNotificationCard(
                                        context,
                                        item,
                                        isUnread: false,
                                      ),
                                    )),
                              ],
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<_UserNotificationItem> allItems,
    bool hasUnread,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          // Tombol Kembali Bulat Formal Modern ala Image
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD6E2E8),
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
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF1C4E68),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Notifikasi',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C4E68),
            ),
          ),
          const Spacer(),
          if (allItems.isNotEmpty)
            GestureDetector(
              onTap: hasUnread ? () => _markAllAsRead(allItems) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  'Tandai dibaca',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasUnread
                        ? const Color(0xFF2E85A8)
                        : const Color(0xFF8B9EAA),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    _UserNotificationItem item, {
    required bool isUnread,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEBE3D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            _markSingleAsRead(item.id);
            item.onTap?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Kotak Ikon Pastel 58x58 Radius 18
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: item.iconBgColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    item.icon,
                    size: 26,
                    color: item.iconColor,
                  ),
                ),
                const SizedBox(width: 14),

                // Konten Tengah
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Chip Kategori
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.chipBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.categoryLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item.chipTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Judul
                      Text(
                        item.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1C4E68),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Subteks
                      Text(
                        item.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B8190),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Waktu & Titik Oranye
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.timeString,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B8190),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isUnread)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 9),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFDCEBF3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: Color(0xFF1C4E68),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada notifikasi',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C4E68),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pengingat jam makan, waktu catat makanan, dan balasan chat dokter Anda akan muncul di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF6B8190),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_UserNotificationItem> _buildNotificationItems(
    List<ConsultationModel> consultations,
  ) {
    final list = <_UserNotificationItem>[];
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Notifikasi Balasan dari Chat Dokter
    // ─────────────────────────────────────────────────────────────────────────
    final activeDoctorChats = consultations.where((c) {
      return c.paymentStatus == PaymentStatus.paid &&
          !c.isCompleted &&
          (c.unreadForPatient > 0 || c.lastMessageSenderType == 'doctor');
    }).toList();

    for (final c in activeDoctorChats) {
      final lastTime = c.lastMessageAt ?? c.createdAt;
      final docName =
          c.doctorName.isNotEmpty ? c.doctorName : 'Dokter Spesialis';
      list.add(
        _UserNotificationItem(
          id: 'doc_reply_${c.id}_${lastTime.millisecondsSinceEpoch}',
          icon: Icons.chat_bubble_outline_rounded,
          iconBgColor: const Color(0xFFEAF3F8),
          iconColor: const Color(0xFF1F5C7A),
          categoryLabel: 'Chat Dokter',
          chipBgColor: const Color(0xFFDCEBF3),
          chipTextColor: const Color(0xFF1F5C7A),
          title: '$docName membalas pesan',
          subtitle: c.lastMessageText?.isNotEmpty == true
              ? c.lastMessageText!
              : 'Dokter telah mengirim balasan baru terkait konsultasi Anda.',
          timeString:
              AppDateFormatter.formatConversationListTimestamp(lastTime),
          timestamp: lastTime,
          isAlwaysPrevious: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDokterScreen(
                  consultationId: c.id,
                  isDoctor: false,
                  patientUid: c.patientUid,
                  initialConsultation: c,
                ),
              ),
            );
          },
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Alarm Pengingat Jam Makan
    // ─────────────────────────────────────────────────────────────────────────
    // Sesi Makan Siang
    list.add(
      _UserNotificationItem(
        id: 'alarm_lunch_$todayKey',
        icon: Icons.alarm_rounded,
        iconBgColor: const Color(0xFFFFF4E5),
        iconColor: const Color(0xFFE65100),
        categoryLabel: 'Alarm Makan',
        chipBgColor: const Color(0xFFFFF0D4),
        chipTextColor: const Color(0xFFD97706),
        title: 'Waktunya Makan Siang',
        subtitle:
            'Jadwal 12.00 – 13.00 WIB · Istirahat sejenak dan makan tepat waktu agar lambung tetap nyaman.',
        timeString: '12.00',
        timestamp: DateTime(now.year, now.month, now.day, 12, 0),
        isAlwaysPrevious: now.hour < 12 ? false : false,
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );

    // Sesi Sarapan
    list.add(
      _UserNotificationItem(
        id: 'alarm_breakfast_$todayKey',
        icon: Icons.alarm_rounded,
        iconBgColor: const Color(0xFFFFF4E5),
        iconColor: const Color(0xFFE65100),
        categoryLabel: 'Alarm Makan',
        chipBgColor: const Color(0xFFFFF0D4),
        chipTextColor: const Color(0xFFD97706),
        title: 'Waktunya Sarapan Pagi',
        subtitle:
            'Jadwal 06.00 – 08.00 WIB · Awali hari dengan sarapan teratur untuk mencegah peningkatan asam lambung.',
        timeString: '07.00',
        timestamp: DateTime(now.year, now.month, now.day, 7, 0),
        isAlwaysPrevious: false,
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );

    // Sesi Makan Malam
    list.add(
      _UserNotificationItem(
        id: 'alarm_dinner_$todayKey',
        icon: Icons.alarm_rounded,
        iconBgColor: const Color(0xFFFFF4E5),
        iconColor: const Color(0xFFE65100),
        categoryLabel: 'Alarm Makan',
        chipBgColor: const Color(0xFFFFF0D4),
        chipTextColor: const Color(0xFFD97706),
        title: 'Waktunya Makan Malam',
        subtitle:
            'Jadwal 18.00 – 19.00 WIB · Hindari makan larut malam untuk mencegah refluks saat tidur.',
        timeString: '18.00',
        timestamp: DateTime(now.year, now.month, now.day, 18, 0),
        isAlwaysPrevious: false,
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Waktunya Catat Makanan
    // ─────────────────────────────────────────────────────────────────────────
    // Catat Makan Siang
    list.add(
      _UserNotificationItem(
        id: 'food_record_lunch_$todayKey',
        icon: Icons.restaurant_menu_rounded,
        iconBgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        categoryLabel: 'Catat Makanan',
        chipBgColor: const Color(0xFFE0F2E9),
        chipTextColor: const Color(0xFF2E7D32),
        title: 'Waktunya Catat Makanan Siang',
        subtitle:
            'Sudah makan siang? Yuk catat menu makananmu sekarang untuk memantau pemicu asam lambung.',
        timeString: '13.00',
        timestamp: DateTime(now.year, now.month, now.day, 13, 0),
        isAlwaysPrevious: false,
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.catatMakanan);
        },
      ),
    );

    // Catat Sarapan
    list.add(
      _UserNotificationItem(
        id: 'food_record_breakfast_$todayKey',
        icon: Icons.restaurant_menu_rounded,
        iconBgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        categoryLabel: 'Catat Makanan',
        chipBgColor: const Color(0xFFE0F2E9),
        chipTextColor: const Color(0xFF2E7D32),
        title: 'Catat Menu Sarapan Pagi',
        subtitle:
            'Lengkapi catatan menu sarapan Anda untuk evaluasi nutrisi dan kesehatan lambung harian.',
        timeString: '08.00',
        timestamp: DateTime(now.year, now.month, now.day, 8, 0),
        isAlwaysPrevious: false,
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.catatMakanan);
        },
      ),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Konsultasi Selesai (Jika ada, masuk ke kategori Selesai di Sebelumnya)
    // ─────────────────────────────────────────────────────────────────────────
    final completedChats = consultations.where((c) => c.isCompleted).toList();
    for (final c in completedChats) {
      final time = c.completedAt ?? c.createdAt;
      final docName =
          c.doctorName.isNotEmpty ? c.doctorName : 'Dokter Spesialis';
      list.add(
        _UserNotificationItem(
          id: 'user_done_${c.id}',
          icon: Icons.check_rounded,
          iconBgColor: DoctorTheme.selesaiPurpleBg,
          iconColor: DoctorTheme.selesaiPurple,
          categoryLabel: 'Selesai',
          chipBgColor: DoctorTheme.selesaiPurpleBg,
          chipTextColor: DoctorTheme.selesaiPurple,
          title: 'Konsultasi dengan $docName selesai',
          subtitle:
              'Terima kasih telah berkonsultasi. Rekomendasi dokter tersimpan dalam riwayat.',
          timeString: AppDateFormatter.formatConversationListTimestamp(time),
          timestamp: time,
          isAlwaysPrevious: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDokterScreen(
                  consultationId: c.id,
                  isDoctor: false,
                  patientUid: c.patientUid,
                  initialConsultation: c,
                  readOnly: true,
                ),
              ),
            );
          },
        ),
      );
    }

    // Jika belum ada chat dokter sama sekali, berikan kartu informasi panduan konsultasi
    if (activeDoctorChats.isEmpty && completedChats.isEmpty) {
      list.add(
        _UserNotificationItem(
          id: 'doc_info_general',
          icon: Icons.medical_services_outlined,
          iconBgColor: const Color(0xFFEAF3F8),
          iconColor: const Color(0xFF1F5C7A),
          categoryLabel: 'Konsultasi',
          chipBgColor: const Color(0xFFDCEBF3),
          chipTextColor: const Color(0xFF1F5C7A),
          title: 'Konsultasi Dokter Spesialis',
          subtitle:
              'Keluhan asam lambung belum reda? Mulai konsultasi langsung dengan dokter spesialis kami.',
          timeString: 'Hari ini',
          timestamp: now.subtract(const Duration(minutes: 10)),
          isAlwaysPrevious: false,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.konsultasi);
          },
        ),
      );
    }

    // Urutkan: terbaru berdasarkan timestamp
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }
}

class _UserNotificationItem {
  final String id;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String categoryLabel;
  final Color chipBgColor;
  final Color chipTextColor;
  final String title;
  final String subtitle;
  final String timeString;
  final DateTime timestamp;
  final bool isAlwaysPrevious;
  final VoidCallback? onTap;

  const _UserNotificationItem({
    required this.id,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.categoryLabel,
    required this.chipBgColor,
    required this.chipTextColor,
    required this.title,
    required this.subtitle,
    required this.timeString,
    required this.timestamp,
    required this.isAlwaysPrevious,
    this.onTap,
  });
}

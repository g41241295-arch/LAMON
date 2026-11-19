import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/doctor_theme.dart';
import '../../constants/practice_slot_constants.dart';
import '../../models/consultation_model.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_date_formatter.dart';
import '../konsultasi/chat_dokter_screen.dart';
import 'doctor_waiting_confirmation_screen.dart';

/// Halaman Notifikasi Dokter (Design System Formal LAMON)
/// Memuat notifikasi dinamis: Pesan Baru, Konsultasi, Jadwal, dan Selesai.
class DoctorNotificationsScreen extends StatefulWidget {
  final String doctorId;
  final List<ConsultationModel>? initialConsultations;
  final Map<String, List<String>>? scheduleMap;

  const DoctorNotificationsScreen({
    super.key,
    required this.doctorId,
    this.initialConsultations,
    this.scheduleMap,
  });

  @override
  State<DoctorNotificationsScreen> createState() =>
      _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen> {
  final DoctorService _doctorService = DoctorService();
  Set<String> _readNotifIds = {};

  @override
  void initState() {
    super.initState();
    _loadReadStatus();
  }

  Future<void> _loadReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('doctor_read_notifs_${widget.doctorId}') ?? [];
      if (mounted) {
        setState(() {
          _readNotifIds = list.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllAsRead(List<_DoctorNotificationItem> allItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedSet = {..._readNotifIds};
      for (final item in allItems) {
        updatedSet.add(item.id);
      }
      await prefs.setStringList(
        'doctor_read_notifs_${widget.doctorId}',
        updatedSet.toList(),
      );
      if (mounted) {
        setState(() {
          _readNotifIds = updatedSet;
        });
      }
    } catch (e) {
      debugPrint('[DoctorNotifications] Error marking all read: $e');
    }
  }

  Future<void> _markSingleAsRead(String id) async {
    if (_readNotifIds.contains(id)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedSet = {..._readNotifIds, id};
      await prefs.setStringList(
        'doctor_read_notifs_${widget.doctorId}',
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
    return Scaffold(
      backgroundColor: DoctorTheme.scaffoldBg,
      body: SafeArea(
        child: StreamBuilder<List<ConsultationModel>>(
          stream: _doctorService.watchDoctorConsultations(widget.doctorId),
          initialData: widget.initialConsultations,
          builder: (context, snapshot) {
            final consultations = snapshot.data ?? widget.initialConsultations ?? [];
            final items = _buildNotificationItems(consultations);

            final unreadItems = items
                .where((item) => !item.isAlwaysPrevious && !_readNotifIds.contains(item.id))
                .toList();
            final previousItems = items
                .where((item) => item.isAlwaysPrevious || _readNotifIds.contains(item.id))
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
                                padding: const EdgeInsets.only(left: 4, bottom: 10),
                                child: Text(
                                  'Baru',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: DoctorTheme.primaryText,
                                  ),
                                ),
                              ),
                              ...unreadItems.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildNotificationCard(context, item, isUnread: true),
                                  )),
                              const SizedBox(height: 10),
                            ],
                            if (previousItems.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 4, top: 4, bottom: 10),
                                child: Text(
                                  'Sebelumnya',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: DoctorTheme.secondaryText,
                                  ),
                                ),
                              ),
                              ...previousItems.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildNotificationCard(context, item, isUnread: false),
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
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<_DoctorNotificationItem> allItems,
    bool hasUnread,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: DoctorTheme.scaffoldBg,
      ),
      child: Row(
        children: [
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
              color: DoctorTheme.primaryText,
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
                    color: hasUnread ? DoctorTheme.primaryLight : DoctorTheme.neutralGray,
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
    _DoctorNotificationItem item, {
    required bool isUnread,
  }) {
    return Container(
      decoration: DoctorTheme.cardDecoration(
        color: Colors.white,
        borderRadius: 24,
        borderColor: DoctorTheme.cardBorder,
        borderWidth: 1.2,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                          color: DoctorTheme.primaryText,
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
                          color: DoctorTheme.secondaryText,
                        ),
                        maxLines: 1,
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
                        color: DoctorTheme.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isUnread)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: DoctorTheme.notifOrange,
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
                color: DoctorTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada notifikasi',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DoctorTheme.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Semua pesan, permintaan konsultasi, dan jadwal praktik Anda akan muncul di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: DoctorTheme.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_DoctorNotificationItem> _buildNotificationItems(
    List<ConsultationModel> consultations,
  ) {
    final list = <_DoctorNotificationItem>[];
    final now = DateTime.now();

    // 1. Pesan Baru Pasien (yang belum dibaca dokter atau sender type patient)
    final unreadChats = consultations.where((c) {
      return c.paymentStatus == PaymentStatus.paid &&
          !c.isCompleted &&
          (c.unreadForDoctor > 0 || c.lastMessageSenderType == 'patient');
    }).toList();

    for (final c in unreadChats) {
      final lastTime = c.lastMessageAt ?? c.createdAt;
      list.add(
        _DoctorNotificationItem(
          id: 'msg_${c.id}_${lastTime.millisecondsSinceEpoch}',
          icon: Icons.mail_outline_rounded,
          iconBgColor: const Color(0xFFEAF3F8),
          iconColor: DoctorTheme.primary,
          categoryLabel: 'Pesan Baru',
          chipBgColor: const Color(0xFFDCEBF3),
          chipTextColor: DoctorTheme.primary,
          title: '${c.displayPatientName} mengirim pesan',
          subtitle: c.lastMessageText?.isNotEmpty == true
              ? c.lastMessageText!
              : 'Pesan baru dari pasien',
          timeString: AppDateFormatter.formatConversationListTimestamp(lastTime),
          timestamp: lastTime,
          isAlwaysPrevious: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDokterScreen(
                  consultationId: c.id,
                  isDoctor: true,
                  patientUid: c.patientUid,
                  initialConsultation: c,
                ),
              ),
            );
          },
        ),
      );
    }

    // 2. Konsultasi Menunggu Konfirmasi (Permintaan Baru)
    final waitingConfirmations = consultations.where((c) {
      return c.paymentStatus == PaymentStatus.paid && c.isWaiting;
    }).toList();

    for (final c in waitingConfirmations) {
      final dateStr = AppDateFormatter.formatScheduledDateTime(
        c.effectiveScheduledDate,
        c.scheduledTime,
      );
      list.add(
        _DoctorNotificationItem(
          id: 'wait_${c.id}',
          icon: Icons.hourglass_empty_rounded,
          iconBgColor: DoctorTheme.konsultasiBoxBg,
          iconColor: DoctorTheme.patientAvatarBrown,
          categoryLabel: 'Konsultasi',
          chipBgColor: DoctorTheme.konsultasiChipBg,
          chipTextColor: DoctorTheme.patientAvatarBrown,
          title: 'Ada yang ingin konsultasi',
          subtitle: '${c.displayPatientName} · $dateStr',
          timeString: AppDateFormatter.formatConversationListTimestamp(c.createdAt),
          timestamp: c.createdAt,
          isAlwaysPrevious: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoctorWaitingConfirmationScreen(
                  doctorId: widget.doctorId,
                ),
              ),
            );
          },
        ),
      );
    }

    // 3. Jadwal Praktik Hari Ini
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final slots = widget.scheduleMap?[todayKey] ?? [];
    for (final slotStr in slots) {
      final parsed = PracticeSlot.fromDynamic(slotStr);
      final timeRange = (parsed.startTime.isNotEmpty && parsed.endTime.isNotEmpty)
          ? '${parsed.startTime} – ${parsed.endTime} WIB'
          : parsed.timeRangeDisplay;

      list.add(
        _DoctorNotificationItem(
          id: 'sched_${todayKey}_${parsed.id}',
          icon: Icons.access_time_rounded,
          iconBgColor: DoctorTheme.jadwalGreenBg,
          iconColor: DoctorTheme.jadwalGreen,
          categoryLabel: 'Jadwal',
          chipBgColor: DoctorTheme.jadwalChipBg,
          chipTextColor: DoctorTheme.jadwalGreen,
          title: 'Sesi ${parsed.label} segera mulai',
          subtitle: '$timeRange · Hari ini',
          timeString: parsed.startTime.isNotEmpty ? parsed.startTime : 'Hari ini',
          timestamp: now,
          isAlwaysPrevious: false,
        ),
      );
    }

    // 4. Selesai (Konsultasi Selesai -> Selalu di bagian Sebelumnya)
    final completedChats = consultations.where((c) => c.isCompleted).toList();
    for (final c in completedChats) {
      final time = c.completedAt ?? c.createdAt;
      list.add(
        _DoctorNotificationItem(
          id: 'done_${c.id}',
          icon: Icons.check_rounded,
          iconBgColor: DoctorTheme.selesaiPurpleBg,
          iconColor: DoctorTheme.selesaiPurple,
          categoryLabel: 'Selesai',
          chipBgColor: DoctorTheme.selesaiPurpleBg,
          chipTextColor: DoctorTheme.selesaiPurple,
          title: 'Konsultasi dengan ${c.displayPatientName} selesai',
          subtitle: 'Terima kasih sudah membantu menjawab keluhan pasien.',
          timeString: AppDateFormatter.formatConversationListTimestamp(time),
          timestamp: time,
          isAlwaysPrevious: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDokterScreen(
                  consultationId: c.id,
                  isDoctor: true,
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

    // Urutkan notifikasi: terbaru berdasarkan timestamp
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }
}

class _DoctorNotificationItem {
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

  const _DoctorNotificationItem({
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

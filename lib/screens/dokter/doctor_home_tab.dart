import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/doctor_theme.dart';
import '../../constants/practice_slot_constants.dart';
import '../../models/consultation_model.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_date_formatter.dart';
import '../beranda/widgets/formal_sapaan_card.dart';
import '../konsultasi/chat_dokter_screen.dart';
import '../konsultasi/widgets/doctor_avatar.dart';
import '../../services/profile_photo_service.dart';
import 'widgets/doctor_calendar_card.dart';
import 'doctor_notifications_screen.dart';
import 'doctor_waiting_confirmation_screen.dart';

/// Tab 1: Beranda Dokter (Design System Formal Konsisten dengan Area Pasien)
class DoctorHomeTab extends StatelessWidget {
  final DoctorModel doctor;
  final List<ConsultationModel> consultations;
  final Map<String, List<String>> scheduleMap;
  final int totalUnreadMessages;
  final VoidCallback onTapProfile;
  final VoidCallback? onTapSearch;
  final VoidCallback onTapWaitingResponse;
  final void Function({bool initialBelumDibalas, bool focusSearch}) onTapMessages;

  const DoctorHomeTab({
    super.key,
    required this.doctor,
    required this.consultations,
    required this.scheduleMap,
    this.totalUnreadMessages = 0,
    required this.onTapProfile,
    this.onTapSearch,
    required this.onTapWaitingResponse,
    required this.onTapMessages,
  });

  @override
  Widget build(BuildContext context) {
    if (doctor.id.isNotEmpty) {
      return StreamBuilder<List<ConsultationModel>>(
        stream: DoctorService().watchDoctorConsultations(doctor.id),
        initialData: consultations,
        builder: (context, snapshot) {
          final liveList = snapshot.data ?? consultations;
          return _buildHomeContent(context, liveList);
        },
      );
    }
    return _buildHomeContent(context, consultations);
  }

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
    return 'Hari Ini, ${date.day} ${months[date.month]}';
  }

  Widget _buildHomeContent(BuildContext context, List<ConsultationModel> consultations) {
    final now = DateTime.now();
    final doctorName = doctor.formattedNameWithDoctorTitle;

    // Hitung statistik pasien hari ini:
    final todayConsultations = consultations.where((c) {
      if (c.paymentStatus != PaymentStatus.paid) return false;
      final isConfirmed = c.status == 'active' || c.status == 'completed';
      if (!isConfirmed) return false;

      final sched = c.effectiveScheduledDate;
      return sched.year == now.year &&
          sched.month == now.month &&
          sched.day == now.day;
    }).toList();

    // "Menunggu respons" mengecualikan completed:
    final waitingResponseList = consultations.where((c) {
      return c.paymentStatus == PaymentStatus.paid &&
          !c.isCompleted &&
          c.lastMessageSenderType == 'patient';
    }).toList();

    final waitingConfirmationList = consultations.where((c) {
      return c.paymentStatus == PaymentStatus.paid && c.isWaiting;
    }).toList();

    // Rekonsiliasi consultationsHandled:
    final completedCount = consultations.where((c) => c.isCompleted).length;
    if (completedCount > doctor.consultationsHandled) {
      DoctorService().reconcileConsultationsHandled(
        doctorId: doctor.id,
        completedCount: completedCount,
      );
    }

    // Jadwal praktik dokter hari ini:
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todaySlots = scheduleMap[todayKey] ?? [];

    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 24;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Header Bar: Logo LAMON + Avatar Bulat + Tanggal Hari Ini ──
          _buildHeaderBar(context, now, consultations),
          const SizedBox(height: 18),

          // ── 2. Kartu Sambutan Formal (Menggunakan FormalSapaanCard dengan Maskot Lambung) ──
          _buildWelcomeCard(doctorName),
          const SizedBox(height: 16),

          // ── 3. Kartu Jadwal Praktik Hari Ini (Deep Teal Gradient Hero Card) ──
          _buildScheduleHeroCard(
            todaySlots: todaySlots,
            waitingConfirmationCount: waitingConfirmationList.length,
          ),
          const SizedBox(height: 18),

          // ── 4. Dua Kartu Statistik Sejajar ──
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Pasien hari ini',
                  value: '${todayConsultations.length}',
                  valueColor: DoctorTheme.primary,
                  borderColor: DoctorTheme.cardBorder,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: onTapWaitingResponse,
                  child: _buildStatCard(
                    title: 'Menunggu respons',
                    value: '${waitingResponseList.length}',
                    valueColor: waitingResponseList.isNotEmpty
                        ? DoctorTheme.alertRed
                        : DoctorTheme.neutralGray,
                    borderColor: waitingResponseList.isNotEmpty
                        ? DoctorTheme.alertRedBorder
                        : DoctorTheme.cardBorder,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 5. Kartu Statistik Penilaian Dokter Live ──
          _buildRatingStatsCard(doctor.id),
          const SizedBox(height: 24),

          // ── 6. Section Jadwal Praktik Kalender ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(
                icon: Icons.calendar_month_rounded,
                label: 'Jadwal Praktik',
              ),
              Flexible(
                child: Text(
                  'Tap tanggal untuk edit',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: DoctorTheme.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DoctorCalendarCard(
            doctorId: doctor.id,
            scheduleMap: scheduleMap,
          ),
          const SizedBox(height: 24),

          // ── 7. Section Pesan Pasien ──
          const DoctorSectionHeader(
            icon: Icons.chat_bubble_rounded,
            title: 'Pesan Pasien',
          ),
          const SizedBox(height: 12),

          // Kartu Pesan Masuk Tunggal dengan Pratinjau Pesan Terakhir
          _buildMessagesCard(context, consultations, totalUnreadMessages),
          const SizedBox(height: 24),

          // ── 8. Section Menunggu Konfirmasi (Dengan Kotak Ikon & Link "Lihat semua ›") ──
          DoctorSectionHeader(
            icon: Icons.hourglass_empty_rounded,
            title: 'Menunggu Konfirmasi',
            trailing: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorWaitingConfirmationScreen(
                      doctorId: doctor.id,
                      initialConsultations: consultations,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  'Lihat semua ›',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DoctorTheme.primaryLight,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (waitingConfirmationList.isEmpty)
            _buildEmptyConfirmationCard()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: waitingConfirmationList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = waitingConfirmationList[index];
                return _buildWaitingItemCard(context, item);
              },
            ),
        ],
      ),
    );
  }

  // ── Header Bar: Avatar Bulat 46px + Teks LAMON + Tanggal Hari Ini + Lonceng 46px ──
  Widget _buildHeaderBar(
    BuildContext context,
    DateTime now,
    List<ConsultationModel> liveConsultations,
  ) {
    return Row(
      children: [
        // Avatar Dokter (46px bulat) + Teks LAMON (Tap untuk buka profil dokter)
        GestureDetector(
          onTap: onTapProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: DoctorTheme.cardBorder, width: 1.2),
                ),
                child: ClipOval(
                  child: RealtimeHeaderAvatar(
                    collection: 'doctors',
                    docId: doctor.id,
                    size: 46,
                    borderRadius: 23,
                    fallback: DoctorAvatar(
                      photoUrl: doctor.effectivePhotoUrl,
                      doctorId: doctor.id,
                      doctorName: doctor.name,
                      size: 46,
                      borderRadius: 23,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'LAMON',
                style: GoogleFonts.poppins(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: DoctorTheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Chip Tanggal "Hari Ini, 17 Nov"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: DoctorTheme.cardBorder,
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
            _formatDate(now),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DoctorTheme.primaryText,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Lonceng Notifikasi 46px Bulat
        _DoctorNotificationBellButton(
          doctorId: doctor.id,
          consultations: liveConsultations,
          scheduleMap: scheduleMap,
        ),
      ],
    );
  }

  // ── Kartu Sambutan Formal (Identik dengan Sapaan Pasien) ──
  Widget _buildWelcomeCard(String doctorName) {
    return FormalSapaanCard(
      userName: doctorName,
      customGreeting: 'Halo, Dokter!',
      customTitle: 'Selamat Datang,\n$doctorName',
      customSubtitle: 'Kelola jadwal praktik dan konsultasi pasienmu di sini',
    );
  }

  // ── Kartu Jadwal Praktik Hari Ini (Deep Teal Gradient Hero Card) ──
  Widget _buildScheduleHeroCard({
    required List<String> todaySlots,
    required int waitingConfirmationCount,
  }) {
    final hasSlots = todaySlots.isNotEmpty;
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment(-0.8, -0.8),
          end: Alignment(0.8, 0.8),
          colors: [Color(0xFF1F5C7A), Color(0xFF2E85A8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F5C7A).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header kartu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Praktik Hari Ini',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        hasSlots
                            ? '${todaySlots.length} sesi praktik terjadwal'
                            : 'Tidak ada sesi hari ini',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (hasSlots)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Aktif',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 16),

          if (hasSlots)
            Column(
              children: [
                for (int i = 0; i < todaySlots.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _buildPracticeSlotRow(
                    slotStr: todaySlots[i],
                    now: now,
                  ),
                ],
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tidak ada jadwal praktik hari ini',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Baris Sesi Praktik Dokter dengan Tab "Sekarang" di Pojok Kanan Atas ──
  Widget _buildPracticeSlotRow({
    required String slotStr,
    required DateTime now,
  }) {
    final parsed = PracticeSlot.fromDynamic(slotStr);
    final isOngoing = _isSlotOngoing(parsed, now);
    final timeDisplay = (parsed.startTime.isNotEmpty && parsed.endTime.isNotEmpty)
        ? '${parsed.startTime} - ${parsed.endTime} WIB'
        : parsed.timeRangeDisplay;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isOngoing
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOngoing
                  ? Colors.white.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.14),
              width: isOngoing ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                parsed.icon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                parsed.label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                softWrap: false,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isOngoing
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  timeDisplay,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE3EEF5),
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
        if (isOngoing)
          Positioned(
            top: -11,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: DoctorTheme.accentGold,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Sekarang',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4A3200),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isSlotOngoing(PracticeSlot slot, DateTime now) {
    if (slot.startTime.isEmpty || slot.endTime.isEmpty) return false;
    try {
      final startParts = slot.startTime.replaceAll(':', '.').split('.');
      final endParts = slot.endTime.replaceAll(':', '.').split('.');
      if (startParts.length < 2 || endParts.length < 2) return false;
      final startMinutes = int.parse(startParts[0].trim()) * 60 + int.parse(startParts[1].trim());
      final endMinutes = int.parse(endParts[0].trim()) * 60 + int.parse(endParts[1].trim());
      final nowMinutes = now.hour * 60 + now.minute;
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } catch (_) {
      return false;
    }
  }

  // ── Kartu Pesan Masuk Tunggal (Revisi 2 Bagian Pesan Pasien) ──
  Widget _buildMessagesCard(
    BuildContext context,
    List<ConsultationModel> consultations,
    int totalUnread,
  ) {
    // Cari pesan terakhir dari seluruh percakapan
    ConsultationModel? latestItem;
    for (final c in consultations) {
      if (c.lastMessageText != null && c.lastMessageText!.trim().isNotEmpty) {
        if (latestItem == null) {
          latestItem = c;
        } else {
          final tItem = latestItem.lastMessageAt ?? latestItem.createdAt;
          final tCurrent = c.lastMessageAt ?? c.createdAt;
          if (tCurrent.isAfter(tItem)) {
            latestItem = c;
          }
        }
      }
    }

    if (latestItem == null && consultations.isNotEmpty) {
      latestItem = consultations.first;
    }

    return GestureDetector(
      onTap: () => onTapMessages(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: DoctorTheme.cardDecoration(
          borderRadius: 22,
          borderColor: totalUnread > 0
              ? DoctorTheme.unreadCardBorder
              : DoctorTheme.cardBorder,
        ),
        child: Column(
          children: [
            // Baris Atas
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DoctorTheme.envelopeIconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    color: DoctorTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesan Masuk',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DoctorTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        totalUnread > 0
                            ? '$totalUnread pesan belum dibaca'
                            : 'Tidak ada pesan baru',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: totalUnread > 0
                              ? DoctorTheme.alertRed
                              : DoctorTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (totalUnread > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DoctorTheme.alertRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      totalUnread > 99 ? '99+' : '$totalUnread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DoctorTheme.neutralGray,
                  size: 22,
                ),
              ],
            ),

            // Garis Pemisah Tipis
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: DoctorTheme.cardBorder,
            ),
            const SizedBox(height: 12),

            // Baris Pratinjau Pesan Terakhir
            if (latestItem != null) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: DoctorTheme.getAvatarColors(latestItem.displayPatientName).background,
                    child: Text(
                      latestItem.patientInitials,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: DoctorTheme.getAvatarColors(latestItem.displayPatientName).text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latestItem.displayPatientName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DoctorTheme.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          (latestItem.lastMessageText != null && latestItem.lastMessageText!.isNotEmpty)
                              ? latestItem.lastMessageText!
                              : (latestItem.isWaiting ? 'Menunggu konfirmasi konsultasi' : 'Belum ada pesan'),
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
                  const SizedBox(width: 8),
                  Text(
                    _formatMessagePreviewTime(latestItem.lastMessageAt ?? latestItem.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: DoctorTheme.neutralGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: DoctorTheme.neutralGray,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Belum ada pesan dari pasien',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: DoctorTheme.neutralGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatMessagePreviewTime(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      final hourStr = date.hour.toString().padLeft(2, '0');
      final minuteStr = date.minute.toString().padLeft(2, '0');
      return '$hourStr.$minuteStr';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
    if (isYesterday) {
      return 'Kemarin';
    }
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month]}';
  }

  // ── Empty State Menunggu Konfirmasi ──
  Widget _buildEmptyConfirmationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: DoctorTheme.cardDecoration(
        borderRadius: 22,
        borderColor: DoctorTheme.cardBorder,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: DoctorTheme.envelopeIconBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: DoctorTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada permintaan baru',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DoctorTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Permintaan konsultasi akan muncul di sini',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: DoctorTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu Item Menunggu Konfirmasi (Revisi 2 Bagian Menunggu Konfirmasi) ──
  Widget _buildWaitingItemCard(BuildContext context, ConsultationModel item) {
    final scheduleDisplay = AppDateFormatter.formatScheduledDateTime(
      item.effectiveScheduledDate,
      item.scheduledTime,
    );
    final avatarColors = DoctorTheme.getAvatarColors(item.displayPatientName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DoctorTheme.cardDecoration(
        borderRadius: 20,
        borderColor: const Color(0xFFF2D9B0),
        borderWidth: 1.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColors.background,
                child: Text(
                  item.patientInitials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: avatarColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayPatientName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DoctorTheme.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (scheduleDisplay.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        scheduleDisplay,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: DoctorTheme.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3DC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Baru',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB5651D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleReject(context, item),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: DoctorTheme.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: Text(
                    'Tolak',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: DoctorTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAccept(context, item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DoctorTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: Text(
                    'Terima',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context, ConsultationModel item) async {
    try {
      final doctorService = DoctorService();
      await doctorService.confirmConsultation(
        patientUid: item.patientUid,
        consultationId: item.id,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDokterScreen(
              consultationId: item.id,
              isDoctor: true,
              patientUid: item.patientUid,
              initialConsultation: item.copyWith(
                status: 'active',
                doctorConfirmedAt: DateTime.now(),
                unreadForDoctor: 0,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[DoctorHomeTab] Error confirming consultation: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengonfirmasi konsultasi: $e'),
            backgroundColor: DoctorTheme.alertRed,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, ConsultationModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Tolak Permintaan Konsultasi?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: DoctorTheme.primaryText,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menolak permintaan konsultasi dari ${item.displayPatientName}?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: DoctorTheme.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: DoctorTheme.secondaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorTheme.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Tolak',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      String pUid = item.patientUid.trim();
      if (pUid.isEmpty) {
        final snap = await FirebaseFirestore.instance
            .collectionGroup('consultations')
            .where(FieldPath.documentId, isEqualTo: item.id)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final segments = snap.docs.first.reference.path.split('/');
          final idx = segments.indexOf('users');
          if (idx != -1 && idx + 1 < segments.length) {
            pUid = segments[idx + 1];
          }
        }
      }

      if (pUid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(pUid)
            .collection('consultations')
            .doc(item.id)
            .update({
          'status': 'cancelled',
          'unreadForDoctor': 0,
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan konsultasi telah ditolak'),
            backgroundColor: DoctorTheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('[DoctorHomeTab] Error rejecting consultation: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menolak konsultasi: $e'),
            backgroundColor: DoctorTheme.alertRed,
          ),
        );
      }
    }
  }

  // ── Kartu Statistik Bersih ──
  Widget _buildStatCard({
    required String title,
    required String value,
    required Color valueColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DoctorTheme.cardDecoration(
        borderColor: borderColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DoctorTheme.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu Statistik Penilaian Dokter Live ──
  Widget _buildRatingStatsCard(String doctorId) {
    if (doctorId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final ratingSum = (data['ratingSum'] as num?)?.toInt() ?? 0;
        final ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;
        final avgRating = ratingCount > 0 ? (ratingSum / ratingCount) : 0.0;
        final formattedAvg =
            ratingCount > 0 ? avgRating.toStringAsFixed(1) : '-';
        final countText =
            ratingCount > 0 ? '$ratingCount penilaian' : 'Belum ada penilaian';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: DoctorTheme.cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFECB3), width: 1),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFB300),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penilaian Pasien',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DoctorTheme.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ratingCount > 0
                            ? DoctorTheme.primary
                            : DoctorTheme.neutralGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    formattedAvg,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: DoctorTheme.primaryText,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '/ 5.0',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DoctorTheme.neutralGray,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Judul Section Formal ──
  Widget _buildSectionTitle({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: DoctorTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: DoctorTheme.primaryText,
          ),
        ),
      ],
    );
  }
}

/// Tombol Lonceng Notifikasi Bulat 46px dengan Titik Oranye Realtime
class _DoctorNotificationBellButton extends StatefulWidget {
  final String doctorId;
  final List<ConsultationModel> consultations;
  final Map<String, List<String>> scheduleMap;

  const _DoctorNotificationBellButton({
    required this.doctorId,
    required this.consultations,
    required this.scheduleMap,
  });

  @override
  State<_DoctorNotificationBellButton> createState() =>
      _DoctorNotificationBellButtonState();
}

class _DoctorNotificationBellButtonState
    extends State<_DoctorNotificationBellButton> {
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _checkUnread();
  }

  @override
  void didUpdateWidget(covariant _DoctorNotificationBellButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.consultations != widget.consultations ||
        oldWidget.doctorId != widget.doctorId) {
      _checkUnread();
    }
  }

  Future<void> _checkUnread() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds =
          (prefs.getStringList('doctor_read_notifs_${widget.doctorId}') ?? [])
              .toSet();

      // Periksa pesan baru yang belum dibaca dokter
      final unreadChats = widget.consultations.where((c) {
        return c.paymentStatus == PaymentStatus.paid &&
            !c.isCompleted &&
            (c.unreadForDoctor > 0 || c.lastMessageSenderType == 'patient');
      }).toList();

      for (final c in unreadChats) {
        final lastTime = c.lastMessageAt ?? c.createdAt;
        final id = 'msg_${c.id}_${lastTime.millisecondsSinceEpoch}';
        if (!readIds.contains(id)) {
          if (mounted) setState(() => _hasUnread = true);
          return;
        }
      }

      // Periksa konsultasi menunggu konfirmasi
      final waiting = widget.consultations.where((c) {
        return c.paymentStatus == PaymentStatus.paid && c.isWaiting;
      }).toList();

      for (final c in waiting) {
        final id = 'wait_${c.id}';
        if (!readIds.contains(id)) {
          if (mounted) setState(() => _hasUnread = true);
          return;
        }
      }

      if (mounted) setState(() => _hasUnread = false);
    } catch (_) {
      final fallbackUnread = widget.consultations.any((c) =>
          c.paymentStatus == PaymentStatus.paid &&
          (!c.isCompleted &&
              (c.unreadForDoctor > 0 ||
                  c.lastMessageSenderType == 'patient' ||
                  c.isWaiting)));
      if (mounted) setState(() => _hasUnread = fallbackUnread);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorNotificationsScreen(
              doctorId: widget.doctorId,
              initialConsultations: widget.consultations,
              scheduleMap: widget.scheduleMap,
            ),
          ),
        );
        _checkUnread();
      },
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: DoctorTheme.cardBorder,
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 22,
              color: DoctorTheme.primary,
            ),
            if (_hasUnread)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: DoctorTheme.notifOrange,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

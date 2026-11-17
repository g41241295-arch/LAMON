import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          _buildHeaderBar(context, now),
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
          _buildSectionTitle(
            icon: Icons.chat_bubble_rounded,
            label: 'Pesan Pasien',
          ),
          const SizedBox(height: 10),

          // Kartu Akses Cepat "Pesan"
          GestureDetector(
            onTap: () => onTapMessages(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: DoctorTheme.cardDecoration(
                borderColor: totalUnreadMessages > 0
                    ? DoctorTheme.alertRedBorder
                    : DoctorTheme.cardBorder,
                borderWidth: totalUnreadMessages > 0 ? 1.5 : 1.2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: totalUnreadMessages > 0
                          ? DoctorTheme.alertRedBg
                          : DoctorTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      color: totalUnreadMessages > 0
                          ? DoctorTheme.alertRed
                          : DoctorTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Pesan',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: DoctorTheme.primaryText,
                          ),
                        ),
                        if (totalUnreadMessages > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: DoctorTheme.alertRed,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              totalUnreadMessages > 99
                                  ? '99+'
                                  : '$totalUnreadMessages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: DoctorTheme.neutralGray,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── 8. Section Menunggu Konfirmasi ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(
                icon: Icons.hourglass_top_rounded,
                label: 'Menunggu Konfirmasi',
              ),
              if (waitingConfirmationList.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: DoctorTheme.alertRedBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DoctorTheme.alertRedBorder),
                  ),
                  child: Text(
                    '${waitingConfirmationList.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: DoctorTheme.alertRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (waitingConfirmationList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: DoctorTheme.cardDecoration(
                borderColor: DoctorTheme.cardBorder,
              ),
              child: Center(
                child: Text(
                  'Belum ada permintaan konsultasi baru',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: DoctorTheme.neutralGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: waitingConfirmationList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = waitingConfirmationList[index];
                return _buildWaitingItemCard(context, item);
              },
            ),
        ],
      ),
    );
  }

  // ── Header Bar: Logo LAMON + Avatar Dokter Dinamis + Tanggal Hari Ini ──
  Widget _buildHeaderBar(BuildContext context, DateTime now) {
    return Row(
      children: [
        // Avatar Dokter + Logo LAMON (Tap untuk buka profil dokter)
        GestureDetector(
          onTap: onTapProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RealtimeHeaderAvatar(
                collection: 'doctors',
                docId: doctor.id,
                size: 38,
                borderRadius: 19,
                fallback: DoctorAvatar(
                  photoUrl: doctor.effectivePhotoUrl,
                  doctorId: doctor.id,
                  doctorName: doctor.name,
                  size: 38,
                  borderRadius: 19,
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/lamon-logo.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 5),
              Text(
                'LAMON',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: DoctorTheme.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Date Navigator Pill ala Halaman Pasien: Hari Ini, 17 Nov
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: DoctorTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(now),
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: DoctorTheme.primaryText,
                ),
              ),
            ],
          ),
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: DoctorTheme.heroGradient,
        boxShadow: [
          BoxShadow(
            color: DoctorTheme.primaryDark.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Atas Hero Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Colors.white,
                      size: 20,
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
                          fontSize: 11,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7DE6D6), // Mint green
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Aktif',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (hasSlots) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            // Daftar sesi per baris rapi (Sarapan/Siang/Malam style)
            Column(
              children: todaySlots.map((slotStr) {
                final parsed = PracticeSlot.fromDynamic(slotStr);
                final timeDisplay = (parsed.startTime.isNotEmpty && parsed.endTime.isNotEmpty)
                    ? '${parsed.startTime} - ${parsed.endTime} WIB'
                    : parsed.timeRangeDisplay;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          parsed.icon,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            parsed.label,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            timeDisplay,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: DoctorTheme.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              waitingConfirmationCount > 0
                  ? 'Ada $waitingConfirmationCount permintaan konsultasi menunggu konfirmasimu.'
                  : 'Semoga harimu menyenangkan, Dokter! Kelola konsultasi pasienmu dengan mudah.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
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

  Widget _buildWaitingItemCard(BuildContext context, ConsultationModel item) {
    final scheduleDisplay = AppDateFormatter.formatScheduledDateTime(
      item.effectiveScheduledDate,
      item.scheduledTime,
    );

    return GestureDetector(
      onTap: () => _showConfirmationBottomSheet(context, item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: DoctorTheme.cardDecoration(
          borderRadius: 18,
          borderColor: DoctorTheme.cardBorder,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: DoctorTheme.primary.withValues(alpha: 0.1),
              child: Text(
                item.patientInitials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: DoctorTheme.primary,
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
                  const SizedBox(height: 2),
                  Text(
                    scheduleDisplay,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: DoctorTheme.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (item.isNew)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DoctorTheme.alertRedBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DoctorTheme.alertRedBorder),
                ),
                child: const Text(
                  'Baru',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: DoctorTheme.alertRed,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationBottomSheet(
      BuildContext context, ConsultationModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Detail Permintaan Konsultasi',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: DoctorTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 14),
                _detailRow('Nama Pasien', item.displayPatientName),
                if (item.patientGender != null && item.patientGender!.isNotEmpty)
                  _detailRow('Jenis Kelamin', item.patientGender!),
                if (item.patientAge != null)
                  _detailRow('Usia', '${item.patientAge} tahun'),
                _detailRow(
                  'Jadwal Konsultasi',
                  AppDateFormatter.formatScheduledDateTime(
                    item.effectiveScheduledDate,
                    item.scheduledTime,
                  ),
                ),
                _detailRow(
                  'Waktu Pemesanan',
                  AppDateFormatter.formatFullDateTime(item.createdAt),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: DoctorTheme.secondaryButtonStyle(),
                        child: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
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
                        },
                        style: DoctorTheme.primaryButtonStyle(),
                        child: const Text('Konfirmasi & Mulai Chat'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: DoctorTheme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ': ',
            style: GoogleFonts.poppins(
              color: DoctorTheme.secondaryText,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DoctorTheme.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

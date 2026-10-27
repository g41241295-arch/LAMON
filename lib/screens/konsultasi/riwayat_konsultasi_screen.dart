import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/consultation_model.dart';
import '../../models/doctor_model.dart';
import '../../services/consultation_service.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_date_formatter.dart';
import '../../widgets/app_header_pill.dart';
import '../../widgets/app_scaffold.dart';
import 'chat_dokter_screen.dart';
import 'widgets/doctor_avatar.dart';

/// Layar Riwayat Konsultasi (Sisi Pasien).
/// Menampilkan daftar konsultasi berstatus "completed" yang dikelompokkan per tanggal.
class RiwayatKonsultasiScreen extends StatefulWidget {
  const RiwayatKonsultasiScreen({super.key});

  @override
  State<RiwayatKonsultasiScreen> createState() =>
      _RiwayatKonsultasiScreenState();
}

class _RiwayatKonsultasiScreenState extends State<RiwayatKonsultasiScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final DoctorService _doctorService = DoctorService();
  bool _isNavigating = false;

  Future<void> _handleChatUlang(
      BuildContext context, ConsultationModel consultation) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    // Capture navigator & messenger before async gap
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      DoctorModel? doctor =
          await _doctorService.getDoctorById(consultation.doctorId);

      doctor ??= DoctorModel(
        id: consultation.doctorId,
        name: consultation.doctorName,
        specialty: consultation.doctorSpecialty,
        experienceYears: 5,
        photoUrl: consultation.doctorPhotoUrl,
        price: consultation.sessionFee > 0 ? consultation.sessionFee : 50000,
        operatingHours: const [],
        alumni: '',
        isRecommended: false,
        practiceLocation: '',
        strNumber: '',
      );

      if (!mounted) return;

      nav.pushNamed(
        '/konsultasi/pembayaran/${doctor.id}',
        arguments: doctor,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal memulai chat ulang: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  /// Mengelompokkan konsultasi per tanggal (yyyy-MM-dd)
  Map<String, List<ConsultationModel>> _groupByDate(
      List<ConsultationModel> list) {
    final Map<String, List<ConsultationModel>> grouped = {};
    for (final item in list) {
      final date = item.completedAt ?? item.createdAt;
      final key = AppDateFormatter.formatDateKey(date);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppHeaderPill(
        title: 'Riwayat Konsultasi',
      ),
      body: StreamBuilder<List<ConsultationModel>>(
        stream: _consultationService.watchAllPatientConsultations(),
        builder: (context, snapshot) {
          // ── 1. State Loading ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 14),
                  Text(
                    'Memuat riwayat konsultasi...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.summaryCardSubtext,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // ── 2. State Error (Tampil sebagai error, bukan empty) ──
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline_rounded,
                          color: Colors.red, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal Memuat Riwayat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.summaryCardSubtext,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final allList = snapshot.data ?? [];

          // ── Pisahkan Sisi Klien: Sedang Berlangsung vs Selesai ──
          final ongoingList = allList
              .where((c) => c.isActive || c.isWaiting)
              .toList();

          ongoingList.sort((a, b) {
            final timeA = a.lastMessageAt ?? a.createdAt;
            final timeB = b.lastMessageAt ?? b.createdAt;
            return timeB.compareTo(timeA);
          });

          final completedList = allList
              .where((c) => c.isCompleted)
              .toList();

          completedList.sort((a, b) {
            final timeA = a.completedAt ?? a.createdAt;
            final timeB = b.completedAt ?? b.createdAt;
            return timeB.compareTo(timeA);
          });

          // ── 3. State Kosong (Empty) hanya jika kedua bagian kosong ──
          if (ongoingList.isEmpty && completedList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Belum ada riwayat konsultasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Konsultasi yang sedang berlangsung dan yang sudah selesai akan tampil di halaman ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.summaryCardSubtext,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── 4. Tampilan Riwayat Konsultasi (Dua Bagian) ──
          final groupedCompleted = _groupByDate(completedList);
          final sortedDateKeys = groupedCompleted.keys.toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // ══════════════════════════════════════════════════════════════
              // BAGIAN ATAS: Sedang Berlangsung (hanya jika ada)
              // ══════════════════════════════════════════════════════════════
              if (ongoingList.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sedang Berlangsung (${ongoingList.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                ...ongoingList.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildOngoingConsultationCard(context, item),
                    )),
                const SizedBox(height: 10),
              ],

              // ══════════════════════════════════════════════════════════════
              // BAGIAN BAWAH: Selesai (hanya jika ada)
              // ══════════════════════════════════════════════════════════════
              if (completedList.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: AppColors.neutralGray,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Selesai (${completedList.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                ...sortedDateKeys.expand((dateKey) {
                  final items = groupedCompleted[dateKey]!;
                  final firstDate =
                      items.first.completedAt ?? items.first.createdAt;
                  final formattedHeaderDate =
                      AppDateFormatter.formatLongDate(firstDate);

                  return [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedHeaderDate,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildConsultationHistoryCard(context, item),
                        )),
                  ];
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildOngoingConsultationCard(
      BuildContext context, ConsultationModel item) {
    final isActive = item.isActive;

    final badgeBg = isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1);
    final badgeBorder =
        isActive ? const Color(0xFFC8E6C9) : const Color(0xFFFFECB3);
    final badgeColor =
        isActive ? const Color(0xFF2E7D32) : const Color(0xFFB45309);
    final badgeDotColor =
        isActive ? AppColors.successGreen : const Color(0xFFB45309);
    final badgeText = isActive ? 'Berlangsung' : 'Menunggu Konfirmasi';

    final buttonLabel = isActive ? 'Lanjutkan Chat' : 'Buka Chat';

    void openLiveChat() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDokterScreen(
            consultationId: item.id,
            isDoctor: false,
            patientUid: item.patientUid,
            initialConsultation: item,
            readOnly: false, // LIVE CHAT!
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: openLiveChat,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? AppColors.successGreen.withValues(alpha: 0.35)
                  : const Color(0xFFE2ECF2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Atas: Label & Badge Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Konsultasi Dokter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.summaryCardSubtext,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeBorder, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: badgeDotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Baris Tengah: Foto, Nama, Spesialisasi, dan Waktu Praktik
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DoctorAvatar(
                    photoUrl: item.effectiveDoctorPhotoUrl,
                    doctorId: item.doctorId,
                    doctorName: item.doctorName,
                    size: 56,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.doctorName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.doctorSpecialty,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.summaryCardSubtext,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.scheduledTime.isNotEmpty
                                  ? item.scheduledTime
                                  : 'Sesuai Jadwal',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Cuplikan Pesan Terakhir Satu Baris (Ellipsis) dengan Jamnya
              if (item.lastMessageText != null &&
                  item.lastMessageText!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEDF2F7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 13,
                        color: AppColors.neutralGray,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.lastMessageText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (item.lastMessageAt != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          AppDateFormatter.formatTime(item.lastMessageAt!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.neutralGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEEF3F6)),
              const SizedBox(height: 12),

              // Baris Bawah: Badge Pesan Belum Dibaca + Tombol Utama Pill Terisi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.unreadForPatient > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item.unreadForPatient} belum dibaca',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton.icon(
                    onPressed: openLiveChat,
                    icon: const Icon(Icons.chat_rounded, size: 16),
                    label: Text(buttonLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationHistoryCard(
      BuildContext context, ConsultationModel item) {
    final finishTime = item.completedAt ?? item.createdAt;
    final finishTimeStr = AppDateFormatter.formatFullDateTime(finishTime);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDokterScreen(
                consultationId: item.id,
                isDoctor: false,
                patientUid: item.patientUid,
                initialConsultation: item,
                readOnly: true,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2ECF2), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Atas: Judul "Konsultasi dengan" & Badge Status "Selesai" (Hijau)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Konsultasi dengan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.summaryCardSubtext,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: Color(0xFF2E7D32),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Baris Tengah: Foto, Nama, Spesialisasi Dokter, dan Jam Konsultasi
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DoctorAvatar(
                photoUrl: item.effectiveDoctorPhotoUrl,
                doctorId: item.doctorId,
                doctorName: item.doctorName,
                size: 56,
                borderRadius: 14,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.doctorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.doctorSpecialty,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.summaryCardSubtext,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.scheduledTime.isNotEmpty
                              ? item.scheduledTime
                              : 'Sesuai Jadwal',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEF3F6)),
          const SizedBox(height: 12),

          // Baris Tanggal & Jam Lengkap
          Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                size: 14,
                color: AppColors.summaryCardSubtext,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Waktu Selesai: $finishTimeStr',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.summaryCardSubtext,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rating UI Statis (Placeholder non-fungsional sesuai Keputusan Audit b & Kriteria 5)
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => const Icon(
                    Icons.star_rounded,
                    size: 17,
                    color: Color(0xFFFFB300),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Belum dinilai (Segera Hadir)',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.neutralGray,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Tombol Chat Ulang (Pill Outline)
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _handleChatUlang(context, item),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Chat Ulang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

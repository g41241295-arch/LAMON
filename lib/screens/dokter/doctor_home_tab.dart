import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/consultation_model.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_date_formatter.dart';
import '../konsultasi/chat_dokter_screen.dart';
import '../konsultasi/widgets/doctor_avatar.dart';
import 'widgets/doctor_calendar_card.dart';

/// Tab 1: Beranda Dokter
class DoctorHomeTab extends StatelessWidget {
  final DoctorModel doctor;
  final List<ConsultationModel> consultations;
  final Map<String, List<String>> scheduleMap;
  final VoidCallback onTapProfile;
  final VoidCallback onTapSearch;
  final VoidCallback onTapWaitingResponse;

  const DoctorHomeTab({
    super.key,
    required this.doctor,
    required this.consultations,
    required this.scheduleMap,
    required this.onTapProfile,
    required this.onTapSearch,
    required this.onTapWaitingResponse,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = AppDateFormatter.getGreetingWord(now);
    final doctorName = doctor.formattedNameWithDoctorTitle;

    // Hitung statistik:
    // 1. Pasien hari ini: paid & tanggal hari ini
    final today = DateTime(now.year, now.month, now.day);
    final todayConsultations = consultations.where((c) {
      if (c.paymentStatus != PaymentStatus.paid) return false;
      final cDate = DateTime(c.createdAt.year, c.createdAt.month, c.createdAt.day);
      return cDate.isAtSameMomentAs(today);
    }).toList();

    // 2. Menunggu respons: paid & pesan terakhir dari pasien
    final waitingResponseList = consultations.where((c) {
      return c.paymentStatus == PaymentStatus.paid &&
          c.lastMessageSenderType == 'patient';
    }).toList();

    // 3. Menunggu konfirmasi: paid & status waiting
    final waitingConfirmationList = consultations.where((c) {
      return c.paymentStatus == PaymentStatus.paid && c.isWaiting;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Baris Atas (Avatar Kecil + Shortcut Cari Pasien) ──
          Row(
            children: [
              GestureDetector(
                onTap: onTapProfile,
                child: DoctorAvatar(
                  photoUrl: doctor.photoUrl,
                  size: 44,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onTapSearch,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.inputBorder,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded,
                            color: AppColors.neutralGray, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Cari pasien...',
                          style: TextStyle(
                            color: AppColors.neutralGray,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── 2. Kartu Sapaan Biru Rounded ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF276F8F), Color(0xFF1E5A74)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                DoctorAvatar(
                  photoUrl: doctor.photoUrl,
                  size: 52,
                  borderRadius: 14,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialty.isNotEmpty
                            ? doctor.specialty
                            : 'Dokter Umum',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── 3. Dua Kartu Statistik Sejajar ──
          Row(
            children: [
              // Pasien Hari Ini
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2F0F9), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pasien hari ini',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.summaryCardSubtext,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${todayConsultations.length}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Menunggu Respons
              Expanded(
                child: GestureDetector(
                  onTap: onTapWaitingResponse,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: waitingResponseList.isNotEmpty
                            ? const Color(0xFFFFCDD2)
                            : const Color(0xFFE2F0F9),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Menunggu respons',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.summaryCardSubtext,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${waitingResponseList.length}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: waitingResponseList.isNotEmpty
                                ? const Color(0xFFD32F2F)
                                : AppColors.neutralGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 4. Section Jadwal Praktik ──
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jadwal Praktik',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                'Tap tanggal untuk edit',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.summaryCardSubtext,
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

          // ── 5. Section Menunggu Konfirmasi ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Menunggu Konfirmasi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              if (waitingConfirmationList.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${waitingConfirmationList.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F),
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EFF5)),
              ),
              child: const Center(
                child: Text(
                  'Belum ada permintaan konsultasi baru',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.neutralGray,
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

  Widget _buildWaitingItemCard(BuildContext context, ConsultationModel item) {
    final scheduleDisplay = item.scheduledTime.isNotEmpty
        ? 'Jadwal: ${item.scheduledTime}'
        : 'Hari ini, ${AppDateFormatter.formatTime(item.createdAt)} WIB';

    return GestureDetector(
      onTap: () => _showConfirmationBottomSheet(context, item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2F0F9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar inisial
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
              child: Text(
                item.patientInitials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nama & Waktu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayPatientName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scheduleDisplay,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.summaryCardSubtext,
                    ),
                  ),
                ],
              ),
            ),

            // Badge "Baru" jika dibuat <24 jam
            if (item.isNew)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: const Text(
                  'Baru',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
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
                const Text(
                  'Detail Permintaan Konsultasi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
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
                  item.scheduledTime.isNotEmpty
                      ? item.scheduledTime
                      : 'Hari ini',
                ),
                _detailRow(
                  'Waktu Pemesanan',
                  AppDateFormatter.formatFullDateTime(item.createdAt),
                ),
                const SizedBox(height: 20),

                // Tombol Aksi
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryText,
                          side: const BorderSide(color: AppColors.inputBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
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
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Konfirmasi & Mulai Chat',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.summaryCardSubtext,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: AppColors.summaryCardSubtext)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

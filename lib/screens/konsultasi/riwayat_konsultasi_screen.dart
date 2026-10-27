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
        stream: _consultationService.watchCompletedConsultations(),
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

          // ── 2. State Error ──
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

          final list = snapshot.data ?? [];

          // ── 3. State Kosong (Empty) ──
          if (list.isEmpty) {
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
                      'Sesi konsultasi yang telah diselesaikan oleh dokter akan tercatat rapi di halaman ini.',
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

          // ── 4. Daftar Kartu Dikelompokkan per Tanggal ──
          final grouped = _groupByDate(list);
          final sortedDateKeys = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: sortedDateKeys.length,
            itemBuilder: (context, index) {
              final dateKey = sortedDateKeys[index];
              final items = grouped[dateKey]!;
              final firstDate = items.first.completedAt ?? items.first.createdAt;
              final formattedHeaderDate =
                  AppDateFormatter.formatLongDate(firstDate);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Tanggal
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedHeaderDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Daftar Kartu Konsultasi pada Tanggal Ini
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildConsultationHistoryCard(context, item),
                      )),
                ],
              );
            },
          );
        },
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

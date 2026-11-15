import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/consultation_constants.dart';
import '../../models/consultation_model.dart';
import '../../models/doctor_model.dart';
import '../../services/consultation_retention_service.dart';
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

  @override
  void initState() {
    super.initState();
    // Trigger pembersihan background 60 hari untuk pasien (Revisi 10 Bagian D)
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      ConsultationRetentionService.instance.runRetentionCleanup(
        uid: uid,
        isDoctor: false,
      );
    }
  }

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

  Future<void> _confirmDeleteConsultation(ConsultationModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus dari riwayat?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Konsultasi dengan ${item.doctorName} akan disembunyikan dari riwayat Anda. Catatan dokter tetap tersimpan normal.',
          style: const TextStyle(fontSize: 13, color: AppColors.primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _consultationService.hideConsultationFromHistory(
          consultationId: item.id,
          patientUid: item.patientUid,
          hidden: true,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Konsultasi dihapus dari riwayat'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Urungkan',
              textColor: Colors.amberAccent,
              onPressed: () async {
                try {
                  await _consultationService.hideConsultationFromHistory(
                    consultationId: item.id,
                    patientUid: item.patientUid,
                    hidden: false,
                  );
                } catch (e) {
                  debugPrint('Gagal membatalkan penghapusan: $e');
                }
              },
            ),
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus riwayat: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _showCleanOldHistoryDialog(
      List<ConsultationModel> completedList) async {
    final cutoff = DateTime.now().subtract(ConsultationConstants.kOldChatAge);
    final oldList = completedList.where((c) {
      if (c.hiddenByPatient) return false;
      final date = c.completedAt ?? c.createdAt;
      return date.isBefore(cutoff);
    }).toList();

    if (oldList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada riwayat lama.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Bersihkan riwayat lama',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Terdapat ${oldList.length} riwayat konsultasi yang lebih dari 30 hari. Apakah Anda yakin ingin menghapusnya dari riwayat Anda?',
          style: const TextStyle(fontSize: 13, color: AppColors.primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bersihkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final count = await _consultationService.cleanOldConsultationHistory();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$count riwayat konsultasi lama berhasil dibersihkan'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membersihkan riwayat: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConsultationModel>>(
      stream: _consultationService.watchAllPatientConsultations(),
      builder: (context, snapshot) {
        final allList = snapshot.data ?? [];
        final completedList =
            allList.where((c) => c.isCompleted && !c.hiddenByPatient).toList();

        return AppScaffold(
          appBar: AppHeaderPill(
            title: 'Riwayat Konsultasi',
            rightAction: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.primaryText),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'clean_old') {
                  _showCleanOldHistoryDialog(completedList);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'clean_old',
                  child: Row(
                    children: [
                      Icon(Icons.cleaning_services_rounded,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Bersihkan riwayat lama',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Builder(
            builder: (context) {
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

              // ── Pisahkan Sisi Klien: Sedang Berlangsung vs Selesai ──
              final ongoingList = allList
                  .where((c) => (c.isActive || c.isWaiting) && !c.hiddenByPatient)
                  .toList();

              ongoingList.sort((a, b) {
                final timeA = a.lastMessageAt ?? a.createdAt;
                final timeB = b.lastMessageAt ?? b.createdAt;
                return timeB.compareTo(timeA);
              });

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
                        const SizedBox(height: 24),
                        _buildRetentionInfoBanner(),
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
                  const SizedBox(height: 8),
                  _buildRetentionInfoBanner(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRetentionInfoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 13, color: AppColors.neutralGray.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            const Text(
              'Chat dihapus otomatis 60 hari setelah aktivitas terakhir.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.neutralGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
                            Expanded(
                              child: Text(
                                AppDateFormatter.formatScheduledDateTime(
                                  item.effectiveScheduledDate,
                                  item.scheduledTime,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
        onLongPress: () => _confirmDeleteConsultation(item),
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
          // Baris Atas: Judul "Konsultasi dengan" & Badge Status "Selesai" (Hijau) + Menu Opsi
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.more_vert_rounded,
                        size: 18, color: AppColors.neutralGray),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onSelected: (val) {
                      if (val == 'delete') {
                        _confirmDeleteConsultation(item);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus dari riwayat',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
                        Expanded(
                          child: Text(
                            AppDateFormatter.formatScheduledDateTime(
                              item.effectiveScheduledDate,
                              item.scheduledTime,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Cuplikan Rekomendasi Dokter (D.6 & D.7)
          if (item.doctorRecommendation != null &&
              item.doctorRecommendation!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    title: const Row(
                      children: [
                        Icon(Icons.assignment_turned_in_rounded,
                            color: AppColors.successGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Rekomendasi Dokter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    content: SingleChildScrollView(
                      child: Text(
                        item.doctorRecommendation!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_turned_in_rounded,
                            size: 13, color: AppColors.successGreen),
                        SizedBox(width: 5),
                        Text(
                          'Rekomendasi Dokter',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.doctorRecommendation!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF15803D),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

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

          // Penilaian Konsultasi (Revisi 11 Bagian A)
          _buildRatingSection(context, item),

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

  /// Menampilkan status penilaian pada kartu konsultasi selesai (Revisi 11 Bagian A)
  Widget _buildRatingSection(BuildContext context, ConsultationModel item) {
    if (item.isRated) {
      final rating = item.rating!;
      return Row(
        children: [
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 18,
                color: index < rating
                    ? const Color(0xFFFFB300)
                    : const Color(0xFFBDBDBD),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Penilaian Anda: $rating/5',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ],
      );
    }

    // Belum dinilai: 5 bintang KOSONG (outline/abu), teks "Beri penilaian", bisa diketuk
    return InkWell(
      onTap: () => _showRatingBottomSheet(context, item),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: List.generate(
                5,
                (index) => const Icon(
                  Icons.star_outline_rounded,
                  size: 18,
                  color: Color(0xFFBDBDBD),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Beri penilaian',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Menampilkan bottom sheet interaktif untuk memberi penilaian (Revisi 11 Bagian A.2)
  void _showRatingBottomSheet(BuildContext context, ConsultationModel item) {
    if (item.isRated) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        int selectedRating = 0;
        bool isSubmitting = false;
        String? errorMessage;
        String? errorCode;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    // Info Dokter: foto, nama, spesialisasi
                    Row(
                      children: [
                        DoctorAvatar(
                          photoUrl: item.effectiveDoctorPhotoUrl,
                          doctorId: item.doctorId,
                          doctorName: item.doctorName,
                          size: 52,
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
                                  fontSize: 16,
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
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFFE8EFF5)),
                    const SizedBox(height: 16),

                    const Center(
                      child: Text(
                        'Beri Penilaian Konsultasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5 Bintang Besar Interaktif (1-5)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starNumber = index + 1;
                        final isFilled = starNumber <= selectedRating;
                        return GestureDetector(
                          onTap: isSubmitting
                              ? null
                              : () {
                                  setSheetState(() {
                                    selectedRating = starNumber;
                                    errorMessage = null;
                                    errorCode = null;
                                  });
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              isFilled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 42,
                              color: isFilled
                                  ? const Color(0xFFFFB300)
                                  : const Color(0xFFBDBDBD),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

                    // Keterangan sekali kirim dan tidak bisa diedit
                    const Center(
                      child: Text(
                        'Penilaian tidak dapat diubah setelah dikirim.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.neutralGray,
                        ),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              errorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFD32F2F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (errorCode != null && errorCode!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Kode: $errorCode',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Tombol Batal & Kirim penilaian
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(bottomSheetContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.neutralGray,
                              side: const BorderSide(
                                  color: AppColors.inputBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: (selectedRating == 0 || isSubmitting)
                                ? null
                                : () async {
                                    setSheetState(() {
                                      isSubmitting = true;
                                      errorMessage = null;
                                      errorCode = null;
                                    });

                                    try {
                                      await _consultationService
                                          .submitConsultationRating(
                                        consultationId: item.id,
                                        doctorId: item.doctorId,
                                        rating: selectedRating,
                                        patientUid: item.patientUid,
                                      );

                                      if (bottomSheetContext.mounted) {
                                        Navigator.pop(bottomSheetContext);
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Terima kasih atas penilaiannya'),
                                            backgroundColor:
                                                AppColors.successGreen,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint('[RiwayatKonsultasiScreen] Error submit rating: $e');
                                      if (bottomSheetContext.mounted) {
                                        setSheetState(() {
                                          isSubmitting = false;
                                          errorMessage =
                                              'Gagal mengirim penilaian. Coba lagi.';
                                          errorCode = e.toString().length > 60
                                              ? e.toString().substring(0, 60)
                                              : e.toString();
                                        });
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.35),
                              disabledForegroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Kirim penilaian',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
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
      },
    );
  }
}

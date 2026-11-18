import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/consultation_constants.dart';
import '../../constants/consultation_theme.dart';
import '../../models/consultation_model.dart';
import '../../models/doctor_model.dart';
import '../../services/consultation_retention_service.dart';
import '../../services/consultation_service.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_date_formatter.dart';
import 'chat_dokter_screen.dart';
import 'widgets/doctor_avatar.dart';

/// Layar Riwayat Konsultasi (Sisi Pasien).
/// Menampilkan daftar konsultasi dengan filter tab segmented ("Semua", "Berlangsung", "Selesai"),
/// kartu formal profesional, dan bottom sheet beri penilaian terpadu.
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
  String _selectedFilter = 'semua'; // 'semua' | 'berlangsung' | 'selesai'

  @override
  void initState() {
    super.initState();
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

    final nav = Navigator.of(context);
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
      showConsultationSnackBar(
        context,
        message: 'Gagal memulai chat ulang: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus dari riwayat?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Konsultasi dengan ${item.doctorName} akan disembunyikan dari riwayat Anda.',
          style: GoogleFonts.poppins(
              fontSize: 13, color: ConsultationTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: ConsultationTheme.secondaryText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ConsultationTheme.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
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
        showConsultationSnackBar(
          context,
          message: 'Konsultasi dihapus dari riwayat',
          action: SnackBarAction(
            label: 'Urungkan',
            textColor: ConsultationTheme.gold,
            onPressed: () async {
              try {
                await _consultationService.hideConsultationFromHistory(
                  consultationId: item.id,
                  patientUid: item.patientUid,
                  hidden: false,
                );
              } catch (_) {}
            },
          ),
        );
      } catch (e) {
        if (mounted) {
          showConsultationSnackBar(
            context,
            message: 'Gagal menghapus riwayat: $e',
            isError: true,
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
      showConsultationSnackBar(
        context,
        message: 'Tidak ada riwayat lama yang perlu dibersihkan.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Bersihkan riwayat lama',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Terdapat ${oldList.length} riwayat konsultasi yang lebih dari 30 hari. Apakah Anda yakin ingin menghapusnya?',
          style: GoogleFonts.poppins(
              fontSize: 13, color: ConsultationTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: ConsultationTheme.secondaryText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ConsultationTheme.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Bersihkan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final count = await _consultationService.cleanOldConsultationHistory();
        if (!mounted) return;
        showConsultationSnackBar(
          context,
          message: '$count riwayat konsultasi lama berhasil dibersihkan',
          isSuccess: true,
        );
      } catch (e) {
        if (mounted) {
          showConsultationSnackBar(
            context,
            message: 'Gagal membersihkan riwayat: $e',
            isError: true,
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

        // Popup menu titik tiga bulat 44: kartu putih radius 16, border krem, bayangan tipis
        final rightMenu = Theme(
          data: Theme.of(context).copyWith(
            cardColor: Colors.white,
            popupMenuTheme: PopupMenuThemeData(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                    color: ConsultationTheme.cardBorder, width: 1),
              ),
            ),
          ),
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
                  color: ConsultationTheme.cardBorder, width: 1),
            ),
            icon: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ConsultationTheme.cardBorder,
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A1F5C7A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                color: ConsultationTheme.primary,
                size: 20,
              ),
            ),
            onSelected: (val) {
              if (val == 'clean_old') {
                _showCleanOldHistoryDialog(completedList);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'clean_old',
                child: Row(
                  children: [
                    const Icon(Icons.cleaning_services_rounded,
                        size: 18, color: ConsultationTheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Bersihkan riwayat lama',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ConsultationTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        return Scaffold(
          backgroundColor: ConsultationTheme.scaffoldBg,
          appBar: ConsultationHeader(
            title: 'Riwayat Konsultasi',
            rightAction: rightMenu,
          ),
          body: SafeArea(
            top: false,
            child: Builder(
              builder: (context) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: ConsultationTheme.primary),
                  );
                }

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
                            decoration: const BoxDecoration(
                              color: ConsultationTheme.lightBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              size: 32,
                              color: ConsultationTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Gagal memuat riwayat',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ConsultationTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: ConsultationTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (ongoingList.isEmpty && completedList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: const BoxDecoration(
                              color: ConsultationTheme.lightBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              size: 38,
                              color: ConsultationTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Belum ada riwayat konsultasi',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ConsultationTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Konsultasi yang sedang berlangsung dan yang sudah selesai akan tampil di halaman ini.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: ConsultationTheme.secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final showOngoing =
                    _selectedFilter == 'semua' || _selectedFilter == 'berlangsung';
                final showCompleted =
                    _selectedFilter == 'semua' || _selectedFilter == 'selesai';

                final groupedCompleted = _groupByDate(completedList);
                final sortedDateKeys = groupedCompleted.keys.toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // ── Filter Chip: "Semua", "Berlangsung", "Selesai" ────────
                    _buildFilterChips(),
                    const SizedBox(height: 16),

                    // ══════════════════════════════════════════════════════════════
                    // 5. RIWAYAT KONSULTASI: SEDANG BERLANGSUNG
                    // ══════════════════════════════════════════════════════════════
                    if (showOngoing && ongoingList.isNotEmpty) ...[
                      _buildSectionHeaderOngoing(ongoingList.length),
                      const SizedBox(height: 12),
                      ...ongoingList.map(
                        (item) => _buildOngoingCard(context, item),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ══════════════════════════════════════════════════════════════
                    // 6. RIWAYAT KONSULTASI: SELESAI
                    // ══════════════════════════════════════════════════════════════
                    if (showCompleted && completedList.isNotEmpty) ...[
                      ...sortedDateKeys.expand((dateKey) {
                        final items = groupedCompleted[dateKey]!;
                        final firstDate =
                            items.first.completedAt ?? items.first.createdAt;
                        final formattedHeaderDate =
                            AppDateFormatter.formatLongDate(firstDate);

                        return [
                          _buildDateGroupHeader(formattedHeaderDate),
                          const SizedBox(height: 10),
                          ...items.map(
                            (item) => _buildCompletedCard(context, item),
                          ),
                          const SizedBox(height: 12),
                        ];
                      }),
                    ],

                    // Pesan kosong jika filter aktif tidak menemukan item
                    if ((_selectedFilter == 'berlangsung' && ongoingList.isEmpty) ||
                        (_selectedFilter == 'selesai' && completedList.isEmpty))
                      _buildEmptyFilterState(),

                    // Keterangan retensi 60 hari
                    _buildRetentionBanner(),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Filter chip: "Semua", "Berlangsung", "Selesai".
  /// Aktif: biru tua teks putih. Tidak aktif: putih, border #D9CDB8, teks biru tua.
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChipItem('Semua', 'semua'),
          const SizedBox(width: 8),
          _buildFilterChipItem('Berlangsung', 'berlangsung'),
          const SizedBox(width: 8),
          _buildFilterChipItem('Selesai', 'selesai'),
        ],
      ),
    );
  }

  Widget _buildFilterChipItem(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ConsultationTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ConsultationTheme.primary : const Color(0xFFD9CDB8),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x081F5C7A),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : ConsultationTheme.primary,
          ),
        ),
      ),
    );
  }

  /// Judul bagian: titik hijau 10px + "Sedang Berlangsung" (bold 16) + chip kecil jumlah (latar #EAF3F8, teks biru tua)
  Widget _buildSectionHeaderOngoing(int count) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: ConsultationTheme.greenDot,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Sedang Berlangsung',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ConsultationTheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: ConsultationTheme.lightBlueBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ConsultationTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// Pengelompokan per tanggal: label mikro tanggal dengan garis tipis memanjang di kanan
  Widget _buildDateGroupHeader(String dateText) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          MicroLabel(
            dateText,
            color: ConsultationTheme.secondaryText,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(
              color: ConsultationTheme.cardBorder,
              thickness: 1,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Kartu Konsultasi: Sedang Berlangsung
  Widget _buildOngoingCard(BuildContext context, ConsultationModel item) {
    final isWaiting = item.isWaiting;

    void openLiveChat() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDokterScreen(
            consultationId: item.id,
            isDoctor: false,
            patientUid: item.patientUid,
            initialConsultation: item,
            readOnly: false,
          ),
        ),
      );
    }

    final scheduledDateStr = item.effectiveScheduledDate != null
        ? AppDateFormatter.formatDateKey(item.effectiveScheduledDate!)
        : 'Hari ini';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ConsultationTheme.cardBorder,
          width: 1,
        ),
        boxShadow: ConsultationTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: openLiveChat,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // a. Baris atas: label mikro "KONSULTASI DOKTER" di kiri, status di kanan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const MicroLabel('KONSULTASI DOKTER'),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isWaiting
                                ? ConsultationTheme.orange
                                : ConsultationTheme.greenDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isWaiting ? 'Menunggu Konfirmasi' : 'Berlangsung',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isWaiting
                                ? const Color(0xFFB5651D)
                                : ConsultationTheme.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // b. Baris dokter: DoctorAvatar 56x56 radius 16, nama bold 15, spesialis
                Row(
                  children: [
                    DoctorAvatar(
                      photoUrl: item.effectiveDoctorPhotoUrl,
                      doctorId: item.doctorId,
                      doctorName: item.doctorName,
                      size: 56,
                      borderRadius: 16,
                      showVerificationBadge: true,
                      isVerified: false,
                      badgeSize: 18,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.doctorName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ConsultationTheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.doctorSpecialty,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ConsultationTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // c. Kotak dua kolom: latar #F7F3EB, border krem, radius 14, dipisah garis tipis: TANGGAL & JAM
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: ConsultationTheme.softBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ConsultationTheme.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Kolom TANGGAL
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const MicroLabel('TANGGAL'),
                            const SizedBox(height: 2),
                            Text(
                              scheduledDateStr,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ConsultationTheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 26,
                        color: ConsultationTheme.divider,
                      ),
                      const SizedBox(width: 14),
                      // Kolom JAM
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const MicroLabel('JAM'),
                            const SizedBox(height: 2),
                            Text(
                              item.scheduledTime.isNotEmpty
                                  ? item.scheduledTime
                                  : '18.00 – 21.00',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ConsultationTheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // d. Cuplikan pesan terakhir: kotak #F7F3EB, ikon chat, teks 1 baris ellipsis, jam kecil
                if (item.lastMessageText != null &&
                    item.lastMessageText!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ConsultationTheme.softBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ConsultationTheme.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: ConsultationTheme.secondaryText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.lastMessageText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: ConsultationTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.lastMessageAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            AppDateFormatter.formatTime(item.lastMessageAt!),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: ConsultationTheme.secondaryText,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // e. Baris bawah: badge merah "N belum dibaca" di kiri (bila ada) + tombol "Buka Chat" di kanan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (item.unreadForPatient > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ConsultationTheme.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.unreadForPatient} belum dibaca',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    ElevatedButton.icon(
                      onPressed: openLiveChat,
                      icon: const Icon(Icons.chat_bubble_rounded,
                          size: 15, color: Colors.white),
                      label: Text(
                        'Buka Chat',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ConsultationTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 6. Kartu Konsultasi: Selesai
  Widget _buildCompletedCard(BuildContext context, ConsultationModel item) {
    final completedTimeStr = item.completedAt != null
        ? '${AppDateFormatter.formatDateTime(item.completedAt!)} WIB'
        : 'Selesai';

    final scheduledDateStr = item.effectiveScheduledDate != null
        ? AppDateFormatter.formatDateKey(item.effectiveScheduledDate!)
        : 'Sesuai jadwal';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ConsultationTheme.cardBorder,
          width: 1,
        ),
        boxShadow: ConsultationTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // a. Baris atas: label mikro "KONSULTASI SELESAI" dan di kanan status "● Selesai" + titik tiga
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const MicroLabel('KONSULTASI SELESAI'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: ConsultationTheme.greenDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Selesai',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: ConsultationTheme.green,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: ConsultationTheme.secondaryText,
                      ),
                      onPressed: () => _confirmDeleteConsultation(item),
                      tooltip: 'Hapus dari riwayat',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // b. Baris dokter (DoctorAvatar 56x56 radius 16) + kotak TANGGAL/JAM
            Row(
              children: [
                DoctorAvatar(
                  photoUrl: item.effectiveDoctorPhotoUrl,
                  doctorId: item.doctorId,
                  doctorName: item.doctorName,
                  size: 56,
                  borderRadius: 16,
                  showVerificationBadge: true,
                  isVerified: false,
                  badgeSize: 18,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.doctorName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ConsultationTheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.doctorSpecialty,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ConsultationTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Kotak dua kolom TANGGAL / JAM
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ConsultationTheme.softBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ConsultationTheme.cardBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MicroLabel('TANGGAL'),
                        const SizedBox(height: 2),
                        Text(
                          scheduledDateStr,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ConsultationTheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 26,
                    color: ConsultationTheme.divider,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MicroLabel('JAM'),
                        const SizedBox(height: 2),
                        Text(
                          item.scheduledTime.isNotEmpty
                              ? item.scheduledTime
                              : '18.00 – 21.00',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ConsultationTheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // c. Kotak Rekomendasi Dokter: latar #F1FAF5, border #BFE3CE, radius 14
            if (item.doctorRecommendation != null &&
                item.doctorRecommendation!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1FAF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFBFE3CE),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MicroLabel('REKOMENDASI DOKTER',
                        color: ConsultationTheme.green),
                    const SizedBox(height: 6),
                    Text(
                      item.doctorRecommendation!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF24435A),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),

            // d. Baris kecil dengan ikon kalender-centang: "Selesai pada [tanggal, jam WIB]"
            Row(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  size: 15,
                  color: ConsultationTheme.secondaryText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Selesai pada $completedTimeStr',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: ConsultationTheme.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SectionDivider(verticalPadding: 10),

            // e. Baris bawah: kiri bintang penilaian + kanan tombol sekunder "Chat Ulang"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Kiri: Penilaian
                _buildRatingSection(context, item),

                // Kanan: Tombol sekunder Chat Ulang
                OutlinedButton.icon(
                  onPressed: () => _handleChatUlang(context, item),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    'Chat Ulang',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ConsultationTheme.primary,
                    side: const BorderSide(
                      color: ConsultationTheme.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Status penilaian pada baris bawah kartu selesai:
  /// kiri bintang penilaian 18px (emas terisi, abu outline bila belum)
  /// dengan di bawahnya "Penilaian Anda: 5/5" (12, #5E7585) atau tautan "Beri penilaian" (teal, semi-bold, garis bawah)
  Widget _buildRatingSection(BuildContext context, ConsultationModel item) {
    if (item.isRated) {
      final rating = item.rating!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    ? ConsultationTheme.gold
                    : const Color(0xFFD9CDB8),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Penilaian Anda: $rating/5',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ConsultationTheme.secondaryText,
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => _showRatingBottomSheet(context, item),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                (_) => const Icon(
                  Icons.star_outline_rounded,
                  size: 18,
                  color: Color(0xFFD9CDB8),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Beri penilaian',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ConsultationTheme.teal,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 7. BOTTOM SHEET BERI PENILAIAN
  /// Sheet putih, sudut atas radius 28, handle abu di tengah atas, padding 12x20x24.
  /// Latar belakang diredupkan dengan overlay biru tua transparan (~42%).
  void _showRatingBottomSheet(BuildContext context, ConsultationModel item) {
    if (item.isRated) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF1F5C7A).withValues(alpha: 0.42),
      builder: (bottomSheetContext) {
        int selectedRating = 0;
        bool isSubmitting = false;
        String? errorMessage;

        final ratingLabels = [
          '',
          '1 Buruk',
          '2 Kurang',
          '3 Cukup',
          '4 Baik',
          '5 Sangat Baik',
        ];

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle abu di tengah atas
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9CDB8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Baris dokter: DoctorAvatar 56x56 radius 16, nama, spesialis
                    Row(
                      children: [
                        DoctorAvatar(
                          photoUrl: item.effectiveDoctorPhotoUrl,
                          doctorId: item.doctorId,
                          doctorName: item.doctorName,
                          size: 56,
                          borderRadius: 16,
                          showVerificationBadge: true,
                          isVerified: false,
                          badgeSize: 18,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.doctorName,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: ConsultationTheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.doctorSpecialty,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: ConsultationTheme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SectionDivider(verticalPadding: 14),

                    // Judul tengah bold 18
                    Center(
                      child: Text(
                        'Beri Penilaian Konsultasi',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ConsultationTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lima bintang besar 36 dengan jarak 10
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
                                  });
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(
                              isFilled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 36,
                              color: isFilled
                                  ? ConsultationTheme.gold
                                  : const Color(0xFFD9CDB8),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),

                    // Label teks di bawah bintang (1 Buruk, 2 Kurang, 3 Cukup, 4 Baik, 5 Sangat Baik)
                    // Warna teal, semi-bold 14, disembunyikan sampai ada bintang dipilih
                    SizedBox(
                      height: 22,
                      child: Center(
                        child: selectedRating > 0
                            ? Text(
                                ratingLabels[selectedRating],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ConsultationTheme.teal,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Catatan miring
                    Center(
                      child: Text(
                        'Penilaian tidak dapat diubah setelah dikirim.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: ConsultationTheme.secondaryText,
                        ),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: ConsultationTheme.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Dua tombol: "Batal" dan "Kirim penilaian" (rasio lebar 1:2)
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(bottomSheetContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ConsultationTheme.secondaryText,
                              side: const BorderSide(
                                  color: Color(0xFFD9CDB8), width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ConsultationTheme.secondaryText,
                              ),
                            ),
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
                                        showConsultationSnackBar(
                                          context,
                                          message:
                                              'Terima kasih atas penilaiannya',
                                          isSuccess: true,
                                        );
                                      }
                                    } catch (e) {
                                      if (bottomSheetContext.mounted) {
                                        setSheetState(() {
                                          isSubmitting = false;
                                          errorMessage =
                                              'Gagal mengirim penilaian: $e';
                                        });
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ConsultationTheme.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  ConsultationTheme.disabledButton,
                              disabledForegroundColor: Colors.white70,
                              elevation: 0,
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
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Kirim penilaian',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.white,
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

  Widget _buildEmptyFilterState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Tidak ada riwayat untuk filter ini.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: ConsultationTheme.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildRetentionBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: ConsultationTheme.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              'Chat dihapus otomatis 60 hari setelah aktivitas terakhir.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: ConsultationTheme.secondaryText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

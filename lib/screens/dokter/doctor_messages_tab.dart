import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/doctor_theme.dart';
import '../../models/consultation_model.dart';
import '../../services/consultation_retention_service.dart';
import '../../services/consultation_service.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_date_formatter.dart';
import '../konsultasi/chat_dokter_screen.dart';

/// Tab/Layar: Daftar Pesan Pasien untuk Dokter (Design System Formal LAMON)
class DoctorMessagesTab extends StatefulWidget {
  final List<ConsultationModel> consultations;
  final String? doctorId;
  final bool initialBelumDibalas;
  final bool focusSearch;
  final VoidCallback? onBack;

  const DoctorMessagesTab({
    super.key,
    required this.consultations,
    this.doctorId,
    this.initialBelumDibalas = false,
    this.focusSearch = false,
    this.onBack,
  });

  @override
  State<DoctorMessagesTab> createState() => _DoctorMessagesTabState();
}

class _DoctorMessagesTabState extends State<DoctorMessagesTab> {
  final DoctorService _doctorService = DoctorService();
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedFilterIndex = 0; // 0: Semua, 1: Belum dibaca, 2: Aktif, 3: Selesai

  @override
  void initState() {
    super.initState();
    final hasBelumDibaca = widget.consultations.any((c) =>
        c.paymentStatus == PaymentStatus.paid &&
        !c.hiddenByDoctor &&
        !c.isCompleted &&
        (c.unreadForDoctor > 0 || c.lastMessageSenderType != 'doctor'));

    if (widget.initialBelumDibalas || hasBelumDibaca) {
      _selectedFilterIndex = 1;
    }
    if (widget.focusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
    _searchController.addListener(() => setState(() {}));

    // Trigger pembersihan background 60 hari
    final docId = widget.doctorId;
    if (docId != null && docId.isNotEmpty) {
      ConsultationRetentionService.instance.runRetentionCleanup(
        uid: FirebaseAuth.instance.currentUser?.uid ?? '',
        isDoctor: true,
        doctorId: docId,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docId = widget.doctorId;
    if (docId != null && docId.isNotEmpty) {
      return StreamBuilder<List<ConsultationModel>>(
        stream: _doctorService.watchDoctorConsultations(docId),
        initialData: widget.consultations,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return _buildLoadingState();
          }
          final liveList = snapshot.data ?? widget.consultations;
          return _buildContent(liveList);
        },
      );
    }
    return _buildContent(widget.consultations);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: DoctorTheme.primary,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: DoctorTheme.alertRed,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat pesan',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DoctorTheme.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: DoctorTheme.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              style: DoctorTheme.primaryButtonStyle(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<ConsultationModel> consultations) {
    final query = _searchController.text.trim().toLowerCase();

    // Hanya konsultasi paid yang tidak disembunyikan dokter & belum expired
    final paidConsultations = consultations
        .where((c) =>
            c.paymentStatus == PaymentStatus.paid &&
            !c.hiddenByDoctor &&
            !ConsultationRetentionService.isExpired(c))
        .toList();

    // Kategori Filter Lokal
    final belumDibacaList = paidConsultations.where((c) {
      return !c.isCompleted &&
          (c.unreadForDoctor > 0 || c.lastMessageSenderType != 'doctor');
    }).toList();

    final selesaiList = paidConsultations.where((c) {
      return c.isCompleted;
    }).toList();
    selesaiList.sort((a, b) {
      final timeA = a.completedAt ?? a.createdAt;
      final timeB = b.completedAt ?? b.createdAt;
      return timeB.compareTo(timeA);
    });

    final List<ConsultationModel> activeCategoryList;
    if (_selectedFilterIndex == 1) {
      activeCategoryList = belumDibacaList;
    } else if (_selectedFilterIndex == 2) {
      activeCategoryList = selesaiList;
    } else {
      activeCategoryList = paidConsultations;
    }

    // Filter lokal berdasarkan nama pasien
    final filteredList = activeCategoryList.where((c) {
      if (query.isEmpty) return true;
      return c.displayPatientName.toLowerCase().contains(query);
    }).toList();

    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 24;

    return Column(
      children: [
        // ── 1. Header Halaman Formal LAMON ──
        _buildHeader(consultations),

        // ── 2. Kolom Pencarian & Chip Filter ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolom Pencarian Nama Pasien
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DoctorTheme.cardBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: DoctorTheme.neutralGray,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: DoctorTheme.primaryText,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari nama pasien…',
                          hintStyle: GoogleFonts.poppins(
                            color: DoctorTheme.neutralGray,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: const Icon(
                          Icons.close_rounded,
                          color: DoctorTheme.neutralGray,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Chip Filter ("Semua", "Belum dibaca · N", "Selesai")
              Row(
                children: [
                  _buildFilterChip(
                    index: 0,
                    label: 'Semua',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    index: 1,
                    label: belumDibacaList.isNotEmpty
                        ? 'Belum dibaca · ${belumDibacaList.length}'
                        : 'Belum dibaca',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    index: 2,
                    label: 'Selesai',
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── 3. Daftar Percakapan Pasien ──
        Expanded(
          child: filteredList.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 6, 20, bottomPadding),
                  itemCount: filteredList.length + 1,
                  separatorBuilder: (_, index) => index < filteredList.length
                      ? const SizedBox(height: 10)
                      : const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    if (index == filteredList.length) {
                      return _buildRetentionInfoBanner();
                    }
                    final item = filteredList[index];
                    return _buildConversationCard(context, item);
                  },
                ),
        ),
      ],
    );
  }

  // ── Header Halaman: Tombol Kembali + Judul "Pesan Pasien" ──
  Widget _buildHeader(List<ConsultationModel> consultations) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      color: Colors.transparent,
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack ?? () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: DoctorTheme.cardBorder, width: 1.2),
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
                color: DoctorTheme.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Pesan Pasien',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DoctorTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chip Filter Pill ──
  Widget _buildFilterChip({
    required int index,
    required String label,
  }) {
    final isSelected = _selectedFilterIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DoctorTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? DoctorTheme.primary : DoctorTheme.cardBorder,
            width: 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: DoctorTheme.primary.withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : DoctorTheme.primary,
          ),
        ),
      ),
    );
  }

  // ── Kartu Percakapan Pasien ──
  Widget _buildConversationCard(BuildContext context, ConsultationModel item) {
    final time = item.isCompleted
        ? (item.completedAt ?? item.lastMessageAt ?? item.createdAt)
        : (item.lastMessageAt ?? item.createdAt);
    final timeStr = AppDateFormatter.formatConversationListTimestamp(time);

    final String rawPreviewText;
    if (item.isCompleted) {
      if (item.doctorRecommendation != null &&
          item.doctorRecommendation!.trim().isNotEmpty) {
        rawPreviewText = item.doctorRecommendation!.trim();
      } else {
        rawPreviewText = 'Konsultasi selesai';
      }
    } else {
      rawPreviewText = item.lastMessageText ??
          (item.isWaiting
              ? 'Menunggu konfirmasi konsultasi'
              : 'Belum ada pesan');
    }

    final hasUnread = !item.isCompleted && item.unreadForDoctor > 0;
    final isLastFromDoctor = item.lastMessageSenderType == 'doctor';

    // Cek apakah pesan sudah dibaca oleh pasien
    final isReadByPatient = item.lastReadByPatientAt != null &&
        item.lastMessageAt != null &&
        (item.lastReadByPatientAt!.isAfter(item.lastMessageAt!) ||
            item.lastReadByPatientAt!.isAtSameMomentAs(item.lastMessageAt!));

    final String checkPrefix;
    if (isLastFromDoctor && !item.isCompleted) {
      checkPrefix = isReadByPatient ? '✓✓ ' : '✓ ';
    } else {
      checkPrefix = '';
    }

    final avatarColors = DoctorTheme.getAvatarColors(item.displayPatientName);

    return Container(
      decoration: DoctorTheme.cardDecoration(
        color: hasUnread ? DoctorTheme.unreadCardBg : Colors.white,
        borderRadius: 22,
        borderColor:
            hasUnread ? DoctorTheme.unreadCardBorder : DoctorTheme.cardBorder,
        borderWidth: hasUnread ? 1.5 : 1.2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onLongPress: () => _handleDeleteConversation(item),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDokterScreen(
                  consultationId: item.id,
                  isDoctor: true,
                  patientUid: item.patientUid,
                  initialConsultation: item,
                  readOnly: item.isCompleted,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar Bulat 48px dengan Inisial Pasien
                (item.patientPhotoUrl != null &&
                        item.patientPhotoUrl!.isNotEmpty &&
                        (item.patientPhotoUrl!.startsWith('http://') ||
                            item.patientPhotoUrl!.startsWith('https://')))
                    ? CircleAvatar(
                        radius: 24,
                        backgroundColor: avatarColors.background,
                        backgroundImage: NetworkImage(item.patientPhotoUrl!),
                        onBackgroundImageError: (_, _) {},
                      )
                    : CircleAvatar(
                        radius: 24,
                        backgroundColor: avatarColors.background,
                        child: Text(
                          item.patientInitials,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: avatarColors.text,
                          ),
                        ),
                      ),
                const SizedBox(width: 14),

                // Nama Pasien & Cuplikan Pesan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayPatientName,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight:
                              hasUnread ? FontWeight.w800 : FontWeight.w700,
                          color: hasUnread
                              ? DoctorTheme.primary
                              : DoctorTheme.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (checkPrefix.isNotEmpty)
                            Text(
                              checkPrefix,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isReadByPatient
                                    ? DoctorTheme.primary
                                    : DoctorTheme.neutralGray,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              rawPreviewText,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: hasUnread
                                    ? DoctorTheme.primary
                                    : DoctorTheme.secondaryText,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.normal,
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
                const SizedBox(width: 10),

                // Jam/Tanggal & Badge Belum Dibaca
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight:
                            hasUnread ? FontWeight.w700 : FontWeight.w500,
                        color: hasUnread
                            ? DoctorTheme.primary
                            : DoctorTheme.neutralGray,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: DoctorTheme.alertRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.unreadForDoctor > 99
                              ? '99+'
                              : '${item.unreadForDoctor}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (item.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: DoctorTheme.selesaiPurpleBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Selesai',
                          style: GoogleFonts.poppins(
                            color: DoctorTheme.selesaiPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: DoctorTheme.neutralGray.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum ada pesan dari pasien',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: DoctorTheme.neutralGray,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildRetentionInfoBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionInfoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: DoctorTheme.neutralGray.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              'Chat dihapus otomatis 60 hari setelah aktivitas terakhir.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: DoctorTheme.neutralGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hapus Chat (Soft Hide) ──
  Future<void> _handleDeleteConversation(ConsultationModel item) async {
    if (!item.isCompleted && !item.isExpired) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selesaikan konsultasi terlebih dahulu.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Chat Pasien',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: DoctorTheme.primaryText,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus chat dengan "${item.displayPatientName}" dari daftar pesan Anda?\n\nPercakapan hanya hilang dari daftar pesan Anda. Pasien tetap dapat melihat riwayat dan ringkasan konsultasi.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: DoctorTheme.secondaryText,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                color: DoctorTheme.neutralGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorTheme.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _consultationService.hideConsultationByDoctor(
        patientUid: item.patientUid,
        consultationId: item.id,
        hidden: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Chat dengan ${item.displayPatientName} dihapus dari daftar pesan'),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Urungkan',
              textColor: Colors.amber,
              onPressed: () async {
                try {
                  await _consultationService.hideConsultationByDoctor(
                    patientUid: item.patientUid,
                    consultationId: item.id,
                    hidden: false,
                  );
                } catch (e) {
                  debugPrint('Gagal membatalkan penghapusan: $e');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[DoctorMessagesTab] Error hiding consultation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus chat: $e'),
            backgroundColor: DoctorTheme.alertRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/consultation_constants.dart';
import '../../constants/doctor_theme.dart';
import '../../models/consultation_model.dart';
import '../../services/consultation_retention_service.dart';
import '../../services/consultation_service.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_date_formatter.dart';
import '../konsultasi/chat_dokter_screen.dart';

/// Tab 2: Daftar Pesan Pasien untuk Dokter (Design System Formal LAMON)
class DoctorMessagesTab extends StatefulWidget {
  final List<ConsultationModel> consultations;
  final String? doctorId;
  final bool initialBelumDibalas;
  final bool focusSearch;

  const DoctorMessagesTab({
    super.key,
    required this.consultations,
    this.doctorId,
    this.initialBelumDibalas = false,
    this.focusSearch = false,
  });

  @override
  State<DoctorMessagesTab> createState() => _DoctorMessagesTabState();
}

class _DoctorMessagesTabState extends State<DoctorMessagesTab> {
  final DoctorService _doctorService = DoctorService();
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedTabIndex = 0; // 0: Sudah Dibalas, 1: Belum Dibalas, 2: Selesai

  @override
  void initState() {
    super.initState();
    final hasBelumDibalas = widget.consultations.any((c) =>
        c.paymentStatus == PaymentStatus.paid &&
        !c.hiddenByDoctor &&
        !c.isCompleted &&
        c.lastMessageSenderType != 'doctor');
    if (widget.initialBelumDibalas || hasBelumDibalas) {
      _selectedTabIndex = 1;
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
          final liveList = snapshot.data ?? widget.consultations;
          return _buildContent(liveList);
        },
      );
    }
    return _buildContent(widget.consultations);
  }

  Widget _buildContent(List<ConsultationModel> consultations) {
    final query = _searchController.text.trim().toLowerCase();

    // Hanya konsultasi paid yang tidak disembunyikan oleh dokter
    // dan belum melewati batas retensi 60 hari
    final paidConsultations = consultations
        .where((c) =>
            c.paymentStatus == PaymentStatus.paid &&
            !c.hiddenByDoctor &&
            !ConsultationRetentionService.isExpired(c))
        .toList();

    // Filter per tab:
    final sudahDibalas = paidConsultations.where((c) {
      return !c.isCompleted &&
          c.lastMessageSenderType == 'doctor' &&
          !c.lastMessageIsAutoReply;
    }).toList();

    final belumDibalas = paidConsultations.where((c) {
      return !c.isCompleted &&
          (c.lastMessageSenderType != 'doctor' || c.lastMessageIsAutoReply);
    }).toList();

    final selesai = paidConsultations.where((c) {
      return c.isCompleted;
    }).toList();
    selesai.sort((a, b) {
      final timeA = a.completedAt ?? a.createdAt;
      final timeB = b.completedAt ?? b.createdAt;
      return timeB.compareTo(timeA);
    });

    // Filter nama sesuai search query
    final List<ConsultationModel> activeList;
    if (_selectedTabIndex == 0) {
      activeList = sudahDibalas;
    } else if (_selectedTabIndex == 1) {
      activeList = belumDibalas;
    } else {
      activeList = selesai;
    }

    final filteredList = activeList.where((c) {
      if (query.isEmpty) return true;
      return c.displayPatientName.toLowerCase().contains(query);
    }).toList();

    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 24;

    return Column(
      children: [
        // ── Search Bar & Tab Pills ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolom Cari Pasien & Tombol Bersihkan Chat Lama
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
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
                          const Icon(Icons.search_rounded,
                              color: DoctorTheme.neutralGray, size: 20),
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
                                hintText: 'Cari pasien...',
                                hintStyle: GoogleFonts.poppins(
                                  color: DoctorTheme.neutralGray,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: const Icon(Icons.close_rounded,
                                  color: DoctorTheme.neutralGray, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: DoctorTheme.cardBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined,
                          color: DoctorTheme.primary, size: 22),
                      tooltip: 'Bersihkan chat lama (>30 hari)',
                      onPressed: () => _handleCleanOldChats(consultations),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Tab Pill (Sudah Dibalas | Belum Dibalas | Selesai) ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildTabPill(
                      index: 0,
                      title: 'Sudah Dibalas',
                      count: sudahDibalas.length,
                    ),
                    const SizedBox(width: 8),
                    _buildTabPill(
                      index: 1,
                      title: 'Belum Dibalas',
                      count: belumDibalas.length,
                      isAlert: belumDibalas.any((c) => c.unreadForDoctor > 0),
                    ),
                    const SizedBox(width: 8),
                    _buildTabPill(
                      index: 2,
                      title: 'Selesai',
                      count: selesai.length,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── List Percakapan Pasien ──
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
                    return _buildConversationTile(context, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTabPill({
    required int index,
    required String title,
    required int count,
    bool isAlert = false,
  }) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : DoctorTheme.primaryText,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isAlert ? DoctorTheme.alertRedBg : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isAlert ? DoctorTheme.alertRed : DoctorTheme.primaryText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, ConsultationModel item) {
    final time = item.isCompleted
        ? (item.completedAt ?? item.lastMessageAt ?? item.createdAt)
        : (item.lastMessageAt ?? item.createdAt);
    final timeStr = AppDateFormatter.formatConversationListTimestamp(time);

    final String previewText;
    if (item.isCompleted) {
      if (item.doctorRecommendation != null &&
          item.doctorRecommendation!.trim().isNotEmpty) {
        previewText = item.doctorRecommendation!.trim();
      } else {
        previewText = 'Konsultasi selesai';
      }
    } else {
      previewText = item.lastMessageText ??
          (item.isWaiting ? 'Menunggu konfirmasi konsultasi' : 'Belum ada pesan');
    }

    final hasUnread = !item.isCompleted && item.unreadForDoctor > 0;
    final schedStr = AppDateFormatter.formatScheduledDateTime(
      item.effectiveScheduledDate,
      item.scheduledTime,
    );

    return Container(
      decoration: DoctorTheme.cardDecoration(
        borderRadius: 18,
        borderColor: hasUnread ? DoctorTheme.alertRedBorder : DoctorTheme.cardBorder,
        borderWidth: hasUnread ? 1.5 : 1.2,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded,
              color: DoctorTheme.neutralGray, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Opsi Chat',
          onSelected: (val) {
            if (val == 'delete') {
              _handleDeleteConversation(item);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 18, color: DoctorTheme.alertRed),
                  SizedBox(width: 8),
                  Text(
                    'Hapus chat',
                    style: TextStyle(
                      color: DoctorTheme.alertRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: (item.patientPhotoUrl != null &&
                item.patientPhotoUrl!.isNotEmpty &&
                (item.patientPhotoUrl!.startsWith('http://') ||
                    item.patientPhotoUrl!.startsWith('https://')))
            ? CircleAvatar(
                radius: 22,
                backgroundColor: DoctorTheme.primary.withValues(alpha: 0.1),
                backgroundImage: NetworkImage(item.patientPhotoUrl!),
                onBackgroundImageError: (_, _) {},
              )
            : CircleAvatar(
                radius: 22,
                backgroundColor: DoctorTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  item.patientInitials,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DoctorTheme.primary,
                  ),
                ),
              ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.displayPatientName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DoctorTheme.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                color: hasUnread ? DoctorTheme.primary : DoctorTheme.neutralGray,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: DoctorTheme.neutralGray,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      schedStr,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: DoctorTheme.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      previewText,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: hasUnread
                            ? DoctorTheme.primaryText
                            : DoctorTheme.secondaryText,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasUnread) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: DoctorTheme.alertRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${item.unreadForDoctor}',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final String emptyMessage;
    if (_selectedTabIndex == 0) {
      emptyMessage = 'Belum ada percakapan yang sudah dibalas';
    } else if (_selectedTabIndex == 1) {
      emptyMessage = 'Tidak ada pesan yang menunggu balasan';
    } else {
      emptyMessage = 'Belum ada konsultasi yang selesai';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTabIndex == 2
                  ? Icons.check_circle_outline_rounded
                  : Icons.chat_bubble_outline_rounded,
              size: 56,
              color: DoctorTheme.neutralGray.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.poppins(
                fontSize: 13,
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
            Icon(Icons.info_outline_rounded,
                size: 13, color: DoctorTheme.neutralGray.withValues(alpha: 0.7)),
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

  /// Menangani hapus chat dokter (soft hide) untuk satu percakapan
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

  /// Menangani pembersihan chat lama dokter (>30 hari) secara massal
  Future<void> _handleCleanOldChats(
      List<ConsultationModel> allConsultations) async {
    final cutoff = DateTime.now().subtract(ConsultationConstants.kOldChatAge);
    final oldChats = allConsultations.where((c) {
      if (c.hiddenByDoctor) return false;
      if (!c.isCompleted && !c.isExpired) return false;
      final time = c.completedAt ?? c.createdAt;
      return time.isBefore(cutoff);
    }).toList();

    if (oldChats.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada chat lama.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Bersihkan Chat Lama',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: DoctorTheme.primaryText,
          ),
        ),
        content: Text(
          'Terdapat ${oldChats.length} chat konsultasi yang sudah lebih dari 30 hari. Apakah Anda yakin ingin menghapusnya dari daftar pesan Anda?\n\nChat hanya disembunyikan dari daftar Anda; pasien tetap dapat melihat riwayat percakapan.',
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
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final docId = widget.doctorId ?? '';
      final count = await _consultationService.cleanOldDoctorConsultations(
        doctorId: docId,
        consultations: allConsultations,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$count chat lama berhasil dibersihkan dari daftar pesan'),
            backgroundColor: DoctorTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[DoctorMessagesTab] Error cleaning old chats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membersihkan chat lama: $e'),
            backgroundColor: DoctorTheme.alertRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

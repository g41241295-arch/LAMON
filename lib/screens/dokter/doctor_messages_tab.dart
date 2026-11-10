import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/consultation_model.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_date_formatter.dart';
import '../konsultasi/chat_dokter_screen.dart';

/// Tab 2: Daftar Pesan Pasien untuk Dokter
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedTabIndex = 0; // 0: Sudah Dibalas, 1: Belum Dibalas, 2: Selesai

  @override
  void initState() {
    super.initState();
    final hasBelumDibalas = widget.consultations.any((c) =>
        c.paymentStatus == PaymentStatus.paid &&
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

    // Hanya konsultasi paid
    final paidConsultations = consultations
        .where((c) => c.paymentStatus == PaymentStatus.paid)
        .toList();

    // Filter per tab (E.2):
    // "Sudah Dibalas" dan "Belum Dibalas" TIDAK lagi memuat consultation completed.
    final sudahDibalas = paidConsultations.where((c) {
      return !c.isCompleted && c.lastMessageSenderType == 'doctor';
    }).toList();

    final belumDibalas = paidConsultations.where((c) {
      return !c.isCompleted && c.lastMessageSenderType != 'doctor';
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
              // Kolom Cari Pasien
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.inputBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: AppColors.neutralGray, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Cari pasien...',
                          hintStyle: TextStyle(
                            color: AppColors.neutralGray,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.neutralGray, size: 18),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Tab Pill (Sudah Dibalas | Belum Dibalas | Selesai) (E.1) ──
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

        // ── List Percakapan Pasien (F.1: Satu area scroll per layar, F.2: padding viewPadding + 24) ──
        Expanded(
          child: filteredList.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(20, 6, 20, bottomPadding),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
            width: 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.primaryText,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isAlert ? const Color(0xFFFFEBEE) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isAlert ? const Color(0xFFD32F2F) : AppColors.primaryText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, ConsultationModel item) {
    // Tanggal/waktu di sisi kanan (C.3): hari ini -> jam; kemarin -> Kemarin; tahun sama -> 3 Nov; beda tahun -> 3 Nov 2025
    final time = item.isCompleted
        ? (item.completedAt ?? item.lastMessageAt ?? item.createdAt)
        : (item.lastMessageAt ?? item.createdAt);
    final timeStr = AppDateFormatter.formatConversationListTimestamp(time);

    // Pratinjau pesan (E.3: baris tab Selesai menampilkan cuplikan rekomendasi 1 baris atau "Konsultasi selesai")
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
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread ? const Color(0xFFFFCDD2) : const Color(0xFFE8EFF5),
          width: hasUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDokterScreen(
                consultationId: item.id,
                isDoctor: true,
                patientUid: item.patientUid,
                initialConsultation: item,
                readOnly: item.isCompleted, // E.3: Selesai -> read-only
              ),
            ),
          );
        },
        leading: (item.patientPhotoUrl != null &&
                item.patientPhotoUrl!.isNotEmpty &&
                (item.patientPhotoUrl!.startsWith('http://') ||
                    item.patientPhotoUrl!.startsWith('https://')))
            ? CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                backgroundImage: NetworkImage(item.patientPhotoUrl!),
                onBackgroundImageError: (_, _) {},
              )
            : CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                child: Text(
                  item.patientInitials,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.displayPatientName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                color: hasUnread ? AppColors.primary : AppColors.neutralGray,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // C.2: Tanggal + Jam konsultasi
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 11,
                    color: AppColors.neutralGray,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      schedStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.neutralGray,
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
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread
                            ? AppColors.primaryText
                            : AppColors.summaryCardSubtext,
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
                        color: Color(0xFFD32F2F),
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
              color: AppColors.neutralGray.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutralGray,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

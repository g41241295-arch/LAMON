import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/consultation_model.dart';
import '../../utils/app_date_formatter.dart';
import '../konsultasi/chat_dokter_screen.dart';

/// Tab 2: Daftar Pesan Pasien untuk Dokter
class DoctorMessagesTab extends StatefulWidget {
  final List<ConsultationModel> consultations;
  final bool initialBelumDibalas;
  final bool focusSearch;

  const DoctorMessagesTab({
    super.key,
    required this.consultations,
    this.initialBelumDibalas = false,
    this.focusSearch = false,
  });

  @override
  State<DoctorMessagesTab> createState() => _DoctorMessagesTabState();
}

class _DoctorMessagesTabState extends State<DoctorMessagesTab> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedTabIndex = 0; // 0: Sudah Dibalas, 1: Belum Dibalas

  @override
  void initState() {
    super.initState();
    if (widget.initialBelumDibalas) {
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
    final query = _searchController.text.trim().toLowerCase();

    // Hanya konsultasi paid
    final paidConsultations = widget.consultations
        .where((c) => c.paymentStatus == PaymentStatus.paid)
        .toList();

    // Filter per tab
    // Sudah Dibalas = pesan terakhir dari dokter
    // Belum Dibalas = pesan terakhir dari pasien atau belum ada pesan
    final sudahDibalas = paidConsultations.where((c) {
      return c.lastMessageSenderType == 'doctor';
    }).toList();

    final belumDibalas = paidConsultations.where((c) {
      return c.lastMessageSenderType != 'doctor';
    }).toList();

    // Filter nama sesuai search query
    final activeList = _selectedTabIndex == 0 ? sudahDibalas : belumDibalas;
    final filteredList = activeList.where((c) {
      if (query.isEmpty) return true;
      return c.displayPatientName.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // ── Header & Search Bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pesan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 12),

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

              // ── Tab Pill (Sudah Dibalas / Belum Dibalas) ──
              Row(
                children: [
                  _buildTabPill(
                    index: 0,
                    title: 'Sudah Dibalas',
                    count: sudahDibalas.length,
                  ),
                  const SizedBox(width: 10),
                  _buildTabPill(
                    index: 1,
                    title: 'Belum Dibalas',
                    count: belumDibalas.length,
                    isAlert: belumDibalas.any((c) => c.unreadForDoctor > 0),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── List Percakapan Pasien ──
        Expanded(
          child: filteredList.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    final time = item.lastMessageAt ?? item.createdAt;
    final timeStr = AppDateFormatter.formatTime(time);
    final previewText = item.lastMessageText ??
        (item.isWaiting ? 'Menunggu konfirmasi konsultasi' : 'Belum ada pesan');
    final hasUnread = item.unreadForDoctor > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
              ),
            ),
          );
        },
        leading: CircleAvatar(
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
          child: Row(
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
        ),
      ),
    );
  }

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
              color: AppColors.neutralGray.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedTabIndex == 0
                  ? 'Belum ada percakapan yang sudah dibalas'
                  : 'Tidak ada pesan yang menunggu balasan',
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

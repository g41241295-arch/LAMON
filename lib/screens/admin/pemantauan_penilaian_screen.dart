import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/profile_photo_service.dart';
import '../../services/rating_monitoring_service.dart';
import '../../widgets/admin/admin_widgets.dart';

class PemantauanPenilaianScreen extends StatefulWidget {
  const PemantauanPenilaianScreen({super.key});

  @override
  State<PemantauanPenilaianScreen> createState() =>
      _PemantauanPenilaianScreenState();
}

class _PemantauanPenilaianScreenState extends State<PemantauanPenilaianScreen> {
  static const int _kPageSize = 20;

  final RatingMonitoringService _service = RatingMonitoringService.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  RatingFeatureType _activeTab = RatingFeatureType.gastropedia;
  int? _selectedStarFilter; // null = Semua, 1..5 = nilai bintang
  String _searchQuery = '';
  int _visibleCount = _kPageSize;

  StreamSubscription<List<UserRatingRecord>>? _gastroSub;
  StreamSubscription<List<UserRatingRecord>>? _consultSub;

  List<UserRatingRecord> _gastropediaRatings = [];
  List<UserRatingRecord> _consultationRatings = [];
  bool _loadingGastro = true;
  bool _loadingConsult = true;
  String? _errorGastro;
  String? _errorConsult;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _subscribeStreams();
  }

  void _subscribeStreams() {
    _gastroSub = _service.watchGastropediaRatings().listen(
      (records) {
        if (!mounted) return;
        setState(() {
          _gastropediaRatings = records;
          _loadingGastro = false;
          _errorGastro = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _loadingGastro = false;
          _errorGastro = 'Gagal memuat penilaian Gastropedia.';
        });
      },
    );

    _consultSub = _service.watchConsultationRatings().listen(
      (records) {
        if (!mounted) return;
        setState(() {
          _consultationRatings = records;
          _loadingConsult = false;
          _errorConsult = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _loadingConsult = false;
          _errorConsult = 'Gagal memuat penilaian Konsultasi Dokter.';
        });
      },
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 160) {
      final filteredLen = _filteredRecords.length;
      if (_visibleCount < filteredLen) {
        setState(() {
          _visibleCount = (_visibleCount + _kPageSize).clamp(0, filteredLen);
        });
      }
    }
  }

  @override
  void dispose() {
    _gastroSub?.cancel();
    _consultSub?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<UserRatingRecord> get _currentTabAllRecords {
    return _activeTab == RatingFeatureType.gastropedia
        ? _gastropediaRatings
        : _consultationRatings;
  }

  bool get _isCurrentTabLoading {
    return _activeTab == RatingFeatureType.gastropedia
        ? _loadingGastro
        : _loadingConsult;
  }

  String? get _currentTabError {
    return _activeTab == RatingFeatureType.gastropedia
        ? _errorGastro
        : _errorConsult;
  }

  List<UserRatingRecord> get _filteredRecords {
    Iterable<UserRatingRecord> list = _currentTabAllRecords;

    if (_selectedStarFilter != null) {
      list = list.where((r) => r.rating == _selectedStarFilter);
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) {
        final matchUser = r.displayUserName.toLowerCase().contains(q);
        final matchTarget = r.targetTitle.toLowerCase().contains(q);
        final matchCategory = r.itemCategory.toLowerCase().contains(q) ||
            r.doctorSpecialty.toLowerCase().contains(q);
        return matchUser || matchTarget || matchCategory;
      });
    }

    final sorted = list.toList()
      ..sort((a, b) => b.ratedAt.compareTo(a.ratedAt));
    return sorted;
  }

  void _switchTab(RatingFeatureType tab) {
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
      _visibleCount = _kPageSize;
    });
  }

  void _selectStarFilter(int? star) {
    setState(() {
      _selectedStarFilter = star;
      _visibleCount = _kPageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabRecords = _currentTabAllRecords;
    final summary = RatingSummaryStats.fromRecords(tabRecords);
    final filtered = _filteredRecords;
    final displayed = filtered.take(_visibleCount).toList();
    final hasMore = filtered.length > displayed.length;

    return AdminScaffold(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.bgGradientTop,
          AppColors.bgGradientMiddle,
          AppColors.bgGradientBottom,
        ],
      ),
      header: _buildHeader(),
      body: Column(
        children: [
          // ── A. DUA TAB UTAMA (GASTROPEDIA & KONSULTASI DOKTER) ──────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: _buildTopTabs(),
          ),

          // ── B. KONTEN UTAMA SCROLLABLE ──────────────────────────────────
          Expanded(
            child: _isCurrentTabLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary,
                      strokeWidth: 2.5,
                    ),
                  )
                : _currentTabError != null
                    ? _buildErrorState(_currentTabError!)
                    : ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        children: [
                          // 1. Ringkasan Singkat (Summary Card)
                          _buildSummaryCard(summary),
                          const SizedBox(height: 16),

                          // 2. Pencarian & Filter Nilai Bintang
                          _buildSearchBar(),
                          const SizedBox(height: 12),
                          _buildStarFilterRow(),
                          const SizedBox(height: 16),

                          // 3. Daftar Penilaian atau Kondisi Kosong
                          if (displayed.isEmpty)
                            _buildEmptyState(
                              isFiltered: _selectedStarFilter != null ||
                                  _searchQuery.trim().isNotEmpty,
                            )
                          else ...[
                            for (int i = 0; i < displayed.length; i++) ...[
                              _buildRatingCard(displayed[i]),
                              if (i < displayed.length - 1)
                                const SizedBox(height: 12),
                            ],
                            if (hasMore) ...[
                              const SizedBox(height: 14),
                              Center(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _visibleCount += _kPageSize;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.surfaceCard,
                                    side: const BorderSide(
                                      color: AppColors.softBlue,
                                      width: 1.4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.expand_more_rounded,
                                    color: AppColors.textPrimary,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Muat lebih banyak (${filtered.length - displayed.length} tersisa)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ── HEADER: TOMBOL BACK + PILL JUDUL (DISAMAKAN DENGAN GASTROPEDIA) ──────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.softBlue, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7D6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE8D7A5),
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
                child: Text(
                  'Pemantauan Penilaian',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C4E68),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── 2 TAB ATAS: GASTROPEDIA & KONSULTASI DOKTER ──────────────────────────
  Widget _buildTopTabs() {
    return Row(
      children: [
        Expanded(
          child: _buildTabButton(
            label: 'Gastropedia',
            count: _loadingGastro ? null : _gastropediaRatings.length,
            isSelected: _activeTab == RatingFeatureType.gastropedia,
            onTap: () => _switchTab(RatingFeatureType.gastropedia),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTabButton(
            label: 'Konsultasi Dokter',
            count: _loadingConsult ? null : _consultationRatings.length,
            isSelected: _activeTab == RatingFeatureType.consultation,
            onTap: () => _switchTab(RatingFeatureType.consultation),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String label,
    required int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.softBlue,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.softBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── B. SUMMARY CARD (RATA-RATA, TOTAL, DISTRIBUSI BINTANG 5..1) ──────────
  Widget _buildSummaryCard(RatingSummaryStats summary) {
    final avgText = summary.totalCount > 0
        ? summary.averageRating.toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBlue, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Kiri: Rata-rata nilai besar + bintang + total penilaian
            SizedBox(
              width: 112,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.accentGold,
                        size: 28,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        avgText,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildStarIconsRow(
                    summary.averageRating.round().clamp(0, 5),
                    size: 15,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${summary.totalCount} penilaian',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              color: AppColors.softBlue,
            ),

            // Kanan: Bar distribusi 5 sampai 1 bintang
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int star = 5; star >= 1; star--) ...[
                    _buildDistributionBarRow(
                      star: star,
                      count: summary.starCounts[star] ?? 0,
                      ratio: summary.ratioForStar(star),
                    ),
                    if (star > 1) const SizedBox(height: 5),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBarRow({
    required int star,
    required int count,
    required double ratio,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 12,
          child: Text(
            '$star',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 3),
        const Icon(
          Icons.star_rounded,
          size: 13,
          color: AppColors.accentGold,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: AppColors.softBlue.withValues(alpha: 0.65),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 26,
          child: Text(
            count.toString(),
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ── C. SEARCH BAR & FILTER BINTANG ───────────────────────────────────────
  Widget _buildSearchBar() {
    final hint = _activeTab == RatingFeatureType.gastropedia
        ? 'Cari nama pengguna atau nama makanan...'
        : 'Cari nama pengguna atau nama dokter...';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softBlue, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          setState(() {
            _searchQuery = v;
            _visibleCount = _kPageSize;
          });
        },
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _visibleCount = _kPageSize;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStarFilterRow() {
    final options = <int?>[null, 5, 4, 3, 2, 1];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            _buildStarFilterChip(options[i]),
            if (i < options.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildStarFilterChip(int? star) {
    final isSelected = _selectedStarFilter == star;
    return GestureDetector(
      onTap: () => _selectStarFilter(star),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.softBlue,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (star != null) ...[
              const Icon(
                Icons.star_rounded,
                size: 15,
                color: AppColors.accentGold,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              star == null ? 'Semua' : '$star',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── D. CARD ITEM PENILAIAN ───────────────────────────────────────────────
  Widget _buildRatingCard(UserRatingRecord record) {
    final hasChangeHistory = record.changeHistory.length > 1;
    final prevRating = record.previousRating ??
        (hasChangeHistory ? record.changeHistory[1].rating : null);

    return GestureDetector(
      onTap: () => _showUserRatingHistorySheet(record),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.softBlue, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Baris Atas: Profil Pengguna + Nilai Bintang
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserAvatar(
                  name: record.displayUserName,
                  initials: record.userInitials,
                  photoUrl: record.userPhotoUrl,
                  photoBase64: record.userPhotoBase64,
                  size: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.displayUserName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDateTime(record.ratedAt),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgAccent.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.accentGold.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStarIconsRow(record.rating, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            '${record.rating}/5',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (prevRating != null && prevRating != record.rating) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Diubah dari $prevRating ★',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 2. Objek yang Dinilai (Gastropedia Item atau Dokter Konsultasi)
            record.featureType == RatingFeatureType.gastropedia
                ? _buildGastropediaTargetBox(record)
                : _buildConsultationTargetBox(record),

            // 3. Komentar / Ulasan Teks (jika ada)
            if (record.comment != null && record.comment!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softBlue.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  record.comment!.trim(),
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // 4. Petunjuk ketuk untuk melihat riwayat penilaian pengguna
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Lihat riwayat penilaian pengguna',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGastropediaTargetBox(UserRatingRecord record) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.softBlue.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.softBlue,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildFoodThumbnail(
            imageAssetOrUrl: record.itemImage,
            imageBase64: record.itemImageBase64,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.itemName.isNotEmpty ? record.itemName : '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.softBlue, width: 1),
                  ),
                  child: Text(
                    record.itemCategory.isNotEmpty
                        ? record.itemCategory
                        : 'Gastropedia',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationTargetBox(UserRatingRecord record) {
    final consultDateText = record.consultationDate != null
        ? _formatDateOnly(record.consultationDate!)
        : '-';
    final scheduleLabel = record.scheduledTime.trim().isNotEmpty
        ? '$consultDateText • ${record.scheduledTime.trim()}'
        : consultDateText;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.softBlue.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.softBlue,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildDoctorThumbnail(
            photoAssetOrUrl: record.doctorPhotoUrl,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.doctorName.isNotEmpty ? record.doctorName : '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.doctorSpecialty.isNotEmpty
                      ? record.doctorSpecialty
                      : 'Dokter',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.event_note_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Konsultasi: $scheduleLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── E. BOTTOM SHEET RIWAYAT PENILAIAN PER PENGGUNA ───────────────────────
  void _showUserRatingHistorySheet(UserRatingRecord selectedRecord) {
    final targetUserId = selectedRecord.userId.trim();
    final targetName = selectedRecord.displayUserName;

    // Gabungkan seluruh penilaian dari kedua fitur milik pengguna tersebut
    final allCombined = <UserRatingRecord>[
      ..._gastropediaRatings,
      ..._consultationRatings,
    ].where((r) {
      if (targetUserId.isNotEmpty && r.userId.trim().isNotEmpty) {
        return r.userId.trim() == targetUserId;
      }
      return r.displayUserName.toLowerCase() == targetName.toLowerCase();
    }).toList()
      ..sort((a, b) => b.ratedAt.compareTo(a.ratedAt));

    final gastroCount = allCombined
        .where((r) => r.featureType == RatingFeatureType.gastropedia)
        .length;
    final consultCount = allCombined
        .where((r) => r.featureType == RatingFeatureType.consultation)
        .length;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.76,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Header Profil Singkat Pengguna (Tanpa email / nomor telepon)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildUserAvatar(
                          name: selectedRecord.displayUserName,
                          initials: selectedRecord.userInitials,
                          photoUrl: selectedRecord.userPhotoUrl,
                          photoBase64: selectedRecord.userPhotoBase64,
                          size: 48,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedRecord.displayUserName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${allCombined.length} penilaian  •  $gastroCount Gastropedia  •  $consultCount Konsultasi',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.softBlue),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Text(
                      'Riwayat Penilaian Pengguna',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // Daftar seluruh riwayat penilaian pengguna
                  Expanded(
                    child: allCombined.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada riwayat penilaian.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: allCombined.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = allCombined[index];
                              return _buildUserHistoryItemCard(item);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserHistoryItemCard(UserRatingRecord item) {
    final isGastro = item.featureType == RatingFeatureType.gastropedia;
    final badgeLabel = isGastro ? 'Gastropedia' : 'Konsultasi Dokter';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softBlue, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris kategori fitur + waktu penilaian + bintang
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isGastro
                      ? AppColors.bgAccent.withValues(alpha: 0.55)
                      : AppColors.softBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStarIconsRow(item.rating, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    '${item.rating}/5',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Detail objek yang dinilai
          isGastro
              ? _buildGastropediaTargetBox(item)
              : _buildConsultationTargetBox(item),

          const SizedBox(height: 8),
          Text(
            'Dinilai pada ${_formatDateTime(item.ratedAt)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),

          // Jika ada komentar/ulasan
          if (item.comment != null && item.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.comment!.trim(),
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],

          // Jika pengguna pernah mengubah nilai pada item Gastropedia yang sama
          if (isGastro && item.changeHistory.length > 1) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgAccent.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Perubahan Nilai (${item.changeHistory.length}x)',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (int i = 0; i < item.changeHistory.length; i++) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              i == 0
                                  ? Icons.check_circle_rounded
                                  : Icons.history_rounded,
                              size: 13,
                              color: i == 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              i == 0
                                  ? 'Nilai saat ini: ${item.changeHistory[i].rating} ★'
                                  : 'Penilaian sebelumnya: ${item.changeHistory[i].rating} ★',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: i == 0
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatDateTime(item.changeHistory[i].ratedAt),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (i < item.changeHistory.length - 1)
                      const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── F. EMPTY & ERROR STATES ──────────────────────────────────────────────
  Widget _buildEmptyState({required bool isFiltered}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBlue, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.softBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_outline_rounded,
              color: AppColors.textPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isFiltered
                ? 'Tidak ada penilaian yang sesuai filter'
                : 'Belum ada penilaian',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFiltered
                ? 'Coba ubah filter bintang atau kata kunci pencarian.'
                : 'Penilaian yang diberikan pengguna akan tampil secara otomatis di halaman ini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.softBlue, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.textPrimary,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGET HELPER VISUAL (AVATAR, THUMBNAIL, BINTANG, TANGGAL) ───────────
  Widget _buildStarIconsRow(int rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: AppColors.accentGold,
        );
      }),
    );
  }

  Widget _buildUserAvatar({
    required String name,
    required String initials,
    required String? photoUrl,
    required String? photoBase64,
    double size = 38,
  }) {
    final memProvider = ProfilePhotoService.provider(photoBase64);
    if (memProvider != null) {
      return ClipOval(
        child: Image(
          image: memProvider,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) =>
              _buildInitialsAvatar(initials: initials, size: size),
        ),
      );
    }

    final cleanUrl = (photoUrl ?? '').trim();
    if (cleanUrl.isNotEmpty) {
      if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
        return ClipOval(
          child: Image.network(
            cleanUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _buildInitialsAvatar(initials: initials, size: size),
          ),
        );
      } else if (cleanUrl.startsWith('assets/')) {
        return ClipOval(
          child: Image.asset(
            cleanUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _buildInitialsAvatar(initials: initials, size: size),
          ),
        );
      }
    }

    return _buildInitialsAvatar(initials: initials, size: size);
  }

  Widget _buildInitialsAvatar({required String initials, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.softBlue,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodThumbnail({
    required String imageAssetOrUrl,
    required String imageBase64,
    double size = 44,
  }) {
    Widget fallback() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.bgAccent.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.restaurant_menu_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
      );
    }

    if (imageBase64.trim().isNotEmpty) {
      try {
        final clean = imageBase64.contains(',')
            ? imageBase64.split(',').last.trim()
            : imageBase64.trim();
        final bytes = base64Decode(clean);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => fallback(),
          ),
        );
      } catch (_) {}
    }

    final cleanPath = imageAssetOrUrl.trim();
    if (cleanPath.isEmpty) return fallback();

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          cleanPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        cleanPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }

  Widget _buildDoctorThumbnail({
    required String photoAssetOrUrl,
    double size = 44,
  }) {
    Widget fallback() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.softBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.medical_services_outlined,
          color: AppColors.textPrimary,
          size: 20,
        ),
      );
    }

    final clean = photoAssetOrUrl.trim();
    if (clean.isEmpty) return fallback();

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          clean,
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        clean,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }

  static const List<String> _kMonthsShort = [
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
    'Des',
  ];

  String _formatDateTime(DateTime dt) {
    if (dt.millisecondsSinceEpoch <= 0) return '-';
    final day = dt.day.toString().padLeft(2, '0');
    final month = _kMonthsShort[(dt.month - 1).clamp(0, 11)];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year • $hour.$minute WIB';
  }

  String _formatDateOnly(DateTime dt) {
    if (dt.millisecondsSinceEpoch <= 0) return '-';
    final day = dt.day.toString().padLeft(2, '0');
    final month = _kMonthsShort[(dt.month - 1).clamp(0, 11)];
    final year = dt.year;
    return '$day $month $year';
  }
}

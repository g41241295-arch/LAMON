import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/reflux_prediction_model.dart';
import '../../providers/app_state.dart';
import '../../services/prediction_history_repository.dart';
import '../../utils/app_date_formatter.dart';
import 'widgets/risk_trend_card.dart';

class DiseasePredictionHistoryScreen extends StatefulWidget {
  /// ID prediksi yang baru saja disimpan. Jika diisi, item tersebut
  /// mendapat badge "Baru" yang hilang otomatis setelah beberapa detik.
  /// Null jika dibuka lewat ikon jam biasa (tanpa sorotan).
  final String? newId;

  const DiseasePredictionHistoryScreen({super.key, this.newId});

  @override
  State<DiseasePredictionHistoryScreen> createState() =>
      _DiseasePredictionHistoryScreenState();
}

class _DiseasePredictionHistoryScreenState
    extends State<DiseasePredictionHistoryScreen> {
  final _repository = PredictionHistoryRepository();
  List<RefluxPredictionResult> _history = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isInitialized = false;

  /// ID yang sedang di-highlight sebagai "Baru". Di-clear setelah 3.5 detik
  /// atau saat halaman ditinggalkan.
  String? _highlightedId;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    if (widget.newId != null) {
      _highlightedId = widget.newId;
      // Badge memudar setelah 3.5 detik
      _highlightTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) {
          setState(() {
            _highlightedId = null;
          });
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final cached = AppState.of(context).predictionHistory;
      if (cached.isNotEmpty) {
        _history = cached;
        _isLoading = false;
      }
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    // Jika di runtime nyata Firebase tersedia dan user belum login, arahkan ke login
    if (_repository.isFirebaseAvailable && !_repository.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    // Jika Firebase tidak tersedia (lingkungan test), gunakan cache AppState
    if (!_repository.isFirebaseAvailable || !_repository.isAuthenticated) {
      final cached = AppState.of(context).predictionHistory;
      setState(() {
        _history = cached;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final items = await _repository.fetchAll();
      if (!mounted) return;
      setState(() {
        _history = items;
        _isLoading = false;
      });
      AppState.of(context).setPredictionHistory(items);
    } catch (e) {
      if (!mounted) return;
      if (_history.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _retryLoading() {
    _loadHistory();
  }

  void _navigateToDetail(RefluxPredictionResult record) {
    Navigator.pushNamed(
      context,
      '/prediksi-penyakit/riwayat/${record.id}',
      arguments: record,
    );
  }

  void _startNewPrediction() {
    Navigator.pushNamed(context, '/prediksi-penyakit/form');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.desktopBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 520;
          final contentWidget = _buildScreenBody(context);

          if (isLargeScreen) {
            final maxH = constraints.maxHeight.isFinite
                ? constraints.maxHeight.clamp(0.0, 920.0)
                : 880.0;
            return Center(
              child: Container(
                width: 420,
                height: maxH,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.12),
                    width: 3,
                  ),
                ),
                child: contentWidget,
              ),
            );
          }

          return contentWidget;
        },
      ),
    );
  }

  Widget _buildScreenBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgGradientTop,
            AppColors.bgGradientMiddle,
            AppColors.bgGradientBottom,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // =========================================================
            // 1. HEADER (BACK + JUDUL "RIWAYAT PREDIKSI")
            // =========================================================
            _buildHeader(context),

            // =========================================================
            // 2. KONTEN STATEFUL (SCROLLABLE)
            // =========================================================
            Expanded(
              child: _buildMainContent(_history),
            ),

            // =========================================================
            // 3. STICKY BUTTON: "MULAI PEMERIKSAAN BARU"
            // =========================================================
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Back Lingkaran
          Semantics(
            label: 'Kembali',
            button: true,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD6E2E8),
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
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),

          // Judul Layar: "Riwayat Prediksi"
          const Expanded(
            child: Text(
              'Riwayat Prediksi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
                letterSpacing: -0.2,
              ),
            ),
          ),

          // Spacer pengimbang
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMainContent(List<RefluxPredictionResult> history) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Color(0xFFC62828),
              ),
              const SizedBox(height: 14),
              const Text(
                'Gagal memuat riwayat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Terjadi gangguan saat mengambil data pemeriksaanmu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _retryLoading,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (history.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadHistory,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Kartu Tren Risiko (custom painter line chart + summary chips)
          RiskTrendCard(history: history),
          const SizedBox(height: 20),

          // Judul Section "Daftar Pemeriksaan"
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.format_list_bulleted_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Semua Pemeriksaan (${history.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Daftar Kartu Riwayat (Terbaru di atas)
          ...history.map((record) => _buildHistoryItemCard(record)),
          const SizedBox(height: 16),
        ],
      ),
    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 42,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada riwayat pemeriksaan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Riwayat prediksi asam lambungmu akan muncul di sini setelah kamu menyelesaikan pemeriksaan pertama.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItemCard(RefluxPredictionResult record) {
    final score = record.riskPercentage;
    final isLow = score <= 33.0;
    final isMedium = score > 33.0 && score <= 66.0;
    final isNew = _highlightedId != null && _highlightedId == record.id;
    final isRecentlySaved = widget.newId != null && widget.newId == record.id;

    final Color riskColor;
    final Color riskBg;
    final String riskLabel = record.riskCategory;

    if (isLow) {
      riskColor = const Color(0xFF2E7D32); // Hijau
      riskBg = const Color(0xFFE8F5E9);
    } else if (isMedium) {
      riskColor = const Color(0xFFE65100); // Oranye
      riskBg = const Color(0xFFFFF3E0);
    } else {
      riskColor = const Color(0xFFC62828); // Merah
      riskBg = const Color(0xFFFFEBEE);
    }

    final formattedDate = AppDateFormatter.formatDateTime(record.createdAt);

    return Semantics(
      label: isRecentlySaved
          ? 'Pemeriksaan terbaru, $formattedDate, $riskLabel, ${score.toInt()} persen'
          : 'Pemeriksaan, $formattedDate, $riskLabel, ${score.toInt()} persen',
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // Lebar border SAMA (1.5 px) di semua kartu agar konten selalu sejajar
            color: isNew
                ? AppColors.primary.withValues(alpha: 0.65)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isNew
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isNew ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => _navigateToDetail(record),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Dot Indikator Level Risiko
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: riskColor,
                      boxShadow: [
                        BoxShadow(
                          color: riskColor.withValues(alpha: 0.35),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Bagian Tengah: Tanggal & Baris 2 (Chip Kategori Risiko + Badge "Baru")
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Baris 1: Tanggal & Waktu
                        Text(
                          formattedDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Baris 2: Chip Risiko & Badge "Baru" berdampingan
                        Wrap(
                          spacing: 7,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Chip Kategori Risiko
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: riskBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: riskColor.withValues(alpha: 0.20),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                riskLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: riskColor,
                                  height: 1.2,
                                ),
                              ),
                            ),

                            // Badge "Baru" — Muncul hanya pada item yang baru disimpan, memudar halus tanpa mengubah ukuran
                            if (isRecentlySaved)
                              AnimatedOpacity(
                                opacity: isNew ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.30),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        size: 11,
                                        color: AppColors.primaryDark,
                                      ),
                                      SizedBox(width: 3.5),
                                      Text(
                                        'Baru',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryDark,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Bagian Kanan: Kolom Persentase Skor & Chevron (Lebar & Posisi Konsisten)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 54),
                        child: Text(
                          '${score.toInt()}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: riskColor,
                            letterSpacing: -0.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _startNewPrediction,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Mulai Pemeriksaan Baru',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

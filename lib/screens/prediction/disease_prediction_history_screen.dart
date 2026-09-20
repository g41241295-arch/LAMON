import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/reflux_prediction_model.dart';
import '../../providers/app_state.dart';
import '../../utils/app_date_formatter.dart';
import 'widgets/risk_trend_card.dart';

class DiseasePredictionHistoryScreen extends StatefulWidget {
  const DiseasePredictionHistoryScreen({super.key});

  @override
  State<DiseasePredictionHistoryScreen> createState() =>
      _DiseasePredictionHistoryScreenState();
}

class _DiseasePredictionHistoryScreenState
    extends State<DiseasePredictionHistoryScreen> {
  bool _isLoading = false;
  bool _hasError = false;

  void _retryLoading() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
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
    final appState = AppState.of(context);
    final history = appState.predictionHistory;

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
              child: _buildMainContent(history),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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

                // Bagian Tengah: Tanggal & Badge Kategori Risiko
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: riskBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          riskLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: riskColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bagian Kanan: Persentase Skor Besar & Chevron
                Row(
                  children: [
                    Text(
                      '${score.toInt()}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: riskColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
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

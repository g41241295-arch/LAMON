import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/reflux_prediction_model.dart';
import '../../providers/app_state.dart';
import 'widgets/factor_contribution_bar.dart';

class DiseasePredictionResultScreen extends StatefulWidget {
  final RefluxPredictionResult result;
  final UserDietInput? dietInput;

  const DiseasePredictionResultScreen({
    super.key,
    required this.result,
    this.dietInput,
  });

  @override
  State<DiseasePredictionResultScreen> createState() =>
      _DiseasePredictionResultScreenState();
}

class _DiseasePredictionResultScreenState
    extends State<DiseasePredictionResultScreen> {
  bool _isSaved = false;

  void _saveToHistory() {
    if (_isSaved) return;

    final appState = AppState.of(context);
    appState.savePredictionResult(widget.result);

    setState(() {
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Hasil analisis berhasil disimpan ke riwayat akun!'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _resetAndRetake() {
    // Kembali ke langkah kuesioner dengan state baru
    Navigator.of(context).pop();
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
            // 1. HEADER (BACK + JUDUL "PREDIKSI LAMBUNG")
            // =========================================================
            _buildHeader(),

            // =========================================================
            // 2. KONTEN HASIL ANALISIS (SCROLLABLE)
            // =========================================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Card Skor Risiko
                    _buildScoreCard(),
                    const SizedBox(height: 20),

                    // Section "Faktor yang paling berpengaruh"
                    _buildTopFactorsSection(),
                    const SizedBox(height: 20),

                    // Section "Rekomendasi untukmu"
                    _buildRecommendationsSection(),
                    const SizedBox(height: 32),

                    // Tombol Aksi
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Back Lingkaran
          InkWell(
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

          // Judul Layar: "Prediksi Lambung"
          const Text(
            'Prediksi Lambung',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
              letterSpacing: -0.2,
            ),
          ),

          // Spacer pengimbang
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // =========================================================
  // CARD SKOR PERSENTASE & KATEGORI RISIKO
  // =========================================================
  Widget _buildScoreCard() {
    final result = widget.result;
    final isLow = result.riskCategory.contains('Rendah');
    final isMedium = result.riskCategory.contains('Sedang');

    final Color badgeBg;
    final Color badgeText;
    final Color badgeBorder;
    final IconData categoryIcon;

    if (isLow) {
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = const Color(0xFF2E7D32);
      badgeBorder = const Color(0xFFA5D6A7);
      categoryIcon = Icons.sentiment_very_satisfied_rounded;
    } else if (isMedium) {
      badgeBg = const Color(0xFFFFF3E0);
      badgeText = const Color(0xFFE65100);
      badgeBorder = const Color(0xFFFFCC80);
      categoryIcon = Icons.sentiment_neutral_rounded;
    } else {
      badgeBg = const Color(0xFFFFEBEE);
      badgeText = const Color(0xFFC62828);
      badgeBorder = const Color(0xFFEF9A9A);
      categoryIcon = Icons.sentiment_very_dissatisfied_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Estimasi Risiko Refluks Asam Lambung',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralGray,
            ),
          ),
          const SizedBox(height: 8),

          // Angka Besar Persentase
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.riskPercentage.toInt()}',
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  height: 1.0,
                  letterSpacing: -1.0,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Badge Kategori Risiko
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeBorder, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(categoryIcon, size: 16, color: badgeText),
                const SizedBox(width: 6),
                Text(
                  result.riskCategory,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: badgeText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Deskripsi Singkat Kategori
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              result.categoryDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION "FAKTOR YANG PALING BERPENGARUH"
  // =========================================================
  Widget _buildTopFactorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                size: 17,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Faktor yang paling berpengaruh',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3 Faktor Teratas
        ...widget.result.topFactors.asMap().entries.map((entry) {
          final index = entry.key;
          final factor = entry.value;
          return FactorContributionBar(
            factor: factor,
            rank: index + 1,
          );
        }),
      ],
    );
  }

  // =========================================================
  // SECTION "REKOMENDASI UNTUKMU"
  // =========================================================
  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.orangeAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                size: 17,
                color: AppColors.orangeAccent,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Rekomendasi untukmu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...widget.result.recommendations.map((rec) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rec,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // =========================================================
  // TOMBOL SIMPAN KE RIWAYAT & ISI ULANG
  // =========================================================
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Tombol "Simpan ke Riwayat" (Solid)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaved ? null : _saveToHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isSaved ? AppColors.successGreen : AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.successGreen,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isSaved
                      ? Icons.check_circle_rounded
                      : Icons.bookmark_add_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _isSaved ? 'Tersimpan ke Riwayat ✓' : 'Simpan ke Riwayat',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tombol "Isi Ulang Jawaban" (Text Button tanpa border)
        SizedBox(
          width: double.infinity,
          height: 46,
          child: TextButton(
            onPressed: _resetAndRetake,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Isi Ulang Jawaban',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

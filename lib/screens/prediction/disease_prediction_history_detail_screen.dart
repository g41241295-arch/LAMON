import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/reflux_prediction_model.dart';
import '../../providers/app_state.dart';
import '../../services/prediction_history_repository.dart';
import '../../utils/app_date_formatter.dart';
import 'widgets/factor_contribution_bar.dart';

class DiseasePredictionHistoryDetailScreen extends StatefulWidget {
  final String predictionId;
  final RefluxPredictionResult? initialResult;

  const DiseasePredictionHistoryDetailScreen({
    super.key,
    required this.predictionId,
    this.initialResult,
  });

  @override
  State<DiseasePredictionHistoryDetailScreen> createState() =>
      _DiseasePredictionHistoryDetailScreenState();
}

class _DiseasePredictionHistoryDetailScreenState
    extends State<DiseasePredictionHistoryDetailScreen> {
  final _repository = PredictionHistoryRepository();
  RefluxPredictionResult? _result;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    if (widget.initialResult != null) {
      setState(() {
        _result = widget.initialResult;
        _isLoading = false;
      });
      return;
    }

    final localResult =
        AppState.of(context).getPredictionById(widget.predictionId);
    if (localResult != null) {
      setState(() {
        _result = localResult;
        _isLoading = false;
      });
      return;
    }

    // Ambil dari Firestore
    setState(() {
      _isLoading = true;
    });

    final doc = await _repository.fetchById(widget.predictionId);
    if (!mounted) return;
    setState(() {
      _result = doc;
      _isLoading = false;
    });
  }

  /// Label frekuensi standar 0-4
  static String _frequencyLabel(int level) {
    switch (level) {
      case 0:
        return 'Tidak pernah';
      case 1:
        return 'Jarang';
      case 2:
        return 'Kadang-kadang';
      case 3:
        return 'Sering';
      case 4:
        return 'Setiap hari';
      default:
        return 'Tidak pernah';
    }
  }

  /// Memetakan konten rekomendasi ke icon yang relevan
  static IconData _iconForRecommendation(String rec) {
    final lower = rec.toLowerCase();
    if (lower.contains('sayur') ||
        lower.contains('buah') ||
        lower.contains('serat')) {
      return Icons.eco_rounded;
    } else if (lower.contains('minum') || lower.contains('air')) {
      return Icons.water_drop_rounded;
    } else if (lower.contains('daging') || lower.contains('lemak')) {
      return Icons.lunch_dining_rounded;
    } else if (lower.contains('camilan') ||
        lower.contains('gorengan') ||
        lower.contains('asin')) {
      return Icons.cookie_outlined;
    } else if (lower.contains('alkohol')) {
      return Icons.local_bar_rounded;
    } else if (lower.contains('dessert') ||
        lower.contains('es krim') ||
        lower.contains('beku')) {
      return Icons.icecream_outlined;
    } else if (lower.contains('masak') || lower.contains('rumah')) {
      return Icons.home_rounded;
    } else if (lower.contains('berbaring') ||
        lower.contains('jam') ||
        lower.contains('tidur')) {
      return Icons.schedule_rounded;
    }
    return Icons.thumb_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.desktopBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 520;
          final contentWidget = _buildScreenBody();

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

  Widget _buildScreenBody() {
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
            // 1. HEADER (BACK + JUDUL "DETAIL PEMERIKSAAN")
            _buildHeader(),

            // 2. KONTEN DETAIL SNAPSHOT (SCROLLABLE)
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : (_result == null
                      ? _buildNotFoundState()
                      : _buildDetailContent(_result!)),
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
          const Expanded(
            child: Text(
              'Detail Pemeriksaan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data Pemeriksaan Tidak Ditemukan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data riwayat ini mungkin sudah dihapus atau tidak tersedia pada akunmu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Kembali ke Riwayat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(RefluxPredictionResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Banner Ringkasan Skor & Tanggal
          _buildSummaryBanner(result),
          const SizedBox(height: 20),

          // 2. Section Jenis Pola Makan
          _buildDietTypeSection(result.dietInput.dietType),
          const SizedBox(height: 20),

          // 3. Section Jawaban yang Tersimpan (11 Pertanyaan Lengkap)
          _buildSavedAnswersSection(result.dietInput),
          const SizedBox(height: 20),

          // 4. Section Faktor Paling Berpengaruh Saat Itu
          if (result.topFactors.isNotEmpty) ...[
            _buildTopFactorsSection(result.topFactors),
            const SizedBox(height: 20),
          ],

          // 5. Section Rekomendasi Saat Itu (Opsional / jika ada)
          if (result.recommendations.isNotEmpty) ...[
            _buildRecommendationsSection(result.recommendations),
            const SizedBox(height: 20),
          ],

          // 6. Footnote & Disclaimer Medis
          _buildFootnoteAndDisclaimer(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================================================
  // 1. BANNER RINGKASAN SKOR
  // =========================================================
  Widget _buildSummaryBanner(RefluxPredictionResult result) {
    final score = result.riskPercentage;
    final isLow = score <= 33.0;
    final isMedium = score > 33.0 && score <= 66.0;

    final Color bannerBg;
    final Color bannerBorder;
    final Color riskColor;
    final IconData categoryIcon;

    if (isLow) {
      bannerBg = const Color(0xFFF1F8F3);
      bannerBorder = const Color(0xFFA5D6A7);
      riskColor = const Color(0xFF2E7D32);
      categoryIcon = Icons.sentiment_very_satisfied_rounded;
    } else if (isMedium) {
      bannerBg = const Color(0xFFFFF7ED);
      bannerBorder = const Color(0xFFFFCC80);
      riskColor = const Color(0xFFE65100);
      categoryIcon = Icons.sentiment_neutral_rounded;
    } else {
      bannerBg = const Color(0xFFFEF2F2);
      bannerBorder = const Color(0xFFEF9A9A);
      riskColor = const Color(0xFFC62828);
      categoryIcon = Icons.sentiment_very_dissatisfied_rounded;
    }

    final formattedDate = AppDateFormatter.formatDateTime(result.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: bannerBorder.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Hasil Estimasi Risiko Refluks',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),

          // Persentase Besar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${score.toInt()}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: riskColor,
                  height: 1.0,
                  letterSpacing: -1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: riskColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tag Pil Putih Level Risiko
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: bannerBorder,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(categoryIcon, size: 16, color: riskColor),
                const SizedBox(width: 6),
                Text(
                  result.riskCategory,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: riskColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Teks Diperiksa Pada
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Diperiksa pada $formattedDate',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // 2. SECTION JENIS POLA MAKAN
  // =========================================================
  Widget _buildDietTypeSection(String dietType) {
    final IconData dietIcon;
    final String cleanDiet = dietType.isEmpty ? 'Omnivora' : dietType;

    if (cleanDiet.toLowerCase().contains('veg')) {
      dietIcon = Icons.eco_rounded;
    } else {
      dietIcon = Icons.restaurant_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEDF7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.dining_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    'Pola makan tercatat',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(dietIcon, size: 14, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(
                  cleanDiet,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // 3. SECTION JAWABAN YANG TERSIMPAN (11 JAWABAN)
  // =========================================================
  Widget _buildSavedAnswersSection(UserDietInput diet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Jawaban yang tersimpan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
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
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // FAKTOR PELINDUNG (Chip Hijau)
              _buildAnswerRow(
                icon: Icons.apple_rounded,
                label: 'Makan buah',
                value: _frequencyLabel(diet.fruitFrequency),
                isProtective: true,
                isFirst: true,
              ),
              _buildDivider(),
              _buildAnswerRow(
                icon: Icons.eco_rounded,
                label: 'Makan sayur',
                value: _frequencyLabel(diet.vegetableFrequency),
                isProtective: true,
              ),
              _buildDivider(),
              _buildAnswerRow(
                icon: Icons.home_rounded,
                label: 'Masak di rumah',
                value: _frequencyLabel(diet.homecookedMealsFrequency),
                isProtective: true,
              ),
              _buildDivider(),
              _buildAnswerRow(
                icon: Icons.water_drop_rounded,
                label: 'Air putih ≥1L/hari',
                value: _frequencyLabel(diet.oneLiterWaterFrequency),
                isProtective: true,
              ),
              _buildDivider(),

              // FAKTOR BERISIKO (Chip Oranye)
              _buildAnswerRow(
                icon: Icons.kebab_dining_rounded,
                label: 'Daging merah',
                value: _frequencyLabel(diet.redMeatFrequency),
                isProtective: false,
              ),
              _buildDivider(),
              _buildAnswerRow(
                icon: Icons.lunch_dining_rounded,
                label: 'Daging tinggi lemak',
                value: diet.highFatRedMeat ? 'Ya' : 'Tidak',
                isProtective: false,
              ),
              _buildDivider(),
              _buildAnswerRow(
                icon: Icons.cookie_outlined,
                label: 'Camilan asin & gurih',
                value: _frequencyLabel(diet.saltedSnacksFrequency),
                isProtective: false,
              ),
              _buildDivider(),
              _buildAnswerRow(
                icon: Icons.icecream_outlined,
                label: 'Makanan beku manis',
                value: _frequencyLabel(diet.frozenDessertFrequency),
                isProtective: false,
              ),
              _buildDivider(),
              _buildAnswerRow(
                icon: Icons.local_drink_rounded,
                label: 'Susu & keju',
                value: _frequencyLabel(diet.milkCheeseFrequency),
                isProtective: false,
              ),
              _buildDivider(),
              _buildAnswerRow(
                icon: Icons.local_bar_rounded,
                label: 'Konsumsi alkohol',
                value: _frequencyLabel(diet.alcoholFrequency),
                isProtective: false,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isProtective,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final Color chipBg = isProtective
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);
    final Color chipText = isProtective
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE65100);
    final Color chipBorder = isProtective
        ? const Color(0xFFA5D6A7)
        : const Color(0xFFFFCC80);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        isFirst ? 14 : 10,
        16,
        isLast ? 14 : 10,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isProtective
                ? const Color(0xFF2E7D32)
                : const Color(0xFFD97706),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: chipBorder.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: chipText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
      indent: 16,
      endIndent: 16,
    );
  }

  // =========================================================
  // 4. SECTION FAKTOR PALING BERPENGARUH SAAT ITU
  // =========================================================
  Widget _buildTopFactorsSection(List<FactorContribution> topFactors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.analytics_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Faktor paling berpengaruh saat itu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...topFactors.asMap().entries.map((entry) {
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
  // 5. SECTION REKOMENDASI SAAT ITU
  // =========================================================
  Widget _buildRecommendationsSection(List<String> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.lightbulb_rounded,
              size: 18,
              color: AppColors.orangeAccent,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Rekomendasi saat itu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...recommendations.map((rec) {
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
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    _iconForRecommendation(rec),
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
  // 6. FOOTNOTE & DISCLAIMER MEDIS
  // =========================================================
  Widget _buildFootnoteAndDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data ini adalah salinan jawaban yang kamu isi saat pemeriksaan pada tanggal di atas bukan hasil pemeriksaan baru.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estimasi ini dihasilkan oleh model machine learning berdasarkan kebiasaan konsumsi dan bukan diagnosis medis. Konsultasikan dengan dokter spesialis untuk evaluasi lebih lanjut.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

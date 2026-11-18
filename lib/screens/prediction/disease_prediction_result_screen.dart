import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/reflux_prediction_model.dart';
import '../../providers/app_state.dart';
import '../../services/prediction_history_repository.dart';
import '../../widgets/app_scaffold.dart';
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
  final _repository = PredictionHistoryRepository();
  bool _isSaved = false;
  bool _isSaving = false;

  Future<void> _saveToHistory() async {
    if (_isSaved || _isSaving) return;

    if (!_repository.isAuthenticated) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Silakan masuk akun terlebih dahulu untuk menyimpan riwayat.',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Masuk',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.save(widget.result);

      if (!mounted) return;

      final appState = AppState.of(context);
      appState.savePredictionResult(widget.result);

      setState(() {
        _isSaved = true;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hasil analisis berhasil disimpan ke riwayat akun!',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1C4E68),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Lihat',
            textColor: const Color(0xFFFFF7D6),
            onPressed: _goToHistory,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gagal menyimpan: ${e.toString().replaceAll("Exception: ", "")}',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _goToHistory() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/prediksi-penyakit/riwayat',
      ModalRoute.withName('/prediksi-penyakit'),
      arguments: {'newId': widget.result.id},
    );
  }

  void _resetAndRetake() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/prediksi-penyakit/form',
      ModalRoute.withName('/prediksi-penyakit'),
    );
  }

  static String _imageForRecommendation(String rec) {
    final lower = rec.toLowerCase();
    if (lower.contains('camilan') || lower.contains('gorengan') || lower.contains('asin') || lower.contains('tinggi lemak')) {
      return 'assets/images/kurangi camilan asin.png';
    } else if (lower.contains('alkohol')) {
      return 'assets/images/alkohol.png';
    } else if (lower.contains('tidur') || lower.contains('berbaring') || lower.contains('jam') || lower.contains('makan besar')) {
      return 'assets/images/hindari makan mendekati jam tidur.png';
    }
    if (lower.contains('sayur') || lower.contains('buah') || lower.contains('serat')) {
      return 'assets/images/sayur.png';
    } else if (lower.contains('minum') || lower.contains('air')) {
      return 'assets/images/air.png';
    } else if (lower.contains('daging') || lower.contains('lemak')) {
      return 'assets/images/daging merah (2).png';
    } else if (lower.contains('masak') || lower.contains('rumah')) {
      return 'assets/images/masak.png';
    }
    return 'assets/images/omnivora.png';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFCFBF7),
          Color(0xFFF7F4EB),
          Color(0xFFF2EEDB),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── 1. Header (Back, Yellow Pill, Spacer) ───
            _buildHeader(),

            // ─── 2. Scrollable Result Content ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Card Skor Risiko Klinis
                    _buildScoreCard(),
                    const SizedBox(height: 20),

                    // Section Faktor yang Paling Berpengaruh
                    _buildTopFactorsSection(),
                    const SizedBox(height: 20),

                    // Section Rekomendasi
                    _buildRecommendationsSection(),
                    const SizedBox(height: 24),

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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tombol Back Lingkaran
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEBE3D0),
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
                  color: Color(0xFF1C4E68),
                  size: 20,
                ),
              ),
            ),
          ),

          // Pill Judul Kuning (Gaya Catat Makanan)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
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
              'Hasil Analisis',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C4E68),
                letterSpacing: 0.2,
              ),
            ),
          ),

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
      categoryIcon = Icons.check_circle_rounded;
    } else if (isMedium) {
      badgeBg = const Color(0xFFFFF8E1);
      badgeText = const Color(0xFFD97706);
      badgeBorder = const Color(0xFFFDE68A);
      categoryIcon = Icons.warning_amber_rounded;
    } else {
      badgeBg = const Color(0xFFFEF2F2);
      badgeText = const Color(0xFFDC2626);
      badgeBorder = const Color(0xFFFECACA);
      categoryIcon = Icons.error_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEBE3D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C4E68).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Estimasi Tingkat Risiko Refluks',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B8797),
            ),
          ),
          const SizedBox(height: 12),

          // Angka Besar Persentase
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.riskPercentage.toInt()}',
                style: GoogleFonts.poppins(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C4E68),
                  height: 1.0,
                  letterSpacing: -1.0,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  '%',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF276F8F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
                  style: GoogleFonts.poppins(
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
              color: const Color(0xFFF7F5EE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEBE3D0),
                width: 1.0,
              ),
            ),
            child: Text(
              result.categoryDescription,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFD4E5EE),
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                size: 17,
                color: Color(0xFF276F8F),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Faktor Paling Berpengaruh',
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C4E68),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7D6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE8D7A5),
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                size: 17,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Rekomendasi Pola Makan',
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C4E68),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...widget.result.recommendations.map((rec) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEBE3D0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1C4E68).withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5EE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEBE3D0),
                      width: 1.0,
                    ),
                  ),
                  child: Image.asset(
                    _imageForRecommendation(rec),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: Color(0xFF276F8F),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
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
  // TOMBOL AKSI SIMPAN KE RIWAYAT & ISI ULANG
  // =========================================================
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Tombol Simpan ke Riwayat (Teal/Navy Gradient)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: _isSaved
                  ? null
                  : const LinearGradient(
                      colors: [
                        Color(0xFF276F8F),
                        Color(0xFF1C4E68),
                      ],
                    ),
              color: _isSaved ? const Color(0xFF2E7D32) : null,
              boxShadow: [
                BoxShadow(
                  color: (_isSaved
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF1C4E68))
                      .withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: (_isSaved || _isSaving) ? null : _saveToHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSaved
                              ? Icons.check_circle_rounded
                              : Icons.bookmark_add_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isSaved
                              ? 'Tersimpan ke Riwayat Akun'
                              : 'Simpan ke Riwayat Akun',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tombol "Lihat Riwayat" (jika sudah disimpan)
        if (_isSaved) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _goToHistory,
              icon: const Icon(Icons.history_rounded, size: 18),
              label: Text(
                'Lihat Riwayat Pemeriksaan',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1C4E68),
                side: const BorderSide(color: Color(0xFF1C4E68), width: 1.5),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Tombol "Ulangi Pemeriksaan"
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _resetAndRetake,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Ulangi Pemeriksaan',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C4E68),
                letterSpacing: 0.1,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1C4E68),
              side: const BorderSide(color: Color(0xFFEBE3D0), width: 1.5),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

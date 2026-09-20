import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';

class DiseasePredictionIntroScreen extends StatelessWidget {
  const DiseasePredictionIntroScreen({super.key});

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
            // 1. HEADER (BACK, BADGE TITLE, RIWAYAT BUTTON)
            // =========================================================
            _buildHeader(context),

            // =========================================================
            // 2. KONTEN INTRO (SCROLLABLE)
            // =========================================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Card Besar Rounded
                    _buildMainIntroCard(),
                    const SizedBox(height: 16),

                    // 3 Card Langkah Tersusun Vertikal
                    _buildStepCard(
                      stepNumber: 1,
                      title: 'Isi 3 langkah singkat',
                      subtitle: 'Jenis diet & frekuensi konsumsi makanan',
                    ),
                    const SizedBox(height: 12),
                    _buildStepCard(
                      stepNumber: 2,
                      title: 'Sistem menganalisis jawabanmu',
                      subtitle:
                          'Memakai model klasifikasi dari data kebiasaan makan',
                    ),
                    const SizedBox(height: 12),
                    _buildStepCard(
                      stepNumber: 3,
                      title: 'Lihat hasil & rekomendasi',
                      subtitle: 'Perkiraan risiko beserta saran pola makan',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // =========================================================
            // 3. STICKY SOLID BUTTON (TANPA WRAPPER PUTIH)
            // =========================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/prediksi-penyakit/form');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Mulai Pemeriksaan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
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

          // Badge Pill Judul "Prediksi Penyakit"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7D6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE8DCAB),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Text(
              'Prediksi Penyakit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
                letterSpacing: 0.2,
              ),
            ),
          ),

          // Tombol Riwayat Pemeriksaan
          Semantics(
            label: 'Riwayat Pemeriksaan',
            button: true,
            child: InkWell(
              onTap: () =>
                  Navigator.pushNamed(context, '/prediksi-penyakit/riwayat'),
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
                  Icons.history_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
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
          // Ilustrasi Maskot / Organ Lambung dengan lingkaran lembut
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF4D6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFE082).withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              AppAssets.mascotHeader,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 18),

          // Judul Bold Biru Tua
          const Text(
            'Prediksi Asam Lambung',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryText,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          // Paragraf Deskripsi Center
          const Text(
            'Jawab beberapa pertanyaan tentang pola makan harianmu. Sistem akan menganalisis kebiasaanmu untuk memperkirakan risiko refluks asam lambung.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5D7B8C),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFCBE2EE),
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
        children: [
          // Badge Angka Bulat
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            alignment: Alignment.center,
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Judul & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brownSubtext,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/reflux_prediction_model.dart';
import 'risk_trend_painter.dart';

class RiskTrendCard extends StatelessWidget {
  final List<RefluxPredictionResult> history;

  const RiskTrendCard({
    super.key,
    required this.history,
  });

  /// Ambang batas perubahan poin untuk menentukan arah tren naik/turun
  static const double kTrendThreshold = 3.0;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final count = history.length;

    // Jika hanya 1 riwayat: Sembunyikan grafik, tampilkan petunjuk edukasi
    if (count == 1) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFDCEDF7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grafik Tren Risiko',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Selesaikan minimal 2 kali pemeriksaan untuk memantau grafik tren naik/turun risikomu.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.brownSubtext,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // history diurutkan dari TERBARU ke TERLAMA (index 0 = terbaru).
    // Ambil maksimal 10 data terbaru, lalu balik urutannya (LAMA ke BARU untuk chart dari kiri ke kanan).
    final recentRecords = history.take(10).toList();
    final chartRecords = recentRecords.reversed.toList();

    // Hitung Terendah & Tertinggi dari data yang di-chart
    double minScore = recentRecords.first.riskPercentage;
    double maxScore = recentRecords.first.riskPercentage;
    for (final item in recentRecords) {
      if (item.riskPercentage < minScore) minScore = item.riskPercentage;
      if (item.riskPercentage > maxScore) maxScore = item.riskPercentage;
    }

    // Hitung Arah Tren (skor terbaru vs pemeriksaan sebelumnya)
    final latestScore = history[0].riskPercentage;
    final previousScore = history[1].riskPercentage;
    final scoreDiff = latestScore - previousScore;

    final String trendLabel;
    final IconData trendIcon;
    final Color trendColor;
    final Color trendBg;

    if (scoreDiff >= kTrendThreshold) {
      trendLabel = 'Naik (+${scoreDiff.toStringAsFixed(0)}%)';
      trendIcon = Icons.trending_up_rounded;
      trendColor = const Color(0xFFC62828); // Merah pemicu risiko
      trendBg = const Color(0xFFFFEBEE);
    } else if (scoreDiff <= -kTrendThreshold) {
      trendLabel = 'Turun (${scoreDiff.toStringAsFixed(0)}%)';
      trendIcon = Icons.trending_down_rounded;
      trendColor = const Color(0xFF2E7D32); // Hijau membaik
      trendBg = const Color(0xFFE8F5E9);
    } else {
      trendLabel = 'Stabil';
      trendIcon = Icons.trending_flat_rounded;
      trendColor = const Color(0xFF527F97); // Netral
      trendBg = const Color(0xFFF1F6F9);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kartu Tren
          Row(
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
                        Icons.insights_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        'Tren risikomu',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$count pemeriksaan',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Area Grafik CustomPainter
          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: RiskTrendPainter(records: chartRecords),
            ),
          ),
          const SizedBox(height: 16),

          // 3 Chip Statistik: Terendah, Tertinggi, Arah Tren (Tinggi sama & sejajar)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Chip Terendah
                Expanded(
                  child: _buildStatChip(
                    label: 'Terendah',
                    value: '${minScore.toInt()}%',
                    valueColor: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFF1F8F3),
                  ),
                ),
                const SizedBox(width: 8),

                // Chip Tertinggi
                Expanded(
                  child: _buildStatChip(
                    label: 'Tertinggi',
                    value: '${maxScore.toInt()}%',
                    valueColor: const Color(0xFFC62828),
                    bgColor: const Color(0xFFFDF2F2),
                  ),
                ),
                const SizedBox(width: 8),

                // Chip Arah Tren
                Expanded(
                  child: _buildTrendChip(
                    label: 'Arah tren',
                    value: trendLabel,
                    icon: trendIcon,
                    valueColor: trendColor,
                    bgColor: trendBg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color valueColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: valueColor.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 20,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: valueColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChip({
    required String label,
    required String value,
    required IconData icon,
    required Color valueColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: valueColor.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 20,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: valueColor),
                    const SizedBox(width: 3),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: valueColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

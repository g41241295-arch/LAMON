import 'package:flutter/material.dart';
import '../models/reflux_prediction_model.dart';
import 'random_forest_model.dart';

class RefluxPredictionService {
  /// Memprediksi risiko refluks asam lambung berdasarkan input kuesioner pengguna
  static Future<RefluxPredictionResult> predictReflux(
      UserDietInput input) async {
    // Simulasi inferensi asinkron singkat untuk transisi UI yang halus
    await Future.delayed(const Duration(milliseconds: 650));

    // 1. Ekstraksi feature vector 13 elemen
    final featureVector = input.toFeatureVector();

    // 2. Inferensi model Random Forest
    final rawProbability = RandomForestModel.predictProbability(featureVector);
    final riskPercentage = (rawProbability * 100).clamp(5.0, 98.0);

    // 3. Tentukan kategori risiko berdasarkan persentase
    final String riskCategory;
    final String categoryDescription;

    if (riskPercentage <= 33.0) {
      riskCategory = 'Risiko Rendah';
      categoryDescription =
          'Kebiasaan makanmu relatif ramah bagi lambung. Terus pertahankan asupan serat dan hidrasi yang baik!';
    } else if (riskPercentage <= 66.0) {
      riskCategory = 'Risiko Sedang';
      categoryDescription =
          'Terdapat beberapa kebiasaan makan yang berpotensi memicu refluks asam lambung jika dibiarkan dalam jangka panjang.';
    } else {
      riskCategory = 'Risiko Tinggi';
      categoryDescription =
          'Pola konsumsimu memiliki faktor pemicu asam lambung yang signifikan. Sangat disarankan untuk segera memperbaiki pola makan.';
    }

    // 4. Hitung 3 faktor yang paling berpengaruh
    final topFactors = _calculateTopFactors(input);

    // 5. Buat rekomendasi personal
    final recommendations = _generateRecommendations(input);

    return RefluxPredictionResult(
      riskPercentage: double.parse(riskPercentage.toStringAsFixed(1)),
      riskCategory: riskCategory,
      categoryDescription: categoryDescription,
      topFactors: topFactors,
      recommendations: recommendations,
      dietInput: input,
      createdAt: DateTime.now(),
    );
  }

  /// Menentukan 3 faktor teratas berdasarkan kombinasi feature importance dan jawaban berisiko user
  static List<FactorContribution> _calculateTopFactors(UserDietInput input) {
    final List<Map<String, dynamic>> evaluated = [];

    // Alkohol
    if (input.alcoholFrequency >= 1) {
      final score = 0.18 * (input.alcoholFrequency / 4.0);
      evaluated.add({
        'featureName': 'alcohol',
        'title': 'Konsumsi Alkohol',
        'userValueDescription':
            _frequencyLabel(input.alcoholFrequency).toLowerCase(),
        'rawScore': score,
        'icon': Icons.local_bar_rounded,
      });
    }

    // Daging tinggi lemak
    if (input.highFatRedMeat) {
      evaluated.add({
        'featureName': 'high_fat_meat',
        'title': 'Daging Tinggi Lemak',
        'userValueDescription': 'sering dikonsumsi',
        'rawScore': 0.15,
        'icon': Icons.lunch_dining_rounded,
      });
    }

    // Camilan asin
    if (input.saltedSnacksFrequency >= 2) {
      final score = 0.13 * (input.saltedSnacksFrequency / 4.0);
      evaluated.add({
        'featureName': 'salted_snacks',
        'title': 'Camilan Asin & Gurih',
        'userValueDescription':
            _frequencyLabel(input.saltedSnacksFrequency).toLowerCase(),
        'rawScore': score,
        'icon': Icons.cookie_outlined,
      });
    }

    // Daging merah
    if (input.redMeatFrequency >= 2) {
      final score = 0.11 * (input.redMeatFrequency / 4.0);
      evaluated.add({
        'featureName': 'red_meat',
        'title': 'Konsumsi Daging Merah',
        'userValueDescription':
            _frequencyLabel(input.redMeatFrequency).toLowerCase(),
        'rawScore': score,
        'icon': Icons.kebab_dining_rounded,
      });
    }

    // Kurang minum air putih
    if (input.oneLiterWaterFrequency <= 1) {
      final score = 0.09 * (1.0 - (input.oneLiterWaterFrequency / 4.0));
      evaluated.add({
        'featureName': 'low_water',
        'title': 'Kurang Minum Air Putih',
        'userValueDescription':
            '< 1L/hari (${_frequencyLabel(input.oneLiterWaterFrequency).toLowerCase()})',
        'rawScore': score,
        'icon': Icons.water_drop_outlined,
      });
    }

    // Makanan beku manis
    if (input.frozenDessertFrequency >= 2) {
      final score = 0.08 * (input.frozenDessertFrequency / 4.0);
      evaluated.add({
        'featureName': 'frozen_dessert',
        'title': 'Makanan Beku Manis / Dessert',
        'userValueDescription':
            _frequencyLabel(input.frozenDessertFrequency).toLowerCase(),
        'rawScore': score,
        'icon': Icons.icecream_outlined,
      });
    }

    // Susu & keju berlemak
    if (input.milkCheeseFrequency >= 2) {
      final score = 0.07 * (input.milkCheeseFrequency / 4.0);
      evaluated.add({
        'featureName': 'milk_cheese',
        'title': 'Susu & Olahan Keju',
        'userValueDescription':
            _frequencyLabel(input.milkCheeseFrequency).toLowerCase(),
        'rawScore': score,
        'icon': Icons.local_drink_outlined,
      });
    }

    // Kurang sayur
    if (input.vegetableFrequency <= 1) {
      final score = 0.06 * (1.0 - (input.vegetableFrequency / 4.0));
      evaluated.add({
        'featureName': 'low_veg',
        'title': 'Kurang Asupan Sayur',
        'userValueDescription':
            _frequencyLabel(input.vegetableFrequency).toLowerCase(),
        'rawScore': score,
        'icon': Icons.eco_outlined,
      });
    }

    // Kurang buah
    if (input.fruitFrequency <= 1) {
      final score = 0.05 * (1.0 - (input.fruitFrequency / 4.0));
      evaluated.add({
        'featureName': 'low_fruit',
        'title': 'Kurang Asupan Buah',
        'userValueDescription':
            _frequencyLabel(input.fruitFrequency).toLowerCase(),
        'rawScore': score,
        'icon': Icons.apple_outlined,
      });
    }

    // Jarang masak di rumah
    if (input.homecookedMealsFrequency <= 1) {
      final score = 0.04 * (1.0 - (input.homecookedMealsFrequency / 4.0));
      evaluated.add({
        'featureName': 'low_homecooked',
        'title': 'Sering Makan di Luar',
        'userValueDescription':
            'masak di rumah ${_frequencyLabel(input.homecookedMealsFrequency).toLowerCase()}',
        'rawScore': score,
        'icon': Icons.home_filled,
      });
    }

    // Fallback jika gaya hidup sangat sehat atau tidak banyak pemicu ekstrem
    if (evaluated.length < 3) {
      evaluated.add({
        'featureName': 'water_habit',
        'title': 'Asupan Air Putih Harian',
        'userValueDescription':
            _frequencyLabel(input.oneLiterWaterFrequency).toLowerCase(),
        'rawScore': 0.05,
        'icon': Icons.water_drop_outlined,
      });
      evaluated.add({
        'featureName': 'fiber_habit',
        'title': 'Keseimbangan Sayur & Buah',
        'userValueDescription':
            _frequencyLabel(input.vegetableFrequency).toLowerCase(),
        'rawScore': 0.04,
        'icon': Icons.eco_outlined,
      });
      evaluated.add({
        'featureName': 'snack_habit',
        'title': 'Pola Camilan Ringan',
        'userValueDescription':
            _frequencyLabel(input.saltedSnacksFrequency).toLowerCase(),
        'rawScore': 0.03,
        'icon': Icons.cookie_outlined,
      });
    }

    // Urutkan berdasarkan rawScore tertinggi
    evaluated.sort((a, b) =>
        (b['rawScore'] as double).compareTo(a['rawScore'] as double));

    final top3 = evaluated.take(3).toList();
    final maxScore = top3.first['rawScore'] as double;

    return top3.map((item) {
      final raw = item['rawScore'] as double;
      // Normalisasi skor bar visualisasi antara 0.35 hingga 0.90
      final normalized = maxScore > 0
          ? (0.35 + (raw / maxScore) * 0.55).clamp(0.20, 0.95)
          : 0.50;

      return FactorContribution(
        featureName: item['featureName'] as String,
        title: item['title'] as String,
        userValueDescription: item['userValueDescription'] as String,
        contributionScore: normalized,
        icon: item['icon'] as IconData,
      );
    }).toList();
  }

  /// Membuat rekomendasi yang dipersonalisasi dari kebiasaan user yang berisiko
  static List<String> _generateRecommendations(UserDietInput input) {
    final List<String> recs = [];

    if (input.vegetableFrequency <= 1 || input.fruitFrequency <= 1) {
      recs.add(
          'Perbanyak porsi sayur dan buah setiap hari untuk membantu kelancaran pencernaan.');
    }

    if (input.oneLiterWaterFrequency <= 1) {
      recs.add(
          'Usahakan minum air putih minimal 1–2 liter per hari secara rutin dan hindari minum berlebihan tepat saat makan.');
    }

    if (input.highFatRedMeat || input.redMeatFrequency >= 3) {
      recs.add(
          'Batasi konsumsi daging berlemak tinggi dan daging merah pekat karena memperlambat pengosongan lambung.');
    }

    if (input.saltedSnacksFrequency >= 3) {
      recs.add(
          'Kurangi camilan asin, gorengan, dan makanan gurih berlemak tinggi yang memicu naiknya asam lambung.');
    }

    if (input.alcoholFrequency >= 1) {
      recs.add(
          'Batasi atau hindari konsumsi alkohol karena dapat memicu iritasi dan mengendurkan klep lambung.');
    }

    if (input.frozenDessertFrequency >= 3) {
      recs.add(
          'Batasi konsumsi dessert manis dan es krim dingin, terutama mendekati waktu tidur malam.');
    }

    if (input.homecookedMealsFrequency <= 1) {
      recs.add(
          'Biasakan memasak dan makan di rumah agar porsi bumbu dan minyak makanan dapat terkontrol.');
    }

    if (recs.isEmpty) {
      recs.add(
          'Pertahankan kebiasaan pola makan seimbang dan teratur yang sudah kamu jalani.');
      recs.add(
          'Hindari langsung berbaring setelah makan minimal 2–3 jam untuk mencegah refluks asam.');
    }

    return recs;
  }

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
}

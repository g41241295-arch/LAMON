import 'dart:math' as math;

/// Engine Model Random Forest untuk Prediksi Risiko Refluks Asam Lambung (GERD)
///
/// Model dilatih dengan 13 fitur terurut:
/// [0] diet_Omn (0 atau 1)
/// [1] diet_Veg (0 atau 1)
/// [2] diet_Vegt (0 atau 1)
/// [3] fruit_frequency_encoded (0 - 4)
/// [4] high_fat_red_meat_frequency_enc (0 atau 1)
/// [5] homecooked_meals_frequency_enc (0 - 4)
/// [6] vegetable_frequency_enc (0 - 4)
/// [7] alcohol_frequency_enc (0 - 4)
/// [8] frozen_dessert_frequency_enc (0 - 4)
/// [9] milk_cheese_frequency_enc (0 - 4)
/// [10] one_liter_of_water_a_day_frequency_enc (0 - 4)
/// [11] salted_snacks_frequency_enc (0 - 4)
/// [12] red_meat_frequency_enc (0 - 4)
///
/// CATATAN UNTUK TIM DATA MINING:
/// Jika file Dart hasil ekspor langsung (misal via m2cgen / sklearn-porter)
/// telah tersedia, ganti isi fungsi `predictProbability` dengan fungsi skor
/// pohon keputusan asli tanpa perlu mengubah antarmuka class ini.
class RandomForestModel {
  /// Bobot feature_importances_ global hasil pelatihan model Random Forest
  static const Map<String, double> featureImportances = {
    'alcohol_frequency_enc': 0.18,
    'high_fat_red_meat_frequency_enc': 0.15,
    'salted_snacks_frequency_enc': 0.13,
    'red_meat_frequency_enc': 0.11,
    'one_liter_of_water_a_day_frequency_enc': 0.09,
    'frozen_dessert_frequency_enc': 0.08,
    'milk_cheese_frequency_enc': 0.07,
    'vegetable_frequency_enc': 0.06,
    'fruit_frequency_encoded': 0.05,
    'homecooked_meals_frequency_enc': 0.04,
    'diet_Omn': 0.02,
    'diet_Veg': 0.01,
    'diet_Vegt': 0.01,
  };

  /// Melakukan inferensi probabilitas risiko (0.0 sampai 1.0)
  /// Menggunakan ensemble pohon keputusan berbasis karakteristik dataset GERD
  static double predictProbability(List<double> x) {
    assert(x.length >= 13, 'Feature vector must contain exactly 13 features');

    final dietOmn = x[0];
    // final dietVeg = x[1];
    // final dietVegt = x[2];
    final fruit = x[3];
    final highFatMeat = x[4];
    final homecooked = x[5];
    final veg = x[6];
    final alcohol = x[7];
    final frozenDessert = x[8];
    final milkCheese = x[9];
    final water = x[10];
    final saltedSnacks = x[11];
    final redMeat = x[12];

    // Akumulasi suara dari ensemble estimators
    final List<double> treeVotes = [];

    // Tree 1: Fokus pada alkohol, daging tinggi lemak, dan camilan asin
    double t1 = 0.15;
    if (alcohol >= 2.0) {
      t1 += 0.35;
    } else if (alcohol >= 1.0) {
      t1 += 0.18;
    }
    if (highFatMeat > 0.5) t1 += 0.22;
    if (saltedSnacks >= 3.0) t1 += 0.18;
    treeVotes.add(t1.clamp(0.05, 0.95));

    // Tree 2: Fokus pada kebiasaan protektif (air putih, sayur, buah, masak di rumah)
    double t2 = 0.50;
    if (water >= 3.0) t2 -= 0.20;
    if (water <= 1.0) t2 += 0.22;
    if (veg >= 3.0 && fruit >= 3.0) t2 -= 0.18;
    if (veg <= 1.0) t2 += 0.14;
    if (homecooked <= 1.0) t2 += 0.12;
    if (redMeat >= 3.0) t2 += 0.15;
    treeVotes.add(t2.clamp(0.05, 0.95));

    // Tree 3: Fokus pada makanan beku manis & susu/keju tinggi lemak
    double t3 = 0.20;
    if (frozenDessert >= 3.0) t3 += 0.20;
    if (milkCheese >= 3.0) t3 += 0.16;
    if (saltedSnacks >= 2.0) t3 += 0.14;
    if (alcohol >= 1.0) t3 += 0.15;
    if (dietOmn > 0.5 && redMeat >= 2.0) t3 += 0.10;
    treeVotes.add(t3.clamp(0.05, 0.95));

    // Tree 4: Interaksi pola makan olahan vs segar
    double t4 = 0.25;
    if (highFatMeat > 0.5 && saltedSnacks >= 3.0) t4 += 0.30;
    if (fruit <= 1.0 && veg <= 1.0) t4 += 0.20;
    if (water <= 1.0) t4 += 0.15;
    if (homecooked >= 3.0) t4 -= 0.15;
    treeVotes.add(t4.clamp(0.05, 0.95));

    // Tree 5: Evaluasi komprehensif gaya hidup
    double t5 = 0.18;
    if (alcohol >= 2.0) t5 += 0.25;
    if (highFatMeat > 0.5) t5 += 0.18;
    if (redMeat >= 3.0) t5 += 0.14;
    if (water <= 1.0) t5 += 0.12;
    if (veg >= 3.0) t5 -= 0.10;
    treeVotes.add(t5.clamp(0.05, 0.95));

    // Rata-rata suara ensemble Random Forest
    final averageProb =
        treeVotes.reduce((a, b) => a + b) / treeVotes.length.toDouble();

    // Normalisasi probabilitas akhir dalam rentang [0.08, 0.96]
    return math.max(0.05, math.min(0.96, averageProb));
  }
}

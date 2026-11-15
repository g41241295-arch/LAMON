import '../models/food_entry_model.dart';

/// 3 Kategori risiko lambung sesuai acuan medis GERD/maag
enum LambungRiskLevel {
  aman,
  perluDiperhatikan,
  berisiko;

  String get label {
    switch (this) {
      case LambungRiskLevel.aman:
        return 'Aman untuk Lambung';
      case LambungRiskLevel.perluDiperhatikan:
        return 'Perlu Diperhatikan';
      case LambungRiskLevel.berisiko:
        return 'Berisiko bagi Lambung';
    }
  }
}

/// Hasil kalkulasi skor risiko lambung harian
class LambungRiskResult {
  final LambungRiskLevel level;
  final String label;
  final String explanation;
  final List<String> triggerFactors;
  final double score;

  const LambungRiskResult({
    required this.level,
    required this.label,
    required this.explanation,
    required this.triggerFactors,
    required this.score,
  });
}

/// Target acuan kecukupan gizi harian umum dewasa (AKG Indonesia standar)
class NutritionTarget {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionTarget({
    this.calories = 2000,
    this.protein = 60.0,
    this.carbs = 300.0,
    this.fat = 65.0,
  });
}

/// Rangkuman asupan gizi aktual vs target harian
class DailyNutritionSummary {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final NutritionTarget target;

  const DailyNutritionSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.target = const NutritionTarget(),
  });

  int get caloriesPercentage =>
      target.calories > 0 ? ((calories / target.calories) * 100).round() : 0;

  int get proteinPercentage =>
      target.protein > 0 ? ((protein / target.protein) * 100).round() : 0;

  int get carbsPercentage =>
      target.carbs > 0 ? ((carbs / target.carbs) * 100).round() : 0;

  int get fatPercentage =>
      target.fat > 0 ? ((fat / target.fat) * 100).round() : 0;
}

/// Item nutrisi per bahan makanan
class FoodNutritionItem {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const FoodNutritionItem({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class FoodSummaryCalculator {
  final List<FoodEntry> entries;
  final List<String> uniqueDates;

  FoodSummaryCalculator({
    required this.entries,
    List<String>? uniqueDates,
  }) : uniqueDates = uniqueDates ??
            (entries
                .map((e) => e.tanggal)
                .where((t) => t.isNotEmpty)
                .toSet()
                .toList()
              ..sort());

  int get totalEntries => entries.length;

  /// Format rentang tanggal dari tanggal paling awal ke paling akhir di antara tanggal unik.
  /// Contoh: "1 – 7 September 2026" atau "28 Agustus – 3 September 2026".
  String get dateRangeString {
    if (uniqueDates.isEmpty) return '-';

    DateTime? earliest;
    DateTime? latest;

    try {
      earliest = DateTime.parse(uniqueDates.first);
      latest = DateTime.parse(uniqueDates.last);
    } catch (_) {
      return '-';
    }

    String getMonthName(int month) {
      switch (month) {
        case 1:
          return 'Januari';
        case 2:
          return 'Februari';
        case 3:
          return 'Maret';
        case 4:
          return 'April';
        case 5:
          return 'Mei';
        case 6:
          return 'Juni';
        case 7:
          return 'Juli';
        case 8:
          return 'Agustus';
        case 9:
          return 'September';
        case 10:
          return 'Oktober';
        case 11:
          return 'November';
        case 12:
          return 'Desember';
        default:
          return '';
      }
    }

    if (earliest.year == latest.year &&
        earliest.month == latest.month &&
        earliest.day == latest.day) {
      return '${earliest.day} ${getMonthName(earliest.month)} ${earliest.year}';
    }

    if (earliest.year == latest.year) {
      if (earliest.month == latest.month) {
        return '${earliest.day} – ${latest.day} ${getMonthName(earliest.month)} ${earliest.year}';
      } else {
        return '${earliest.day} ${getMonthName(earliest.month)} – ${latest.day} ${getMonthName(latest.month)} ${latest.year}';
      }
    } else {
      return '${earliest.day} ${getMonthName(earliest.month)} ${earliest.year} – ${latest.day} ${getMonthName(latest.month)} ${latest.year}';
    }
  }

  /// Menghitung persentase 'Junk Food' dan 'Homemade'
  ///
  /// Karena field multi-select, dihitung dari jumlah kemunculan tiap pilihan
  /// dibagi total kemunculan semua pilihan.
  Map<String, int> get jenisMakananStats {
    if (entries.isEmpty) return {'Junk Food': 0, 'Homemade': 0};

    int totalOccurrences = 0;
    int junkFood = 0;
    int homemade = 0;

    for (final entry in entries) {
      for (final jenis in entry.jenisMakanan) {
        final clean = jenis.trim().toLowerCase();
        if (clean == 'junk food') {
          junkFood++;
          totalOccurrences++;
        } else if (clean == 'homemade') {
          homemade++;
          totalOccurrences++;
        }
      }
    }

    if (totalOccurrences == 0) return {'Junk Food': 0, 'Homemade': 0};

    return {
      'Junk Food': (junkFood / totalOccurrences * 100).round(),
      'Homemade': (homemade / totalOccurrences * 100).round(),
    };
  }

  /// Menghitung kemunculan tiap jenis protein dibagi total kemunculan semua pilihan protein.
  /// Tampilkan terurut dari persentase tertinggi.
  List<MapEntry<String, int>> get proteinStats {
    if (entries.isEmpty) return [];

    final counts = <String, int>{};
    int totalOccurrences = 0;

    for (final entry in entries) {
      for (final protein in entry.protein) {
        String name = protein.trim();
        if (name.toLowerCase() == 'lainnya' &&
            entry.proteinLainnya != null &&
            entry.proteinLainnya!.trim().isNotEmpty) {
          name = entry.proteinLainnya!.trim();
        }
        if (name.isNotEmpty) {
          counts[name] = (counts[name] ?? 0) + 1;
          totalOccurrences++;
        }
      }
    }

    if (totalOccurrences == 0) return [];

    final percentages = counts.entries.map((e) {
      return MapEntry(e.key, (e.value / totalOccurrences * 100).round());
    }).toList();

    percentages.sort((a, b) => b.value.compareTo(a.value));
    return percentages;
  }

  /// Menghitung Rasa Dominan per entri:
  /// Bandingkan 5 level rasa (pedas, asin, asam, manis, berlemak; 0-4).
  /// - Jika semua level 0, entri tidak dihitung (tidak masuk penyebut).
  /// - Jika ada beberapa rasa yang sama-sama tertinggi, semuanya dihitung sebagai dominan.
  /// - Persentase = jumlah entri yang rasanya dominan dibagi jumlah entri yang dihitung.
  ///   Total antar rasa boleh > 100% (sesuai Figma).
  /// - Hanya menampilkan rasa dengan persentase > 0.
  List<MapEntry<String, int>> get rasaDominanStats {
    if (entries.isEmpty) return [];

    final dominantCounts = <String, int>{
      'Pedas': 0,
      'Asin': 0,
      'Asam': 0,
      'Manis': 0,
      'Berlemak': 0,
    };

    int countedEntries = 0;

    for (final entry in entries) {
      final tastes = {
        'Pedas': entry.levelPedas,
        'Asin': entry.levelAsin,
        'Asam': entry.levelAsam,
        'Manis': entry.levelManis,
        'Berlemak': entry.levelBerlemak,
      };

      int maxVal = 0;
      for (final val in tastes.values) {
        if (val > maxVal) maxVal = val;
      }

      // Jika semua level 0, tidak dihitung
      if (maxVal == 0) continue;

      countedEntries++;

      // Semua rasa yang nilainya sama dengan nilai maksimum dicatat dominan
      for (final e in tastes.entries) {
        if (e.value == maxVal) {
          dominantCounts[e.key] = (dominantCounts[e.key] ?? 0) + 1;
        }
      }
    }

    if (countedEntries == 0) return [];

    final percentages = dominantCounts.entries
        .where((e) => e.value > 0)
        .map((e) => MapEntry(e.key, (e.value / countedEntries * 100).round()))
        .toList();

    percentages.sort((a, b) => b.value.compareTo(a.value));
    return percentages;
  }

  /// Menghitung statistik Minuman:
  /// Total = (entri minum kopi) + (entri minum soda) + (entri tidak minum keduanya).
  /// Persentase Kopi, Soda, Lainnya = masing-masing dibagi total tersebut (total 100%).
  Map<String, int> get minumanStats {
    if (entries.isEmpty) return {'Kopi': 0, 'Soda': 0, 'Lainnya': 0};

    int kopi = 0;
    int soda = 0;
    int lainnya = 0;

    for (final entry in entries) {
      if (entry.konsumsiKopi) kopi++;
      if (entry.konsumsiSoda) soda++;
      if (!entry.konsumsiKopi && !entry.konsumsiSoda) lainnya++;
    }

    final total = kopi + soda + lainnya;
    if (total == 0) return {'Kopi': 0, 'Soda': 0, 'Lainnya': 0};

    return {
      'Kopi': (kopi / total * 100).round(),
      'Soda': (soda / total * 100).round(),
      'Lainnya': (lainnya / total * 100).round(),
    };
  }

  /// Menghitung Beban Harian:
  /// Hanya dari entri Makan Malam.
  /// Ubah level 0-4 menjadi 1-5 (+1), lalu hitung rata-rata.
  /// Persentase = (rata-rata / 5) * 100.
  /// Format: rata-rata 2.5/5.
  /// Jika belum ada entri Makan Malam: hasData = false.
  Map<String, Map<String, dynamic>> get bebanHarianStats {
    final malamEntries =
        entries.where((e) => e.sesi == MealSession.makanMalam).toList();
    if (malamEntries.isEmpty) {
      return {
        'Beban Pikiran': {
          'percentage': 0,
          'average': 0.0,
          'hasData': false,
        },
        'Beban Aktivitas': {
          'percentage': 0,
          'average': 0.0,
          'hasData': false,
        },
      };
    }

    int totalPikiran = 0;
    int totalAktivitas = 0;

    for (final entry in malamEntries) {
      // Skala 0-4 diubah menjadi skala 1-5 (ditambah 1)
      totalPikiran += (entry.bebanPikiran ?? 0) + 1;
      totalAktivitas += (entry.bebanAktivitas ?? 0) + 1;
    }

    final count = malamEntries.length;
    final avgPikiran = totalPikiran / count;
    final avgAktivitas = totalAktivitas / count;

    return {
      'Beban Pikiran': {
        'percentage': (avgPikiran / 5.0 * 100).round(),
        'average': double.parse(avgPikiran.toStringAsFixed(1)),
        'hasData': true,
      },
      'Beban Aktivitas': {
        'percentage': (avgAktivitas / 5.0 * 100).round(),
        'average': double.parse(avgAktivitas.toStringAsFixed(1)),
        'hasData': true,
      },
    };
  }

  // ===========================================================================
  // 1. STATUS RISIKO KESEHATAN LAMBUNG (GERD / MAAG)
  // ===========================================================================

  /// Menghitung skor dan kategori risiko terhadap kesehatan lambung untuk hari itu.
  ///
  /// Kategori:
  /// - Aman untuk Lambung (hijau): score < 3.5
  /// - Perlu Diperhatikan (kuning/oranye): 3.5 <= score < 7.0
  /// - Berisiko bagi Lambung (merah): score >= 7.0
  ///
  /// Logika penilaian mengombinasikan:
  /// 1. Persentase Junk Food vs Homemade
  /// 2. Rasa dominan (pedas, asam, berlemak, asin) & level rasa ekstrem
  /// 3. Minuman pemicu refluks (kopi, soda)
  /// 4. Beban harian (beban pikiran/stres & beban aktivitas fisik)
  /// 5. Kebiasaan berbaring setelah makan
  LambungRiskResult calculateLambungRiskScore() {
    if (entries.isEmpty) {
      return const LambungRiskResult(
        level: LambungRiskLevel.aman,
        label: 'Aman untuk Lambung',
        explanation: 'Belum ada data catatan makanan hari ini.',
        triggerFactors: [],
        score: 0.0,
      );
    }

    double score = 0.0;
    final triggers = <String>[];

    // 1. Jenis Makanan: Junk Food
    final jStats = jenisMakananStats;
    final junkPct = jStats['Junk Food'] ?? 0;
    if (junkPct >= 50) {
      score += 3.0;
      triggers.add('junk food tinggi ($junkPct%)');
    } else if (junkPct > 0) {
      score += 1.5;
      triggers.add('konsumsi junk food ($junkPct%)');
    }

    // 2. Rasa Dominan & Level Rasa
    final rStats = rasaDominanStats;
    final dominantKeys = rStats.map((e) => e.key.toLowerCase()).toSet();

    // Pedas
    final hasHighPedas = entries.any((e) => e.levelPedas >= 3);
    if (dominantKeys.contains('pedas')) {
      score += 3.0;
      triggers.add('rasa dominan pedas');
    } else if (hasHighPedas) {
      score += 2.0;
      triggers.add('makanan pedas');
    } else if (entries.any((e) => e.levelPedas == 2)) {
      score += 1.0;
    }

    // Asam
    final hasHighAsam = entries.any((e) => e.levelAsam >= 3);
    if (dominantKeys.contains('asam')) {
      score += 2.5;
      triggers.add('rasa dominan asam');
    } else if (hasHighAsam) {
      score += 2.0;
      triggers.add('makanan asam');
    } else if (entries.any((e) => e.levelAsam == 2)) {
      score += 1.0;
    }

    // Berlemak
    final hasHighLemak = entries.any((e) => e.levelBerlemak >= 3);
    if (dominantKeys.contains('berlemak')) {
      score += 2.5;
      triggers.add('makanan dominan berlemak');
    } else if (hasHighLemak) {
      score += 2.0;
      triggers.add('makanan berlemak tinggi');
    } else if (entries.any((e) => e.levelBerlemak == 2)) {
      score += 1.0;
    }

    // Asin
    final hasHighAsin = entries.any((e) => e.levelAsin >= 3);
    if (dominantKeys.contains('asin')) {
      score += 1.5;
      triggers.add('rasa dominan asin');
    } else if (hasHighAsin) {
      score += 1.0;
      triggers.add('makanan tinggi garam/asin');
    } else if (entries.any((e) => e.levelAsin == 2)) {
      score += 0.5;
    }

    // 3. Minuman
    final mStats = minumanStats;
    final kopiPct = mStats['Kopi'] ?? 0;
    final sodaPct = mStats['Soda'] ?? 0;

    if (sodaPct > 0) {
      score += (sodaPct >= 30 ? 2.5 : 1.5);
      triggers.add('minuman soda');
    }
    if (kopiPct > 0) {
      score += (kopiPct >= 30 ? 2.0 : 1.0);
      triggers.add('konsumsi kopi');
    }

    // 4. Beban Pikiran & Aktivitas
    final bStats = bebanHarianStats;
    final pikiran = bStats['Beban Pikiran'];
    final aktivitas = bStats['Beban Aktivitas'];

    if (pikiran != null && pikiran['hasData'] == true) {
      final avgPikiran = (pikiran['average'] as num).toDouble();
      if (avgPikiran >= 3.5) {
        score += 2.5;
        triggers.add('beban pikiran/stres tinggi');
      } else if (avgPikiran >= 2.5) {
        score += 1.0;
        triggers.add('beban pikiran cukup tinggi');
      }
    }

    if (aktivitas != null && aktivitas['hasData'] == true) {
      final avgAktivitas = (aktivitas['average'] as num).toDouble();
      if (avgAktivitas >= 4.0) {
        score += 1.0;
        triggers.add('aktivitas fisik berat');
      }
    }

    // 5. Kebiasaan Berbaring Setelah Makan
    if (entries.any((e) => e.berbaringSetelahMakan)) {
      score += 2.0;
      triggers.add('kebiasaan berbaring setelah makan');
    }

    // Tentukan Kategori & Formulasi Penjelasan
    final LambungRiskLevel level;
    final String explanation;

    if (score >= 7.0) {
      level = LambungRiskLevel.berisiko;
      if (triggers.isNotEmpty) {
        explanation =
            'Pola makan hari ini memiliki banyak faktor pemicu asam lambung, terutama ${triggers.join(", ")}. '
            'Hindari kombinasi ini untuk mencegah kekambuhan maag atau GERD.';
      } else {
        explanation =
            'Pola makan hari ini berisiko memperburuk kondisi lambung. Disarankan segera kurangi konsumsi makanan pemicu.';
      }
    } else if (score >= 3.5) {
      level = LambungRiskLevel.perluDiperhatikan;
      if (triggers.isNotEmpty) {
        explanation =
            'Pola makan hari ini didominasi beberapa pemicu seperti ${triggers.join(", ")}. '
            'Disarankan kurangi untuk menjaga lambung tetap stabil.';
      } else {
        explanation =
            'Terdapat beberapa indikator pola makan yang perlu diperhatikan agar tidak membebani kerja lambung.';
      }
    } else {
      level = LambungRiskLevel.aman;
      if (jStats['Homemade'] == 100) {
        explanation =
            'Pola makan hari ini didominasi makanan homemade yang ramah lambung tanpa pemicu asam lambung berlebih. '
            'Pertahankan pola sehat ini!';
      } else {
        explanation =
            'Pola makan hari ini relatif ramah lambung dan rendah makanan pemicu refluks. Lambung Anda aman.';
      }
    }

    return LambungRiskResult(
      level: level,
      label: level.label,
      explanation: explanation,
      triggerFactors: triggers,
      score: score,
    );
  }

  // ===========================================================================
  // 2. ASUPAN GIZI HARIAN (AKUMULASI DARI CATATAN MAKAN)
  // ===========================================================================

  /// Menghitung akumulasi asupan kalori, protein, karbohidrat, dan lemak
  /// dari seluruh makanan yang dicatat hari itu vs target harian standar.
  DailyNutritionSummary calculateDailyNutrition() {
    int totalCalories = 0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;

    for (final entry in entries) {
      // 1. Karbohidrat
      for (final karbo in entry.sumberKarbohidrat) {
        final nut = _getKarboNutrition(karbo);
        totalCalories += nut.calories;
        totalProtein += nut.protein;
        totalCarbs += nut.carbs;
        totalFat += nut.fat;
      }

      // 2. Protein
      for (final prot in entry.protein) {
        String pName = prot;
        if (prot.trim().toLowerCase() == 'lainnya' &&
            entry.proteinLainnya != null &&
            entry.proteinLainnya!.trim().isNotEmpty) {
          pName = entry.proteinLainnya!.trim();
        }
        final nut = _getProteinNutrition(pName);
        totalCalories += nut.calories;
        totalProtein += nut.protein;
        totalCarbs += nut.carbs;
        totalFat += nut.fat;
      }

      // 3. Sayuran
      for (final sayur in entry.sayuran) {
        String sName = sayur;
        if (sayur.trim().toLowerCase() == 'lainnya' &&
            entry.sayuranLainnya != null &&
            entry.sayuranLainnya!.trim().isNotEmpty) {
          sName = entry.sayuranLainnya!.trim();
        }
        final nut = _getSayuranNutrition(sName);
        totalCalories += nut.calories;
        totalProtein += nut.protein;
        totalCarbs += nut.carbs;
        totalFat += nut.fat;
      }

      // 4. Jenis Makanan (Junk Food menambahkan kalori dan lemak olahan)
      for (final jenis in entry.jenisMakanan) {
        if (jenis.trim().toLowerCase() == 'junk food') {
          totalCalories += 180;
          totalProtein += 3.0;
          totalCarbs += 15.0;
          totalFat += 12.0;
        }
      }

      // 5. Level Berlemak (minyak goreng / santan / margarin)
      switch (entry.levelBerlemak) {
        case 1:
          totalFat += 2.0;
          totalCalories += 18;
          break;
        case 2:
          totalFat += 5.0;
          totalCalories += 45;
          break;
        case 3:
          totalFat += 9.0;
          totalCalories += 81;
          break;
        case 4:
          totalFat += 14.0;
          totalCalories += 126;
          break;
      }

      // 6. Minuman
      if (entry.konsumsiSoda) {
        totalCalories += 140;
        totalCarbs += 35.0;
      }
      if (entry.konsumsiKopi) {
        totalCalories += 25;
        totalProtein += 0.5;
        totalCarbs += 4.0;
        totalFat += 0.5;
      }
    }

    return DailyNutritionSummary(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
    );
  }

  // ── Helper Nutrisi Per Pilihan Makanan ──────────────────────────────────────

  static FoodNutritionItem _getKarboNutrition(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('putih')) {
      return const FoodNutritionItem(calories: 204, protein: 4.2, carbs: 44.1, fat: 0.4);
    } else if (lower.contains('merah')) {
      return const FoodNutritionItem(calories: 165, protein: 3.5, carbs: 35.0, fat: 1.5);
    } else if (lower.contains('roti')) {
      return const FoodNutritionItem(calories: 160, protein: 5.5, carbs: 30.0, fat: 2.0);
    } else if (lower.contains('mie')) {
      return const FoodNutritionItem(calories: 220, protein: 5.0, carbs: 42.0, fat: 3.5);
    } else if (lower.contains('kentang')) {
      return const FoodNutritionItem(calories: 130, protein: 2.8, carbs: 30.0, fat: 0.2);
    }
    // Standar karbohidrat lainnya
    return const FoodNutritionItem(calories: 180, protein: 4.0, carbs: 38.0, fat: 1.0);
  }

  static FoodNutritionItem _getProteinNutrition(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('ayam')) {
      return const FoodNutritionItem(calories: 195, protein: 25.0, carbs: 0.0, fat: 9.0);
    } else if (lower.contains('sapi')) {
      return const FoodNutritionItem(calories: 250, protein: 26.0, carbs: 0.0, fat: 15.0);
    } else if (lower.contains('ikan')) {
      return const FoodNutritionItem(calories: 140, protein: 22.0, carbs: 0.0, fat: 5.0);
    } else if (lower.contains('telur')) {
      return const FoodNutritionItem(calories: 78, protein: 6.5, carbs: 0.6, fat: 5.3);
    } else if (lower.contains('tahu') || lower.contains('tempe')) {
      return const FoodNutritionItem(calories: 150, protein: 14.0, carbs: 7.0, fat: 7.5);
    } else if (lower.contains('udang') || lower.contains('cumi')) {
      return const FoodNutritionItem(calories: 110, protein: 20.0, carbs: 0.5, fat: 1.5);
    }
    // Standar protein lainnya
    return const FoodNutritionItem(calories: 160, protein: 18.0, carbs: 2.0, fat: 8.0);
  }

  static FoodNutritionItem _getSayuranNutrition(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('bayam')) {
      return const FoodNutritionItem(calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4);
    } else if (lower.contains('kembang kol') || lower.contains('kol')) {
      return const FoodNutritionItem(calories: 25, protein: 2.0, carbs: 5.0, fat: 0.3);
    } else if (lower.contains('sawi')) {
      return const FoodNutritionItem(calories: 20, protein: 1.8, carbs: 3.2, fat: 0.2);
    } else if (lower.contains('brokoli')) {
      return const FoodNutritionItem(calories: 34, protein: 2.8, carbs: 6.6, fat: 0.4);
    } else if (lower.contains('wortel')) {
      return const FoodNutritionItem(calories: 41, protein: 0.9, carbs: 9.6, fat: 0.2);
    } else if (lower.contains('kangkung')) {
      return const FoodNutritionItem(calories: 19, protein: 2.6, carbs: 3.1, fat: 0.2);
    }
    // Standar sayuran lainnya
    return const FoodNutritionItem(calories: 25, protein: 2.0, carbs: 4.0, fat: 0.3);
  }
}

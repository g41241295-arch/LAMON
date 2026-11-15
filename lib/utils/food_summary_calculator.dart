import '../models/food_entry_model.dart';

// ─── Enum & Model untuk Status Kesehatan Lambung ─────────────────────────────

/// Tiga level risiko kesehatan lambung berdasarkan pola makan harian.
enum LambungRiskLevel {
  aman,
  perluDiperhatikan,
  berisiko,
}

/// Hasil kalkulasi skor risiko lambung.
class LambungRiskScore {
  final LambungRiskLevel level;
  final String label;
  final String explanation;

  const LambungRiskScore({
    required this.level,
    required this.label,
    required this.explanation,
  });
}

// ─── Model untuk Target & Realisasi Gizi Harian ──────────────────────────────

/// Target gizi harian (kebutuhan rata-rata orang dewasa aktif).
class NutritionTarget {
  /// Kalori target harian (kkal)
  final int calories;
  /// Protein target harian (gram)
  final double protein;
  /// Karbohidrat target harian (gram)
  final double carbs;
  /// Lemak target harian (gram)
  final double fat;

  const NutritionTarget({
    this.calories = 2000,
    this.protein = 60.0,
    this.carbs = 300.0,
    this.fat = 65.0,
  });
}

/// Hasil kalkulasi asupan gizi harian beserta persentase terhadap target.
class DailyNutrition {
  /// Estimasi kalori total (kkal) — dihitung dari jumlah entri & intensitas makan
  final int calories;
  /// Estimasi protein (gram)
  final double protein;
  /// Estimasi karbohidrat (gram)
  final double carbs;
  /// Estimasi lemak (gram)
  final double fat;

  /// Persentase kalori terhadap target (0–100+)
  final int caloriesPercentage;
  /// Persentase protein terhadap target (0–100+)
  final int proteinPercentage;
  /// Persentase karbohidrat terhadap target (0–100+)
  final int carbsPercentage;
  /// Persentase lemak terhadap target (0–100+)
  final int fatPercentage;

  final NutritionTarget target;

  const DailyNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.caloriesPercentage,
    required this.proteinPercentage,
    required this.carbsPercentage,
    required this.fatPercentage,
    required this.target,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

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

  // ─── Kalkulasi Status Lambung & Gizi Harian ──────────────────────────────

  /// Menghitung skor risiko kesehatan lambung berdasarkan pola makan.
  ///
  /// Faktor risiko (tiap faktor menambah skor):
  /// - Berbaring setelah makan: +2 per entri
  /// - Level pedas tinggi (>=3): +1 per entri
  /// - Level asam tinggi (>=3): +1 per entri
  /// - Level berlemak tinggi (>=3): +1 per entri
  /// - Konsumsi kopi: +1 per entri
  /// - Konsumsi soda: +2 per entri
  /// - Junk food: +1 per kemunculan
  ///
  /// Skoring:
  /// - Skor rata-rata <= 2.0: Aman
  /// - Skor rata-rata 2.1–4.0: Perlu Diperhatikan
  /// - Skor rata-rata > 4.0: Berisiko
  LambungRiskScore calculateLambungRiskScore() {
    if (entries.isEmpty) {
      return const LambungRiskScore(
        level: LambungRiskLevel.aman,
        label: 'Belum Ada Data',
        explanation:
            'Belum ada catatan makan hari ini. Mulai catat pola makanmu untuk melihat status kesehatan lambung.',
      );
    }

    double totalScore = 0;

    for (final entry in entries) {
      double entryScore = 0;

      if (entry.berbaringSetelahMakan) entryScore += 2;
      if (entry.levelPedas >= 3) entryScore += 1;
      if (entry.levelAsam >= 3) entryScore += 1;
      if (entry.levelBerlemak >= 3) entryScore += 1;
      if (entry.konsumsiKopi) entryScore += 1;
      if (entry.konsumsiSoda) entryScore += 2;

      for (final jenis in entry.jenisMakanan) {
        if (jenis.trim().toLowerCase() == 'junk food') entryScore += 1;
      }

      totalScore += entryScore;
    }

    final avgScore = totalScore / entries.length;

    if (avgScore <= 2.0) {
      return const LambungRiskScore(
        level: LambungRiskLevel.aman,
        label: 'Lambung Aman',
        explanation:
            'Pola makanmu hari ini cukup baik untuk kesehatan lambung. Pertahankan kebiasaan makan yang sehat dan hindari makanan yang bisa memicu asam lambung.',
      );
    } else if (avgScore <= 4.0) {
      return const LambungRiskScore(
        level: LambungRiskLevel.perluDiperhatikan,
        label: 'Perlu Diperhatikan',
        explanation:
            'Ada beberapa kebiasaan makan yang bisa memicu gangguan lambung. Kurangi makanan pedas, asam, atau berlemak tinggi, dan hindari berbaring segera setelah makan.',
      );
    } else {
      return const LambungRiskScore(
        level: LambungRiskLevel.berisiko,
        label: 'Berisiko Tinggi',
        explanation:
            'Pola makanmu berisiko tinggi untuk kesehatan lambung. Segera ubah kebiasaan makan: hindari makanan pedas/asam/berlemak, minuman berkafein dan soda, serta jangan berbaring setelah makan.',
      );
    }
  }

  /// Menghitung estimasi asupan gizi harian berdasarkan pencatatan makanan.
  ///
  /// Karena tidak ada data nutrisi aktual per makanan, estimasi dilakukan
  /// berdasarkan pilihan sumber karbohidrat & protein menggunakan nilai rata-rata
  /// tipikal per sajian, disesuaikan jumlah sesi makan yang tercatat.
  ///
  /// Nilai estimasi per sesi (kebutuhan 2000 kkal untuk 3 sesi):
  /// - Sarapan: ~25% kebutuhan harian
  /// - Makan Siang: ~40% kebutuhan harian
  /// - Makan Malam: ~35% kebutuhan harian
  DailyNutrition calculateDailyNutrition() {
    const target = NutritionTarget(
      calories: 2000,
      protein: 60.0,
      carbs: 300.0,
      fat: 65.0,
    );

    if (entries.isEmpty) {
      return DailyNutrition(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        caloriesPercentage: 0,
        proteinPercentage: 0,
        carbsPercentage: 0,
        fatPercentage: 0,
        target: target,
      );
    }

    // Bobot kalori per sesi makan (proporsi dari total harian)
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final entry in entries) {
      // Kalori dasar per sesi
      final double sessionCalories;
      final double sessionProtein;
      final double sessionCarbs;
      final double sessionFat;

      switch (entry.sesi) {
        case MealSession.sarapan:
          sessionCalories = 500; // ~25% dari 2000 kkal
          sessionProtein = 15;
          sessionCarbs = 75;
          sessionFat = 16;
          break;
        case MealSession.makanSiang:
          sessionCalories = 800; // ~40% dari 2000 kkal
          sessionProtein = 24;
          sessionCarbs = 120;
          sessionFat = 26;
          break;
        case MealSession.makanMalam:
          sessionCalories = 700; // ~35% dari 2000 kkal
          sessionProtein = 21;
          sessionCarbs = 105;
          sessionFat = 23;
          break;
      }

      // Modifikasi berdasarkan jenis makanan (Junk Food +20% kalori & lemak)
      double calMod = 1.0;
      double fatMod = 1.0;
      for (final jenis in entry.jenisMakanan) {
        if (jenis.trim().toLowerCase() == 'junk food') {
          calMod += 0.20;
          fatMod += 0.30;
        }
      }

      // Modifikasi berdasarkan level berlemak (skala 0-4)
      final fatLevelMod = 1.0 + (entry.levelBerlemak * 0.05);

      totalCalories += sessionCalories * calMod;
      totalProtein += sessionProtein * (entry.protein.isNotEmpty ? 1.1 : 0.8);
      totalCarbs += sessionCarbs * (entry.sumberKarbohidrat.isNotEmpty ? 1.0 : 0.6);
      totalFat += sessionFat * fatMod * fatLevelMod;
    }

    int pct(double actual, double tgt) =>
        tgt > 0 ? (actual / tgt * 100).round().clamp(0, 999) : 0;

    return DailyNutrition(
      calories: totalCalories.round(),
      protein: double.parse(totalProtein.toStringAsFixed(1)),
      carbs: double.parse(totalCarbs.toStringAsFixed(1)),
      fat: double.parse(totalFat.toStringAsFixed(1)),
      caloriesPercentage: pct(totalCalories, target.calories.toDouble()),
      proteinPercentage: pct(totalProtein, target.protein),
      carbsPercentage: pct(totalCarbs, target.carbs),
      fatPercentage: pct(totalFat, target.fat),
      target: target,
    );
  }
}

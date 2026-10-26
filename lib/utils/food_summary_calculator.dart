import '../models/food_entry_model.dart';

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
}

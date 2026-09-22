import '../models/food_entry_model.dart';

class FoodSummaryCalculator {
  final List<FoodEntry> entries;
  final DateTime now;

  FoodSummaryCalculator({required this.entries, DateTime? now})
      : now = now ?? DateTime.now();

  int get totalEntries => entries.length;

  String get dateRangeString {
    final endDate = now;
    final startDate = now.subtract(const Duration(days: 6)); // 7 days inclusive

    String getMonthName(int month) {
      switch (month) {
        case 1: return 'Januari';
        case 2: return 'Februari';
        case 3: return 'Maret';
        case 4: return 'April';
        case 5: return 'Mei';
        case 6: return 'Juni';
        case 7: return 'Juli';
        case 8: return 'Agustus';
        case 9: return 'September';
        case 10: return 'Oktober';
        case 11: return 'November';
        case 12: return 'Desember';
        default: return '';
      }
    }

    final startMonth = getMonthName(startDate.month);
    final endMonth = getMonthName(endDate.month);
    final year = endDate.year;

    if (startMonth == endMonth) {
      return '${startDate.day} - ${endDate.day} $startMonth $year';
    } else {
      return '${startDate.day} $startMonth - ${endDate.day} $endMonth $year';
    }
  }

  /// Calculates the percentage of 'Junk Food' and 'Homemade'
  Map<String, int> get jenisMakananStats {
    if (entries.isEmpty) return {'Junk Food': 0, 'Homemade': 0};

    int totalOccurrences = 0;
    int junkFood = 0;
    int homemade = 0;

    for (final entry in entries) {
      for (final jenis in entry.jenisMakanan) {
        if (jenis.toLowerCase() == 'junk food') {
          junkFood++;
        } else if (jenis.toLowerCase() == 'homemade') {
          homemade++;
        }
        totalOccurrences++;
      }
    }

    if (totalOccurrences == 0) return {'Junk Food': 0, 'Homemade': 0};

    return {
      'Junk Food': (junkFood / totalOccurrences * 100).round(),
      'Homemade': (homemade / totalOccurrences * 100).round(),
    };
  }

  /// Calculates occurrences of each protein type, sorted descending
  List<MapEntry<String, int>> get proteinStats {
    if (entries.isEmpty) return [];

    final counts = <String, int>{};
    int totalOccurrences = 0;

    for (final entry in entries) {
      for (final protein in entry.protein) {
        if (protein == 'Lainnya' && entry.proteinLainnya != null && entry.proteinLainnya!.isNotEmpty) {
           counts[entry.proteinLainnya!] = (counts[entry.proteinLainnya!] ?? 0) + 1;
        } else {
           counts[protein] = (counts[protein] ?? 0) + 1;
        }
        totalOccurrences++;
      }
    }

    if (totalOccurrences == 0) return [];

    final percentages = counts.entries.map((e) {
      return MapEntry(e.key, (e.value / totalOccurrences * 100).round());
    }).toList();

    percentages.sort((a, b) => b.value.compareTo(a.value));
    return percentages;
  }

  /// Calculates dominant taste per entry. Priority: Asin > Pedas > Asam > Manis > Berlemak
  List<MapEntry<String, int>> get rasaDominanStats {
    if (entries.isEmpty) return [];

    final dominantCounts = <String, int>{
      'Asin': 0,
      'Pedas': 0,
      'Asam': 0,
      'Manis': 0,
      'Berlemak': 0,
    };

    for (final entry in entries) {
      final tastes = {
        'Asin': entry.levelAsin,
        'Pedas': entry.levelPedas,
        'Asam': entry.levelAsam,
        'Manis': entry.levelManis,
        'Berlemak': entry.levelBerlemak,
      };

      // Find max value
      int maxValue = -1;
      for (final value in tastes.values) {
        if (value > maxValue) maxValue = value;
      }

      // Priority order list
      final priority = ['Asin', 'Pedas', 'Asam', 'Manis', 'Berlemak'];
      
      String dominant = '';
      for (final taste in priority) {
        if (tastes[taste] == maxValue) {
          dominant = taste;
          break;
        }
      }

      if (dominant.isNotEmpty) {
        dominantCounts[dominant] = dominantCounts[dominant]! + 1;
      }
    }

    final total = entries.length;
    final percentages = dominantCounts.entries
        .where((e) => e.value > 0)
        .map((e) => MapEntry(e.key, (e.value / total * 100).round()))
        .toList();

    percentages.sort((a, b) => b.value.compareTo(a.value));
    return percentages;
  }

  /// Calculates Minuman stats: Kopi, Soda, Lainnya
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

    final total = entries.length;
    return {
      'Kopi': (kopi / total * 100).round(),
      'Soda': (soda / total * 100).round(),
      'Lainnya': (lainnya / total * 100).round(),
    };
  }

  /// Calculates Beban Harian (Makan Malam only). Returns average (1-5) and percentage.
  Map<String, Map<String, dynamic>> get bebanHarianStats {
    final malamEntries = entries.where((e) => e.sesi == MealSession.makanMalam).toList();
    if (malamEntries.isEmpty) {
      return {
        'Beban Pikiran': {'percentage': 0, 'average': 0.0, 'hasData': false},
        'Beban Aktivitas': {'percentage': 0, 'average': 0.0, 'hasData': false},
      };
    }

    int totalPikiran = 0;
    int totalAktivitas = 0;

    for (final entry in malamEntries) {
      // 0-4 mapped to 1-5
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

import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum sesi makan: sarapan, makan siang, makan malam.
enum MealSession {
  sarapan,
  makanSiang,
  makanMalam;

  String get label {
    switch (this) {
      case MealSession.sarapan:
        return 'Sarapan';
      case MealSession.makanSiang:
        return 'Makan Siang';
      case MealSession.makanMalam:
        return 'Makan Malam';
    }
  }

  String get firestoreKey {
    switch (this) {
      case MealSession.sarapan:
        return 'sarapan';
      case MealSession.makanSiang:
        return 'makan_siang';
      case MealSession.makanMalam:
        return 'makan_malam';
    }
  }

  static MealSession fromKey(String key) {
    switch (key) {
      case 'sarapan':
        return MealSession.sarapan;
      case 'makan_siang':
        return MealSession.makanSiang;
      case 'makan_malam':
        return MealSession.makanMalam;
      default:
        return MealSession.sarapan;
    }
  }
}

/// Model entri pencatatan makanan untuk satu sesi makan.
///
/// Semua field level menggunakan skala 0–4 (5 tahap diskrit):
/// 0 = tidak, 1 = sedikit, 2 = cukup, 3 = tinggi, 4 = sangat tinggi.
class FoodEntry {
  final String id;
  final String userId;

  /// Format: "yyyy-MM-dd", diambil dari waktu real-time perangkat.
  final String tanggal;

  /// Waktu pengisian real-time (dari perangkat).
  final DateTime waktuPengisian;

  final MealSession sesi;

  // ─── Pilihan kategori makanan ──────────────────────────────────────────────
  final List<String> jenisMakanan;       // ['Junk Food', 'Homemade']
  final List<String> sumberKarbohidrat;  // ['Nasi putih', 'Roti']
  final List<String> protein;            // ['Daging Ayam', ..., 'Lainnya']
  final List<String> sayuran;            // ['Bayam', ..., 'Lainnya']

  /// Isian bebas jika 'Lainnya' dipilih pada protein.
  final String? proteinLainnya;

  /// Isian bebas jika 'Lainnya' dipilih pada sayuran.
  final String? sayuranLainnya;

  // ─── Level rasa (0–4) ─────────────────────────────────────────────────────
  final int levelPedas;
  final int levelAsin;
  final int levelAsam;
  final int levelManis;
  final int levelBerlemak;

  // ─── Toggle ya/tidak ──────────────────────────────────────────────────────
  final bool berbaringSetelahMakan;
  final bool konsumsiSoda;
  final bool konsumsiKopi;

  // ─── Khusus Makan Malam (nullable untuk sesi lain) ───────────────────────
  final int? bebanPikiran;   // 0–4
  final int? bebanAktivitas; // 0–4

  const FoodEntry({
    required this.id,
    required this.userId,
    required this.tanggal,
    required this.waktuPengisian,
    required this.sesi,
    required this.jenisMakanan,
    required this.sumberKarbohidrat,
    required this.protein,
    required this.sayuran,
    this.proteinLainnya,
    this.sayuranLainnya,
    required this.levelPedas,
    required this.levelAsin,
    required this.levelAsam,
    required this.levelManis,
    required this.levelBerlemak,
    required this.berbaringSetelahMakan,
    required this.konsumsiSoda,
    required this.konsumsiKopi,
    this.bebanPikiran,
    this.bebanAktivitas,
  });

  /// Serialisasi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'tanggal': tanggal,
      'waktu_pengisian': Timestamp.fromDate(waktuPengisian),
      'sesi': sesi.firestoreKey,
      'jenis_makanan': jenisMakanan,
      'sumber_karbohidrat': sumberKarbohidrat,
      'protein': protein,
      'sayuran': sayuran,
      'protein_lainnya': proteinLainnya,
      'sayuran_lainnya': sayuranLainnya,
      'level_pedas': levelPedas,
      'level_asin': levelAsin,
      'level_asam': levelAsam,
      'level_manis': levelManis,
      'level_berlemak': levelBerlemak,
      'berbaring_setelah_makan': berbaringSetelahMakan,
      'konsumsi_soda': konsumsiSoda,
      'konsumsi_kopi': konsumsiKopi,
    };

    if (sesi == MealSession.makanMalam) {
      map['beban_pikiran'] = bebanPikiran;
      map['beban_aktivitas'] = bebanAktivitas;
    }

    return map;
  }

  /// Deserialisasi dari snapshot Firestore.
  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      tanggal: json['tanggal'] as String? ?? '',
      waktuPengisian: json['waktu_pengisian'] is Timestamp
          ? (json['waktu_pengisian'] as Timestamp).toDate()
          : DateTime.now(),
      sesi: MealSession.fromKey(json['sesi'] as String? ?? 'sarapan'),
      jenisMakanan: List<String>.from(json['jenis_makanan'] as List? ?? []),
      sumberKarbohidrat:
          List<String>.from(json['sumber_karbohidrat'] as List? ?? []),
      protein: List<String>.from(json['protein'] as List? ?? []),
      sayuran: List<String>.from(json['sayuran'] as List? ?? []),
      proteinLainnya: json['protein_lainnya'] as String?,
      sayuranLainnya: json['sayuran_lainnya'] as String?,
      levelPedas: (json['level_pedas'] as num?)?.toInt() ?? 0,
      levelAsin: (json['level_asin'] as num?)?.toInt() ?? 0,
      levelAsam: (json['level_asam'] as num?)?.toInt() ?? 0,
      levelManis: (json['level_manis'] as num?)?.toInt() ?? 0,
      levelBerlemak: (json['level_berlemak'] as num?)?.toInt() ?? 0,
      berbaringSetelahMakan:
          json['berbaring_setelah_makan'] as bool? ?? false,
      konsumsiSoda: json['konsumsi_soda'] as bool? ?? false,
      konsumsiKopi: json['konsumsi_kopi'] as bool? ?? false,
      bebanPikiran: (json['beban_pikiran'] as num?)?.toInt(),
      bebanAktivitas: (json['beban_aktivitas'] as num?)?.toInt(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/gastropedia_item_model.dart';
import '../services/food_entry_service.dart';
import '../services/prediction_history_repository.dart';

/// Profil kesehatan & kebiasaan makan pengguna yang dianalisis
/// dari riwayat makanan, riwayat prediksi refluks, dan konsultasi dokter.
class UserHealthProfile {
  final bool hasHighRefluxRisk;
  final bool needsProtein;
  final bool needsFiber;
  final bool highFatDiet;
  final bool hasAcidTriggers;
  final bool hasConsultationHistory;
  final bool hasHistoryData;
  final String? primaryConcern;

  const UserHealthProfile({
    this.hasHighRefluxRisk = false,
    this.needsProtein = false,
    this.needsFiber = false,
    this.highFatDiet = false,
    this.hasAcidTriggers = false,
    this.hasConsultationHistory = false,
    this.hasHistoryData = false,
    this.primaryConcern,
  });

  @override
  String toString() {
    return 'UserHealthProfile(hasHistory: $hasHistoryData, reflux: $hasHighRefluxRisk, '
        'needProtein: $needsProtein, needFiber: $needsFiber, highFat: $highFatDiet, '
        'triggers: $hasAcidTriggers, consult: $hasConsultationHistory)';
  }
}

/// Service untuk menghasilkan rekomendasi makanan Gastropedia yang dipersonalisasi
/// berdasarkan data riwayat pengguna (catatan makanan & riwayat prediksi/konsultasi).
class GastropediaRecommendationService {
  final FoodEntryService _foodService;
  final PredictionHistoryRepository _predRepo;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  GastropediaRecommendationService({
    FoodEntryService? foodService,
    PredictionHistoryRepository? predRepo,
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _foodService = foodService ?? FoodEntryService(),
        _predRepo = predRepo ?? PredictionHistoryRepository(),
        _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Rekomendasi bawaan/default jika data pengguna belum cukup/tidak ada.
  /// Selalu mengembalikan tepat 4 item.
  static List<GastropediaItem> getDefaultRecommendations(List<GastropediaItem> items) {
    final pool = items.isNotEmpty ? items : GastropediaData.items;
    final recommended = pool.where((i) => i.isRecommended).toList();
    if (recommended.isEmpty) {
      return pool.take(4).toList();
    }
    if (recommended.length < 4) {
      final existingIds = recommended.map((r) => r.id).toSet();
      final extras = pool
          .where((i) => !existingIds.contains(i.id))
          .take(4 - recommended.length);
      return [...recommended, ...extras];
    }
    return recommended.take(4).toList();
  }

  /// Menganalisis kondisi dan kebutuhan nutrisi pengguna berdasarkan:
  /// 1. Riwayat catatan makanan (7 hari / ringkasan makanan)
  /// 2. Riwayat hasil prediksi risiko refluks / GERD
  /// 3. Riwayat konsultasi dokter
  Future<UserHealthProfile> analyzeUserProfile(String? userId) async {
    final uid = (userId != null && userId.isNotEmpty) ? userId : _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const UserHealthProfile(hasHistoryData: false);
    }

    bool hasHistory = false;
    bool highReflux = false;
    bool needProtein = false;
    bool needFiber = false;
    bool highFat = false;
    bool acidTriggers = false;
    bool consultHistory = false;
    String? concern;

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Analisis Riwayat Prediksi Refluks (GERD / Maag)
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final predictions = await _predRepo.fetchAll();
      if (predictions.isNotEmpty) {
        hasHistory = true;
        final latest = predictions.first;
        final catLower = latest.riskCategory.toLowerCase();

        if (catLower.contains('tinggi') ||
            catLower.contains('sedang') ||
            latest.riskPercentage >= 45.0) {
          highReflux = true;
          concern = 'Risiko Asam Lambung';
        }

        // Cek kontribusi faktor risiko terbanyak
        for (final factor in latest.topFactors) {
          final fname = factor.featureName.toLowerCase();
          if (fname.contains('veg') || fname.contains('fruit') || fname.contains('fiber')) {
            needFiber = true;
          }
          if (fname.contains('fat') || fname.contains('snack') || fname.contains('dessert')) {
            highFat = true;
          }
          if (fname.contains('alcohol') || fname.contains('water')) {
            acidTriggers = true;
          }
        }
      }
    } catch (e) {
      debugPrint('[GastropediaRecommendationService] Error membaca riwayat prediksi: $e');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Analisis Riwayat Catatan Makanan (7 Hari Terakhir / Summary)
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final summaryResult = await _foodService.getEntriesForSummary();
      if (summaryResult is FoodSummarySuccess && summaryResult.entries.isNotEmpty) {
        hasHistory = true;
        final entries = summaryResult.entries;
        final total = entries.length;

        int noSayurCount = 0;
        int noProteinCount = 0;
        int highFatCount = 0;
        int triggerCount = 0;

        for (final entry in entries) {
          if (entry.sayuran.isEmpty) noSayurCount++;
          if (entry.protein.isEmpty) noProteinCount++;
          if (entry.levelBerlemak >= 3 ||
              entry.jenisMakanan.any((j) => j.toLowerCase().contains('junk'))) {
            highFatCount++;
          }
          if (entry.levelPedas >= 3 ||
              entry.levelAsam >= 3 ||
              entry.konsumsiKopi ||
              entry.konsumsiSoda ||
              entry.berbaringSetelahMakan) {
            triggerCount++;
          }
        }

        // Jika > 40% entri kurang serat / sayur
        if (noSayurCount / total >= 0.4) {
          needFiber = true;
          concern ??= 'Kebutuhan Serat';
        }

        // Jika > 40% entri kurang protein
        if (noProteinCount / total >= 0.4) {
          needProtein = true;
          concern ??= 'Kebutuhan Protein';
        }

        // Jika > 35% entri berlemak tinggi / junk food
        if (highFatCount / total >= 0.35) {
          highFat = true;
        }

        // Jika > 35% sering konsumsi makanan/kebiasaan pemicu refluks
        if (triggerCount / total >= 0.35) {
          acidTriggers = true;
          highReflux = true; // Tingkat risiko naik akibat trigger berulang
          concern ??= 'Stabilisasi Asam Lambung';
        }
      }
    } catch (e) {
      debugPrint('[GastropediaRecommendationService] Error membaca catatan makanan: $e');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Analisis Riwayat Konsultasi Dokter
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final consultSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('consultations')
          .limit(1)
          .get();
      if (consultSnap.docs.isNotEmpty) {
        hasHistory = true;
        consultHistory = true;
      }
    } catch (e) {
      debugPrint('[GastropediaRecommendationService] Error membaca konsultasi: $e');
    }

    return UserHealthProfile(
      hasHighRefluxRisk: highReflux,
      needsProtein: needProtein,
      needsFiber: needFiber,
      highFatDiet: highFat,
      hasAcidTriggers: acidTriggers,
      hasConsultationHistory: consultHistory,
      hasHistoryData: hasHistory,
      primaryConcern: concern,
    );
  }

  /// Mengurutkan list item Gastropedia berdasarkan skor relevansi profil pengguna.
  List<GastropediaItem> rankItems({
    required List<GastropediaItem> items,
    required UserHealthProfile profile,
  }) {
    final pool = items.isNotEmpty ? items : GastropediaData.items;

    // Jika pengguna baru atau belum punya riwayat data, kembalikan rekomendasi default
    if (!profile.hasHistoryData) {
      return getDefaultRecommendations(pool);
    }

    final scoredItems = <MapEntry<GastropediaItem, double>>[];

    for (final item in pool) {
      double score = item.isRecommended ? 15.0 : 5.0;

      final textCorpus = [
        item.name,
        item.deskripsi,
        item.manfaat.join(' '),
        item.kandungan.join(' '),
      ].join(' ').toLowerCase();

      // ─── LOGIKA 1: Prioritas Asam Lambung (GERD / Maag / Konsultasi) ───
      if (profile.hasHighRefluxRisk ||
          profile.hasConsultationHistory ||
          profile.hasAcidTriggers) {
        const refluxKeywords = [
          'asam lambung',
          'refluks',
          'gerd',
          'maag',
          'heartburn',
          'ulu hati',
          'mukosa',
          'antasida',
          'alkalis',
          'alkalin',
          'basa',
          'sfingter',
          'menstabilkan asam',
          'menetralkan asam',
          'tidak memicu refluks',
          'ramah lambung',
          'melapisi dinding lambung',
          'menyejukkan',
          'radang lambung',
          'tukak lambung',
        ];

        int keywordHits = 0;
        for (final kw in refluxKeywords) {
          if (textCorpus.contains(kw)) {
            keywordHits++;
          }
        }

        if (keywordHits > 0) {
          // Bobot tinggi untuk makanan yang menenangkan dan melindungi lambung
          score += 25.0 + (keywordHits * 3.0);
        }
      }

      // ─── LOGIKA 2: Kebutuhan Protein (Asupan protein harian kurang) ───
      if (profile.needsProtein) {
        if (item.protein >= 15.0) {
          score += 35.0;
        } else if (item.protein >= 8.0) {
          score += 20.0;
        } else if (item.protein >= 4.0) {
          score += 10.0;
        }
      }

      // ─── LOGIKA 3: Kebutuhan Serat / Sayuran / Buah ───
      if (profile.needsFiber) {
        if (item.category == GastropediaCategory.sayuran) {
          score += 25.0;
        } else if (item.category == GastropediaCategory.buah) {
          score += 20.0;
        }

        if (textCorpus.contains('serat') ||
            textCorpus.contains('pektin') ||
            textCorpus.contains('pencernaan') ||
            textCorpus.contains('prebiotik')) {
          score += 12.0;
        }
      }

      // ─── LOGIKA 4: Pengendalian Lemak Tinggi / Sensitivitas Pencernaan ───
      if (profile.highFatDiet || profile.hasAcidTriggers) {
        if (item.fat <= 2.0) {
          score += 15.0; // Pilihan rendah lemak ramah esofagus
        } else if (item.fat > 6.0 && item.id != 'alpukat') {
          // Alpukat mengandung lemak baik tak jenuh tunggal yang melapisi mukosa
          score -= 10.0;
        }
      }

      scoredItems.add(MapEntry(item, score));
    }

    // Urutkan dari skor tertinggi
    scoredItems.sort((a, b) => b.value.compareTo(a.value));

    // Ambil 4 item terbaik
    final result = scoredItems.map((e) => e.key).take(4).toList();

    // Fallback keamanan jika kurang dari 4 item
    if (result.length < 4) {
      final existingIds = result.map((r) => r.id).toSet();
      final extras = pool
          .where((i) => !existingIds.contains(i.id))
          .take(4 - result.length);
      return [...result, ...extras];
    }

    return result;
  }

  /// Fungsi utama yang dipanggil oleh antarmuka Gastropedia:
  /// Mengambil data pengguna, menentukan profil, dan mengembalikan 4 item rekomendasi personal.
  Future<List<GastropediaItem>> getPersonalizedRecommendations({
    String? userId,
    List<GastropediaItem>? allItems,
  }) async {
    final pool = (allItems != null && allItems.isNotEmpty)
        ? allItems
        : GastropediaData.items;

    try {
      final profile = await analyzeUserProfile(userId);
      return rankItems(items: pool, profile: profile);
    } catch (e) {
      debugPrint('[GastropediaRecommendationService] Fallback ke rekomendasi default: $e');
      return getDefaultRecommendations(pool);
    }
  }
}

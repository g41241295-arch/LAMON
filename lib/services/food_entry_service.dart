import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/food_entry_model.dart';

// ─── Query Result Type untuk Ringkasan Makanan ──────────────────────────────
sealed class FoodSummaryQueryResult {
  const FoodSummaryQueryResult();
}

class FoodSummarySuccess extends FoodSummaryQueryResult {
  final List<FoodEntry> entries;
  const FoodSummarySuccess(this.entries);
}

class FoodSummaryEmpty extends FoodSummaryQueryResult {
  const FoodSummaryEmpty();
}

class FoodSummaryFailure extends FoodSummaryQueryResult {
  final String? code;
  final String message;
  const FoodSummaryFailure({this.code, required this.message});
}

/// Service untuk menyimpan dan mengambil entri pencatatan makanan dari Firestore.
///
/// Struktur koleksi:
/// ```
/// users/{uid}/food_entries/{auto-id}
/// ```
/// Data bersifat personal — hanya bisa dibaca/ditulis oleh user yang bersangkutan.
class FoodEntryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Referensi ke sub-koleksi food_entries milik user saat ini.
  CollectionReference<Map<String, dynamic>>? get _entriesRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('food_entries');
  }

  /// Menyimpan satu entri makanan ke Firestore.
  ///
  /// Akan melempar Exception jika gagal.
  Future<void> saveEntry(FoodEntry entry) async {
    try {
      final ref = _entriesRef;
      if (ref == null) {
        throw Exception('Tidak ada user yang login.');
      }

      final docRef = ref.doc(entry.id.isNotEmpty ? entry.id : null);
      await docRef.set(entry.toJson());
    } catch (e) {
      if (e is FirebaseException) {
        throw Exception('Error Database (${e.code}): ${e.message}');
      } else {
        throw Exception('Terjadi kesalahan: $e');
      }
    }
  }

  /// Mengambil entri untuk sesi dan tanggal tertentu milik user saat ini.
  ///
  /// Format [tanggal]: "yyyy-MM-dd".
  /// Mengembalikan [FoodEntry] jika sudah ada, atau `null` jika belum diisi.
  Future<FoodEntry?> getEntryBySessionAndDate(
    MealSession sesi,
    String tanggal,
  ) async {
    try {
      final ref = _entriesRef;
      if (ref == null) return null;

      final snapshot = await ref
          .where('tanggal', isEqualTo: tanggal)
          .where('sesi', isEqualTo: sesi.firestoreKey)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return FoodEntry.fromJson(data);
    } catch (e) {
      debugPrint('[FoodEntryService] GAGAL mengambil entri: $e');
      return null;
    }
  }

  /// Memeriksa apakah format string tanggal adalah "yyyy-MM-dd" yang valid.
  static bool isValidDateString(String dateStr) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
      return false;
    }
    try {
      final parts = dateStr.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      final dt = DateTime(y, m, d);
      return dt.year == y && dt.month == m && dt.day == d;
    } catch (_) {
      return false;
    }
  }

  /// Mengambil entri makanan milik user untuk kalkulasi Ringkasan Makanan.
  ///
  /// Menggunakan paling banyak satu orderBy('tanggal', descending: true)
  /// dan limit(200) tanpa orderBy kedua, sehingga TIDAK memerlukan
  /// composite index di Firestore.
  ///
  /// Mengembalikan [FoodSummaryQueryResult] yang membedakan 3 kemungkinan:
  /// - [FoodSummarySuccess]: berhasil dengan list data valid
  /// - [FoodSummaryEmpty]: berhasil query tetapi tidak ada entri
  /// - [FoodSummaryFailure]: gagal query dengan kode dan pesan error asli
  Future<FoodSummaryQueryResult> getEntriesForSummary() async {
    try {
      final uid = _auth.currentUser?.uid;
      final ref = _entriesRef;
      if (uid == null || ref == null) {
        return const FoodSummaryFailure(
          code: 'unauthenticated',
          message: 'Tidak ada sesi pengguna yang aktif. Silakan masuk terlebih dahulu.',
        );
      }

      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        // Query menggunakan filter user_id agar sesuai dengan aturan Firestore
        // (resource.data.user_id == request.auth.uid) yang masih aktif di server.
        // Tanpa orderBy pada query agar TIDAK membutuhkan composite index.
        snapshot = await ref.where('user_id', isEqualTo: uid).get();
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          // Fallback tanpa filter jika rules di server mengizinkan read langsung
          snapshot = await ref.orderBy('tanggal', descending: true).limit(200).get();
        } else {
          rethrow;
        }
      }

      if (snapshot.docs.isEmpty) {
        return const FoodSummaryEmpty();
      }

      final validEntries = <FoodEntry>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final tanggal = data['tanggal'] as String? ?? '';
          if (!isValidDateString(tanggal)) {
            debugPrint('[FoodEntryService] Entri dilewati karena tanggal tidak valid: id=${doc.id}, tanggal="$tanggal"');
            continue;
          }
          final entry = FoodEntry.fromJson(data);
          validEntries.add(entry);
        } catch (e) {
          debugPrint('[FoodEntryService] Entri dilewati karena gagal deserialisasi: id=${doc.id}, error=$e');
        }
      }

      if (validEntries.isEmpty) {
        return const FoodSummaryEmpty();
      }

      // Urutkan berdasarkan waktu_pengisian secara in-memory untuk entri pada tanggal yang sama
      validEntries.sort((a, b) {
        final cmpTanggal = b.tanggal.compareTo(a.tanggal);
        if (cmpTanggal != 0) return cmpTanggal;
        return b.waktuPengisian.compareTo(a.waktuPengisian);
      });

      return FoodSummarySuccess(validEntries);
    } on FirebaseException catch (e) {
      debugPrint('[FoodEntryService] FirebaseException getEntriesForSummary: [${e.code}] ${e.message}');
      return FoodSummaryFailure(code: e.code, message: e.message ?? e.toString());
    } catch (e) {
      debugPrint('[FoodEntryService] Exception getEntriesForSummary: $e');
      return FoodSummaryFailure(message: e.toString());
    }
  }

  /// Mengambil semua entri dalam 7 hari terakhir untuk user saat ini.
  ///
  /// Query hanya menggunakan filter tanggal tanpa multiple orderBy
  /// agar TIDAK membutuhkan composite index di Firestore.
  Future<List<FoodEntry>> getLast7DaysEntries() async {
    try {
      final ref = _entriesRef;
      if (ref == null) return [];

      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final startDate = _formatDate(sevenDaysAgo);
      final endDate = _formatDate(now);

      // Hanya gunakan orderBy('tanggal', descending: true) tanpa orderBy kedua.
      final snapshot = await ref
          .where('tanggal', isGreaterThanOrEqualTo: startDate)
          .where('tanggal', isLessThanOrEqualTo: endDate)
          .orderBy('tanggal', descending: true)
          .get();

      final list = <FoodEntry>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final tanggal = data['tanggal'] as String? ?? '';
          if (!isValidDateString(tanggal)) {
            debugPrint('[FoodEntryService] Invalid date skipped: id=${doc.id}, tanggal="$tanggal"');
            continue;
          }
          list.add(FoodEntry.fromJson(data));
        } catch (e) {
          debugPrint('[FoodEntryService] Error parsing entry ${doc.id}: $e');
        }
      }

      // Urutkan waktu_pengisian descending di memori
      list.sort((a, b) {
        final cmpTanggal = b.tanggal.compareTo(a.tanggal);
        if (cmpTanggal != 0) return cmpTanggal;
        return b.waktuPengisian.compareTo(a.waktuPengisian);
      });

      return list;
    } on FirebaseException catch (e) {
      debugPrint('[FoodEntryService] FirebaseException getLast7DaysEntries: [${e.code}] ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FoodEntryService] GAGAL mengambil entri 7 hari: $e');
      rethrow;
    }
  }

  /// Mengambil semua entri berdasarkan rentang tanggal kustom.
  ///
  /// Format: "yyyy-MM-dd".
  Future<List<FoodEntry>> getEntriesByDateRange(
    String startDate,
    String endDate,
  ) async {
    try {
      final ref = _entriesRef;
      if (ref == null) return [];

      // Tanpa multiple orderBy agar tidak perlu composite index
      final snapshot = await ref
          .where('tanggal', isGreaterThanOrEqualTo: startDate)
          .where('tanggal', isLessThanOrEqualTo: endDate)
          .orderBy('tanggal', descending: true)
          .get();

      final list = <FoodEntry>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final tanggal = data['tanggal'] as String? ?? '';
          if (!isValidDateString(tanggal)) {
            debugPrint('[FoodEntryService] Invalid date skipped: id=${doc.id}, tanggal="$tanggal"');
            continue;
          }
          list.add(FoodEntry.fromJson(data));
        } catch (e) {
          debugPrint('[FoodEntryService] Error parsing entry ${doc.id}: $e');
        }
      }

      // Urutkan waktu_pengisian di memori
      list.sort((a, b) {
        final cmpTanggal = b.tanggal.compareTo(a.tanggal);
        if (cmpTanggal != 0) return cmpTanggal;
        return b.waktuPengisian.compareTo(a.waktuPengisian);
      });

      return list;
    } on FirebaseException catch (e) {
      debugPrint('[FoodEntryService] FirebaseException getEntriesByDateRange: [${e.code}] ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FoodEntryService] GAGAL mengambil entri rentang: $e');
      rethrow;
    }
  }

  /// Format DateTime ke String "yyyy-MM-dd".
  String _formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Format DateTime ke String tanggal saat ini untuk form.
  static String todayString() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Generate unique ID untuk entri baru berdasarkan userId + sesi + tanggal.
  static String generateEntryId(String userId, MealSession sesi, String tanggal) {
    return '${userId}_${sesi.firestoreKey}_$tanggal';
  }

  // ===========================================================================
  // FUNGSI DEVELOPMENT (DUMMY DATA)
  // ===========================================================================

  /// Membuat 7 data dummy untuk 7 hari terakhir agar chart Ringkasan Makanan bisa diuji.
  Future<void> generateDummyData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Tidak ada user yang login.');

    final ref = _entriesRef;
    if (ref == null) return;

    final now = DateTime.now();
    final List<String> junkFoods = ['Junk Food'];
    final List<String> homemades = ['Homemade'];
    final List<String> karbo = ['Nasi Putih', 'Nasi Merah', 'Roti', 'Mie', 'Kentang'];
    final List<String> proteins = ['Daging Ayam', 'Daging Sapi', 'Ikan', 'Telur', 'Tahu/Tempe'];
    final List<String> sayurans = ['Bayam', 'Kangkung', 'Wortel', 'Brokoli', 'Sawi'];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateString = _formatDate(date);
      
      // Pilih sesi secara random, tapi pastikan ada beberapa makan malam agar Beban Harian terisi
      final sesi = (i % 3 == 0) ? MealSession.makanMalam : MealSession.makanSiang;

      final isJunk = (i % 2 == 0); // Selang seling junkfood dan homemade

      final entry = FoodEntry(
        id: 'dummy_${generateEntryId(uid, sesi, dateString)}',
        userId: uid,
        tanggal: dateString,
        waktuPengisian: date,
        sesi: sesi,
        jenisMakanan: isJunk ? junkFoods : homemades,
        sumberKarbohidrat: [karbo[i % karbo.length]],
        protein: [proteins[i % proteins.length]],
        sayuran: [sayurans[i % sayurans.length]],
        levelPedas: (i * 2) % 5,     // 0-4
        levelAsin: (i * 3) % 5,
        levelAsam: (i + 1) % 5,
        levelManis: (i * 4) % 5,
        levelBerlemak: (i + 2) % 5,
        berbaringSetelahMakan: i % 2 == 0,
        konsumsiKopi: i % 3 == 0,
        konsumsiSoda: isJunk && (i % 2 == 0),
        bebanPikiran: sesi == MealSession.makanMalam ? (i % 5) : null,
        bebanAktivitas: sesi == MealSession.makanMalam ? ((i + 2) % 5) : null,
      );

      await ref.doc(entry.id).set({
        ...entry.toJson(),
        'is_dummy': true, // penanda agar mudah dihapus
      });
    }
  }

  /// Menghapus semua data dummy yang dibuat oleh fungsi [generateDummyData].
  Future<void> deleteDummyData() async {
    final ref = _entriesRef;
    if (ref == null) return;

    final snapshot = await ref.where('is_dummy', isEqualTo: true).get();
    
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

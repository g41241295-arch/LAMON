import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/food_entry_model.dart';

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

  /// Mengambil semua entri dalam 7 hari terakhir untuk user saat ini.
  ///
  /// Digunakan oleh menu "Ringkasan Makanan".
  /// Mengembalikan list entri terurut dari yang terbaru (descending).
  Future<List<FoodEntry>> getLast7DaysEntries() async {
    try {
      final ref = _entriesRef;
      if (ref == null) return [];

      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final startDate = _formatDate(sevenDaysAgo);
      final endDate = _formatDate(now);

      final snapshot = await ref
          .where('tanggal', isGreaterThanOrEqualTo: startDate)
          .where('tanggal', isLessThanOrEqualTo: endDate)
          .orderBy('tanggal', descending: true)
          .orderBy('waktu_pengisian', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return FoodEntry.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('[FoodEntryService] GAGAL mengambil entri 7 hari: $e');
      return [];
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

      final snapshot = await ref
          .where('tanggal', isGreaterThanOrEqualTo: startDate)
          .where('tanggal', isLessThanOrEqualTo: endDate)
          .orderBy('tanggal', descending: true)
          .orderBy('waktu_pengisian', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return FoodEntry.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('[FoodEntryService] GAGAL mengambil entri rentang: $e');
      return [];
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
}

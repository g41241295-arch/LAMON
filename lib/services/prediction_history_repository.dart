import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/reflux_prediction_model.dart';

/// Repository untuk mengelola penyimpanan dan pengambilan riwayat prediksi
/// refluks asam lambung pada Cloud Firestore.
///
/// Struktur data:
/// ```
/// users/{uid}/prediction_history/{historyId}
/// ```
/// Sub-koleksi ini sejajar dengan dokumen users/{uid} dan tidak mengubah
/// field-field profil yang sudah ada.
class PredictionHistoryRepository {
  final FirebaseFirestore? _customDb;
  final FirebaseAuth? _customAuth;

  PredictionHistoryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _customDb = firestore,
        _customAuth = auth;

  /// Cek apakah Firebase sudah terinisialisasi
  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore? get _db {
    if (_customDb != null) return _customDb;
    try {
      if (!isFirebaseAvailable) return null;
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      if (!isFirebaseAvailable) return null;
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Mendapatkan referensi sub-koleksi prediction_history milik user yang aktif.
  CollectionReference<Map<String, dynamic>>? get _historyRef {
    final uid = _auth?.currentUser?.uid;
    final db = _db;
    if (uid == null || db == null) return null;
    return db.collection('users').doc(uid).collection('prediction_history');
  }

  /// ID user yang saat ini sedang login, jika ada.
  String? get currentUserId => _auth?.currentUser?.uid;

  /// Apakah user sedang terautentikasi.
  bool get isAuthenticated => _auth?.currentUser != null;

  /// Menyimpan satu hasil prediksi ke Firestore di bawah uid user yang sedang login.
  ///
  /// Menggunakan [result.id] sebagai document ID untuk mencegah duplikasi.
  /// Field `createdAt` ditulis menggunakan server timestamp.
  /// Melempar [Exception] jika user belum login atau penyimpanan gagal.
  Future<void> save(RefluxPredictionResult result) async {
    try {
      final ref = _historyRef;
      if (ref == null) {
        throw Exception('User belum login. Silakan login terlebih dahulu.');
      }

      final docId = result.id.isNotEmpty
          ? result.id
          : 'pred_${result.createdAt.millisecondsSinceEpoch}';

      final docRef = ref.doc(docId);
      await docRef.set(result.toFirestore());
      debugPrint('[PredictionHistoryRepository] Berhasil menyimpan riwayat: $docId');
    } catch (e) {
      if (e is FirebaseException) {
        debugPrint('[PredictionHistoryRepository] FirebaseException: ${e.code} - ${e.message}');
        throw Exception('Gagal menyimpan ke Firestore (${e.code}): ${e.message}');
      } else {
        debugPrint('[PredictionHistoryRepository] Error: $e');
        rethrow;
      }
    }
  }

  /// Mengambil semua riwayat pemeriksaan milik user saat ini,
  /// diurutkan dari yang paling baru (`createdAt` descending).
  Future<List<RefluxPredictionResult>> fetchAll() async {
    try {
      final ref = _historyRef;
      if (ref == null) {
        debugPrint('[PredictionHistoryRepository] fetchAll: Tidak ada user yang login.');
        return [];
      }

      final snapshot = await ref.orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map((doc) => RefluxPredictionResult.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[PredictionHistoryRepository] GAGAL mengambil riwayat: $e');
      rethrow;
    }
  }

  /// Stream realtime untuk memantau perubahan daftar riwayat milik user aktif.
  Stream<List<RefluxPredictionResult>> watchAll() {
    final ref = _historyRef;
    if (ref == null) {
      return Stream.value(<RefluxPredictionResult>[]);
    }

    return ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RefluxPredictionResult.fromFirestore(doc))
          .toList();
    });
  }

  /// Mengambil satu riwayat spesifik berdasarkan document ID.
  /// Digunakan oleh halaman detail jika dibuka tanpa argumen memori.
  Future<RefluxPredictionResult?> fetchById(String id) async {
    try {
      final ref = _historyRef;
      if (ref == null) return null;

      final doc = await ref.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return RefluxPredictionResult.fromFirestore(doc);
    } catch (e) {
      debugPrint('[PredictionHistoryRepository] GAGAL mengambil riwayat $id: $e');
      return null;
    }
  }
}

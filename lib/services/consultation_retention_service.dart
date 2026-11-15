import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/consultation_model.dart';

/// Service tunggal untuk kebijakan retensi chat 60 hari (Revisi 10 Bagian D).
///
/// Fitur:
/// - Konstanta tunggal [kChatRetentionDays] = 60 hari.
/// - Filter tampilan instan ([isExpired]) berbasis aktivitas terakhir
///   (lastMessageAt ?? completedAt ?? createdAt) atau flag chatExpired.
/// - Pembersihan fisik background bertahap dan idempoten ([runRetentionCleanup]):
///   Maksimal 10 konsultasi per putaran, maksimal 1 kali per sesi aplikasi,
///   menghapus dokumen pesan per batch (maks. 400 doc), mencoba menghapus file storage (best effort),
///   lalu menandai dokumen konsultasi `chatExpired: true` dan `lastMessageText: ''`
///   (dokumen konsultasi dipertahankan sebagai satu-satunya catatan booking/pembayaran).
class ConsultationRetentionService {
  ConsultationRetentionService._();
  static final ConsultationRetentionService instance =
      ConsultationRetentionService._();

  /// Masa retensi chat dalam hari (Revisi 10 Bagian D: persis 60 hari).
  static const int kChatRetentionDays = 60;

  /// Override aman HANYA untuk kebutuhan pengujian debug tanpa menunggu 60 hari.
  /// Pada rilis produksi nilai ini WAJIB `null`.
  static int? debugRetentionDaysOverride;

  /// Jumlah hari retensi efektif (memperhitungkan override pengujian debug jika aktif).
  static int get effectiveRetentionDays =>
      debugRetentionDaysOverride ?? kChatRetentionDays;

  /// Durasi retensi efektif.
  static Duration get retentionDuration =>
      Duration(days: effectiveRetentionDays);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Flag pencegah pembersihan berulang dalam satu sesi aplikasi.
  bool _hasRunThisSession = false;

  /// Mereset flag pembersihan sesi (misalnya saat logout/login akun baru).
  void resetSession() {
    _hasRunThisSession = false;
  }

  /// Menentukan waktu aktivitas terakhir sebuah konsultasi:
  /// Prioritas: lastMessageAt -> completedAt -> createdAt.
  static DateTime getLastActivityDate(ConsultationModel c) {
    return c.lastMessageAt ?? c.completedAt ?? c.createdAt;
  }

  /// Memeriksa apakah sebuah konsultasi sudah melewati batas retensi 60 hari.
  /// Digunakan oleh filter tampilan instan di semua daftar dan penghitung.
  static bool isExpired(ConsultationModel c, [DateTime? referenceTime]) {
    if (c.chatExpired) return true;
    final now = referenceTime ?? DateTime.now();
    final lastActivity = getLastActivityDate(c);
    final elapsed = now.difference(lastActivity);
    return elapsed >= retentionDuration;
  }

  /// Memeriksa data mentah Firestore Map apakah sudah lewat 60 hari.
  static bool isFirestoreDataExpired(
    Map<String, dynamic> data, [
    DateTime? referenceTime,
  ]) {
    if (data['chatExpired'] == true) return true;
    final now = referenceTime ?? DateTime.now();

    DateTime? lastActivity;
    final lastMsg = data['lastMessageAt'];
    if (lastMsg is Timestamp) {
      lastActivity = lastMsg.toDate();
    } else {
      final comp = data['completedAt'];
      if (comp is Timestamp) {
        lastActivity = comp.toDate();
      } else {
        final cr = data['createdAt'];
        if (cr is Timestamp) {
          lastActivity = cr.toDate();
        }
      }
    }

    if (lastActivity == null) return false;
    return now.difference(lastActivity) >= retentionDuration;
  }

  /// Menjalankan pembersihan fisik di background:
  /// - Maksimal 10 konsultasi per putaran.
  /// - Maksimal sekali per sesi aplikasi.
  /// - Menghapus subkoleksi `messages` (per batch maks. 400 doc).
  /// - Membersihkan file Storage terkait (best effort).
  /// - Menandai konsultasi: `chatExpired: true`, `lastMessageText: ''`, `lastMessageId: null`.
  /// - Idempoten dan tidak memblokir UI pengguna.
  Future<void> runRetentionCleanup({
    required String uid,
    required bool isDoctor,
    String? doctorId,
  }) async {
    if (_hasRunThisSession) {
      return;
    }
    _hasRunThisSession = true;

    try {
      debugPrint('[RetentionService] Memulai pembersihan background (retensi $effectiveRetentionDays hari)...');
      final now = DateTime.now();

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> expiredConsultDocs = [];

      if (isDoctor) {
        final docId = (doctorId ?? '').trim();
        if (docId.isEmpty) return;
        // Ambil konsultasi dokter lewat collectionGroup
        final snap = await _db
            .collectionGroup('consultations')
            .where('doctorId', isEqualTo: docId)
            .limit(50)
            .get();

        for (final doc in snap.docs) {
          final data = doc.data();
          if (isFirestoreDataExpired(data, now)) {
            expiredConsultDocs.add(doc);
            if (expiredConsultDocs.length >= 10) break;
          }
        }
      } else {
        // Ambil konsultasi pasien
        final snap = await _db
            .collection('users')
            .doc(uid)
            .collection('consultations')
            .limit(50)
            .get();

        for (final doc in snap.docs) {
          final data = doc.data();
          if (isFirestoreDataExpired(data, now)) {
            expiredConsultDocs.add(doc);
            if (expiredConsultDocs.length >= 10) break;
          }
        }
      }

      if (expiredConsultDocs.isEmpty) {
        debugPrint('[RetentionService] Tidak ada konsultasi yang melewati batas $effectiveRetentionDays hari.');
        return;
      }

      debugPrint('[RetentionService] Ditemukan ${expiredConsultDocs.length} konsultasi lewat 60 hari untuk dibersihkan.');

      for (final consultDoc in expiredConsultDocs) {
        try {
          await _cleanupSingleConsultation(consultDoc);
        } catch (itemErr) {
          debugPrint('[RetentionService] Gagal membersihkan konsultasi ${consultDoc.id}: $itemErr');
        }
      }

      debugPrint('[RetentionService] Pembersihan background selesai.');
    } catch (e) {
      debugPrint('[RetentionService] Error pada runRetentionCleanup: $e');
    }
  }

  /// Membersihkan pesan satu konsultasi secara fisik dan menandai chatExpired: true.
  Future<void> _cleanupSingleConsultation(
    QueryDocumentSnapshot<Map<String, dynamic>> consultDoc,
  ) async {
    final messagesRef = consultDoc.reference.collection('messages');
    final messagesSnap = await messagesRef.limit(400).get();

    if (messagesSnap.docs.isNotEmpty) {
      // 1. Best-effort hapus attachment di Storage
      for (final msgDoc in messagesSnap.docs) {
        final data = msgDoc.data();
        final url = data['attachmentUrl'] as String?;
        if (url != null && (url.startsWith('http://') || url.startsWith('https://'))) {
          try {
            await _storage.refFromURL(url).delete();
          } catch (_) {
            // Storage delete gagal/tidak ada billing -> abaikan agar tidak menggagalkan batch
          }
        }
      }

      // 2. Batch delete dokumen pesan (maks. 400 docs)
      final batch = _db.batch();
      for (final msgDoc in messagesSnap.docs) {
        batch.delete(msgDoc.reference);
      }
      await batch.commit();
      debugPrint('[RetentionService] ${messagesSnap.docs.length} pesan dihapus untuk konsultasi ${consultDoc.id}');
    }

    // 3. Update dokumen konsultasi (D3b: Pertahankan dokumen untuk catatan pembayaran)
    await consultDoc.reference.update({
      'chatExpired': true,
      'lastMessageText': '',
      'lastMessageId': FieldValue.delete(),
    });
    debugPrint('[RetentionService] Konsultasi ${consultDoc.id} ditandai chatExpired: true');
  }
}

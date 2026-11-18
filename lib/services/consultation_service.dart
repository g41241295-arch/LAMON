import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/consultation_constants.dart';
import '../models/consultation_model.dart';
import 'attachment_service.dart';
import 'consultation_retention_service.dart';
import 'notification_relay_client.dart';

/// Service untuk mengelola data konsultasi dan chat pada Firestore.
///
/// Struktur data:
/// ```
/// users/{patientUid}/consultations/{consultationId}   ← data booking
/// users/{patientUid}/consultations/{consultationId}/messages/{messageId}  ← chat
/// ```
class ConsultationService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final Random _random = Random();

  ConsultationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  String? get _uid => _auth.currentUser?.uid;
  String? get currentUid => _uid;

  /// Referensi sub-koleksi consultations milik user yang sedang login.
  CollectionReference<Map<String, dynamic>>? get _consultationsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('consultations');
  }

  /// Referensi dokumen konsultasi (bisa milik patientUid tertentu).
  DocumentReference<Map<String, dynamic>>? _consultationDocRef(
      String consultationId, [String? patientUid]) {
    final pUid = (patientUid != null && patientUid.isNotEmpty) ? patientUid : _uid;
    if (pUid == null) return null;
    return _db.collection('users').doc(pUid).collection('consultations').doc(consultationId);
  }

  /// Referensi sub-koleksi messages dari satu konsultasi.
  CollectionReference<Map<String, dynamic>>? _messagesRef(
      String consultationId, [String? patientUid]) {
    final docRef = _consultationDocRef(consultationId, patientUid);
    return docRef?.collection('messages');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOOKING & PAYMENT
  // ─────────────────────────────────────────────────────────────────────────

  /// Membuat dokumen konsultasi baru di Firestore.
  /// Otomatis menyertakan data profil pasien (nama, usia, gender, status: "waiting").
  Future<String> createConsultation({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required String scheduledTime,
    required int sessionFee,
    required String paymentMethod,
    required String paymentMethodName,
    DateTime? scheduledDate,
  }) async {
    final uid = _uid;
    final ref = _consultationsRef;
    if (ref == null || uid == null) {
      throw Exception('User belum login. Silakan login terlebih dahulu.');
    }

    final now = DateTime.now();
    final effectiveScheduledDate = scheduledDate ?? DateTime(now.year, now.month, now.day);
    final orderId = _generateOrderId(now);
    final vaNumber = _generateVA(now);
    final expiresAt = now.add(ConsultationConstants.kPaymentWindow);
    final totalFee = sessionFee + ConsultationConstants.serviceFee;

    // Ambil data pasien dari users/{uid} untuk snapshot data konsultasi
    String patientName = '';
    String? patientGender;
    int? patientAge;
    String? patientPhotoUrl;

    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        patientName = (data['nama'] ?? data['name'] ?? '').toString().trim();
        patientGender = data['jenis_kelamin']?.toString();
        patientPhotoUrl = (data['photo_url'] ?? data['photoUrl'])?.toString().trim();

        final birthDateVal = data['tanggal_lahir'] ?? data['screeningData']?['birthDate'];
        if (birthDateVal != null) {
          patientAge = _calculateAge(birthDateVal);
        }
        if (patientGender == null && data['screeningData'] != null) {
          patientGender = data['screeningData']['gender']?.toString();
        }
      }
    } catch (e) {
      debugPrint('[ConsultationService] Gagal membaca profil pasien untuk snapshot: $e');
    }

    // Ambil foto dokter dari collection 'doctors' jika ada
    String doctorPhotoUrl = '';
    try {
      final docDoc = await _db.collection('doctors').doc(doctorId).get();
      if (docDoc.exists) {
        doctorPhotoUrl = (docDoc.data()?['photoUrl'] ?? '').toString().trim();
      }
    } catch (e) {
      debugPrint('[ConsultationService] Gagal membaca foto dokter: $e');
    }

    // Fallback nama pasien jika belum tersimpan di Firestore
    if (patientName.isEmpty) {
      patientName = _auth.currentUser?.displayName?.trim() ?? '';
    }
    if (patientName.isEmpty) {
      final email = _auth.currentUser?.email ?? '';
      if (email.contains('@')) {
        patientName = email.split('@').first;
        if (patientName.isNotEmpty) {
          patientName = patientName[0].toUpperCase() + patientName.substring(1);
        }
      }
    }
    if (patientName.isEmpty) {
      patientName = 'Pasien';
    }

    final consultation = ConsultationModel(
      id: '', // Diisi docRef
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      scheduledTime: scheduledTime,
      sessionFee: sessionFee,
      serviceFee: ConsultationConstants.serviceFee,
      totalFee: totalFee,
      paymentMethod: paymentMethod,
      paymentMethodName: paymentMethodName,
      virtualAccountNumber: vaNumber,
      orderId: orderId,
      paymentStatus: PaymentStatus.unpaid,
      paymentDeadline: expiresAt,
      paymentExpiresAt: expiresAt,
      scheduledDate: effectiveScheduledDate,
      createdAt: now,
      patientUid: uid,
      patientName: patientName,
      patientGender: patientGender,
      patientAge: patientAge,
      doctorPhotoUrl: doctorPhotoUrl,
      patientPhotoUrl: patientPhotoUrl,
      status: 'waiting',
      unreadForDoctor: 0,
      unreadForPatient: 0,
    );

    try {
      final docRef = ref.doc();
      final data = consultation.copyWith(id: docRef.id).toFirestore();
      data['consultationId'] = docRef.id;
      await docRef.set(data);
      debugPrint('[ConsultationService] Konsultasi dibuat: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('[ConsultationService] Gagal membuat konsultasi: $e');
      rethrow;
    }
  }

  /// Mengambil data satu konsultasi berdasarkan ID (mendukung akses dari dokter lewat patientUid).
  Future<ConsultationModel?> fetchById(String consultationId, {String? patientUid}) async {
    try {
      final docRef = _consultationDocRef(consultationId, patientUid);
      if (docRef != null) {
        final doc = await docRef.get();
        if (doc.exists && doc.data() != null) {
          return ConsultationModel.fromFirestore(doc);
        }
      }

      // Fallback via collectionGroup jika patientUid belum ada
      final groupSnap = await _db
          .collectionGroup('consultations')
          .where('consultationId', isEqualTo: consultationId)
          .limit(1)
          .get();
      if (groupSnap.docs.isNotEmpty) {
        return ConsultationModel.fromFirestore(groupSnap.docs.first);
      }

      // Fallback kedua via FieldPath.documentId untuk dokumen lama tanpa field consultationId
      final docIdSnap = await _db
          .collectionGroup('consultations')
          .where(FieldPath.documentId, isEqualTo: consultationId)
          .limit(1)
          .get();
      if (docIdSnap.docs.isNotEmpty) {
        return ConsultationModel.fromFirestore(docIdSnap.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('[ConsultationService] fetchById error: $e');
      return null;
    }
  }

  /// Mengambil konsultasi aktif atau menunggu konfirmasi yang sudah lunas (paid)
  /// antara pasien saat ini dengan dokter tertentu.
  Future<ConsultationModel?> getActiveOrWaitingConsultation(String doctorId) async {
    final ref = _consultationsRef;
    if (ref == null) return null;

    try {
      final snap = await ref
          .where('doctorId', isEqualTo: doctorId)
          .where('paymentStatus', isEqualTo: 'paid')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final model = ConsultationModel.fromFirestore(snap.docs.first);
        if (model.isWaiting || model.isActive) {
          return model;
        }
      }
    } catch (e) {
      debugPrint('[ConsultationService] Gagal memeriksa konsultasi aktif pasien: $e');
    }
    return null;
  }

  /// Stream live satu dokumen konsultasi (misal status aktif atau unread counter).
  Stream<ConsultationModel?> watchConsultation(String consultationId, {String? patientUid}) {
    final docRef = _consultationDocRef(consultationId, patientUid);
    if (docRef == null) return Stream.value(null);

    return docRef.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ConsultationModel.fromFirestore(doc);
    });
  }

  /// Menandai status pembayaran menjadi "paid" dan status "waiting".
  /// Guard (A.6): Memeriksa batas waktu pembayaran. Jika waktu habis,
  /// status di-set ke 'expired' dan pembayaran ditolak.
  Future<void> markAsPaid(String consultationId, {String? patientUid}) async {
    try {
      final docRef = _consultationDocRef(consultationId, patientUid);
      if (docRef == null) throw Exception('User belum login atau referensi tidak valid.');

      final docSnap = await docRef.get();
      if (!docSnap.exists || docSnap.data() == null) {
        throw Exception('Data konsultasi tidak ditemukan.');
      }

      final data = docSnap.data()!;
      final expiresTimestamp = data['paymentExpiresAt'] as Timestamp?;
      if (expiresTimestamp != null && expiresTimestamp.toDate().isBefore(DateTime.now())) {
        await docRef.update({'paymentStatus': PaymentStatus.expired.value});
        throw Exception('Waktu pembayaran telah habis.');
      }

      await docRef.update({
        'paymentStatus': PaymentStatus.paid.value,
        'status': 'waiting',
      });
      debugPrint('[ConsultationService] Konsultasi $consultationId ditandai lunas (waiting confirmation).');
    } catch (e) {
      debugPrint('[ConsultationService] Gagal markAsPaid: $e');
      rethrow;
    }
  }

  /// Menandai konsultasi menjadi "expired" (idempoten).
  Future<void> markAsExpired(String consultationId, {String? patientUid}) async {
    try {
      final docRef = _consultationDocRef(consultationId, patientUid);
      if (docRef == null) return;
      await docRef.update({
        'paymentStatus': PaymentStatus.expired.value,
      });
      debugPrint('[ConsultationService] Konsultasi $consultationId ditandai expired.');
    } catch (e) {
      debugPrint('[ConsultationService] Gagal markAsExpired: $e');
    }
  }

  /// Best-effort (A.8): Memeriksa dan menandai konsultasi berstatus pending milik pasien
  /// yang sudah lewat paymentExpiresAt menjadi 'expired'.
  Future<void> expirePastPendingConsultations({String? patientUid}) async {
    final uid = patientUid ?? _uid;
    if (uid == null || uid.isEmpty) return;

    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('consultations')
          .where('paymentStatus', isEqualTo: 'pending')
          .limit(20)
          .get();

      final now = DateTime.now();
      final batch = _db.batch();
      bool hasUpdates = false;

      for (final doc in snap.docs) {
        final data = doc.data();
        final expTs = data['paymentExpiresAt'] as Timestamp?;
        // A.9: Data lama tanpa paymentExpiresAt dianggap tanpa batas waktu (jangan diubah)
        if (expTs != null && expTs.toDate().isBefore(now)) {
          batch.update(doc.reference, {'paymentStatus': PaymentStatus.expired.value});
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
        debugPrint('[ConsultationService] Batch expire pending consultations selesai.');
      }
    } catch (e) {
      debugPrint('[ConsultationService] expirePastPendingConsultations error (silent): $e');
    }
  }

  /// Menandai konsultasi sebagai "completed" (selesai).
  /// Dipanggil oleh dokter setelah sesi konsultasi berakhir.
  Future<void> completeConsultation({
    required String consultationId,
    String? patientUid,
  }) async {
    try {
      String pUid = (patientUid ?? '').trim();
      if (pUid.isEmpty) {
        final groupSnap = await _db
            .collectionGroup('consultations')
            .where('consultationId', isEqualTo: consultationId)
            .limit(1)
            .get();
        if (groupSnap.docs.isNotEmpty) {
          final doc = groupSnap.docs.first;
          final pathSegments = doc.reference.path.split('/');
          final usersIdx = pathSegments.indexOf('users');
          if (usersIdx != -1 && usersIdx + 1 < pathSegments.length) {
            pUid = pathSegments[usersIdx + 1];
          }
          if (pUid.isEmpty) {
            final dataUid = doc.data()['patientUid'] as String?;
            if (dataUid != null && dataUid.isNotEmpty) {
              pUid = dataUid;
            }
          }
        }
      }

      if (pUid.isEmpty) {
        pUid = _uid ?? '';
      }

      if (pUid.isEmpty) {
        throw Exception('patientUid tidak ditemukan untuk konsultasi $consultationId');
      }

      await _db
          .collection('users')
          .doc(pUid)
          .collection('consultations')
          .doc(consultationId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[ConsultationService] Konsultasi $consultationId ditandai selesai (completed).');
    } catch (e) {
      debugPrint('[ConsultationService] Gagal completeConsultation: $e');
      rethrow;
    }
  }

  /// Pop-up dan transaksi penyelesaian konsultasi oleh dokter (Bagian A - Revisi 9):
  /// - Transaksi UTAMA hanya berisi:
  ///   (a) Guard idempoten (jika sudah completed -> batalkan transaksi dengan pesan "Konsultasi sudah selesai").
  ///   (b) Update consultation (status 'completed', completedAt serverTimestamp, doctorRecommendation,
  ///       lastMessageText "Konsultasi selesai", lastMessageAt serverTimestamp, lastMessageSenderType 'doctor',
  ///       lastMessageId, unreadForPatient +1).
  ///   (c) Tulis dokumen pesan ringkasan di sub-koleksi messages (senderType 'doctor', type 'consultation_summary', text = rekomendasi).
  /// - Increment doctors/{doctorId}.consultationsHandled dilakukan SETELAH transaksi utama sukses
  ///   sebagai langkah terpisah best effort (FieldValue.increment(1), error ditangkap tanpa membatalkan penyelesaian).
  ///   Rekonsiliasi di Beranda Dokter menutup selisih jika increment gagal.
  Future<void> completeConsultationWithRecommendation({
    required String consultationId,
    required String recommendation,
    required String doctorId,
    String? patientUid,
  }) async {
    String pUid = (patientUid ?? '').trim();
    if (pUid.isEmpty) {
      final consult = await fetchById(consultationId);
      pUid = consult?.patientUid ?? '';
    }
    if (pUid.isEmpty) {
      throw Exception('patientUid tidak ditemukan untuk konsultasi $consultationId');
    }

    final consultationDocRef = _consultationDocRef(consultationId, pUid);
    if (consultationDocRef == null) {
      throw Exception('Referensi konsultasi tidak valid.');
    }

    final messagesColRef = consultationDocRef.collection('messages');
    final newMessageDocRef = messagesColRef.doc();

    // 1. Transaksi UTAMA: HANYA consultation & pesan ringkasan
    await _db.runTransaction((transaction) async {
      final consultSnap = await transaction.get(consultationDocRef);
      if (!consultSnap.exists) {
        throw Exception('Data konsultasi tidak ditemukan.');
      }
      final consultData = consultSnap.data() ?? {};
      final currentStatus = consultData['status'] as String?;
      if (currentStatus == 'completed') {
        throw Exception('Konsultasi sudah selesai.');
      }

      // Update consultation
      transaction.update(consultationDocRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'doctorRecommendation': recommendation.trim(),
        'lastMessageText': 'Konsultasi selesai',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderType': 'doctor',
        'lastMessageId': newMessageDocRef.id,
        'unreadForPatient': FieldValue.increment(1),
      });

      // Write consultation_summary message
      transaction.set(newMessageDocRef, {
        'senderType': 'doctor',
        'type': 'consultation_summary',
        'text': recommendation.trim(),
        'sentAt': FieldValue.serverTimestamp(),
        'deletedForEveryone': false,
        'hiddenFor': <String>[],
      });
    });

    debugPrint('[ConsultationService] Transaksi utama penyelesaian konsultasi $consultationId sukses.');

    // 2. Increment consultationsHandled dokter sebagai langkah terpisah best effort
    if (doctorId.isNotEmpty) {
      try {
        final doctorDocRef = _db.collection('doctors').doc(doctorId);
        await doctorDocRef.update({
          'consultationsHandled': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[ConsultationService] Increment consultationsHandled dokter $doctorId berhasil.');
      } catch (e) {
        debugPrint('[ConsultationService] Gagal increment consultationsHandled (rekonsiliasi Beranda Dokter akan menutup selisih): $e');
      }
    }

    // 3. Relay notifikasi
    NotificationRelayClient.instance.notify(
      patientUid: pUid,
      consultationId: consultationId,
    );
  }

  /// Menandai pop-up rekomendasi selesai telah dilihat oleh pasien (D.5).
  Future<void> markCompletionSeenByPatient({
    required String consultationId,
    String? patientUid,
  }) async {
    final docRef = _consultationDocRef(consultationId, patientUid);
    if (docRef == null) return;
    try {
      await docRef.update({'completionSeenByPatient': true});
    } catch (e) {
      debugPrint('[ConsultationService] Gagal markCompletionSeenByPatient: $e');
    }
  }

  /// Stream seluruh konsultasi milik pasien (baik active, waiting, maupun completed),
  /// tanpa filter server-side agar tidak memerlukan composite index dan live real-time.
  /// Otomatis menyaring konsultasi yang disembunyikan oleh pasien (hiddenByPatient == true).
  Stream<List<ConsultationModel>> watchAllPatientConsultations({String? patientUid}) {
    final pUid = patientUid ?? _uid;
    if (pUid == null || pUid.isEmpty) {
      return Stream.value(<ConsultationModel>[]);
    }

    return _db
        .collection('users')
        .doc(pUid)
        .collection('consultations')
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => ConsultationModel.fromFirestore(doc))
          .where((c) =>
              c.paymentStatus != PaymentStatus.expired &&
              !c.hiddenByPatient &&
              !ConsultationRetentionService.isExpired(c))
          .toList();
    });
  }

  /// Stream daftar riwayat konsultasi pasien berstatus "completed".
  /// Otomatis menyaring konsultasi yang disembunyikan oleh pasien (hiddenByPatient == true).
  Stream<List<ConsultationModel>> watchCompletedConsultations({String? patientUid}) {
    final pUid = patientUid ?? _uid;
    if (pUid == null || pUid.isEmpty) {
      return Stream.value(<ConsultationModel>[]);
    }

    return _db
        .collection('users')
        .doc(pUid)
        .collection('consultations')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => ConsultationModel.fromFirestore(doc))
          .where((c) =>
              !c.hiddenByPatient &&
              !ConsultationRetentionService.isExpired(c))
          .toList();

      // Urutkan terbaru: completedAt ?? createdAt descending
      list.sort((a, b) {
        final timeA = a.completedAt ?? a.createdAt;
        final timeB = b.completedAt ?? b.createdAt;
        return timeB.compareTo(timeA);
      });

      return list;
    });
  }

  /// Sembunyikan atau pulihkan konsultasi dari Riwayat Konsultasi pasien (Bagian D).
  /// Menggunakan soft-hide `hiddenByPatient` sehingga catatan dokter tetap utuh.
  Future<void> hideConsultationFromHistory({
    required String consultationId,
    String? patientUid,
    bool hidden = true,
  }) async {
    final docRef = _consultationDocRef(consultationId, patientUid);
    if (docRef == null) throw Exception('Referensi konsultasi tidak valid.');
    await docRef.update({'hiddenByPatient': hidden});
    debugPrint('[ConsultationService] Konsultasi $consultationId hiddenByPatient = $hidden.');
  }

  /// Membersihkan riwayat lama (> 30 hari secara default) dengan soft-hide (Bagian D.2).
  /// Dipecah per 400 operasi untuk mematuhi limit batch Firestore.
  Future<int> cleanOldConsultationHistory({
    String? patientUid,
    Duration olderThan = ConsultationConstants.kOldChatAge,
  }) async {
    final uid = patientUid ?? _uid;
    if (uid == null || uid.isEmpty) return 0;

    final cutoff = DateTime.now().subtract(olderThan);
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('consultations')
        .where('status', isEqualTo: 'completed')
        .get();

    final toHide = snap.docs.where((doc) {
      final data = doc.data();
      if (data['hiddenByPatient'] == true) return false;
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate();
      if (completedAt == null) return false;
      return completedAt.isBefore(cutoff);
    }).toList();

    if (toHide.isEmpty) return 0;

    // Pecah per 400 dokumen per batch
    const int chunkSize = 400;
    for (int i = 0; i < toHide.length; i += chunkSize) {
      final chunk = toHide.skip(i).take(chunkSize);
      final batch = _db.batch();
      for (final doc in chunk) {
        batch.update(doc.reference, {'hiddenByPatient': true});
      }
      await batch.commit();
    }

    debugPrint('[ConsultationService] Berhasil menyembunyikan ${toHide.length} konsultasi lama.');
    return toHide.length;
  }

  /// Mengirim penilaian (rating 1-5) dari pasien untuk konsultasi yang sudah completed (Revisi 11 Bagian A).
  /// Operasi dilakukan atomik dalam satu batch/transaksi:
  /// - consultation.rating = rating (1-5)
  /// - consultation.ratedAt = serverTimestamp()
  /// - doctors/{doctorId}.ratingSum += rating
  /// - doctors/{doctorId}.ratingCount += 1
  Future<void> submitConsultationRating({
    required String consultationId,
    required String doctorId,
    required int rating,
    String? patientUid,
  }) async {
    final uid = patientUid ?? _uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('User belum login.');
    }
    if (rating < 1 || rating > 5) {
      throw Exception('Rating harus bernilai antara 1 dan 5.');
    }

    final consultationRef = _db
        .collection('users')
        .doc(uid)
        .collection('consultations')
        .doc(consultationId);

    final cleanDoctorId = doctorId.trim();
    if (cleanDoctorId.isEmpty) {
      throw Exception('ID Dokter tidak valid.');
    }
    final doctorRef = _db.collection('doctors').doc(cleanDoctorId);

    // Lakukan secara atomik menggunakan WriteBatch
    final batch = _db.batch();
    batch.update(consultationRef, {
      'rating': rating,
      'ratedAt': FieldValue.serverTimestamp(),
    });
    batch.update(doctorRef, {
      'ratingSum': FieldValue.increment(rating),
      'ratingCount': FieldValue.increment(1),
    });

    await batch.commit();
    debugPrint('[ConsultationService] Sukses submit rating $rating untuk konsultasi $consultationId dan dokter $cleanDoctorId.');
  }

  /// Sembunyikan atau pulihkan konsultasi dari daftar pesan dokter (Revisi 11 Bagian B).
  /// Menggunakan soft-hide `hiddenByDoctor` sehingga riwayat pasien tetap utuh.
  Future<void> hideConsultationByDoctor({
    required String patientUid,
    required String consultationId,
    bool hidden = true,
  }) async {
    final cleanPatientUid = patientUid.trim();
    if (cleanPatientUid.isEmpty) {
      throw Exception('Patient UID tidak valid.');
    }
    final docRef = _db
        .collection('users')
        .doc(cleanPatientUid)
        .collection('consultations')
        .doc(consultationId);

    await docRef.update({
      'hiddenByDoctor': hidden,
      if (hidden) 'hiddenByDoctorAt': FieldValue.serverTimestamp()
      else 'hiddenByDoctorAt': FieldValue.delete(),
    });
    debugPrint('[ConsultationService] Konsultasi $consultationId hiddenByDoctor = $hidden.');
  }

  /// Membersihkan chat lama dokter (> 30 hari secara default) dengan soft-hide (Revisi 11 Bagian B).
  /// Hanya menyembunyikan konsultasi berstatus completed atau expired.
  Future<int> cleanOldDoctorConsultations({
    required String doctorId,
    required List<ConsultationModel> consultations,
    Duration olderThan = ConsultationConstants.kOldChatAge,
  }) async {
    if (doctorId.isEmpty) return 0;

    final cutoff = DateTime.now().subtract(olderThan);
    final toHide = consultations.where((c) {
      if (c.hiddenByDoctor) return false;
      if (!c.isCompleted && !c.isExpired) return false;
      final time = c.completedAt ?? c.createdAt;
      return time.isBefore(cutoff);
    }).toList();

    if (toHide.isEmpty) return 0;

    const int chunkSize = 400;
    for (int i = 0; i < toHide.length; i += chunkSize) {
      final chunk = toHide.skip(i).take(chunkSize);
      final batch = _db.batch();
      for (final item in chunk) {
        if (item.patientUid.isNotEmpty) {
          final ref = _db
              .collection('users')
              .doc(item.patientUid)
              .collection('consultations')
              .doc(item.id);
          batch.update(ref, {
            'hiddenByDoctor': true,
            'hiddenByDoctorAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
    }

    debugPrint('[ConsultationService] Berhasil menyembunyikan ${toHide.length} chat lama untuk dokter $doctorId.');
    return toHide.length;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHAT & ATTACHMENTS
  // ─────────────────────────────────────────────────────────────────────────

  /// Upload file ke Firebase Storage pada path `consultations/{uid}/{consultationId}/{filename}`.
  Future<String> uploadAttachment({
    required String consultationId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? patientUid,
  }) async {
    final uid = patientUid ?? _uid;
    if (uid == null) throw Exception('User belum login.');

    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child('consultations/$uid/$consultationId/$uniqueName');

    final metadata = SettableMetadata(
      contentType: mimeType,
      customMetadata: {'uploadedBy': _uid ?? uid, 'consultationId': consultationId},
    );

    final uploadTask = await ref.putData(bytes, metadata);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Stream realtime daftar pesan di satu sesi konsultasi,
  /// diurutkan dari yang paling lama (ascending).
  Stream<List<ChatMessage>> watchMessages(String consultationId, {String? patientUid}) {
    final ref = _messagesRef(consultationId, patientUid);
    if (ref == null) return Stream.value(<ChatMessage>[]);

    return ref
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Menandai chat telah dibaca oleh peran tertentu (set unread = 0 & lastReadAt).
  Future<void> markChatAsRead({
    required String consultationId,
    required String role, // "patient" | "doctor"
    String? patientUid,
  }) async {
    final docRef = _consultationDocRef(consultationId, patientUid);
    if (docRef == null) return;

    try {
      if (role == 'doctor') {
        await docRef.update({
          'unreadForDoctor': 0,
          'lastReadByDoctorAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          'unreadForPatient': 0,
          'lastReadByPatientAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[ConsultationService] Gagal markChatAsRead: $e');
    }
  }

  /// Mengirim pesan dalam batch:
  /// Menulis dokumen pesan + memperbarui summary pesan terakhir & unread counter pada konsultasi.
  Future<void> sendMessage({
    required String consultationId,
    required String senderType, // "patient" | "doctor"
    required String text,
    String? patientUid,
    String type = 'text',
    String? attachmentUrl,
    String? attachmentId,
    String? fileName,
    int? fileSize,
    int? sizeBytes,
    String? mimeType,
    String? doctorId,
  }) async {
    // Pastikan patientUid selalu valid. Dokter TIDAK BOLEH menulis ke users/{doctorUid}
    String? effectivePatientUid = (patientUid != null && patientUid.trim().isNotEmpty)
        ? patientUid.trim()
        : null;

    if (effectivePatientUid == null) {
      if (senderType == 'patient') {
        effectivePatientUid = _uid;
      } else {
        final consultation = await fetchById(consultationId);
        effectivePatientUid = consultation?.patientUid;
      }
    }

    if (effectivePatientUid == null || effectivePatientUid.isEmpty) {
      throw Exception('patientUid tidak ditemukan untuk konsultasi $consultationId. Pesan dibatalkan.');
    }

    final messagesRef = _messagesRef(consultationId, effectivePatientUid);
    final consultationDocRef = _consultationDocRef(consultationId, effectivePatientUid);

    if (messagesRef == null || consultationDocRef == null) {
      throw Exception('Referensi konsultasi tidak valid.');
    }

    final trimmedText = text.trim();
    final hasAttachUrl = attachmentUrl != null && attachmentUrl.isNotEmpty;
    final hasAttachId = attachmentId != null && attachmentId.isNotEmpty;
    if (trimmedText.isEmpty && !hasAttachUrl && !hasAttachId) {
      return;
    }

    final effectiveSize = sizeBytes ?? fileSize;
    final messageDoc = messagesRef.doc();
    final messageData = <String, dynamic>{
      'senderType': senderType,
      'text': trimmedText,
      'sentAt': FieldValue.serverTimestamp(),
      'type': type,
      'deletedForEveryone': false,
      'hiddenFor': <String>[],
      if (hasAttachUrl) 'attachmentUrl': attachmentUrl,
      if (hasAttachId) 'attachmentId': attachmentId,
      if (fileName != null && fileName.isNotEmpty) 'fileName': fileName,
      'fileSize': ?effectiveSize,
      'sizeBytes': ?effectiveSize,
      if (mimeType != null && mimeType.isNotEmpty) 'mimeType': mimeType,
      'isAutoReply': false,
    };

    String previewText = trimmedText;
    if (previewText.isEmpty) {
      previewText = type == 'image' ? '[Foto]' : '[Dokumen]';
    }

    final batch = _db.batch();
    batch.set(messageDoc, messageData);

    if (senderType == 'patient') {
      batch.update(consultationDocRef, {
        'lastMessageText': previewText,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderType': 'patient',
        'lastMessageIsAutoReply': false,
        'lastMessageId': messageDoc.id,
        'unreadForDoctor': FieldValue.increment(1),
      });
    } else {
      batch.update(consultationDocRef, {
        'lastMessageText': previewText,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderType': 'doctor',
        'lastMessageIsAutoReply': false,
        'lastMessageId': messageDoc.id,
        'unreadForPatient': FieldValue.increment(1),
      });
    }

    await batch.commit();
    debugPrint('[ConsultationService] Pesan $senderType berhasil dikirim via batch ke users/$effectivePatientUid/consultations/$consultationId.');

    // Panggil relay notifikasi secara fire-and-forget
    NotificationRelayClient.instance.notify(
      patientUid: effectivePatientUid,
      consultationId: consultationId,
    );

    // Jika pengirim adalah pasien, picu balasan perkenalan otomatis (Revisi 12)
    if (senderType == 'patient') {
      _checkAndTriggerSimulatedReply(
        consultationId: consultationId,
        doctorId: doctorId,
        patientText: trimmedText,
        patientUid: effectivePatientUid,
      );
    }
  }

  /// Mengirim pesan dari pasien (backward compatibility wrapper).
  Future<void> sendPatientMessage({
    required String consultationId,
    required String text,
    String type = 'text',
    String? attachmentUrl,
    String? attachmentId,
    String? fileName,
    int? fileSize,
    int? sizeBytes,
    String? mimeType,
    String? doctorId,
  }) async {
    await sendMessage(
      consultationId: consultationId,
      senderType: 'patient',
      text: text,
      type: type,
      attachmentUrl: attachmentUrl,
      attachmentId: attachmentId,
      fileName: fileName,
      fileSize: fileSize,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
      doctorId: doctorId,
    );
  }

  /// Mengedit teks pesan chat (Bagian C.2).
  /// Menandai editedAt dan jika pesan yang diedit adalah pesan terakhir (lastMessageId cocok),
  /// perbarui juga lastMessageText pada dokumen consultation.
  Future<void> editMessage({
    required String consultationId,
    required String messageId,
    required String newText,
    String? patientUid,
    bool isLastMessage = false,
  }) async {
    String? effectivePatientUid = (patientUid != null && patientUid.trim().isNotEmpty)
        ? patientUid.trim()
        : null;

    if (effectivePatientUid == null) {
      final consultation = await fetchById(consultationId);
      effectivePatientUid = consultation?.patientUid ?? _uid;
    }

    if (effectivePatientUid == null || effectivePatientUid.isEmpty) {
      throw Exception('patientUid tidak ditemukan untuk konsultasi $consultationId');
    }

    final messageDocRef = _messagesRef(consultationId, effectivePatientUid)?.doc(messageId);
    final consultationDocRef = _consultationDocRef(consultationId, effectivePatientUid);

    if (messageDocRef == null || consultationDocRef == null) {
      throw Exception('Referensi dokumen pesan tidak valid.');
    }

    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;

    final batch = _db.batch();
    batch.update(messageDocRef, {
      'text': trimmed,
      'editedAt': FieldValue.serverTimestamp(),
    });

    if (isLastMessage) {
      batch.update(consultationDocRef, {
        'lastMessageText': trimmed,
      });
    }

    await batch.commit();
    debugPrint('[ConsultationService] Pesan $messageId berhasil diedit.');
  }

  /// Menyembunyikan pesan untuk diri sendiri (Bagian C.3: Hapus untuk saya).
  /// Menambahkan uid pengguna ke dalam array hiddenFor pada dokumen pesan.
  Future<void> hideMessageForMe({
    required String consultationId,
    required String messageId,
    required String myUid,
    String? patientUid,
  }) async {
    String? effectivePatientUid = (patientUid != null && patientUid.trim().isNotEmpty)
        ? patientUid.trim()
        : null;

    if (effectivePatientUid == null) {
      final consultation = await fetchById(consultationId);
      effectivePatientUid = consultation?.patientUid ?? _uid;
    }

    if (effectivePatientUid == null || effectivePatientUid.isEmpty) {
      throw Exception('patientUid tidak ditemukan untuk konsultasi $consultationId');
    }

    final messageDocRef = _messagesRef(consultationId, effectivePatientUid)?.doc(messageId);
    if (messageDocRef == null) {
      throw Exception('Referensi pesan tidak valid.');
    }

    await messageDocRef.update({
      'hiddenFor': FieldValue.arrayUnion([myUid]),
    });
    debugPrint('[ConsultationService] Pesan $messageId disembunyikan untuk uid $myUid.');
  }

  /// Menghapus pesan untuk semua orang (Bagian C.3: Hapus untuk semua orang).
  /// Menandai deletedForEveryone = true, mengosongkan teks dan lampiran,
  /// serta mengubah preview lastMessageText menjadi "Pesan ini telah dihapus" jika pesan terakhir.
  Future<void> deleteMessageForEveryone({
    required String consultationId,
    required String messageId,
    String? patientUid,
    bool isLastMessage = false,
  }) async {
    String? effectivePatientUid = (patientUid != null && patientUid.trim().isNotEmpty)
        ? patientUid.trim()
        : null;

    if (effectivePatientUid == null) {
      final consultation = await fetchById(consultationId);
      effectivePatientUid = consultation?.patientUid ?? _uid;
    }

    if (effectivePatientUid == null || effectivePatientUid.isEmpty) {
      throw Exception('patientUid tidak ditemukan untuk konsultasi $consultationId');
    }

    final messageDocRef = _messagesRef(consultationId, effectivePatientUid)?.doc(messageId);
    final consultationDocRef = _consultationDocRef(consultationId, effectivePatientUid);

    if (messageDocRef == null || consultationDocRef == null) {
      throw Exception('Referensi dokumen tidak valid.');
    }

    // Bersihkan data attachment jika ada
    try {
      final snap = await messageDocRef.get();
      if (snap.exists) {
        final data = snap.data() ?? {};
        final attachUrl = data['attachmentUrl'] as String?;
        final attachId = data['attachmentId'] as String?;
        if (attachId != null && attachId.isNotEmpty) {
          await AttachmentService.instance.clearAttachmentData(
            patientUid: effectivePatientUid,
            consultationId: consultationId,
            attachmentId: attachId,
          );
        }
        if (attachUrl != null && (attachUrl.startsWith('http://') || attachUrl.startsWith('https://'))) {
          try {
            await _storage.refFromURL(attachUrl).delete();
          } catch (storageErr) {
            debugPrint('[ConsultationService] Gagal menghapus file storage (best-effort): $storageErr');
          }
        }
      }
    } catch (_) {}

    final batch = _db.batch();
    batch.update(messageDocRef, {
      'deletedForEveryone': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'text': '',
      'attachmentUrl': FieldValue.delete(),
      'attachmentId': FieldValue.delete(),
      'fileName': FieldValue.delete(),
      'fileSize': FieldValue.delete(),
      'sizeBytes': FieldValue.delete(),
      'mimeType': FieldValue.delete(),
    });

    if (isLastMessage) {
      batch.update(consultationDocRef, {
        'lastMessageText': 'Pesan ini telah dihapus',
      });
    }

    await batch.commit();
    debugPrint('[ConsultationService] Pesan $messageId berhasil dihapus untuk semua orang.');
  }

  /// Menghasilkan template balasan perkenalan otomatis dokter (Revisi 12 Bagian A.2.3).
  /// Format: "Halo selamat {pagi/siang/sore/malam}. Perkenalkan saya dokter {spesialisasi} {nama}. Apa keluhan yang anda alami?"
  ///
  /// Mematuhi aturan Revisi 5 Bagian R: bebas dari nama penyakit, nama obat, diagnosis, atau saran pengobatan.
  static String generateDoctorAutoReplyText({
    required String doctorName,
    required String doctorSpecialty,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final hour = effectiveNow.hour;

    // Salam menurut jam lokal perangkat:
    // pagi 04.00-10.59, siang 11.00-14.59, sore 15.00-17.59, malam 18.00-03.59
    final String greeting;
    if (hour >= 4 && hour < 11) {
      greeting = 'pagi';
    } else if (hour >= 11 && hour < 15) {
      greeting = 'siang';
    } else if (hour >= 15 && hour < 18) {
      greeting = 'sore';
    } else {
      greeting = 'malam';
    }

    // Nama panggilan: nama depan setelah membuang awalan "Dr."/"dr."/"drg."/"Dokter" dan gelar belakang
    String cleanName = doctorName.trim();
    if (cleanName.contains(',')) {
      cleanName = cleanName.split(',').first.trim();
    }
    cleanName = cleanName.replaceFirst(
      RegExp(r'^(drg\.|drg\s+|dr\.|dr\s+|dokter\s+)', caseSensitive: false),
      '',
    ).trim();
    final nickname = cleanName.isNotEmpty ? cleanName.split(RegExp(r'\s+')).first : '';

    // Spesialisasi: field spesialisasi tanpa kata awal "Dokter", huruf kecil.
    // Contoh: "Dokter Umum" -> "umum", "Spesialis Penyakit Dalam" -> "spesialis penyakit dalam".
    String cleanSpecialty = doctorSpecialty.trim();
    cleanSpecialty = cleanSpecialty.replaceFirst(
      RegExp(r'^(dokter\s+)', caseSensitive: false),
      '',
    ).trim().toLowerCase();

    // Template balasan
    if (cleanSpecialty.isNotEmpty && nickname.isNotEmpty) {
      return 'Halo selamat $greeting. Perkenalkan saya dokter $cleanSpecialty $nickname. Apa keluhan yang anda alami?';
    } else if (nickname.isNotEmpty) {
      return 'Halo selamat $greeting. Perkenalkan saya dokter $nickname. Apa keluhan yang anda alami?';
    } else {
      return 'Halo selamat $greeting. Perkenalkan saya dokter. Apa keluhan yang anda alami?';
    }
  }

  /// [AUTO-REPLY] Memeriksa kelayakan dan menjadwalkan balasan otomatis perkenalan dokter (Revisi 12).
  ///
  /// Kriteria:
  /// 1. Idempoten: hanya 1 kali per sesi konsultasi (consultation.autoReplySent == true membatalkan).
  /// 2. Berlaku untuk SEMUA dokter (tidak dibatasi Oggy atau keberadaan akun nyata dokter).
  /// 3. Memeriksa doctors/{id}.autoReplyEnabled (jika false, jangan kirim).
  /// 4. Jika konsultasi sudah memiliki pesan dokter (senderType doctor) non-bot, tandai autoReplySent dan batalkan.
  Future<void> _checkAndTriggerSimulatedReply({
    required String consultationId,
    required String? doctorId,
    required String patientText,
    String? patientUid,
  }) async {
    final effectivePatientUid = patientUid ?? _uid;
    if (effectivePatientUid == null || effectivePatientUid.isEmpty) {
      return;
    }

    try {
      final docRef = _consultationDocRef(consultationId, effectivePatientUid);
      if (docRef == null) return;

      final consultDoc = await docRef.get();
      if (!consultDoc.exists) return;

      final data = consultDoc.data() ?? {};
      final autoReplySent = data['autoReplySent'] as bool? ?? false;
      if (autoReplySent) {
        debugPrint('[ConsultationService] autoReplySent sudah true untuk $consultationId. Abaikan bot.');
        return;
      }

      final effectiveDoctorId = (doctorId != null && doctorId.isNotEmpty)
          ? doctorId
          : (data['doctorId'] as String? ?? '');
      if (effectiveDoctorId.isEmpty) return;

      String doctorName = data['doctorName'] as String? ?? '';
      String doctorSpecialty = data['doctorSpecialty'] as String? ?? '';

      // Cek field opsional doctors/{id}.autoReplyEnabled (null dianggap true)
      final docSnap = await _db.collection('doctors').doc(effectiveDoctorId).get();
      if (docSnap.exists) {
        final docData = docSnap.data() ?? {};
        final autoReplyEnabled = docData['autoReplyEnabled'] as bool? ?? true;
        if (!autoReplyEnabled) {
          debugPrint('[ConsultationService] Dokter $effectiveDoctorId autoReplyEnabled = false. Abaikan bot.');
          return;
        }
        if (doctorName.isEmpty) {
          doctorName = docData['name'] as String? ?? '';
        }
        if (doctorSpecialty.isEmpty) {
          doctorSpecialty = docData['specialty'] as String? ?? '';
        }
      }

      // Cek apakah sudah ada pesan dokter sungguhan (non-bot)
      final messagesRef = _messagesRef(consultationId, effectivePatientUid);
      if (messagesRef != null) {
        final doctorMsgQuery = await messagesRef
            .where('senderType', isEqualTo: 'doctor')
            .limit(1)
            .get();
        if (doctorMsgQuery.docs.isNotEmpty) {
          final firstDocMsg = doctorMsgQuery.docs.first.data();
          if (firstDocMsg['isAutoReply'] != true) {
            debugPrint('[ConsultationService] Sudah ada pesan dokter sungguhan di $consultationId. Set autoReplySent = true.');
            await docRef.update({'autoReplySent': true});
            return;
          }
        }
      }

      // Jadwalkan balasan perkenalan otomatis setelah jeda waktu yang sama
      _scheduleSimulatedDoctorReply(
        consultationId: consultationId,
        patientUid: effectivePatientUid,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
      );
    } catch (e) {
      debugPrint('[ConsultationService] Gagal memeriksa auto-reply: $e');
    }
  }

  /// Mengirim pesan balasan perkenalan dokter otomatis dalam batch atomik (Revisi 12).
  void _scheduleSimulatedDoctorReply({
    required String consultationId,
    required String patientUid,
    required String doctorName,
    required String doctorSpecialty,
  }) {
    Future.delayed(ConsultationConstants.doctorReplyDelay, () async {
      try {
        final messagesRef = _messagesRef(consultationId, patientUid);
        final consultationDocRef = _consultationDocRef(consultationId, patientUid);
        if (messagesRef == null || consultationDocRef == null) return;

        // Re-check idempoten sebelum batch commit
        final freshDoc = await consultationDocRef.get();
        if (!freshDoc.exists || (freshDoc.data()?['autoReplySent'] == true)) {
          return;
        }

        final replyText = generateDoctorAutoReplyText(
          doctorName: doctorName,
          doctorSpecialty: doctorSpecialty,
        );

        final messageDoc = messagesRef.doc();
        final batch = _db.batch();

        batch.set(messageDoc, {
          'senderType': 'doctor',
          'text': replyText,
          'sentAt': FieldValue.serverTimestamp(),
          'type': 'text',
          'deletedForEveryone': false,
          'hiddenFor': <String>[],
          'isAutoReply': true,
        });

        // Balasan otomatis BUKAN balasan dokter sungguhan (A2.6):
        // - autoReplySent = true
        // - lastMessageIsAutoReply = true (agar tetap di 'Belum Dibalas')
        // - unreadForPatient increment 1 (pasien mendapat notifikasi/banner pesan masuk)
        // - TIDAK mengisi doctorConfirmedAt, TIDAK mengubah unreadForDoctor, TIDAK menaikkan consultationsHandled
        batch.update(consultationDocRef, {
          'autoReplySent': true,
          'lastMessageText': replyText,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessageSenderType': 'doctor',
          'lastMessageIsAutoReply': true,
          'lastMessageId': messageDoc.id,
          'unreadForPatient': FieldValue.increment(1),
        });

        await batch.commit();
        debugPrint('[ConsultationService] Balasan otomatis dokter berhasil terkirim via batch atomik.');

        // Panggil relay notifikasi untuk pasien
        NotificationRelayClient.instance.notify(
          patientUid: patientUid,
          consultationId: consultationId,
        );
      } catch (e) {
        debugPrint('[ConsultationService] Gagal kirim balasan otomatis dokter: $e');
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  int? _calculateAge(dynamic birthDateVal) {
    try {
      DateTime? bDate;
      if (birthDateVal is Timestamp) {
        bDate = birthDateVal.toDate();
      } else if (birthDateVal is String) {
        bDate = DateTime.tryParse(birthDateVal);
      }
      if (bDate != null) {
        final now = DateTime.now();
        int age = now.year - bDate.year;
        if (now.month < bDate.month ||
            (now.month == bDate.month && now.day < bDate.day)) {
          age--;
        }
        return age >= 0 ? age : null;
      }
    } catch (_) {}
    return null;
  }

  String _generateVA(DateTime now) {
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix = _random.nextInt(999).toString().padLeft(3, '0');
    return '${ConsultationConstants.vaPrefix} $datePart$suffix';
  }

  String _generateOrderId(DateTime now) {
    final ts =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final rand = _random.nextInt(9999).toString().padLeft(4, '0');
    return 'LAMON-$ts-$rand';
  }
}

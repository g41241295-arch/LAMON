import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/consultation_constants.dart';
import '../models/consultation_model.dart';

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
  }) async {
    final uid = _uid;
    final ref = _consultationsRef;
    if (ref == null || uid == null) {
      throw Exception('User belum login. Silakan login terlebih dahulu.');
    }

    final now = DateTime.now();
    final orderId = _generateOrderId(now);
    final vaNumber = _generateVA(now);
    final deadline = now.add(ConsultationConstants.paymentDeadlineDuration);
    final totalFee = sessionFee + ConsultationConstants.serviceFee;

    // Ambil data pasien dari users/{uid} untuk snapshot data konsultasi
    String patientName = '';
    String? patientGender;
    int? patientAge;

    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        patientName = (data['nama'] ?? data['name'] ?? '').toString().trim();
        patientGender = data['jenis_kelamin']?.toString();

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
      paymentStatus: PaymentStatus.pending,
      paymentDeadline: deadline,
      createdAt: now,
      patientUid: uid,
      patientName: patientName,
      patientGender: patientGender,
      patientAge: patientAge,
      status: 'waiting',
      unreadForDoctor: 0,
      unreadForPatient: 0,
    );

    try {
      final docRef = await ref.add(consultation.toFirestore());
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
      if (docRef == null) return null;
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) return null;
      return ConsultationModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[ConsultationService] fetchById error: $e');
      return null;
    }
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
  Future<void> markAsPaid(String consultationId) async {
    try {
      final ref = _consultationsRef;
      if (ref == null) throw Exception('User belum login.');
      await ref.doc(consultationId).update({
        'paymentStatus': PaymentStatus.paid.value,
        'status': 'waiting',
      });
      debugPrint('[ConsultationService] Konsultasi $consultationId ditandai lunas (waiting confirmation).');
    } catch (e) {
      debugPrint('[ConsultationService] Gagal markAsPaid: $e');
      rethrow;
    }
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
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? doctorId,
  }) async {
    final messagesRef = _messagesRef(consultationId, patientUid);
    final consultationDocRef = _consultationDocRef(consultationId, patientUid);

    if (messagesRef == null || consultationDocRef == null) {
      throw Exception('Referensi konsultasi tidak valid.');
    }

    final trimmedText = text.trim();
    if (trimmedText.isEmpty && (attachmentUrl == null || attachmentUrl.isEmpty)) {
      return;
    }

    final messageDoc = messagesRef.doc();
    final messageData = {
      'senderType': senderType,
      'text': trimmedText,
      'sentAt': FieldValue.serverTimestamp(),
      'type': type,
      'attachmentUrl': ?attachmentUrl,
      'fileName': ?fileName,
      'fileSize': ?fileSize,
      'mimeType': ?mimeType,
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
        'unreadForDoctor': FieldValue.increment(1),
      });
    } else {
      batch.update(consultationDocRef, {
        'lastMessageText': previewText,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderType': 'doctor',
        'unreadForPatient': FieldValue.increment(1),
      });
    }

    await batch.commit();
    debugPrint('[ConsultationService] Pesan $senderType berhasil dikirim via batch.');

    // Jika pengirim adalah pasien, cek apakah dokter punya akun nyata
    if (senderType == 'patient') {
      _checkAndTriggerSimulatedReply(
        consultationId: consultationId,
        doctorId: doctorId,
        patientText: trimmedText,
      );
    }
  }

  /// Mengirim pesan dari pasien (backward compatibility wrapper).
  Future<void> sendPatientMessage({
    required String consultationId,
    required String text,
    String type = 'text',
    String? attachmentUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? doctorId,
  }) async {
    await sendMessage(
      consultationId: consultationId,
      senderType: 'patient',
      text: text,
      type: type,
      attachmentUrl: attachmentUrl,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      doctorId: doctorId,
    );
  }

  /// [SIMULASI] Cek apakah dokter punya akun nyata.
  /// Jika dokter punya akun nyata (`uid` tidak kosong), balasan simulasi DIMATIKAN.
  Future<void> _checkAndTriggerSimulatedReply({
    required String consultationId,
    required String? doctorId,
    required String patientText,
  }) async {
    if (doctorId == null || doctorId.isEmpty) {
      _scheduleSimulatedDoctorReply(consultationId, patientText);
      return;
    }

    try {
      final doc = await _db.collection('doctors').doc(doctorId).get();
      if (doc.exists) {
        final doctorUid = doc.data()?['uid'] as String?;
        if (doctorUid != null && doctorUid.trim().isNotEmpty) {
          debugPrint('[ConsultationService] Dokter memiliki akun nyata (uid: $doctorUid). Simulasi auto-reply dinonaktifkan.');
          return;
        }
      }
    } catch (e) {
      debugPrint('[ConsultationService] Gagal cek akun dokter: $e');
    }

    // Fallback: jalankan simulasi jika dokter belum punya akun nyata
    _scheduleSimulatedDoctorReply(consultationId, patientText);
  }

  /// [SIMULASI] Mengirim balasan dokter otomatis setelah delay jika dokter belum punya akun nyata.
  void _scheduleSimulatedDoctorReply(String consultationId, String patientText) {
    Future.delayed(ConsultationConstants.doctorReplyDelay, () async {
      try {
        final messagesRef = _messagesRef(consultationId);
        final consultationDocRef = _consultationDocRef(consultationId);
        if (messagesRef == null || consultationDocRef == null) return;

        final replies = ConsultationConstants.simulatedDoctorReplies;
        final idx = _random.nextInt(replies.length);
        final replyText = replies[idx];

        final messageDoc = messagesRef.doc();
        final batch = _db.batch();
        batch.set(messageDoc, {
          'senderType': 'doctor',
          'text': replyText,
          'sentAt': FieldValue.serverTimestamp(),
          'type': 'text',
        });
        batch.update(consultationDocRef, {
          'lastMessageText': replyText,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessageSenderType': 'doctor',
          'unreadForPatient': FieldValue.increment(1),
        });
        await batch.commit();
        debugPrint('[ConsultationService] Balasan simulasi dokter terkirim via batch.');
      } catch (e) {
        debugPrint('[ConsultationService] Gagal kirim simulasi dokter: $e');
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

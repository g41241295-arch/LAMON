import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/consultation_constants.dart';
import '../models/consultation_model.dart';

/// Service untuk mengelola data konsultasi dan chat pada Firestore.
///
/// Struktur data:
/// ```
/// users/{uid}/consultations/{consultationId}   ← data booking
/// users/{uid}/consultations/{consultationId}/messages/{messageId}  ← chat
/// ```
class ConsultationService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final Random _random = Random();

  ConsultationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Referensi sub-koleksi consultations milik user yang sedang login.
  CollectionReference<Map<String, dynamic>>? get _consultationsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('consultations');
  }

  /// Referensi sub-koleksi messages dari satu konsultasi.
  CollectionReference<Map<String, dynamic>>? _messagesRef(String consultationId) {
    final uid = _uid;
    if (uid == null) return null;
    return _db
        .collection('users')
        .doc(uid)
        .collection('consultations')
        .doc(consultationId)
        .collection('messages');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOOKING & PAYMENT
  // ─────────────────────────────────────────────────────────────────────────

  /// Membuat dokumen konsultasi baru di Firestore.
  ///
  /// Menghasilkan nomor Virtual Account dan Order ID secara lokal (simulasi).
  /// TODO(payment-gateway): Ganti [_generateVA] dan [_generateOrderId] dengan
  /// data yang diterima dari response Midtrans/Xendit API setelah integrasi.
  ///
  /// Mengembalikan consultationId jika berhasil.
  Future<String> createConsultation({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required String scheduledTime,
    required int sessionFee,
    required String paymentMethod,
    required String paymentMethodName,
  }) async {
    final ref = _consultationsRef;
    if (ref == null) {
      throw Exception('User belum login. Silakan login terlebih dahulu.');
    }

    final now = DateTime.now();
    final orderId = _generateOrderId(now);
    final vaNumber = _generateVA(now);
    final deadline = now.add(ConsultationConstants.paymentDeadlineDuration);
    final totalFee = sessionFee + ConsultationConstants.serviceFee;

    final consultation = ConsultationModel(
      id: '', // akan diisi Firestore
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

  /// Mengambil data satu konsultasi berdasarkan ID.
  Future<ConsultationModel?> fetchById(String consultationId) async {
    try {
      final ref = _consultationsRef;
      if (ref == null) return null;
      final doc = await ref.doc(consultationId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ConsultationModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[ConsultationService] fetchById error: $e');
      return null;
    }
  }

  /// Menandai status pembayaran menjadi "paid" (SIMULASI).
  ///
  /// TODO(payment-gateway): Dalam implementasi sungguhan, status paid
  /// seharusnya di-update melalui webhook dari payment gateway (Midtrans/Xendit),
  /// bukan langsung dari client. Tambahkan Firebase Cloud Functions untuk
  /// menangani webhook tersebut.
  Future<void> markAsPaid(String consultationId) async {
    try {
      final ref = _consultationsRef;
      if (ref == null) throw Exception('User belum login.');
      await ref.doc(consultationId).update({
        'paymentStatus': PaymentStatus.paid.value,
      });
      debugPrint('[ConsultationService] Konsultasi $consultationId ditandai lunas.');
    } catch (e) {
      debugPrint('[ConsultationService] Gagal markAsPaid: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHAT
  // ─────────────────────────────────────────────────────────────────────────

  /// Stream realtime daftar pesan di satu sesi konsultasi,
  /// diurutkan dari yang paling lama (ascending).
  ///
  /// TODO(chat-realtime): Untuk chat real-time dokter sungguhan, ganti
  /// dengan Firebase Cloud Messaging atau WebSocket agar dokter dapat
  /// menerima notifikasi dan membalas dari perangkat mereka sendiri.
  Stream<List<ChatMessage>> watchMessages(String consultationId) {
    final ref = _messagesRef(consultationId);
    if (ref == null) return Stream.value(<ChatMessage>[]);

    return ref
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Mengirim pesan dari pasien ke Firestore.
  Future<void> sendPatientMessage({
    required String consultationId,
    required String text,
  }) async {
    final ref = _messagesRef(consultationId);
    if (ref == null) throw Exception('User belum login.');
    if (text.trim().isEmpty) return;

    final message = ChatMessage(
      id: '',
      senderType: 'patient',
      text: text.trim(),
      sentAt: DateTime.now(),
    );

    await ref.add(message.toFirestore());
    debugPrint('[ConsultationService] Pesan pasien terkirim.');

    // Trigger simulasi balasan dokter
    // TODO(chat-realtime): Hapus ini setelah integrasi dengan dokter sungguhan.
    _scheduleSimulatedDoctorReply(consultationId, text);
  }

  /// [SIMULASI] Mengirim balasan dokter otomatis setelah delay.
  ///
  /// TODO(chat-realtime): Hapus seluruh fungsi ini dan ganti dengan
  /// sistem notifikasi push ke perangkat dokter yang sesungguhnya.
  void _scheduleSimulatedDoctorReply(String consultationId, String patientText) {
    Future.delayed(ConsultationConstants.doctorReplyDelay, () async {
      try {
        final ref = _messagesRef(consultationId);
        if (ref == null) return;

        // Pilih reply secara semi-random berdasarkan konten pesan
        final replies = ConsultationConstants.simulatedDoctorReplies;
        final idx = _random.nextInt(replies.length);
        final replyText = replies[idx];

        final reply = ChatMessage(
          id: '',
          senderType: 'doctor',
          text: replyText,
          sentAt: DateTime.now(),
        );

        await ref.add(reply.toFirestore());
        debugPrint('[ConsultationService] Balasan simulasi dokter terkirim.');
      } catch (e) {
        debugPrint('[ConsultationService] Gagal kirim simulasi dokter: $e');
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Generate nomor Virtual Account simulasi.
  /// Format: {vaPrefix}{YYYYMMdd}{randomSuffix}
  ///
  /// TODO(payment-gateway): Hapus ini, gunakan VA dari response payment gateway.
  String _generateVA(DateTime now) {
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix = _random.nextInt(999).toString().padLeft(3, '0');
    return '${ConsultationConstants.vaPrefix} $datePart$suffix';
  }

  /// Generate Order ID simulasi.
  /// Format: LAMON-{YYYYMMddHHmm}-{random4digit}
  ///
  /// TODO(payment-gateway): Hapus ini, gunakan Order ID dari response payment gateway.
  String _generateOrderId(DateTime now) {
    final ts =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final rand = _random.nextInt(9999).toString().padLeft(4, '0');
    return 'LAMON-$ts-$rand';
  }
}

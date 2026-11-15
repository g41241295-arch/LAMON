import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/consultation_constants.dart';

/// Exception khusus jika ukuran lampiran melebihi kuota dokumen Firestore (Revisi 12).
class AttachmentSizeException implements Exception {
  final String message;
  final int maxBytes;
  final int actualBytes;

  AttachmentSizeException({
    required this.message,
    required this.maxBytes,
    required this.actualBytes,
  });

  @override
  String toString() => message;
}

/// Metadata lampiran yang disimpan di dokumen pesan Firestore (tanpa data base64).
class AttachmentMeta {
  final String attachmentId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  const AttachmentMeta({
    required this.attachmentId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });
}

/// Data lampiran lengkap beserta binary bytes hasil decode base64.
class AttachmentData {
  final String attachmentId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final Uint8List bytes;

  const AttachmentData({
    required this.attachmentId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.bytes,
  });
}

/// Layanan terisolasi untuk pengelolaan lampiran berkas / PDF chat di Firestore (Revisi 12).
///
/// Menggantikan Firebase Storage yang membutuhkan paket Blaze (berbayar).
/// Menyimpan isi berkas secara base64 di subkoleksi terpisah:
/// `users/{patientUid}/consultations/{cid}/attachments/{attachmentId}`
/// agar stream pesan `watchMessages` tidak ikut mengunduh binary berkas berukuran besar (hemat kuota Spark).
///
/// TODO(storage-migration):
/// Ketika proyek berpindah ke Firebase Blaze (berbayar), implementasi di dalam service ini
/// dapat dialihkan langsung ke Firebase Storage (misal: FirebaseStorage.instance.ref().putData)
/// dengan mengubah return value `saveAttachment` dan `loadAttachment` tanpa merombak UI ChatBubble
/// maupun alur percakapan lainnya.
class AttachmentService {
  AttachmentService._();
  static final AttachmentService instance = AttachmentService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _attachmentDocRef({
    required String patientUid,
    required String consultationId,
    required String attachmentId,
  }) {
    return _db
        .collection('users')
        .doc(patientUid.trim())
        .collection('consultations')
        .doc(consultationId.trim())
        .collection('attachments')
        .doc(attachmentId.trim());
  }

  /// Memvalidasi ukuran berkas dan menyimpan binary berkas sebagai base64
  /// di subkoleksi `attachments/{attachmentId}`.
  ///
  /// Melempar [AttachmentSizeException] jika ukuran melebihi [ConsultationConstants.kMaxAttachmentBytes].
  Future<AttachmentMeta> saveAttachment({
    required String patientUid,
    required String consultationId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String senderType, // 'patient' | 'doctor'
  }) async {
    final cleanUid = patientUid.trim();
    final cleanCid = consultationId.trim();
    if (cleanUid.isEmpty || cleanCid.isEmpty) {
      throw Exception('patientUid atau consultationId tidak valid.');
    }

    final int size = bytes.lengthInBytes;
    if (size > ConsultationConstants.kMaxAttachmentBytes) {
      final maxKb = (ConsultationConstants.kMaxAttachmentBytes / 1000).round();
      throw AttachmentSizeException(
        message: 'Ukuran file melebihi $maxKb KB. Kompres atau kirim file yang lebih kecil.',
        maxBytes: ConsultationConstants.kMaxAttachmentBytes,
        actualBytes: size,
      );
    }

    // Generate unique attachment ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rand = (timestamp % 9999).toString().padLeft(4, '0');
    final attachmentId = 'att_${timestamp}_$rand';

    // Encode to base64
    final base64String = base64Encode(bytes);

    final docRef = _attachmentDocRef(
      patientUid: cleanUid,
      consultationId: cleanCid,
      attachmentId: attachmentId,
    );

    await docRef.set({
      'data': base64String,
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': size,
      'senderType': senderType,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint(
        '[AttachmentService] Lampiran $attachmentId ($size bytes) disimpan di users/$cleanUid/consultations/$cleanCid/attachments.');

    return AttachmentMeta(
      attachmentId: attachmentId,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: size,
    );
  }

  /// Mengunduh dan mendecode binary berkas hanya saat diminta (on-demand) oleh pengguna.
  /// Mengembalikan `null` jika dokumen tidak ditemukan atau berkas telah dikosongkan.
  Future<AttachmentData?> loadAttachment({
    required String patientUid,
    required String consultationId,
    required String attachmentId,
  }) async {
    final cleanUid = patientUid.trim();
    final cleanCid = consultationId.trim();
    final cleanAid = attachmentId.trim();

    if (cleanUid.isEmpty || cleanCid.isEmpty || cleanAid.isEmpty) {
      return null;
    }

    try {
      final docRef = _attachmentDocRef(
        patientUid: cleanUid,
        consultationId: cleanCid,
        attachmentId: cleanAid,
      );

      final snap = await docRef.get();
      if (!snap.exists) return null;

      final data = snap.data();
      if (data == null) return null;

      final base64String = data['data'] as String?;
      if (base64String == null || base64String.trim().isEmpty) {
        return null; // Telah dihapus untuk semua orang
      }

      final bytes = base64Decode(base64String.trim());
      final fileName = data['fileName'] as String? ?? 'Dokumen.pdf';
      final mimeType = data['mimeType'] as String? ?? 'application/pdf';
      final sizeBytes = (data['sizeBytes'] as num?)?.toInt() ?? bytes.lengthInBytes;

      return AttachmentData(
        attachmentId: cleanAid,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        bytes: bytes,
      );
    } catch (e) {
      debugPrint('[AttachmentService] Gagal loadAttachment $cleanAid: $e');
      rethrow;
    }
  }

  /// Mengosongkan isi file di dokumen attachment saat pesan dihapus untuk semua orang (Revisi 9 & 12).
  Future<void> clearAttachmentData({
    required String patientUid,
    required String consultationId,
    required String attachmentId,
  }) async {
    final cleanUid = patientUid.trim();
    final cleanCid = consultationId.trim();
    final cleanAid = attachmentId.trim();

    if (cleanUid.isEmpty || cleanCid.isEmpty || cleanAid.isEmpty) {
      return;
    }

    try {
      final docRef = _attachmentDocRef(
        patientUid: cleanUid,
        consultationId: cleanCid,
        attachmentId: cleanAid,
      );

      await docRef.update({
        'data': '',
      });
      debugPrint('[AttachmentService] Konten lampiran $cleanAid berhasil dikosongkan.');
    } catch (e) {
      debugPrint('[AttachmentService] Gagal clearAttachmentData $cleanAid: $e');
    }
  }
}

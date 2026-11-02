import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoService {
  /// Memilih foto menggunakan [ImagePicker], mengompresi, mengonversi ke Base64,
  /// dan menyimpannya langsung ke dokumen Firestore [collection]/[docId].
  ///
  /// - [maxWidth]: 400, [maxHeight]: 400, [imageQuality]: 70
  /// - Menolak gambar jika ukurannya melebihi 300 KB
  /// - Field tersimpan: 'photoBase64' dan 'photoUpdatedAt' (serverTimestamp)
  /// - [docId] default: UID pengguna yang sedang login di FirebaseAuth
  /// - Mengembalikan String Base64 jika sukses, atau null jika pemilihan dibatalkan.
  static Future<String?> pickAndSave({
    required String collection,
    String? docId,
    ImageSource source = ImageSource.gallery,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 70,
    );

    if (picked == null) {
      return null;
    }

    final bytes = await picked.readAsBytes();

    // Validasi ukuran: tolak jika > 300 KB
    if (bytes.lengthInBytes > 300 * 1024) {
      throw Exception('Ukuran foto terlalu besar (maksimal 300 KB).');
    }

    final targetDocId = (docId != null && docId.trim().isNotEmpty)
        ? docId.trim()
        : FirebaseAuth.instance.currentUser?.uid;

    if (targetDocId == null || targetDocId.isEmpty) {
      throw Exception('ID dokumen tidak ditemukan atau pengguna belum login.');
    }

    final b64 = base64Encode(bytes);

    await FirebaseFirestore.instance.collection(collection).doc(targetDocId).set({
      'photoBase64': b64,
      'photoUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return b64;
  }

  /// Menghapus foto profil dari dokumen Firestore [collection]/[docId].
  ///
  /// Menghapus field 'photoBase64' dan memperbarui 'photoUpdatedAt'.
  /// [docId] default: UID pengguna yang sedang login di FirebaseAuth.
  static Future<void> deletePhoto({
    required String collection,
    String? docId,
  }) async {
    final targetDocId = (docId != null && docId.trim().isNotEmpty)
        ? docId.trim()
        : FirebaseAuth.instance.currentUser?.uid;

    if (targetDocId == null || targetDocId.isEmpty) {
      throw Exception('ID dokumen tidak ditemukan atau pengguna belum login.');
    }

    await FirebaseFirestore.instance
        .collection(collection)
        .doc(targetDocId)
        .set({
      'photoBase64': FieldValue.delete(),
      'photoUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Mengembalikan [MemoryImage] dari string Base64 [b64], atau null jika kosong/tidak valid.
  static MemoryImage? provider(String? b64) {
    if (b64 == null) return null;
    final trimmed = b64.trim();
    if (trimmed.isEmpty) return null;

    try {
      final clean = trimmed.contains(',') ? trimmed.split(',').last.trim() : trimmed;
      final bytes = base64Decode(clean);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint('[ProfilePhotoService] Gagal decode base64: $e');
      return null;
    }
  }
}

/// Widget universal untuk menampilkan avatar di Beranda/Header secara real-time
/// membaca field `photoBase64` dari dokumen Firestore [collection]/[docId].
///
/// Jika belum ada foto atau Base64 tidak valid, menampilkan widget [fallback].
/// Menggunakan `gaplessPlayback: true` agar gambar tidak berkedip saat refresh.
class RealtimeHeaderAvatar extends StatelessWidget {
  final String collection;
  final String docId;
  final double size;
  final double borderRadius;
  final Widget fallback;

  const RealtimeHeaderAvatar({
    super.key,
    required this.collection,
    required this.docId,
    this.size = 28,
    this.borderRadius = 14,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (docId.trim().isEmpty) return fallback;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .doc(docId.trim())
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return fallback;
        }

        final data = snapshot.data!.data();
        final b64 = data?['photoBase64']?.toString().trim();
        if (b64 == null || b64.isEmpty) {
          return fallback;
        }

        try {
          final clean = b64.contains(',') ? b64.split(',').last.trim() : b64;
          final bytes = base64Decode(clean);
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: SizedBox(
              width: size,
              height: size,
              child: Image.memory(
                bytes,
                width: size,
                height: size,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => fallback,
              ),
            ),
          );
        } catch (e) {
          debugPrint('[RealtimeHeaderAvatar] Gagal decode base64: $e');
          return fallback;
        }
      },
    );
  }
}

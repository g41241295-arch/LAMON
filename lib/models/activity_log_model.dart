import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String aksi; // "tambah", "ubah", "hapus"
  final String modul; // "ensiklopedia"
  final String judul;
  final String oleh;
  final String olehId;
  final DateTime? createdAt; // nullable karena bisa serverTimestamp saat ditulis

  ActivityLogModel({
    required this.id,
    required this.aksi,
    required this.modul,
    required this.judul,
    required this.oleh,
    required this.olehId,
    this.createdAt,
  });

  factory ActivityLogModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ActivityLogModel(
      id: doc.id,
      aksi: data['aksi'] ?? '',
      modul: data['modul'] ?? '',
      judul: data['judul'] ?? '',
      oleh: data['oleh'] ?? '',
      olehId: data['olehId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'aksi': aksi,
      'modul': modul,
      'judul': judul,
      'oleh': oleh,
      'olehId': olehId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

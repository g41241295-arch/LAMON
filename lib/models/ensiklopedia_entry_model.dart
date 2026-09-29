import 'package:cloud_firestore/cloud_firestore.dart';

class EnsiklopediaEntry {
  final String id;
  final String istilah;
  final String istilahLower;
  final String? namaLain;
  final String definisiSingkat;
  final String penjelasanLengkap;
  final String kategori;
  final String? referensi;
  
  final String createdBy;
  final String createdById;
  final String createdByType; // "admin", "dokter", "redaksi"
  final DateTime createdAt;
  
  final String? updatedBy;
  final String? updatedById;
  final DateTime? updatedAt;

  EnsiklopediaEntry({
    required this.id,
    required this.istilah,
    required this.istilahLower,
    this.namaLain,
    required this.definisiSingkat,
    required this.penjelasanLengkap,
    required this.kategori,
    this.referensi,
    required this.createdBy,
    required this.createdById,
    required this.createdByType,
    required this.createdAt,
    this.updatedBy,
    this.updatedById,
    this.updatedAt,
  });

  factory EnsiklopediaEntry.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EnsiklopediaEntry(
      id: doc.id,
      istilah: data['istilah'] ?? '',
      istilahLower: data['istilahLower'] ?? '',
      namaLain: data['namaLain'],
      definisiSingkat: data['definisiSingkat'] ?? '',
      penjelasanLengkap: data['penjelasanLengkap'] ?? '',
      kategori: data['kategori'] ?? '',
      referensi: data['referensi'],
      createdBy: data['createdBy'] ?? '',
      createdById: data['createdById'] ?? '',
      createdByType: data['createdByType'] ?? 'admin',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy'],
      updatedById: data['updatedById'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'istilah': istilah,
      'istilahLower': istilahLower,
      'namaLain': namaLain,
      'definisiSingkat': definisiSingkat,
      'penjelasanLengkap': penjelasanLengkap,
      'kategori': kategori,
      'referensi': referensi,
      'createdBy': createdBy,
      'createdById': createdById,
      'createdByType': createdByType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedBy': updatedBy,
      'updatedById': updatedById,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

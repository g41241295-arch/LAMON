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

  // Field baru untuk integrasi Gastropedia pengguna
  final String status; // 'terbit' | 'draft'
  final String? imageAsset;
  final List<String> manfaat;
  final List<String> kandungan;
  final bool isRecommended;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

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
    this.status = 'terbit',
    this.imageAsset,
    this.manfaat = const [],
    this.kandungan = const [],
    this.isRecommended = false,
    this.calories = 150,
    this.protein = 6,
    this.carbs = 18,
    this.fat = 6,
  });

  factory EnsiklopediaEntry.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final Map<String, dynamic> data = (raw is Map<String, dynamic>)
        ? raw
        : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});

    List<String> parseStringList(dynamic val) {
      if (val is Iterable) {
        return val.where((e) => e != null).map((e) => e.toString()).toList();
      }
      return [];
    }

    return EnsiklopediaEntry(
      id: doc.id,
      istilah: data['istilah']?.toString() ?? '',
      istilahLower: data['istilahLower']?.toString() ?? (data['istilah']?.toString().toLowerCase() ?? ''),
      namaLain: data['namaLain']?.toString(),
      definisiSingkat: data['definisiSingkat']?.toString() ?? '',
      penjelasanLengkap: data['penjelasanLengkap']?.toString() ?? '',
      kategori: data['kategori']?.toString() ?? 'Makanan',
      referensi: data['referensi']?.toString(),
      createdBy: data['createdBy']?.toString() ?? '',
      createdById: data['createdById']?.toString() ?? '',
      createdByType: data['createdByType']?.toString() ?? 'admin',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy']?.toString(),
      updatedById: data['updatedById']?.toString(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      status: data['status']?.toString() ?? 'terbit',
      imageAsset: data['imageAsset']?.toString() ?? data['imageUrl']?.toString(),
      manfaat: parseStringList(data['manfaat']),
      kandungan: parseStringList(data['kandungan']),
      isRecommended: data['isRecommended'] == true,
      calories: (data['calories'] is num) ? (data['calories'] as num).toInt() : 150,
      protein: (data['protein'] is num) ? (data['protein'] as num).toInt() : 6,
      carbs: (data['carbs'] is num) ? (data['carbs'] as num).toInt() : 18,
      fat: (data['fat'] is num) ? (data['fat'] as num).toInt() : 6,
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
      'status': status,
      'imageAsset': imageAsset ?? '',
      'manfaat': manfaat,
      'kandungan': kandungan,
      'isRecommended': isRecommended,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model jam operasional dokter.
class OperatingHour {
  final String start; // format "07.00"
  final String end;   // format "11.00"

  const OperatingHour({required this.start, required this.end});

  String get display => '$start - $end';

  Map<String, dynamic> toMap() => {'start': start, 'end': end};

  factory OperatingHour.fromMap(Map<String, dynamic> map) {
    return OperatingHour(
      start: map['start'] as String? ?? '',
      end: map['end'] as String? ?? '',
    );
  }
}

/// Model untuk data dokter dari koleksi Firestore `doctors/{doctorId}`.
///
/// Struktur Firestore:
/// ```
/// doctors/{doctorId} {
///   name: String,
///   specialty: String,        // mis. "Dokter Umum"
///   experienceYears: Number,
///   photoUrl: String,         // URL foto atau string kosong untuk avatar generik
///   price: Number,            // harga konsultasi dalam Rupiah
///   operatingHours: Array<{start: String, end: String}>,
///   alumni: String,           // nama universitas
///   practiceLocation: String, // nama rumah sakit / klinik
///   strNumber: String,        // nomor STR
///   isRecommended: Boolean,
///   uid: String?,             // Auth UID dokter jika sudah punya akun nyata
///   gender: String?,          // "Laki-laki" | "Perempuan"
///   updatedAt: Timestamp?,
/// }
/// ```
class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final int experienceYears;
  final String photoUrl;
  final int price;
  final List<OperatingHour> operatingHours;
  final String alumni;
  final String practiceLocation;
  final String strNumber;
  final bool isRecommended;
  final String? uid;
  final String? gender;
  final DateTime? updatedAt;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.experienceYears,
    required this.photoUrl,
    required this.price,
    required this.operatingHours,
    required this.alumni,
    required this.practiceLocation,
    required this.strNumber,
    required this.isRecommended,
    this.uid,
    this.gender,
    this.updatedAt,
  });

  /// Formatted specialty + experience string untuk tampilan kartu.
  String get specialtyDisplay => '$specialty • $experienceYears tahun';

  /// Jam operasional pertama untuk ditampilkan di kartu.
  OperatingHour? get primaryHour =>
      operatingHours.isNotEmpty ? operatingHours.first : null;

  /// Nama dokter dengan prefiks "dr." hanya jika belum memilikinya.
  String get formattedNameWithDoctorTitle {
    final trimmed = name.trim();
    if (trimmed.toLowerCase().startsWith('dr.') ||
        trimmed.toLowerCase().startsWith('dr ')) {
      return trimmed;
    }
    return 'dr. $trimmed';
  }

  /// URL atau path asset foto dokter lokal sebagai fallback jika photoUrl di DB kosong
  String get effectivePhotoUrl {
    if (photoUrl.trim().isNotEmpty) return photoUrl.trim();
    final lowerId = id.toLowerCase();
    final lowerName = name.toLowerCase();
    if (lowerId.contains('ketut') || lowerName.contains('ketut')) {
      return 'assets/images/doctors/Ketut Maulana.jpg';
    }
    if (lowerId.contains('oggy') || lowerName.contains('oggy')) {
      return 'assets/images/doctors/Oggy Agustin.jpg';
    }
    if (lowerId.contains('dandi') || lowerName.contains('dandi')) {
      return 'assets/images/doctors/Dandi Wijaya.jpg';
    }
    return '';
  }

  DoctorModel copyWith({
    String? id,
    String? name,
    String? specialty,
    int? experienceYears,
    String? photoUrl,
    int? price,
    List<OperatingHour>? operatingHours,
    String? alumni,
    String? practiceLocation,
    String? strNumber,
    bool? isRecommended,
    String? uid,
    String? gender,
    DateTime? updatedAt,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      experienceYears: experienceYears ?? this.experienceYears,
      photoUrl: photoUrl ?? this.photoUrl,
      price: price ?? this.price,
      operatingHours: operatingHours ?? this.operatingHours,
      alumni: alumni ?? this.alumni,
      practiceLocation: practiceLocation ?? this.practiceLocation,
      strNumber: strNumber ?? this.strNumber,
      isRecommended: isRecommended ?? this.isRecommended,
      uid: uid ?? this.uid,
      gender: gender ?? this.gender,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DoctorModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawHours = data['operatingHours'] as List<dynamic>? ?? [];
    return DoctorModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      specialty: data['specialty'] as String? ?? '',
      experienceYears: (data['experienceYears'] as num?)?.toInt() ?? 0,
      photoUrl: data['photoUrl'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      operatingHours: rawHours
          .map((h) => OperatingHour.fromMap(h as Map<String, dynamic>))
          .toList(),
      alumni: data['alumni'] as String? ?? '',
      practiceLocation: data['practiceLocation'] as String? ?? '',
      strNumber: data['strNumber'] as String? ?? '',
      isRecommended: data['isRecommended'] as bool? ?? false,
      uid: data['uid'] as String?,
      gender: data['gender'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'specialty': specialty,
        'experienceYears': experienceYears,
        'photoUrl': photoUrl,
        'price': price,
        'operatingHours': operatingHours.map((h) => h.toMap()).toList(),
        'alumni': alumni,
        'practiceLocation': practiceLocation,
        'strNumber': strNumber,
        'isRecommended': isRecommended,
        if (uid != null) 'uid': uid,
        if (gender != null) 'gender': gender,
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      };
}

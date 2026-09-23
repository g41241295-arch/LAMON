import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/doctor_model.dart';

/// Service untuk mengakses data dokter dari koleksi Firestore `doctors`.
///
/// Koleksi `doctors` bersifat read-only dari sisi client user biasa
/// (sesuai Firestore rules). Penulisan/pengeditan data dilakukan
/// melalui Firebase Console atau Admin SDK.
class DoctorService {
  final FirebaseFirestore _db;

  DoctorService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _doctorsRef =>
      _db.collection('doctors');

  /// Stream realtime daftar semua dokter, diurutkan berdasarkan nama.
  Stream<List<DoctorModel>> watchAll() {
    return _doctorsRef.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((doc) => DoctorModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream realtime daftar dokter yang direkomendasikan (`isRecommended == true`).
  Stream<List<DoctorModel>> watchRecommended() {
    return _doctorsRef
        .where('isRecommended', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => DoctorModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Mengambil satu dokter berdasarkan ID.
  Future<DoctorModel?> fetchById(String doctorId) async {
    try {
      final doc = await _doctorsRef.doc(doctorId).get();
      if (!doc.exists || doc.data() == null) return null;
      return DoctorModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[DoctorService] fetchById error: $e');
      return null;
    }
  }

  /// [DEBUG ONLY] Mengisi koleksi `doctors` dengan data seed 3 dokter contoh.
  ///
  /// Fungsi ini HANYA bisa dipanggil saat `kDebugMode == true`.
  /// JANGAN dipanggil di production build.
  /// Jalankan sekali saat pertama kali setup development environment.
  ///
  /// TODO(payment-gateway): Saat integrasi dengan sistem dokter sungguhan,
  /// hapus seed ini dan gunakan sistem manajemen dokter dari admin panel.
  Future<void> seedDoctors() async {
    assert(kDebugMode, 'seedDoctors() hanya boleh dipanggil saat kDebugMode!');
    if (!kDebugMode) return;

    debugPrint('[DoctorService] Memulai seed data dokter...');

    final seedData = [
      DoctorModel(
        id: 'dr_ketut_maulana',
        name: 'Dr. Ketut Maulana',
        specialty: 'Dokter Umum',
        experienceYears: 8,
        photoUrl: '', // Gunakan avatar generik di UI
        price: 50000,
        operatingHours: const [
          OperatingHour(start: '07.00', end: '11.00'),
          OperatingHour(start: '14.00', end: '17.00'),
        ],
        alumni: 'Universitas Udayana',
        practiceLocation: 'RS Sanglah Denpasar',
        strNumber: '3217/A/KKI/2018',
        isRecommended: true,
      ),
      DoctorModel(
        id: 'dr_oggy_agustin',
        name: 'Dr. Oggy Agustin',
        specialty: 'Spesialis Penyakit Dalam',
        experienceYears: 12,
        photoUrl: '',
        price: 75000,
        operatingHours: const [
          OperatingHour(start: '08.00', end: '12.00'),
          OperatingHour(start: '15.00', end: '18.00'),
        ],
        alumni: 'Universitas Indonesia',
        practiceLocation: 'RS Cipto Mangunkusumo',
        strNumber: '4521/B/KKI/2014',
        isRecommended: true,
      ),
      DoctorModel(
        id: 'dr_dandi_wijaya',
        name: 'Dr. Dandi Wijaya',
        specialty: 'Dokter Umum',
        experienceYears: 5,
        photoUrl: '',
        price: 45000,
        operatingHours: const [
          OperatingHour(start: '09.00', end: '13.00'),
        ],
        alumni: 'Universitas Gadjah Mada',
        practiceLocation: 'Klinik Sehat Sentosa',
        strNumber: '6789/C/KKI/2021',
        isRecommended: true,
      ),
    ];

    final batch = _db.batch();
    for (final doctor in seedData) {
      final ref = _doctorsRef.doc(doctor.id);
      batch.set(ref, doctor.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint('[DoctorService] Seed selesai — ${seedData.length} dokter berhasil ditambahkan.');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/consultation_model.dart';
import '../models/doctor_model.dart';

/// Service untuk mengelola data dan operasi dokter:
/// - Daftar dan detail dokter untuk pasien (watchAll, watchRecommended, fetchById)
/// - Profil dokter
/// - Jadwal praktik (doctors/{doctorId}/schedule/{yyyy-MM-dd})
/// - Konsultasi pasien via collection group 'consultations'
class DoctorService {
  final FirebaseFirestore _db;

  DoctorService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _doctorsRef =>
      _db.collection('doctors');

  /// Stream realtime seluruh data dokter, diurutkan berdasarkan nama.
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

  /// Mengambil data dokter berdasarkan doctorId (alias untuk fetchById).
  Future<DoctorModel?> getDoctorById(String doctorId) => fetchById(doctorId);

  /// Mengambil data dokter untuk user login saat ini:
  /// 1. Cek field `doctorId` di `users/{uid}`
  /// 2. Jika tidak ada, coba query `doctors` where `uid == uid`
  Future<DoctorModel?> getDoctorForUser(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final doctorId = userDoc.data()?['doctorId'] as String?;
        if (doctorId != null && doctorId.isNotEmpty) {
          final doc = await fetchById(doctorId);
          if (doc != null) return doc;
        }
      }

      // Fallback: cari di koleksi doctors where uid == uid
      final query = await _db
          .collection('doctors')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return DoctorModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('[DoctorService] getDoctorForUser error: $e');
      return null;
    }
  }

  /// Stream live daftar konsultasi pasien untuk dokter tertentu
  /// menggunakan collection group query: `consultations` where `doctorId == doctorId`.
  ///
  /// Diurutkan di sisi klien untuk menghindari kebutuhan composite index.
  Stream<List<ConsultationModel>> watchDoctorConsultations(String doctorId) {
    if (doctorId.isEmpty) return Stream.value(<ConsultationModel>[]);

    return _db
        .collectionGroup('consultations')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => ConsultationModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      // Urutkan terbaru: lastMessageAt ?? createdAt descending
      list.sort((a, b) {
        final timeA = a.lastMessageAt ?? a.createdAt;
        final timeB = b.lastMessageAt ?? b.createdAt;
        return timeB.compareTo(timeA);
      });

      return list;
    });
  }

  /// Konfirmasi konsultasi oleh dokter:
  /// Ubah status menjadi 'active' dan isi 'doctorConfirmedAt'.
  Future<void> confirmConsultation({
    required String patientUid,
    required String consultationId,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(patientUid)
          .collection('consultations')
          .doc(consultationId)
          .update({
        'status': 'active',
        'doctorConfirmedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[DoctorService] Konsultasi $consultationId dikonfirmasi dokter.');
    } catch (e) {
      debugPrint('[DoctorService] Gagal confirmConsultation: $e');
      rethrow;
    }
  }

  /// Stream jadwal bulanan dokter:
  /// Mengembalikan Map berformat { '2026-09-28': ['pagi', 'malam'] }
  Stream<Map<String, List<String>>> watchMonthlySchedule(
      String doctorId, int year, int month) {
    if (doctorId.isEmpty) return Stream.value({});

    final monthStr = month.toString().padLeft(2, '0');
    final startKey = '$year-$monthStr-01';
    final endKey = '$year-$monthStr-31';

    return _db
        .collection('doctors')
        .doc(doctorId)
        .collection('schedule')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
        .snapshots()
        .map((snap) {
      final map = <String, List<String>>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final rawSlots = data['slots'] as List<dynamic>? ?? [];
        map[doc.id] = rawSlots.map((s) => s.toString()).toList();
      }
      return map;
    });
  }

  /// Menyimpan jadwal praktik untuk satu tanggal (yyyy-MM-dd).
  /// Jika [slotIds] kosong, dokumen jadwal tanggal tersebut dihapus (hari libur).
  Future<void> saveSchedule({
    required String doctorId,
    required String dateKey, // "yyyy-MM-dd"
    required DateTime date,
    required List<String> slotIds,
  }) async {
    final docRef = _db
        .collection('doctors')
        .doc(doctorId)
        .collection('schedule')
        .doc(dateKey);

    try {
      if (slotIds.isEmpty) {
        await docRef.delete();
        debugPrint('[DoctorService] Jadwal $dateKey dihapus (libur).');
      } else {
        await docRef.set({
          'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
          'slots': slotIds,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('[DoctorService] Jadwal $dateKey disimpan: $slotIds');
      }
    } catch (e) {
      debugPrint('[DoctorService] Gagal saveSchedule: $e');
      rethrow;
    }
  }

  /// Memperbarui profil dokter: nama, strNumber, gender (+ updatedAt).
  Future<void> updateDoctorProfile({
    required String doctorId,
    required String name,
    required String strNumber,
    String? gender,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Nama dokter tidak boleh kosong.');
    }

    try {
      final data = <String, dynamic>{
        'name': trimmedName,
        'strNumber': strNumber.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (gender != null && gender.isNotEmpty) {
        data['gender'] = gender;
      }

      await _db.collection('doctors').doc(doctorId).update(data);
      debugPrint('[DoctorService] Profil dokter $doctorId berhasil diperbarui.');
    } catch (e) {
      debugPrint('[DoctorService] Gagal updateDoctorProfile: $e');
      rethrow;
    }
  }

  /// [DEBUG ONLY] Mengisi koleksi `doctors` dengan data seed 3 dokter contoh.
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
        photoUrl: '',
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

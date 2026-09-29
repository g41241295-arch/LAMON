import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ensiklopedia_entry_model.dart';
import '../models/activity_log_model.dart';
import '../utils/app_exception.dart';

class EnsiklopediaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<EnsiklopediaEntry>> streamEnsiklopedia() {
    return _firestore
        .collection('encyclopedia')
        .orderBy('istilahLower')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnsiklopediaEntry.fromFirestore(doc))
            .toList());
  }

  Stream<List<ActivityLogModel>> streamRecentActivity() {
    return _firestore
        .collection('activity_log')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityLogModel.fromFirestore(doc))
            .toList());
  }

  String _generateDocId(String istilahLower) {
    // Ganti spasi, karakter non-alphanumeric selain underscore/hyphen agar aman jadi ID
    return istilahLower.replaceAll(RegExp(r'[^a-z0-9\-_]+'), '_').replaceAll(RegExp(r'_+'), '_');
  }

  Future<void> createEntry(EnsiklopediaEntry entry, String adminName, String adminId) async {
    final docId = _generateDocId(entry.istilahLower);
    final docRef = _firestore.collection('encyclopedia').doc(docId);
    final logRef = _firestore.collection('activity_log').doc();
    
    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);
      if (docSnapshot.exists) {
        throw AppException("Istilah medis ini sudah terdaftar.");
      }

      final entryToSave = EnsiklopediaEntry(
        id: docId,
        istilah: entry.istilah,
        istilahLower: entry.istilahLower,
        namaLain: entry.namaLain,
        definisiSingkat: entry.definisiSingkat,
        penjelasanLengkap: entry.penjelasanLengkap,
        kategori: entry.kategori,
        referensi: entry.referensi,
        createdBy: entry.createdBy,
        createdById: entry.createdById,
        createdByType: entry.createdByType,
        createdAt: entry.createdAt,
      );
      transaction.set(docRef, entryToSave.toFirestore());

      final log = ActivityLogModel(
        id: logRef.id,
        aksi: 'tambah',
        modul: 'ensiklopedia',
        judul: entry.istilah,
        oleh: adminName,
        olehId: adminId,
        createdAt: null, // Akan menjadi serverTimestamp
      );
      transaction.set(logRef, log.toFirestore());
    });
  }

  // Mengembalikan ID dokumen baru jika berubah
  Future<String> updateEntry(String oldId, EnsiklopediaEntry updatedEntry, String adminName, String adminId) async {
    final oldDocRef = _firestore.collection('encyclopedia').doc(oldId);
    final newDocId = _generateDocId(updatedEntry.istilahLower);
    final newDocRef = _firestore.collection('encyclopedia').doc(newDocId);
    final logRef = _firestore.collection('activity_log').doc();

    await _firestore.runTransaction((transaction) async {
      final oldSnapshot = await transaction.get(oldDocRef);
      if (!oldSnapshot.exists) {
        throw AppException("Entri yang akan diubah tidak ditemukan.");
      }

      if (oldId != newDocId) {
        final newSnapshot = await transaction.get(newDocRef);
        if (newSnapshot.exists) {
          throw AppException("Istilah medis ini sudah terdaftar pada entri lain.");
        }
      }

      final oldData = oldSnapshot.data()!;
      final entryToSave = EnsiklopediaEntry(
        id: newDocId,
        istilah: updatedEntry.istilah,
        istilahLower: updatedEntry.istilahLower,
        namaLain: updatedEntry.namaLain,
        definisiSingkat: updatedEntry.definisiSingkat,
        penjelasanLengkap: updatedEntry.penjelasanLengkap,
        kategori: updatedEntry.kategori,
        referensi: updatedEntry.referensi,
        createdBy: oldData['createdBy'] ?? '',
        createdById: oldData['createdById'] ?? '',
        createdByType: oldData['createdByType'] ?? 'admin',
        createdAt: (oldData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedBy: adminName,
        updatedById: adminId,
        updatedAt: DateTime.now(),
      );

      if (oldId != newDocId) {
        transaction.set(newDocRef, entryToSave.toFirestore());
        transaction.delete(oldDocRef);
      } else {
        transaction.update(oldDocRef, entryToSave.toFirestore());
      }

      final log = ActivityLogModel(
        id: logRef.id,
        aksi: 'ubah',
        modul: 'ensiklopedia',
        judul: updatedEntry.istilah,
        oleh: adminName,
        olehId: adminId,
        createdAt: null,
      );
      transaction.set(logRef, log.toFirestore());
    });
    return newDocId;
  }

  Future<void> deleteEntry(String entryId, String istilah, String adminName, String adminId) async {
    final docRef = _firestore.collection('encyclopedia').doc(entryId);
    final logRef = _firestore.collection('activity_log').doc();
    
    final batch = _firestore.batch();
    
    batch.delete(docRef);
    
    final log = ActivityLogModel(
      id: logRef.id,
      aksi: 'hapus',
      modul: 'ensiklopedia',
      judul: istilah,
      oleh: adminName,
      olehId: adminId,
      createdAt: null,
    );
    batch.set(logRef, log.toFirestore());
    
    await batch.commit();
  }

  Future<void> seedData() async {
    if (!kDebugMode) return;

    final batch = _firestore.batch();
    
    final List<Map<String, dynamic>> initialData = [
      {
        'id': _generateDocId('gerd'),
        'istilah': 'GERD',
        'istilahLower': 'gerd',
        'namaLain': 'Asam Lambung naik',
        'definisiSingkat': 'Kondisi ketika asam lambung naik berulang kali ke kerongkongan, menyebabkan iritasi dan gejala kronis.',
        'penjelasanLengkap': 'GERD (Gastroesophageal Reflux Disease) berbeda dari maag biasa karena bersifat kronis dan berulang. Kondisi ini terjadi ketika LES melemah dan tidak menutup rapat.',
        'kategori': 'Pencernaan',
        'referensi': '',
        'createdBy': 'Nadia W.',
        'createdById': 'seed_admin_1',
        'createdByType': 'admin',
        'createdAt': Timestamp.now(),
        'updatedBy': 'Nadia W.',
        'updatedById': 'seed_admin_1',
        'updatedAt': Timestamp.now(),
      },
      {
        'id': _generateDocId('heartburn'),
        'istilah': 'Heartburn',
        'istilahLower': 'heartburn',
        'namaLain': 'Rasa terbakar dada',
        'definisiSingkat': 'Heartburn adalah sensasi panas atau terbakar di dada yang terjadi akibat naiknya asam lambung ke kerongkongan (refluks asam).',
        'penjelasanLengkap': 'Heartburn terjadi dikarenakan adanya katup berbentuk cincin otot di bagian bawah kerongkongan yang disebut sfingter esofagus bawah (LES). Katup ini berfungsi mencegah isi lambung naik kembali ke atas.',
        'kategori': 'Pencernaan',
        'referensi': '',
        'createdBy': 'dr. Ahmad Yusran, Sp.PD',
        'createdById': 'seed_doctor_1',
        'createdByType': 'dokter',
        'createdAt': Timestamp.now(),
      },
      {
        'id': _generateDocId('les (lower esophageal sphincter)'),
        'istilah': 'LES (Lower Esophageal Sphincter)',
        'istilahLower': 'les (lower esophageal sphincter)',
        'namaLain': 'Katup lambung',
        'definisiSingkat': 'LES adalah otot cincin yang berada di ujung bawah kerongkongan, tempat kerongkongan bertemu dengan lambung.',
        'penjelasanLengkap': 'LES berperan penting dalam mencegah asam lambung dan isi lambung lainnya kembali naik ke kerongkongan. Kegagalan fungsi LES dapat menyebabkan kondisi seperti penyakit refluks gastroesofageal (GERD).',
        'kategori': 'Pencernaan',
        'referensi': '',
        'createdBy': 'Redaksi Holodoc',
        'createdById': 'seed_redaksi_1',
        'createdByType': 'redaksi',
        'createdAt': Timestamp.now(),
      },
    ];

    for (var data in initialData) {
      final docRef = _firestore.collection('encyclopedia').doc(data['id']);
      Map<String, dynamic> dataToSave = Map.from(data)..remove('id');
      batch.set(docRef, dataToSave);
    }

    await batch.commit();
  }
}


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/berita_article_model.dart';
import '../../models/activity_log_model.dart';
import '../../utils/app_exception.dart';
import 'berita_repository.dart';

/// Service CRUD artikel berita ke Firestore collection `berita_articles`
/// dan Firebase Storage path `berita/`.
class BeritaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _collection = 'berita_articles';
  static const String _metaCollection = 'meta';
  static const String _seedDoc = 'berita_seed';

  // ── Penanda Seeding ────────────────────────────────────────────────────────

  /// Cek apakah proses seeding awal sudah pernah dilakukan
  Future<bool> hasSeeded() async {
    try {
      final doc = await _firestore.collection(_metaCollection).doc(_seedDoc).get();
      return doc.exists;
    } catch (e) {
      debugPrint('[BeritaService] Cek hasSeeded error: $e');
      return false;
    }
  }

  /// Tandai bahwa seeding sudah selesai dilakukan
  Future<void> markSeeded() async {
    try {
      await _firestore.collection(_metaCollection).doc(_seedDoc).set({
        'seededAt': FieldValue.serverTimestamp(),
        'version': 1,
        'itemCount': 9,
      }, SetOptions(merge: true));
      debugPrint('[BeritaService] Penanda meta/berita_seed berhasil disimpan.');
    } catch (e) {
      debugPrint('[BeritaService] Gagal menulis penanda seeding: $e');
    }
  }

  // ── Seeding Otomatis & Pemulihan Berita Bawaan ──────────────────────────────

  /// Jalankan seeding otomatis hanya jika penanda meta/berita_seed belum ada.
  /// Hanya menambahkan dokumen yang belum ada (tidak menimpa artikel yang sudah ada).
  Future<void> ensureAutoSeeded() async {
    try {
      final alreadySeeded = await hasSeeded();
      if (alreadySeeded) {
        debugPrint('[BeritaService] Seeding dilewati: meta/berita_seed sudah ada.');
        return;
      }
      debugPrint('[BeritaService] Menjalankan seeding awal 9 berita bawaan...');
      await _seedArticlesInternal(isRestore: false);
      await markSeeded();
    } catch (e) {
      debugPrint('[BeritaService] ensureAutoSeeded gagal: $e');
    }
  }

  /// Pulihkan 9 berita bawaan yang belum ada di Firestore (cek per ID).
  /// Tidak pernah menimpa artikel yang sudah ada atau menghapus artikel lain.
  Future<({int restored, int alreadyExist})> restoreStaticArticles() async {
    return await _seedArticlesInternal(isRestore: true);
  }

  Future<({int restored, int alreadyExist})> _seedArticlesInternal({
    required bool isRestore,
  }) async {
    final seedItems = _buildSeedData();
    int addedCount = 0;
    int existingCount = 0;

    for (final item in seedItems) {
      final docId = item['id'] as String;
      final ref = _firestore.collection(_collection).doc(docId);

      try {
        final snap = await ref.get();
        if (snap.exists) {
          existingCount++;
          debugPrint('[BeritaService] Dokumen $docId sudah ada, tidak ditimpa.');
          continue;
        }

        final Map<String, dynamic> data = Map.from(item);
        data.remove('id');
        data['createdBy'] = 'system';
        data['createdById'] = 'seed_script';
        data['createdAt'] = FieldValue.serverTimestamp();
        data['updatedAt'] = FieldValue.serverTimestamp();

        await ref.set(data);
        addedCount++;
        debugPrint('[BeritaService] Berita bawaan $docId berhasil dibuat.');
      } catch (e) {
        debugPrint('[BeritaService] Gagal memproses seed doc $docId: $e');
      }
    }

    if (!isRestore) {
      await markSeeded();
    }

    return (restored: addedCount, alreadyExist: existingCount);
  }

  // ── Streams Firestore (Tanpa orderBy dan Tanpa where pada status) ──────────

  /// Stream seluruh artikel untuk admin (Semua status: terbit & draft).
  /// Mengambil data mentah tanpa orderBy di Firestore, lalu diurutkan di memori.
  Stream<List<BeritaArticle>> streamAll() {
    return _firestore.collection(_collection).snapshots().map((snap) {
      final List<BeritaArticle> list = [];
      for (final doc in snap.docs) {
        try {
          final article = BeritaArticle.fromFirestore(doc);
          list.add(article);
        } catch (e) {
          debugPrint('[BeritaService] Gagal parsing dokumen ${doc.id}: $e. Dokumen dilewati.');
        }
      }

      // Pengurutan in-memory: tanggal terbaru lebih dulu, tanggal null di paling akhir
      return _sortArticles(list);
    });
  }

  /// Stream artikel berstatus 'terbit' untuk sisi pengguna.
  /// Menggunakan query where('status', isEqualTo: 'terbit') agar mematuhi aturan keamanan Firestore di server,
  /// serta menggabungkan data statis bawaan dan dokumen Firestore (Firestore selalu menang).
  Stream<List<BeritaArticle>> streamPublished() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'terbit')
        .snapshots()
        .map((snap) {
          final List<BeritaArticle> list = [];
          for (final doc in snap.docs) {
            try {
              final article = BeritaArticle.fromFirestore(doc);
              list.add(article);
            } catch (e) {
              debugPrint('[BeritaService] Gagal parsing dokumen terbit ${doc.id}: $e');
            }
          }

          // Gabungkan berita statis bawaan dan artikel Firestore (ID sama dimenangkan Firestore)
          final Map<String, BeritaArticle> map = {};
          for (final s in BeritaRepository.getStaticAll()) {
            if (s.status == 'terbit') {
              map[s.id] = s;
            }
          }
          for (final p in list) {
            map[p.id] = p; // Dokumen Firestore menambahkan artikel baru & memperbarui artikel lama
          }

          return _sortArticles(map.values.toList());
        })
        .handleError((error) {
          debugPrint('[BeritaService.streamPublished] Error stream: $error. Menggunakan fallback data statis.');
          return _sortArticles(
            BeritaRepository.getStaticAll().where((a) => a.status == 'terbit').toList(),
          );
        });
  }

  static List<BeritaArticle> _sortArticles(List<BeritaArticle> list) {
    list.sort((a, b) {
      if (a.tanggal == null && b.tanggal == null) {
        return a.judul.toLowerCase().compareTo(b.judul.toLowerCase());
      }
      if (a.tanggal == null) return 1;
      if (b.tanggal == null) return -1;
      return b.tanggal!.compareTo(a.tanggal!);
    });
    return list;
  }

  // ── Mengambil 1 Dokumen Berita ─────────────────────────────────────────────

  Future<BeritaArticle?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return BeritaArticle.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('[BeritaService] Error getById($id): $e');
    }
    return null;
  }

  // ── Upload & Kelola Gambar ke Firebase Storage ──────────────────────────────

  /// Mengunggah gambar cover ke path `berita_articles/{articleId}/cover_{timestamp}.{ext}`.
  /// Memvalidasi berkas ada, ukuran <= 2MB, format JPG/PNG/WEBP.
  /// Menunggu hingga unggahan selesai (await) lalu mengambil getDownloadURL() dari snapshot.ref.
  Future<String> uploadBeritaCover(
    File imageFile,
    String articleId, {
    void Function(double progress)? onProgress,
  }) async {
    // 1. Validasi keberadaan file di penyimpanan lokal
    if (!await imageFile.exists()) {
      debugPrint('[BeritaService] File gambar lokal tidak ditemukan: ${imageFile.path}');
      throw AppException('Berkas gambar tidak ditemukan di penyimpanan perangkat.');
    }

    // 2. Baca bytes dan validasi ukuran berkas (maks 2MB)
    final bytes = await imageFile.readAsBytes();
    final length = bytes.length;
    if (length > 2 * 1024 * 1024) {
      final sizeMb = (length / (1024 * 1024)).toStringAsFixed(2);
      debugPrint('[BeritaService] Ukuran gambar melebihi batas: $sizeMb MB');
      throw AppException('Ukuran gambar ($sizeMb MB) melebihi batas maksimal 2 MB.');
    }

    // 3. Validasi format file dan penentuan contentType
    final ext = imageFile.path.split('.').last.toLowerCase();
    const allowed = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowed.contains(ext)) {
      debugPrint('[BeritaService] Format gambar tidak didukung: .$ext');
      throw AppException('Format gambar .$ext tidak didukung. Harap gunakan format JPG atau PNG.');
    }
    final contentType = (ext == 'png') ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

    // 4. Susun path sesuai rekomendasi: berita_articles/{idArtikel}/cover_{timestamp}.{ext}
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'berita_articles/$articleId/cover_$timestamp.$ext';
    debugPrint('[BeritaService] Memulai upload: path=$storagePath, size=$length bytes, contentType=$contentType, bucket=${_storage.bucket}');

    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {
        'articleId': articleId,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    // 5. Eksekusi upload aman ke Firebase Storage
    try {
      return await _performUpload(
        storage: _storage,
        storagePath: storagePath,
        bytes: bytes,
        metadata: metadata,
        onProgress: onProgress,
      );
    } catch (primaryErr) {
      debugPrint('[BeritaService] Upload bucket utama gagal ($primaryErr). Mencoba alternatif bucket...');

      // Coba bucket alternatif lamon-a720b.appspot.com
      const fallbackBucket = 'lamon-a720b.appspot.com';
      if (_storage.bucket != fallbackBucket) {
        try {
          final fallbackStorage = FirebaseStorage.instanceFor(bucket: fallbackBucket);
          final url = await _performUpload(
            storage: fallbackStorage,
            storagePath: storagePath,
            bytes: bytes,
            metadata: metadata,
            onProgress: onProgress,
          );
          debugPrint('[BeritaService] Upload berhasil via fallback bucket: $url');
          return url;
        } catch (altErr) {
          debugPrint('[BeritaService] Fallback bucket juga gagal: $altErr');
        }
      }

      // 6. Graceful Fallback: Simpan langsung sebagai Base64 Data URI
      // Mirip dengan strategi pada doctor_service.dart saat Cloud Storage belum aktif.
      // Dokumen Firestore berkapasitas 1 MiB, gambar terkompresi (< 600 KB) aman disimpan langsung.
      if (length <= 600 * 1024) {
        debugPrint('[BeritaService] Menggunakan fallback Base64 Data URI ke Firestore (${bytes.length} bytes).');
        onProgress?.call(1.0);
        final base64String = base64Encode(bytes);
        return 'data:$contentType;base64,$base64String';
      } else {
        // Jika file terlalu besar untuk base64 (> 600 KB) dan Storage gagal
        throw AppException(
          'Firebase Storage belum aktif di Firebase Console dan ukuran gambar (${(length / 1024).toStringAsFixed(0)} KB) terlalu besar untuk penyimpanan langsung. '
          'Pilih gambar berukuran lebih kecil (< 500 KB) atau aktifkan Cloud Storage di Firebase Console.',
        );
      }
    }
  }

  /// Helper eksekusi upload menggunakan putData untuk konsistensi cross-platform
  Future<String> _performUpload({
    required FirebaseStorage storage,
    required String storagePath,
    required Uint8List bytes,
    required SettableMetadata metadata,
    void Function(double progress)? onProgress,
  }) async {
    final ref = storage.ref().child(storagePath);
    final uploadTask = ref.putData(bytes, metadata);

    StreamSubscription? sub;
    if (onProgress != null) {
      sub = uploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress(progress);
        }
      });
    }

    try {
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('[BeritaService] Upload berhasil ke ${snapshot.ref.fullPath}! URL: $downloadUrl');
      return downloadUrl;
    } finally {
      await sub?.cancel();
    }
  }

  /// Menghapus file gambar lama di Storage dengan upaya terbaik (try/catch aman).
  Future<void> deleteStorageFile(String fileUrl) async {
    if (fileUrl.isEmpty) return;
    if (!fileUrl.startsWith('http://') && !fileUrl.startsWith('https://')) return;

    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      debugPrint('[BeritaService] Berkas lama Storage berhasil dihapus: $fileUrl');
    } catch (e) {
      try {
        final fallbackStorage = FirebaseStorage.instanceFor(bucket: 'lamon-a720b.appspot.com');
        final ref = fallbackStorage.refFromURL(fileUrl);
        await ref.delete();
        debugPrint('[BeritaService] Berkas lama Storage berhasil dihapus dari fallback bucket: $fileUrl');
      } catch (_) {
        debugPrint('[BeritaService] Menghapus berkas Storage lama diabaikan: $e');
      }
    }
  }

  // ── Create Artikel (Hanya set pada dokumen itu) ───────────────────────────

  Future<String> createArtikel({
    required BeritaArticle artikel,
    required String adminName,
    required String adminId,
  }) async {
    // Pastikan seeding awal sudah berjalan jika ini instalasi baru
    await ensureAutoSeeded();

    final docRef = _firestore.collection(_collection).doc();
    final newId = docRef.id;
    debugPrint('[BeritaService] Membuat artikel baru dengan ID Firestore: $newId');

    final docData = artikel.toFirestore();
    docData['createdBy'] = adminName;
    dataWithTimestamps(docData, isCreate: true, adminName: adminName, adminId: adminId);

    final batch = _firestore.batch();
    batch.set(docRef, docData);

    // Activity log
    final logRef = _firestore.collection('activity_log').doc();
    final log = ActivityLogModel(
      id: logRef.id,
      aksi: artikel.status == 'terbit' ? 'terbit' : 'tambah',
      modul: 'berita',
      judul: artikel.judul,
      oleh: adminName,
      olehId: adminId,
      createdAt: null,
    );
    batch.set(logRef, log.toFirestore());

    await batch.commit();
    debugPrint('[BeritaService] Artikel $newId berhasil disimpan.');
    return newId;
  }

  // ── Update Artikel (Hanya update dokumen yang bersangkutan) ───────────────

  Future<void> updateArtikel({
    required String artikelId,
    required BeritaArticle artikel,
    required String adminName,
    required String adminId,
    bool wasPublished = false,
  }) async {
    if (artikelId.isEmpty) {
      throw Exception('ID artikel tidak boleh kosong saat memperbarui.');
    }

    final docRef = _firestore.collection(_collection).doc(artikelId);
    debugPrint('[BeritaService] Memperbarui artikel: $artikelId');

    final docData = artikel.toFirestore();
    dataWithTimestamps(docData, isCreate: false, adminName: adminName, adminId: adminId);

    final batch = _firestore.batch();
    batch.set(docRef, docData, SetOptions(merge: true));

    final logRef = _firestore.collection('activity_log').doc();
    String aksiText = 'ubah';
    if (artikel.status == 'terbit' && !wasPublished) {
      aksiText = 'terbit';
    }

    final log = ActivityLogModel(
      id: logRef.id,
      aksi: aksiText,
      modul: 'berita',
      judul: artikel.judul,
      oleh: adminName,
      olehId: adminId,
      createdAt: null,
    );
    batch.set(logRef, log.toFirestore());

    await batch.commit();
    debugPrint('[BeritaService] Perubahan artikel $artikelId berhasil disimpan.');
  }

  // ── Delete Artikel (Hanya hapus dokumen yang dipilih) ─────────────────────

  Future<void> deleteArtikel({
    required String artikelId,
    required String judul,
    required String adminName,
    required String adminId,
    String? gambarUrl,
  }) async {
    if (artikelId.isEmpty) return;

    debugPrint('[BeritaService] Menghapus artikel: $artikelId');
    final docRef = _firestore.collection(_collection).doc(artikelId);
    final logRef = _firestore.collection('activity_log').doc();

    final batch = _firestore.batch();
    batch.delete(docRef);

    final log = ActivityLogModel(
      id: logRef.id,
      aksi: 'hapus',
      modul: 'berita',
      judul: judul,
      oleh: adminName,
      olehId: adminId,
      createdAt: null,
    );
    batch.set(logRef, log.toFirestore());

    await batch.commit();

    // Hapus file Storage jika ada (best-effort)
    if (gambarUrl != null && gambarUrl.isNotEmpty) {
      await deleteStorageFile(gambarUrl);
    }

    debugPrint('[BeritaService] Artikel $artikelId berhasil dihapus.');
  }

  void dataWithTimestamps(
    Map<String, dynamic> data, {
    required bool isCreate,
    required String adminName,
    required String adminId,
  }) {
    if (isCreate) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = adminName;
      data['createdById'] = adminId;
    }
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['updatedBy'] = adminName;
    data['updatedById'] = adminId;
  }

  // ── 9 Data Bawaan Lengkap untuk Seeding ───────────────────────────────────

  List<Map<String, dynamic>> _buildSeedData() {
    return [
      {
        'id': 'kenapa-genz-sakit-lambung',
        'judul': 'Kenapa Gen Z Sering Sakit Lambung? Ini 4 Penyebabnya',
        'judulLower': 'kenapa gen z sering sakit lambung? ini 4 penyebabnya',
        'kategori': 'Gaya Hidup',
        'tanggal': Timestamp.fromDate(DateTime(2026, 9, 18)),
        'gambarUrl': '',
        'gambarAsset': 'assets/images/berita/berita_1.png',
        'sumberNama': 'ANTARA News',
        'sumberUrl': 'https://www.antaranews.com/berita/5747829/kenapa-gen-z-sering-sakit-lambung-ini-4-penyebabnya',
        'ringkasanSingkat': 'Sakit lambung adalah gejala gangguan pada saluran pencernaan bagian atas. Tren kesehatan mencatat sekitar 36 persen kasus asam lambung saat ini ditemukan di kalangan anak muda.',
        'status': 'terbit',
        'bacaJuga': ['beda-maag-dan-gerd'],
        'kontenMarkdown': 'Sakit lambung adalah gejala gangguan pada saluran pencernaan bagian atas yang ditandai nyeri, perih, atau tidak nyaman di ulu hati, mencakup dispepsia (maag), gastritis, tukak lambung, hingga GERD. Tren kesehatan mencatat sekitar 36 persen kasus asam lambung saat ini ditemukan di kalangan anak muda.\n\n4 Faktor yang Membuat Lambung Gen Z Rentan:\n- 1. Stres dan GERD Anxiety: Tekanan akademis, pekerjaan, hingga tren FOMO meningkatkan produksi hormon kortisol yang memicu asam lambung berlebih.\n- 2. Ketergantungan kopi dan minuman manis: Konsumsi kopi berkafein tinggi saat perut kosong mengendurkan otot katup kerongkongan bawah sehingga asam lambung mudah naik.\n- 3. Pola makan tidak teratur: Melewatkan sarapan, sering makan pedas atau bersantan, serta makan larut malam memperburuk iritasi dinding lambung.\n- 4. Sering begadang: Jam tidur yang berantakan mengganggu irama sirkadian dan fungsi saluran pencernaan.\n\nLangkah Mengatasi dan Mencegah:\n- Terapkan pola makan mindful eating: porsi kecil tapi sering (4-5 kali sehari), hindari langsung berbaring 2-3 jam setelah makan\n- Batasi kafein, makanan bersantan, pedas, dan minuman berkarbonasi\n- Kelola stres lewat istirahat, olahraga teratur, atau teknik pernapasan\n- Perbaiki jam tidur 7-8 jam sehari',
      },
      {
        'id': 'mengenal-gerd-penanganan-dini',
        'judul': 'Mengenal GERD dan Pentingnya Penanganan yang Tepat Sejak Dini',
        'judulLower': 'mengenal gerd dan pentingnya penanganan yang tepat sejak dini',
        'kategori': 'Pencernaan',
        'tanggal': Timestamp.fromDate(DateTime(2026, 9, 19)),
        'gambarUrl': '',
        'gambarAsset': 'assets/images/berita/berita_2.png',
        'sumberNama': 'Indozone.id (Gema Trisna Yudha)',
        'sumberUrl': 'https://life.indozone.id/health/2486734267/mengenal-gerd-dan-pentingnya-penanganan-yang-tepat-sejak-dini',
        'ringkasanSingkat': 'GERD adalah gangguan saluran cerna yang cukup banyak ditemukan di Indonesia. Kondisi ini terjadi ketika isi lambung, termasuk asam lambung, naik kembali ke kerongkongan.',
        'status': 'terbit',
        'bacaJuga': ['gerd-dapat-sembuh'],
        'kontenMarkdown': 'GERD (gastroesophageal reflux disease) adalah gangguan saluran cerna yang cukup banyak ditemukan di Indonesia. Kondisi ini terjadi ketika isi lambung, termasuk asam lambung, naik kembali ke kerongkongan dan menimbulkan berbagai keluhan.\n\nMenurut Konsensus Nasional Penatalaksanaan Penyakit GERD Indonesia 2022, prevalensi GERD pada populasi umum di Indonesia diperkirakan sekitar 9,35 persen.\n\nBisa Berkembang Menjadi Lebih Serius:\nGERD dapat berkembang menjadi esofagitis erosif, yaitu peradangan kerongkongan yang disertai kerusakan pada lapisannya. Data dari rumah sakit rujukan tingkat tersier menunjukkan 55,4 persen pasien GERD mengalami kondisi ini.\n\nKeluhan asam lambung yang sering berulang perlu diperiksakan ke dokter. Jenis terapi ditentukan oleh dokter sesuai kondisi Anda.',
      },
      {
        'id': 'gerd-dapat-sembuh',
        'judul': 'GERD Dapat Sembuh dengan Kurangi Faktor Risiko dan Pengobatan Tuntas',
        'judulLower': 'gerd dapat sembuh dengan kurangi faktor risiko dan pengobatan tuntas',
        'kategori': 'Pencernaan',
        'tanggal': Timestamp.fromDate(DateTime(2026, 3, 6)),
        'gambarUrl': '',
        'gambarAsset': 'assets/images/berita/berita_3.png',
        'sumberNama': 'ANTARA News',
        'sumberUrl': 'https://www.antaranews.com/berita/5456227/gerd-dapat-sembuh-dengan-kurangi-faktor-risiko-dan-pengobatan-tuntas',
        'ringkasanSingkat': 'GERD dapat sembuh apabila faktor risikonya dikurangi dan pengobatan dijalankan sampai tuntas, menurut Guru Besar FK UI RSCM Prof. Dr. dr. Ari Fahrial Syam.',
        'status': 'terbit',
        'bacaJuga': ['beda-jantung-dan-asam-lambung'],
        'kontenMarkdown': 'Guru Besar Ilmu Penyakit Dalam konsultan gastroenterologi-hepatologi FK UI RSCM, Prof. Dr. dr. Ari Fahrial Syam, SpPD-KGEH, menyatakan bahwa GERD dapat sembuh apabila faktor risikonya dikurangi dan pengobatan dijalankan sampai tuntas.\n\nPerbaiki Gaya Hidup:\n- Menghindari makanan berlemak, asam, dan pedas\n- Tidak langsung berbaring setelah makan, beri jeda minimal 2 jam\n- Menghindari stres berlebih\n- Menghentikan kebiasaan merokok dan konsumsi alkohol\n- Menurunkan berat badan jika berlebih\n\nPengobatan Medis yang Tuntas:\nPengobatan GERD umumnya membutuhkan terapi penekan asam lambung (seperti PPI) selama 4-8 minggu secara teratur sesuai anjuran dokter, bukan dihentikan sendiri saat gejala membaik.',
      },
      {
        'id': 'begadang-asam-lambung',
        'judul': 'Sering Begadang Bikin Asam Lambung Naik, Ini Alasannya',
        'judulLower': 'sering begadang bikin asam lambung naik, ini alasannya',
        'kategori': 'Gaya Hidup',
        'tanggal': Timestamp.fromDate(DateTime(2026, 9, 27)),
        'gambarUrl': '',
        'gambarAsset': 'assets/images/berita/berita_4.png',
        'sumberNama': 'ANTARA News',
        'sumberUrl': 'https://www.antaranews.com/berita/5760544/sering-begadang-bikin-asam-lambung-naik-ini-alasannya',
        'ringkasanSingkat': 'Begadang tidak hanya membuat tubuh lelah. Kebiasaan tidur larut juga berkaitan dengan meningkatnya keluhan asam lambung, terutama pada orang yang sudah memiliki GERD.',
        'status': 'terbit',
        'bacaJuga': ['pertolongan-pertama-asam-lambung'],
        'kontenMarkdown': 'Begadang tidak hanya membuat tubuh lelah. Kebiasaan tidur larut malam juga berkaitan erat dengan meningkatnya keluhan asam lambung, terutama pada individu yang sudah memiliki riwayat GERD.\n\nKenapa Begadang Memperburuk Asam Lambung:\n- Produksi asam lambung tetap berjalan di malam hari, terutama jika perut kosong atau diisi camilan larut malam\n- Hormon stres (kortisol) meningkat saat kurang tidur, memicu kontraksi lambung yang lebih sensitif\n- Posisi tidur larut yang tidak teratur memudahkan refluks cairan lambung ke kerongkongan\n\nTips Menjaga Lambung bagi Pekerja Malam:\n- Jangan makan berat 2 jam sebelum tidur\n- Pilih camilan ramah lambung seperti pisang atau biskuit gandum\n- Gunakan bantal lebih tinggi (15-20 cm) saat tidur\n- Cukupi kebutuhan tidur di siang/pagi hari',
      },
      {
        'id': 'makanan-aman-untuk-maag',
        'judul': 'Makanan untuk Penderita Maag: Ini yang Aman dan Harus Dihindari',
        'judulLower': 'makanan untuk penderita maag: ini yang aman dan harus dihindari',
        'kategori': 'Gizi',
        'tanggal': Timestamp.fromDate(DateTime(2026, 9, 18)),
        'gambarUrl': '',
        'gambarAsset': 'assets/images/berita/berita_makanan_maag.png',
        'sumberNama': 'ANTARA News',
        'sumberUrl': 'https://www.antaranews.com/berita/5747915/makanan-untuk-penderita-maag-ini-yang-aman-dan-harus-dihindari',
        'ringkasanSingkat': 'Sakit maag umumnya dipicu pola makan tidak teratur, stres, infeksi bakteri H. pylori, atau efek samping obat. Pilihan makanan yang tepat sangat membantu proses pemulihan.',
        'status': 'terbit',
        'bacaJuga': ['pola-makan-baik-asam-lambung'],
        'kontenMarkdown': 'Sakit maag umumnya dipicu pola makan tidak teratur, stres, infeksi bakteri H. pylori, atau efek samping obat. Pilihan makanan yang tepat sangat membantu proses pemulihan dinding lambung.\n\nMakanan yang Aman dan Dianjurkan:\n- Karbohidrat mudah cerna: nasi tim, bubur, kentang rebus, oatmeal\n- Sayuran rendah serat kasar: labu siam, wortel, bayam\n- Buah non-asam: pisang, melon, pepaya\n- Protein rendah lemak: dada ayam tanpa kulit, tahu, tempe, ikan kukus\n\nMakanan yang Harus Dihindari:\n- Makanan pedas dan asam (cabai, cuka, jeruk, tomat berlebih)\n- Makanan berlemak tinggi dan santan kental\n- Minuman berkafein, bersoda, dan beralkohol\n- Makanan penghasil gas (kol, sawi, minuman bersoda)',
      },
      {
        'id': 'pertolongan-pertama-asam-lambung',
        'judul': 'Asam Lambung Naik? Terapkan 7 Langkah Pertolongan Pertama Ini',
        'judulLower': 'asam lambung naik? terapkan 7 langkah pertolongan pertama ini',
        'kategori': 'Gaya Hidup',
        'tanggal': Timestamp.fromDate(DateTime(2025, 7, 6)),
        'gambarUrl': '',
        'gambarAsset': 'assets/images/berita/berita_6.png',
        'sumberNama': 'ANTARA News',
        'sumberUrl': 'https://www.antaranews.com/berita/4947537/asam-lambung-naik-terapkan-7-langkah-pertolongan-pertama-ini',
        'ringkasanSingkat': 'Asam lambung naik sering muncul saat melewatkan waktu makan, stres, atau setelah makanan pemicu. Ada 7 langkah pertolongan pertama yang bisa dilakukan.',
        'status': 'terbit',
        'bacaJuga': ['kenapa-genz-sakit-lambung'],
        'kontenMarkdown': 'Asam lambung naik sering muncul mendadak saat melewatkan waktu makan, stres tinggi, atau setelah mengonsumsi makanan pemicu. Ada 7 langkah pertolongan pertama yang bisa dilakukan mandiri:\n\n7 Langkah Pertolongan Pertama:\n- 1. Longgarkan pakaian, terutama di bagian pinggang dan perut\n- 2. Duduk tegak, jangan langsung berbaring\n- 3. Minum air hangat sedikit demi sedikit\n- 4. Lakukan teknik pernapasan lambat (tarik napas dalam, hembuskan perlahan)\n- 5. Konsumsi antasida bila tersedia sesuai petunjuk kemasan\n- 6. Hindari rokok dan kopi seketika\n- 7. Tinggikan kepala jika harus berbaring\n\nJika keluhan disertai sesak napas berat, muntah darah, atau nyeri dada tembus ke punggung, segera cari pertolongan medis.',
      },
      {
        'id': 'beda-maag-dan-gerd',
        'judul': 'Apa Bedanya Maag dan GERD? Kenali Gejala dan Penyebabnya',
        'judulLower': 'apa bedanya maag dan gerd? kenali gejala dan penyebabnya',
        'kategori': 'Pencernaan',
        'tanggal': Timestamp.fromDate(DateTime(2026, 9, 18)),
        'gambarUrl': '',
        'gambarAsset': 'assets/images/berita/berita_7.png',
        'sumberNama': 'ANTARA News',
        'sumberUrl': 'https://www.antaranews.com/berita/5747907/apa-bedanya-maag-dan-gerd-kenali-gejala-dan-penyebabnya',
        'ringkasanSingkat': 'Maag adalah peradangan dinding lambung, sedangkan GERD adalah kondisi kronis ketika asam lambung naik ke kerongkongan akibat melemahnya katup sfingter esofagus bawah.',
        'status': 'terbit',
        'bacaJuga': ['mengenal-gerd-penanganan-dini'],
        'kontenMarkdown': 'Banyak orang menganggap maag dan GERD adalah kondisi yang sama. Padahal keduanya memiliki mekanisme dan lokasi gangguan yang berbeda.\n\nPerbedaan Utama:\n- Maag (Gastritis/Dispepsia): Peradangan atau iritasi pada dinding lambung. Gejalanya rasa perih, begah, mual di ulu hati.\n- GERD: Kondisi kronis di mana katup sfingter esofagus bawah melemah, sehingga asam lambung naik kembali ke kerongkongan. Gejalanya heartburn (dada terbakar) dan rasa asam/pahit di mulut.\n\nPenanganan:\nPenanganan maag berfokus pada melindungi lapisan mukosa lambung, sedangkan penanganan GERD berfokus pada menekan asam lambung dan mencegah aliran balik cairan ke kerongkongan.',
      },
      {
        'id': 'beda-jantung-dan-asam-lambung',
        'judul': 'Sering Dianggap Mirip, Ini Bedanya Sakit Jantung dan Asam Lambung',
        'judulLower': 'sering dianggap mirip, ini bedanya sakit jantung dan asam lambung',
        'kategori': 'Kesehatan Umum',
        'tanggal': Timestamp.fromDate(DateTime(2026, 9, 20)),
        'gambarUrl': '',
        'gambarAsset': 'assets/images/berita/berita_8.png',
        'sumberNama': 'ANTARA News',
        'sumberUrl': 'https://www.antaranews.com/berita/5731188/sering-dianggap-mirip-ini-bedanya-sakit-jantung-dan-asam-lambung',
        'ringkasanSingkat': 'Nyeri dada sering dikaitkan dengan asam lambung, padahal gangguan jantung bisa menimbulkan keluhan serupa. Penting untuk mengenali perbedaannya.',
        'status': 'terbit',
        'bacaJuga': ['begadang-asam-lambung'],
        'kontenMarkdown': 'Nyeri dada sering dikaitkan dengan asam lambung (heartburn), padahal gangguan jantung (angina/serangan jantung) bisa menimbulkan keluhan yang serupa. Mengenali perbedaannya sangat penting untuk keselamatan.\n\nPerbedaan Gejala:\n- Sakit Jantung: Nyeri dada seperti tertekan beban berat, menjalar ke lengan kiri, leher, atau rahang, disertai keringat dingin dan sesak napas. Tidak membaik dengan antasida.\n- Asam Lambung: Sensasi panas terbakar di dada belakang tulang dada, memburuk saat berbaring atau membungkuk, sering disertai rasa asam di mulut, membaik setelah minum antasida.\n\nTanda Bahaya:\nJika nyeri dada muncul tiba-tiba dengan sesak napas dan keringat dingin, segera ke IGD rumah sakit terdekat.',
      },
      {
        'id': 'pola-makan-baik-asam-lambung',
        'judul': 'Pola Makan yang Baik bagi Penderita Asam Lambung',
        'judulLower': 'pola makan yang baik bagi penderita asam lambung',
        'kategori': 'Gizi',
        'tanggal': Timestamp.fromDate(DateTime(2025, 7, 29)),
        'gambarUrl': '',
        'gambarAsset': 'assets/images/berita/berita_9.png',
        'sumberNama': 'ANTARA News',
        'sumberUrl': 'https://www.antaranews.com/berita/4998689/pola-makan-yang-baik-bagi-penderita-asam-lambung',
        'ringkasanSingkat': 'Pola makan tepat adalah kunci mengendalikan gejala GERD. Makan dalam porsi kecil tapi sering dan menghindari makanan pemicu adalah langkah utamanya.',
        'status': 'terbit',
        'bacaJuga': ['makanan-aman-untuk-maag'],
        'kontenMarkdown': 'Pola makan yang tepat adalah kunci utama mengendalikan gejala refluks asam lambung dan mencegah kekambuhan.\n\nPanduan Pola Makan Harian:\n- Makan dalam porsi kecil tapi sering (4-5 kali sehari)\n- Jangan melewatkan waktu makan, terutama sarapan\n- Kunyah makanan secara perlahan\n- Hindari makanan berlemak, pedas, asam, dan bersoda\n- Beri jeda 2-3 jam antara makan malam dan waktu tidur\n\nContoh Pilihan Sarapan Ramah Lambung:\nOatmeal dengan susu almond, roti gandum panggang, bubur ayam tanpa kuah pedas, atau pisang matang.',
      },
    ];
  }
}

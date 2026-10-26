import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/berita_article_model.dart';
import '../../models/activity_log_model.dart';
import 'berita_repository.dart';

/// Service CRUD artikel berita ke Firestore collection `berita_articles`.
/// Menggunakan arsitektur hybrid (offline-first & resilient) sehingga:
/// 1. 9 artikel bawaan selalu muncul instan di UI admin & pengguna.
/// 2. Operasi CRUD (tambah, edit, simpan draft, terbitkan, hapus) langsung berhasil.
/// 3. Data disinkronkan ke Cloud Firestore di latar belakang secara aman.
class BeritaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _collection = 'berita_articles';

  // ── Memory Store & Reactive Controller ─────────────────────────────────────
  static final List<BeritaArticle> _memoryArticles = [];
  static final StreamController<List<BeritaArticle>> _controller =
      StreamController<List<BeritaArticle>>.broadcast();
  static bool _initialized = false;
  static StreamSubscription? _remoteSub;

  static void _ensureInitialized() {
    if (_initialized && _memoryArticles.isNotEmpty) return;
    _initialized = true;
    _memoryArticles.clear();
    _memoryArticles.addAll(BeritaRepository.getStaticAll());
  }

  static void _notify() {
    if (!_controller.isClosed) {
      _controller.add(_sortedList(List.from(_memoryArticles)));
    }
  }

  static List<BeritaArticle> _sortedList(List<BeritaArticle> list) {
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

  void _startRemoteListener() {
    if (_remoteSub != null) return;
    try {
      _remoteSub = _firestore.collection(_collection).snapshots().listen(
        (snap) {
          bool changed = false;
          for (final doc in snap.docs) {
            try {
              final remoteArticle = BeritaArticle.fromFirestore(doc);
              final idx = _memoryArticles.indexWhere((a) => a.id == remoteArticle.id);
              if (idx >= 0) {
                _memoryArticles[idx] = remoteArticle;
              } else {
                _memoryArticles.add(remoteArticle);
              }
              changed = true;
            } catch (e) {
              debugPrint('[BeritaService] Remote doc parse error ${doc.id}: $e');
            }
          }
          if (changed) _notify();
        },
        onError: (err) {
          debugPrint('[BeritaService] Remote Firestore stream error ($err). Menggunakan data lokal.');
        },
      );
    } catch (e) {
      debugPrint('[BeritaService] Failed to start remote listener: $e');
    }
  }

  // ── Public Streams ─────────────────────────────────────────────────────────

  /// Stream semua artikel (terbit & draft) untuk admin
  Stream<List<BeritaArticle>> streamAll() async* {
    _ensureInitialized();
    _startRemoteListener();
    yield _sortedList(List.from(_memoryArticles));
    yield* _controller.stream;
  }

  /// Stream artikel berstatus terbit untuk sisi pengguna
  Stream<List<BeritaArticle>> streamPublished() async* {
    _ensureInitialized();
    _startRemoteListener();
    yield _sortedList(List.from(_memoryArticles))
        .where((a) => a.status == 'terbit')
        .toList();
    await for (final list in _controller.stream) {
      yield list.where((a) => a.status == 'terbit').toList();
    }
  }

  // ── Getters untuk Sinkronisasi Sisi Pengguna ────────────────────────────────

  static List<BeritaArticle> get currentArticles {
    _ensureInitialized();
    return _sortedList(List.from(_memoryArticles));
  }

  static List<BeritaArticle> get currentPublishedArticles {
    _ensureInitialized();
    return _sortedList(List.from(_memoryArticles))
        .where((a) => a.status == 'terbit')
        .toList();
  }

  // ── Cek Keberadaan Data ───────────────────────────────────────────────────

  Future<bool> hasArticles() async {
    _ensureInitialized();
    return _memoryArticles.isNotEmpty;
  }

  Future<BeritaArticle?> getById(String id) async {
    _ensureInitialized();
    final local = _memoryArticles.where((a) => a.id == id).firstOrNull;
    if (local != null) return local;

    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return BeritaArticle.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('[BeritaService] Error getById from remote: $e');
    }
    return null;
  }

  // ── Upload Gambar ──────────────────────────────────────────────────────────

  Future<String> uploadImage(File imageFile, String articleId) async {
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final ref = _storage.ref().child('berita_images/$articleId.$ext');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('[BeritaService] uploadImage remote failed: $e. Fallback path lokal.');
      return imageFile.path;
    }
  }

  // ── Create Artikel ────────────────────────────────────────────────────────

  Future<String> createArtikel({
    required BeritaArticle artikel,
    required String adminName,
    required String adminId,
  }) async {
    _ensureInitialized();

    String newId = artikel.id;
    if (newId.isEmpty) {
      try {
        newId = _firestore.collection(_collection).doc().id;
      } catch (_) {
        newId = 'art_${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    final articleWithId = BeritaArticle(
      id: newId,
      judul: artikel.judul,
      kategori: artikel.kategori,
      tanggal: artikel.status == 'terbit'
          ? (artikel.tanggal ?? DateTime.now())
          : artikel.tanggal,
      gambarAsset: artikel.gambarAsset,
      gambarAlignment: artikel.gambarAlignment,
      konten: artikel.konten,
      bacaJuga: artikel.bacaJuga,
      sumberNama: artikel.sumberNama,
      sumberUrl: artikel.sumberUrl,
      ringkasanSingkat: artikel.ringkasanSingkat,
      status: artikel.status,
      kontenMarkdown: artikel.kontenMarkdown,
    );

    // 1. Simpan ke memory seketika
    _memoryArticles.removeWhere((a) => a.id == newId);
    _memoryArticles.add(articleWithId);
    _notify();

    // 2. Sinkronkan ke Cloud Firestore di latar belakang
    try {
      final docRef = _firestore.collection(_collection).doc(newId);
      final logRef = _firestore.collection('activity_log').doc();

      final data = articleWithId.toFirestore();
      data['createdBy'] = adminName;
      data['createdById'] = adminId;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final batch = _firestore.batch();
      batch.set(docRef, data);

      final aksiText = artikel.status == 'terbit' ? 'terbit' : 'tambah';
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
    } catch (e) {
      debugPrint('[BeritaService] createArtikel remote sync note: $e');
    }

    return newId;
  }

  // ── Update Artikel ────────────────────────────────────────────────────────

  Future<void> updateArtikel({
    required String artikelId,
    required BeritaArticle artikel,
    required String adminName,
    required String adminId,
    bool wasPublished = false,
  }) async {
    _ensureInitialized();

    final updatedArticle = BeritaArticle(
      id: artikelId,
      judul: artikel.judul,
      kategori: artikel.kategori,
      tanggal: artikel.status == 'terbit' && !wasPublished && artikel.tanggal == null
          ? DateTime.now()
          : (artikel.tanggal ?? DateTime.now()),
      gambarAsset: artikel.gambarAsset,
      gambarAlignment: artikel.gambarAlignment,
      konten: artikel.konten,
      bacaJuga: artikel.bacaJuga,
      sumberNama: artikel.sumberNama,
      sumberUrl: artikel.sumberUrl,
      ringkasanSingkat: artikel.ringkasanSingkat,
      status: artikel.status,
      kontenMarkdown: artikel.kontenMarkdown,
    );

    final idx = _memoryArticles.indexWhere((a) => a.id == artikelId);
    if (idx >= 0) {
      _memoryArticles[idx] = updatedArticle;
    } else {
      _memoryArticles.add(updatedArticle);
    }
    _notify();

    // Sinkronkan ke Cloud Firestore di latar belakang
    try {
      final docRef = _firestore.collection(_collection).doc(artikelId);
      final logRef = _firestore.collection('activity_log').doc();

      final data = updatedArticle.toFirestore();
      data['updatedBy'] = adminName;
      data['updatedById'] = adminId;
      data['updatedAt'] = FieldValue.serverTimestamp();

      final batch = _firestore.batch();
      batch.set(docRef, data, SetOptions(merge: true));

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
    } catch (e) {
      debugPrint('[BeritaService] updateArtikel remote sync note: $e');
    }
  }

  // ── Delete Artikel ────────────────────────────────────────────────────────

  Future<void> deleteArtikel({
    required String artikelId,
    required String judul,
    required String adminName,
    required String adminId,
  }) async {
    _ensureInitialized();
    _memoryArticles.removeWhere((a) => a.id == artikelId);
    _notify();

    // Sinkronkan ke Cloud Firestore di latar belakang
    try {
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
    } catch (e) {
      debugPrint('[BeritaService] deleteArtikel remote sync note: $e');
    }
  }

  // ── Seeding 9 Artikel Statis (Upsert Bawaan Pengguna) ─────────────────────

  Future<SeedResult> seedStaticArticles() async {
    _ensureInitialized();

    final statics = BeritaRepository.getStaticAll();
    for (final s in statics) {
      final idx = _memoryArticles.indexWhere((a) => a.id == s.id);
      if (idx == -1) {
        _memoryArticles.add(s);
      } else {
        _memoryArticles[idx] = s;
      }
    }
    _notify();

    int inserted = 0;
    int updated = 0;
    int skipped = 0;

    final articles = _buildSeedData();
    try {
      for (final article in articles) {
        final docId = article['id'] as String;
        final ref = _firestore.collection(_collection).doc(docId);
        bool isNew = true;
        try {
          final snap = await ref.get();
          if (snap.exists) {
            isNew = false;
            final existingData = snap.data();
            final updatedById = existingData?['updatedById'];
            // Kebijakan: Jika artikel bawaan sudah diedit manual oleh admin,
            // JANGAN timpa (skip agar hasil edit admin tetap aman).
            if (updatedById != null && updatedById != 'seed_script') {
              skipped++;
              continue;
            }
          }
        } catch (_) {}

        final Map<String, dynamic> data = Map.from(article);
        data.remove('id');
        data['createdBy'] = 'system';
        data['createdById'] = 'seed_script';
        if (isNew) {
          data['createdAt'] = FieldValue.serverTimestamp();
        }
        data['updatedAt'] = FieldValue.serverTimestamp();

        await ref.set(data, SetOptions(merge: true));
        if (isNew) {
          inserted++;
        } else {
          updated++;
        }
      }
    } catch (e) {
      debugPrint('[BeritaService] seedStaticArticles remote push error: $e');
      rethrow;
    }

    return SeedResult(inserted: inserted + updated, skipped: skipped);
  }

  List<Map<String, dynamic>> _buildSeedData() {
    return [
      {
        'id': 'kenapa-genz-sakit-lambung',
        'judul': 'Kenapa Gen Z Sering Sakit Lambung? Ini 4 Penyebabnya',
        'judulLower': 'kenapa gen z sering sakit lambung? ini 4 penyebabnya',
        'kategori': 'Gaya Hidup',
        'tanggal': Timestamp.fromDate(DateTime(2026, 9, 18)),
        'gambarUrl': 'assets/images/berita/berita_1.png',
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
        'gambarUrl': 'assets/images/berita/berita_2.png',
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
        'gambarUrl': 'assets/images/berita/berita_3.png',
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
        'gambarUrl': 'assets/images/berita/berita_4.png',
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
        'gambarUrl': 'assets/images/berita/berita_makanan_maag.png',
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
        'gambarUrl': 'assets/images/berita/berita_6.png',
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
        'gambarUrl': 'assets/images/berita/berita_7.png',
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
        'gambarUrl': 'assets/images/berita/berita_8.png',
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
        'gambarUrl': 'assets/images/berita/berita_9.png',
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

class SeedResult {
  final int inserted;
  final int skipped;
  const SeedResult({required this.inserted, required this.skipped});
}

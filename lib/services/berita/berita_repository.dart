import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/berita_article_model.dart';

// lib/services/berita/berita_repository.dart
//
// Repository artikel berita LAMON.
//
// Arsitektur dual-source:
//   • Data statis lokal (9 artikel lama) tetap ada untuk backward-compatibility
//     sehingga halaman daftar, carousel, dan detail sisi pengguna tetap berfungsi
//     persis seperti sebelum migrasi bahkan ketika Firestore belum di-seed.
//   • Setelah seeding, BeritaRepository.getAll() / getById() membaca dari
//     Firestore (status == terbit) sehingga artikel yang ditambah/dihapus admin
//     langsung terlihat di sisi pengguna.
//
// Cara pakai sisi pengguna (TIDAK BERUBAH dari sisi pemanggil):
//   final articles = await BeritaRepository.getAll();      // async sekarang
//   final article  = await BeritaRepository.getById(id);
//
// CATATAN: BeritaListScreen & BeritaDetailScreen sudah diperbarui untuk
// memanggil versi async. Versi sync legacy dihapus.

class BeritaRepository {
  static final FirebaseFirestore _fs = FirebaseFirestore.instance;
  static const String _col = 'berita_articles';

  // ── Data statis (fallback jika Firestore belum di-seed) ──────────────────

  static final List<BeritaArticle> _staticArticles = [
    BeritaArticle(
      id: 'kenapa-genz-sakit-lambung',
      kategori: 'Gaya Hidup',
      tanggal: DateTime(2026, 9, 18),
      gambarAsset: 'assets/images/berita/berita_1.png',
      gambarAlignment: const Alignment(0, -0.6),
      sumberNama: 'ANTARA News',
      sumberUrl: 'https://www.antaranews.com/berita/5747829/kenapa-gen-z-sering-sakit-lambung-ini-4-penyebabnya',
      judul: 'Kenapa Gen Z Sering Sakit Lambung? Ini 4 Penyebabnya',
      ringkasanSingkat: 'Sakit lambung adalah gejala gangguan pada saluran pencernaan bagian atas. Tren kesehatan mencatat sekitar 36 persen kasus asam lambung ditemukan di kalangan anak muda.',
      status: 'terbit',
      konten: [
        BeritaBlockParagraph(
            'Sakit lambung adalah gejala gangguan pada saluran pencernaan bagian atas yang ditandai nyeri, perih, atau tidak nyaman di ulu hati, mencakup dispepsia (maag), gastritis, tukak lambung, hingga GERD. Tren kesehatan mencatat sekitar 36 persen kasus asam lambung saat ini ditemukan di kalangan anak muda.'),
        BeritaBlockSubjudul('4 Faktor yang Membuat Lambung Gen Z Rentan'),
        BeritaBlockButirAngka(nomor: 1, judul: 'Stres dan GERD Anxiety', isi: 'Tekanan akademis, pekerjaan, hingga tren FOMO meningkatkan produksi hormon kortisol yang memicu produksi asam lambung berlebih.'),
        BeritaBlockButirAngka(nomor: 2, judul: 'Ketergantungan kopi dan minuman manis', isi: 'Konsumsi kopi berkafein tinggi saat perut kosong mengendurkan otot katup kerongkongan bawah sehingga asam lambung mudah naik.'),
        BeritaBlockButirAngka(nomor: 3, judul: 'Pola makan tidak teratur', isi: 'Melewatkan sarapan, sering makan pedas atau bersantan, serta makan larut malam memperburuk iritasi dinding lambung.'),
        BeritaBlockButirAngka(nomor: 4, judul: 'Sering begadang', isi: 'Jam tidur yang berantakan mengganggu irama sirkadian dan fungsi kerja saluran pencernaan.'),
        BeritaBlockSubjudul('Langkah Mengatasi dan Mencegah'),
        BeritaBlockBulletList([
          'Terapkan pola makan mindful eating: porsi kecil tapi sering (4–5 kali sehari), hindari langsung berbaring minimal 2–3 jam setelah makan',
          'Batasi kafein, makanan bersantan, pedas, dan minuman berkarbonasi',
          'Kelola stres lewat istirahat, olahraga teratur, atau teknik pernapasan',
          'Perbaiki jam tidur, usahakan 7–8 jam sehari'
        ]),
        BeritaBlockTips('Jika nyeri ulu hati atau rasa terbakar di dada sering kambuh, konsultasikan ke dokter untuk penanganan yang tepat.'),
      ],
      bacaJuga: ['beda-maag-dan-gerd'],
    ),
    BeritaArticle(
      id: 'mengenal-gerd-penanganan-dini',
      kategori: 'Pencernaan',
      tanggal: DateTime(2026, 9, 19),
      gambarAsset: 'assets/images/berita/berita_2.png',
      gambarAlignment: const Alignment(0, -0.4),
      sumberNama: 'Indozone.id (Gema Trisna Yudha)',
      sumberUrl: 'https://life.indozone.id/health/2486734267/mengenal-gerd-dan-pentingnya-penanganan-yang-tepat-sejak-dini',
      judul: 'Mengenal GERD dan Pentingnya Penanganan yang Tepat Sejak Dini',
      ringkasanSingkat: 'GERD adalah gangguan saluran cerna yang cukup banyak ditemukan di Indonesia. Kondisi ini terjadi ketika isi lambung, termasuk asam lambung, naik kembali ke kerongkongan.',
      status: 'terbit',
      konten: [
        BeritaBlockParagraph(
            'GERD (gastroesophageal reflux disease) adalah gangguan saluran cerna yang cukup banyak ditemukan di Indonesia. Kondisi ini terjadi ketika isi lambung, termasuk asam lambung, naik kembali ke kerongkongan dan menimbulkan berbagai keluhan.'),
        BeritaBlockParagraph(
            'Menurut Konsensus Nasional Penatalaksanaan Penyakit GERD Indonesia 2022, prevalensi GERD pada populasi umum di Indonesia diperkirakan sekitar 9,35 persen.'),
        BeritaBlockSubjudul('Bisa Berkembang Menjadi Lebih Serius'),
        BeritaBlockParagraph(
            'GERD dapat berkembang menjadi esofagitis erosif, yaitu peradangan kerongkongan yang disertai kerusakan pada lapisannya. Data dari rumah sakit rujukan tingkat tersier menunjukkan 55,4 persen pasien GERD mengalami kondisi ini.'),
        BeritaBlockTips(
            'Keluhan asam lambung yang sering berulang perlu diperiksakan ke dokter. Jenis terapi ditentukan oleh dokter sesuai kondisi Anda.'),
      ],
      bacaJuga: ['gerd-dapat-sembuh'],
    ),
    BeritaArticle(
      id: 'gerd-dapat-sembuh',
      kategori: 'Pencernaan',
      tanggal: DateTime(2026, 3, 6),
      gambarAsset: 'assets/images/berita/berita_3.png',
      gambarAlignment: const Alignment(0, -0.3),
      sumberNama: 'ANTARA News',
      sumberUrl: 'https://www.antaranews.com/berita/5456227/gerd-dapat-sembuh-dengan-kurangi-faktor-risiko-dan-pengobatan-tuntas',
      judul: 'GERD Dapat Sembuh dengan Kurangi Faktor Risiko dan Pengobatan Tuntas',
      ringkasanSingkat: 'GERD dapat sembuh apabila faktor risikonya dikurangi dan pengobatan dijalankan sampai tuntas, menurut Guru Besar FK UI RSCM Prof. Dr. dr. Ari Fahrial Syam.',
      status: 'terbit',
      konten: [
        BeritaBlockParagraph(
            'Guru Besar Ilmu Penyakit Dalam konsultan gastroenterologi–hepatologi FK UI RSCM, Prof. Dr. dr. Ari Fahrial Syam, SpPD-KGEH, menyatakan bahwa GERD dapat sembuh apabila faktor risikonya dikurangi dan pengobatan dijalankan sampai tuntas.'),
        BeritaBlockSubjudul('Perbaiki Gaya Hidup'),
        BeritaBlockBulletList([
          'Berhenti merokok dan tidak mengonsumsi alkohol',
          'Turunkan berat badan jika berlebih',
          'Terapkan pola makan rendah lemak',
          'Olahraga teratur, tidur cukup, dan kelola stres'
        ]),
        BeritaBlockSubjudul('Siapa yang Rentan?'),
        BeritaBlockParagraph(
            'Berdasarkan penelitiannya, penderita GERD umumnya laki-laki, merokok, obesitas, dan berusia di atas 40 tahun. Namun kini banyak anak yang juga mengalaminya.'),
      ],
      bacaJuga: ['beda-jantung-dan-asam-lambung'],
    ),
    BeritaArticle(
      id: 'begadang-asam-lambung',
      kategori: 'Gaya Hidup',
      tanggal: DateTime(2026, 9, 27),
      gambarAsset: 'assets/images/berita/berita_4.png',
      gambarAlignment: const Alignment(0, 0.1),
      sumberNama: 'ANTARA News',
      sumberUrl: 'https://www.antaranews.com/berita/5760544/sering-begadang-bikin-asam-lambung-naik-ini-alasannya',
      judul: 'Sering Begadang Bikin Asam Lambung Naik, Ini Alasannya',
      ringkasanSingkat: 'Begadang tidak hanya membuat tubuh lelah. Kebiasaan tidur larut juga berkaitan dengan meningkatnya keluhan asam lambung, terutama pada penderita GERD.',
      status: 'terbit',
      konten: [
        BeritaBlockParagraph(
            'Begadang tidak hanya membuat tubuh lelah keesokan harinya. Kebiasaan tidur larut dan kurang tidur juga berkaitan dengan meningkatnya keluhan asam lambung, terutama pada orang yang sudah memiliki GERD.'),
        BeritaBlockSubjudul('Mengapa Begadang Memicu Asam Lambung?'),
        BeritaBlockButirAngka(
            nomor: 1,
            judul: 'Kurang tidur meningkatkan paparan asam',
            isi: 'Dalam sebuah penelitian, peserta yang hanya tidur empat jam selama dua malam mengalami peningkatan parameter refluks dibanding yang tidur tujuh sampai delapan jam.'),
        BeritaBlockButirAngka(
            nomor: 2,
            judul: 'Begadang sering diikuti makan larut malam',
            isi: 'Jika langsung berbaring atau tidur tak lama setelah makan, isi lambung lebih mudah naik ke kerongkongan.'),
        BeritaBlockSubjudul('Kapan Perlu ke Dokter?'),
        BeritaBlockTandaBahaya(items: [
          'Keluhan asam lambung muncul berulang atau mengganggu tidur',
          'Sulit menelan atau muntah',
          'Berat badan turun tanpa sebab yang jelas',
          'Disertai nyeri dada'
        ]),
      ],
      bacaJuga: ['pertolongan-pertama-asam-lambung'],
    ),
    BeritaArticle(
      id: 'makanan-aman-untuk-maag',
      kategori: 'Gizi',
      tanggal: DateTime(2026, 9, 18),
      gambarAsset: 'assets/images/berita/berita_makanan_maag.png',
      gambarAlignment: const Alignment(0, -0.8),
      sumberNama: 'ANTARA News',
      sumberUrl: 'https://www.antaranews.com/berita/5747915/makanan-untuk-penderita-maag-ini-yang-aman-dan-harus-dihindari',
      judul: 'Makanan untuk Penderita Maag: Ini yang Aman dan Harus Dihindari',
      ringkasanSingkat: 'Sakit maag umumnya dipicu pola makan tidak teratur, stres, infeksi bakteri H. pylori. Pilihan makanan yang tepat sangat membantu proses pemulihan.',
      status: 'terbit',
      konten: [
        BeritaBlockParagraph(
            'Sakit maag (dispepsia) adalah gejala tidak nyaman di perut bagian atas seperti rasa terbakar, nyeri ulu hati, mual, dan kembung, umumnya dipicu pola makan tidak teratur, stres, infeksi bakteri H. pylori, atau efek samping obat-obatan tertentu.'),
        BeritaBlockSubjudul('Makanan yang Aman dan Dianjurkan'),
        BeritaBlockBulletList([
          'Karbohidrat kompleks: beras merah, gandum utuh, oatmeal, kentang, dan ubi',
          'Sayuran tinggi antioksidan: bayam, brokoli, labu kuning, wortel',
          'Protein rendah lemak: ayam tanpa kulit, ikan, tahu, tempe, telur rebus',
          'Buah non-sitrus: pisang, pepaya, melon, apel'
        ]),
        BeritaBlockTips('Terapkan porsi kecil tapi sering (5–6 kali sehari), hindari menunda waktu makan, dan beri jeda 2–3 jam setelah makan sebelum berbaring.'),
      ],
      bacaJuga: ['pola-makan-baik-asam-lambung'],
    ),
    BeritaArticle(
      id: 'pertolongan-pertama-asam-lambung',
      kategori: 'Gaya Hidup',
      tanggal: DateTime(2025, 7, 6),
      gambarAsset: 'assets/images/berita/berita_6.png',
      gambarAlignment: const Alignment(0, 0),
      sumberNama: 'ANTARA News',
      sumberUrl: 'https://www.antaranews.com/berita/4947537/asam-lambung-naik-terapkan-7-langkah-pertolongan-pertama-ini',
      judul: 'Asam Lambung Naik? Terapkan 7 Langkah Pertolongan Pertama Ini',
      ringkasanSingkat: 'Asam lambung naik sering muncul saat melewatkan waktu makan, stres, atau setelah makanan pemicu. Ada 7 langkah pertolongan pertama yang bisa dilakukan.',
      status: 'terbit',
      konten: [
        BeritaBlockParagraph(
            'Asam lambung naik sering muncul saat melewatkan waktu makan, stres, atau setelah makanan pemicu; kondisi ini dikenal sebagai GERD.'),
        BeritaBlockButirAngka(
            nomor: 1, judul: 'Longgarkan pakaian ketat', isi: 'Kurangi tekanan pada perut dengan mengendurkan ikat pinggang atau kancing celana.'),
        BeritaBlockButirAngka(
            nomor: 2, judul: 'Duduk tegak', isi: 'Posisi tegak mengurangi tekanan pada katup lambung-kerongkongan.'),
        BeritaBlockButirAngka(
            nomor: 3, judul: 'Tinggikan posisi kepala saat berbaring', isi: 'Gunakan bantal tambahan membentuk sudut 30–45 derajat.'),
        BeritaBlockButirAngka(
            nomor: 4, judul: 'Minum air jahe hangat', isi: 'Sifat antiradang jahe membantu meredakan mual.'),
        BeritaBlockButirAngka(
            nomor: 5, judul: 'Kunyah permen karet', isi: 'Merangsang air liur yang membantu menetralkan asam.'),
        BeritaBlockButirAngka(
            nomor: 6, judul: 'Konsumsi satu sendok teh madu', isi: 'Membantu melindungi lapisan kerongkongan.'),
        BeritaBlockButirAngka(
            nomor: 7, judul: 'Tidur miring ke kiri', isi: 'Posisi ini membantu mengurangi tekanan pada lambung.'),
        BeritaBlockParagraph(
            'Langkah ini membantu meringankan gejala, tetapi bila keluhan sering berulang atau memberat, tetap perlu konsultasi ke tenaga medis.'),
      ],
      bacaJuga: ['kenapa-genz-sakit-lambung'],
    ),
    BeritaArticle(
      id: 'beda-maag-dan-gerd',
      kategori: 'Pencernaan',
      tanggal: DateTime(2026, 9, 18),
      gambarAsset: 'assets/images/berita/berita_7.png',
      gambarAlignment: const Alignment(0, 0),
      sumberNama: 'ANTARA News',
      sumberUrl: 'https://www.antaranews.com/berita/5747907/apa-bedanya-maag-dan-gerd-kenali-gejala-dan-penyebabnya',
      judul: 'Apa Bedanya Maag dan GERD? Kenali Gejala dan Penyebabnya',
      ringkasanSingkat: 'Maag adalah peradangan dinding lambung, sedangkan GERD adalah kondisi kronis ketika asam lambung naik ke kerongkongan akibat melemahnya katup sfingter esofagus bawah.',
      status: 'terbit',
      konten: [
        BeritaBlockParagraph(
            'Maag (gastritis/dispepsia) adalah peradangan dinding lambung, sedangkan GERD adalah kondisi kronis ketika asam lambung naik ke kerongkongan akibat melemahnya katup sfingter esofagus bawah.'),
        BeritaBlockSubjudul('Gejalanya Berbeda'),
        BeritaBlockParagraph(
            'Maag bergejala nyeri ulu hati, mual, kembung, dan cepat kenyang; GERD bergejala rasa terbakar di dada, mulut pahit/asam, bau mulut, dan batuk kering kronis.'),
        BeritaBlockSubjudul('Penyebabnya Juga Berbeda'),
        BeritaBlockParagraph(
            'Maag dipicu infeksi bakteri H. pylori, obat pereda nyeri jangka panjang, atau stres; GERD dipicu obesitas, kebiasaan langsung berbaring setelah makan, merokok, kehamilan, dan makanan tinggi lemak/kafein/pedas.'),
      ],
      bacaJuga: ['mengenal-gerd-penanganan-dini'],
    ),
    BeritaArticle(
      id: 'beda-jantung-dan-asam-lambung',
      kategori: 'Kesehatan Umum',
      tanggal: DateTime(2026, 9, 20),
      gambarAsset: 'assets/images/berita/berita_8.png',
      gambarAlignment: const Alignment(0, 0),
      sumberNama: 'ANTARA News',
      sumberUrl: 'https://www.antaranews.com/berita/5731188/sering-dianggap-mirip-ini-bedanya-sakit-jantung-dan-asam-lambung',
      judul: 'Sering Dianggap Mirip, Ini Bedanya Sakit Jantung dan Asam Lambung',
      ringkasanSingkat: 'Nyeri dada sering dikaitkan dengan asam lambung, padahal gangguan jantung bisa menimbulkan keluhan serupa. Penting untuk mengenali perbedaannya.',
      status: 'terbit',
      konten: [
        BeritaBlockParagraph(
            'Nyeri dada sering dikaitkan dengan asam lambung, padahal gangguan jantung bisa menimbulkan keluhan serupa.'),
        BeritaBlockParagraph(
            'Ciri khas refluks asam lambung adalah heartburn di tengah dada belakang tulang dada, disertai rasa asam/pahit di mulut, makanan terasa naik ke tenggorokan, mual, sulit menelan, batuk kronis, atau suara serak.'),
        BeritaBlockTandaBahaya(items: [
          'Nyeri dada yang tidak jelas penyebabnya, terutama disertai sesak napas, keringat dingin, atau menjalar ke lengan, perlu segera diperiksakan ke layanan gawat darurat untuk menyingkirkan kemungkinan gangguan jantung.'
        ]),
      ],
      bacaJuga: ['begadang-asam-lambung'],
    ),
    BeritaArticle(
      id: 'pola-makan-baik-asam-lambung',
      kategori: 'Gizi',
      tanggal: DateTime(2025, 7, 29),
      gambarAsset: 'assets/images/berita/berita_9.png',
      gambarAlignment: const Alignment(0, 0),
      sumberNama: 'ANTARA News',
      sumberUrl: 'https://www.antaranews.com/berita/4998689/pola-makan-yang-baik-bagi-penderita-asam-lambung',
      judul: 'Pola Makan yang Baik bagi Penderita Asam Lambung',
      ringkasanSingkat: 'Pola makan tepat adalah kunci mengendalikan gejala GERD. Makan dalam porsi kecil tapi sering dan menghindari makanan pemicu adalah langkah utamanya.',
      status: 'terbit',
      konten: [
        BeritaBlockParagraph(
            'Pola makan tepat adalah kunci mengendalikan gejala GERD.'),
        BeritaBlockBulletList([
          'Makan dalam porsi kecil tapi sering, bukan porsi besar sekaligus',
          'Hindari makanan pemicu: gorengan/berlemak, pedas, asam, serta minuman berkafein dan bersoda',
          'Pilih makanan yang direbus, dikukus, atau dipanggang tanpa minyak berlebih',
          'Hindari makan menjelang tidur, beri jeda 2–3 jam'
        ]),
        BeritaBlockTips(
            'Contoh sarapan sehat pukul 06.00–08.00: oatmeal, sereal, roti gandum, atau pisang.'),
      ],
      bacaJuga: ['makanan-aman-untuk-maag'],
    ),
  ];

  // ────────────────────────────────────────────────────────────────────────────
  // API Publik (async — dibaca dari Firestore, fallback ke data statis)
  // ────────────────────────────────────────────────────────────────────────────

  /// Ambil semua artikel berstatus "terbit".
  /// Membaca data sinkron dari BeritaService / Firestore, dengan fallback ke data statis.
  static Future<List<BeritaArticle>> getAll() async {
    try {
      final snap = await _fs
          .collection(_col)
          .where('status', isEqualTo: 'terbit')
          .get();
      if (snap.docs.isNotEmpty) {
        final List<BeritaArticle> list = [];
        for (final doc in snap.docs) {
          try {
            final art = BeritaArticle.fromFirestore(doc);
            final stat = _staticArticles.where((a) => a.id == doc.id).firstOrNull;
            if (stat != null && (art.kontenMarkdown == null || art.kontenMarkdown!.trim().isEmpty || art.konten.isEmpty)) {
              list.add(stat);
            } else {
              list.add(art);
            }
          } catch (docErr) {
            debugPrint('[BeritaRepository] Dokumen rusak ${doc.id} dilewati: $docErr');
          }
        }
        if (list.isNotEmpty) {
          list.sort((a, b) {
            if (a.tanggal == null && b.tanggal == null) return 0;
            if (a.tanggal == null) return 1;
            if (b.tanggal == null) return -1;
            return b.tanggal!.compareTo(a.tanggal!);
          });
          return list;
        }
      }
    } catch (e) {
      debugPrint('BeritaRepository.getAll remote note: $e');
    }

    // Fallback: data statis lokal (sudah diurutkan terbaru dulu)
    final sorted = List<BeritaArticle>.from(_staticArticles);
    sorted.sort((a, b) {
      if (a.tanggal == null && b.tanggal == null) return 0;
      if (a.tanggal == null) return 1;
      if (b.tanggal == null) return -1;
      return b.tanggal!.compareTo(a.tanggal!);
    });
    return sorted;
  }

  /// Ambil artikel berdasarkan ID dari Firestore atau data lokal.
  static Future<BeritaArticle?> getById(String id) async {
    final stat = _staticArticles.where((a) => a.id == id).firstOrNull;
    try {
      final doc = await _fs.collection(_col).doc(id).get();
      if (doc.exists) {
        final art = BeritaArticle.fromFirestore(doc);
        if (stat != null && (art.kontenMarkdown == null || art.kontenMarkdown!.trim().isEmpty || art.konten.isEmpty)) {
          return stat;
        }
        return art;
      }
    } catch (e) {
      debugPrint('BeritaRepository.getById error: $e');
    }
    return stat;
  }

  /// Kembalikan data statis sinkron (untuk sisi pengguna yang masih sync).
  /// Dipakai oleh widget yang belum dikonversi ke async.
  static List<BeritaArticle> getStaticAll() => List.from(_staticArticles);

  static BeritaArticle? getStaticById(String id) =>
      _staticArticles.where((a) => a.id == id).firstOrNull;
}

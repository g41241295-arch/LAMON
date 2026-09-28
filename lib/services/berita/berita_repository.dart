// lib/services/berita/berita_repository.dart
// Sumber data berita LAMON (lokal / statis).
// Nanti bisa diganti dengan Firestore tanpa mengubah UI:
//   - Ganti BeritaRepository.getAll() dengan stream/future Firestore
//   - Model BeritaArticle tetap sama

import '../../models/berita_article_model.dart';

class BeritaRepository {
  // ───────────────────────────────────────────────────────────────────────────
  // Data statis – urut terbaru dulu (tanggal descending)
  // ───────────────────────────────────────────────────────────────────────────
  static final List<BeritaArticle> _articles = [
    // ── Berita 1 ──────────────────────────────────────────────────────────────
    BeritaArticle(
      id: 'gerd-bukan-sekadar-maag',
      judulKartu:
          'GERD Bukan Sekadar Maag Biasa: Mengapa Anak Muda Kini Sering Mengalaminya?',
      judulDetail:
          'GERD Bukan Sekadar Maag Biasa: Mengapa Anak Muda Kini Sering Mengalaminya?',
      kategori: 'Pencernaan',
      tanggal: DateTime(2026, 1, 28),
      gambarAsset: 'assets/images/berita/berita_gerd_anak_muda.jpg',
      konten: [
        BeritaBlockParagraph(
          'GERD (Gastroesophageal Reflux Disease) atau penyakit refluks gastroesofagus adalah kondisi kronis di mana asam lambung sering naik ke kerongkongan (esofagus), menyebabkan iritasi pada lapisan esofagus. Berbeda dengan maag biasa (dyspepsia) yang umumnya hanya menyebabkan nyeri ulu hati sesekali, GERD adalah kondisi yang lebih serius dan berulang.',
        ),
        BeritaBlockSubjudul(
          'Mengapa GERD Banyak Terjadi pada Anak Muda ?',
        ),
        BeritaBlockParagraph(
          'GERD terjadi ketika Lower Esophageal Sphincter (LES)—otot berbentuk cincin di bagian bawah kerongkongan—melemah atau tidak berfungsi normal. LES seharusnya membuka untuk memungkinkan makanan masuk ke lambung, lalu menutup rapat untuk mencegah isi lambung naik kembali. Ketika LES melemah, asam lambung dapat mengalir balik ke esofagus.',
        ),
        BeritaBlockTips(
          'Hindari makan larut malam dan kurangi makanan berlemak untuk menjaga LES tetap berfungsi optimal',
        ),
      ],
      bacaJuga: ['5-kebiasaan-makan'],
    ),

    // ── Berita 2 ──────────────────────────────────────────────────────────────
    BeritaArticle(
      id: '5-kebiasaan-makan',
      judulKartu: '5 kebiasaan makan yang perburuk asam lambung',
      judulDetail:
          '5 Kebiasaan Makan Yang Merusak Lambung, Jangan Dianggap Sepele',
      kategori: 'Gizi',
      tanggal: DateTime(2026, 1, 26),
      gambarAsset: 'assets/images/berita/berita_kebiasaan_makan.jpg',
      konten: [
        BeritaBlockParagraph(
          'Lambung berperan penting dalam mencerna makanan sebelum nutrisi diserap oleh tubuh. Namun tanpa disadari, ada sejumlah kebiasaan makan yang merusak lambung dan dapat meningkatkan risiko berbagai gangguan pencernaan.',
        ),
        BeritaBlockParagraph(
          'Jika terus dilakukan, kebiasaan tersebut berpotensi memicu sakit maag, asam lambung naik (GERD), radang lambung (gastritis), hingga tukak lambung. Agar kesehatan lambung tetap terjaga, berikut beberapa kebiasaan makan yang sebaiknya mulai dihindari:',
        ),
        BeritaBlockButirAngka(
          nomor: 1,
          judul: 'Sering melewatkan waktu makan',
          isi: 'Menurut Mission Gastro Hospital, salah satu kebiasaan makan yang dapat merusak lambung adalah sering melewatkan waktu makan. Banyak orang sengaja melewatkan sarapan atau menunda makan karena kesibukan. Padahal, lambung tetap memproduksi asam meski tidak ada makanan yang masuk.',
        ),
        BeritaBlockButirAngka(
          nomor: 2,
          judul: 'Makan dalam porsi berlebihan',
          isi: 'Makan terlalu banyak membuat lambung bekerja lebih keras untuk mencerna makanan. Kondisi ini menyebabkan lambung meregang dan menghasilkan lebih banyak asam. Akibatnya, Anda bisa mengalami perut begah, mual, gangguan pencernaan, hingga asam lambung naik ke kerongkongan. Sebaiknya makan dalam porsi secukupnya dan berhenti sebelum merasa terlalu kenyang.',
        ),
        BeritaBlockButirAngka(
          nomor: 3,
          judul: 'Terlalu sering mengonsumsi makanan olahan',
          isi: 'Makanan instan, makanan cepat saji, dan camilan kemasan umumnya tinggi garam, gula, lemak jenuh, serta bahan tambahan pangan. Selain rendah serat, makanan jenis ini juga dapat mengganggu keseimbangan bakteri baik di saluran cerna. Jika dikonsumsi terlalu sering, makanan olahan dapat meningkatkan risiko peradangan pada lambung sekaligus memicu gangguan pencernaan.',
        ),
        BeritaBlockButirAngka(
          nomor: 4,
          judul: 'Kurang mengonsumsi makanan berserat',
          isi: 'Serat berperan penting dalam menjaga kesehatan saluran cerna dan membantu memperlancar proses pencernaan. Jika asupan serat kurang, proses pencernaan menjadi lebih lambat sehingga dapat menyebabkan sembelit, perut terasa penuh, dan tidak nyaman. Perbanyak konsumsi buah, sayuran, kacang-kacangan, dan biji-bijian untuk memenuhi kebutuhan serat harian.',
        ),
        BeritaBlockButirAngka(
          nomor: 5,
          judul: 'Terlalu banyak minum kopi',
          isi: 'Kopi memang dapat meningkatkan energi, tetapi konsumsi berlebihan juga dapat merangsang produksi asam lambung. Jika diminum saat perut kosong, risiko iritasi lambung bisa semakin besar. Bagi penderita maag atau GERD, membatasi konsumsi kopi dapat membantu mengurangi munculnya keluhan.',
        ),
      ],
      bacaJuga: ['mengenal-gerd'],
    ),

    // ── Berita 3 ──────────────────────────────────────────────────────────────
    BeritaArticle(
      id: 'mengenal-gerd',
      judulKartu: 'Mengenal GERD dan cara mencegahnya sejak dini',
      judulDetail: 'Mengenal GERD dan Cara Mencegahnya Sejak Dini',
      kategori: 'Pencernaan',
      tanggal: DateTime(2026, 1, 25),
      gambarAsset: 'assets/images/berita/berita_mengenal_gerd.jpg',
      konten: [
        BeritaBlockParagraph(
          'GERD (Gastroesophageal Reflux Disease) adalah kondisi ketika asam lambung naik berulang kali ke kerongkongan. Berbeda dari maag biasa, GERD bersifat kronis dan bisa memicu komplikasi jika dibiarkan tanpa penanganan.',
        ),
        BeritaBlockJudulBagian('Kenali Gejalanya'),
        BeritaBlockBulletList([
          'Sensasi panas/terbakar di dada (heartburn)',
          'Rasa asam atau pahit di tenggorokan',
          'Mudah kenyang, mual, atau sering bersendawa',
        ]),
        BeritaBlockJudulBagian('Cara Mencegah Sejak Dini'),
        BeritaBlockArrowList([
          'Makan teratur, hindari menunda jam makan',
          'Tidak langsung berbaring setelah makan',
          'Batasi kopi, makanan pedas dan berlemak',
          'Jaga berat badan ideal, kelola stres',
        ]),
      ],
      bacaJuga: ['kapan-periksa-dokter'],
    ),

    // ── Berita 4 ──────────────────────────────────────────────────────────────
    BeritaArticle(
      id: 'kapan-periksa-dokter',
      judulKartu: 'Kapan harus periksa ke dokter saat maag berulang?',
      judulDetail: 'Kapan Harus Periksa ke Dokter soal Maag yang Berulang?',
      kategori: 'Gaya Hidup',
      tanggal: DateTime(2026, 1, 23),
      gambarAsset: 'assets/images/berita/berita_kapan_ke_dokter.jpg',
      konten: [
        BeritaBlockParagraph(
          'Maag sesekali biasanya tidak berbahaya dan bisa mereda dengan istirahat atau obat lambung biasa. Namun jika keluhan terus berulang dalam waktu berdekatan, itu bisa jadi tanda kondisi yang butuh pemeriksaan lebih lanjut, bukan sekadar diobati sendiri terus-menerus.',
        ),
        BeritaBlockJudulBagian('Maag Biasa vs Perlu Diperiksa'),
        BeritaBlockPerbandingan(
          judulHijau: 'Masih wajar',
          isiHijau:
              'Muncul sesekali, reda dalam 1-2 hari, ada pemicu jelas (telat makan, makan pedas dan lainnya)',
          judulMerah: 'Perlu diperiksa',
          isiMerah:
              'Lebih dari 2x seminggu, berlangsung berminggu-minggu, makin sering kambuh',
        ),
        BeritaBlockTandaBahaya(
          judul: 'Tanda Bahaya, Jangan Ditunda',
          items: [
            'Sulit atau nyeri saat menelan',
            'Muntah darah atau BAB berwarna hitam',
            'Berat badan turun drastis tanpa sebab jelas',
            'Nyeri dada disertai sesak napas',
          ],
        ),
        BeritaBlockParagraph(
          'Bila salah satu tanda di atas muncul, segera periksakan diri ke fasilitas kesehatan terdekat, jangan menunggu sampai membaik sendiri. Dokter mungkin akan merekomendasikan pemeriksaan lanjutan seperti endoskopi untuk mengetahui penyebab pastinya.',
        ),
      ],
      bacaJuga: [], // tidak ada "Baca juga" untuk berita ini
    ),
  ];

  // ───────────────────────────────────────────────────────────────────────────
  // Public API
  // ───────────────────────────────────────────────────────────────────────────

  /// Kembalikan semua artikel, urut terbaru dulu.
  static List<BeritaArticle> getAll() => List.unmodifiable(_articles);

  /// Cari artikel berdasarkan id. Kembalikan null jika tidak ditemukan.
  static BeritaArticle? getById(String id) {
    try {
      return _articles.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

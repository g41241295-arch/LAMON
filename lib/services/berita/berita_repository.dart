import 'package:flutter/material.dart';
import '../../models/berita_article_model.dart';

class BeritaRepository {
  // Data disimpan statis lokal. Nanti bisa diganti Firestore tanpa mengubah UI.
  static final List<BeritaArticle> _articles = [
    BeritaArticle(
      id: 'remaja-asam-lambung',
      kategori: 'Pencernaan',
      gambarAsset: 'assets/images/berita/berita_1.png',
      gambarAlignment: const Alignment(0, -0.6),
      sumberNama: 'RRI Meulaboh',
      sumberUrl: 'https://rri.co.id/meulaboh/kesehatan/2128978/remaja-zaman-sekarang-rentan-mengalami-penyakit-asam-lambung',
      judul: 'Remaja Zaman Sekarang Rentan Mengalami Penyakit Asam Lambung',
      // TODO: isi tanggal terbit sesuai halaman sumber.
      tanggal: null,
      konten: [
        // TODO: ganti dengan ringkasan lengkap setelah teks berita tersedia.
        BeritaBlockParagraph(
            'Keluhan asam lambung kini tidak hanya dialami orang dewasa. Remaja masa kini juga semakin rentan mengalaminya.'),
      ],
      bacaJuga: ['mengenal-gerd-penanganan-dini'],
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
      konten: [
        BeritaBlockParagraph(
            'GERD (gastroesophageal reflux disease) adalah gangguan saluran cerna yang cukup banyak ditemukan di Indonesia. Kondisi ini terjadi ketika isi lambung, termasuk asam lambung, naik kembali ke kerongkongan dan menimbulkan berbagai keluhan.'),
        BeritaBlockParagraph(
            'Menurut Konsensus Nasional Penatalaksanaan Penyakit GERD Indonesia 2022, prevalensi GERD pada populasi umum di Indonesia diperkirakan sekitar 9,35 persen.'),
        BeritaBlockSubjudul('Bisa Berkembang Menjadi Lebih Serius'),
        BeritaBlockParagraph(
            'GERD dapat berkembang menjadi esofagitis erosif, yaitu peradangan kerongkongan yang disertai kerusakan pada lapisannya. Data dari rumah sakit rujukan tingkat tersier menunjukkan 55,4 persen pasien GERD mengalami kondisi ini. Karena itu, diagnosis yang tepat dan penanganan sejak dini sangat penting, dan strategi pengobatan perlu disesuaikan dengan kondisi masing-masing pasien.'),
        BeritaBlockSubjudul('Dibahas dalam Simposium Ahli'),
        BeritaBlockParagraph(
            'Topik ini dibahas dalam simposium yang dihadiri lebih dari 150 dokter spesialis penyakit dalam dan konsultan gastroenterologi pada rangkaian Indonesian Digestive Disease Week (IDDW) 2026 di Jakarta, 18 September 2026. Simposium diselenggarakan oleh PT Daewoong Pharmaceutical Indonesia dan membahas perkembangan terapi GERD, termasuk golongan obat P-CAB serta hasil penelitian yang melibatkan pasien di Indonesia.'),
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
      konten: [
        BeritaBlockParagraph(
            'Guru Besar Ilmu Penyakit Dalam konsultan gastroenterologi–hepatologi FK UI RSCM, Prof. Dr. dr. Ari Fahrial Syam, SpPD-KGEH, menyatakan bahwa GERD dapat sembuh apabila faktor risikonya dikurangi dan pengobatan dijalankan sampai tuntas. Pernyataan ini disampaikan dalam diskusi kesehatan tentang GERD bersama Primaya Hospital di Jakarta pada 5 Maret 2026.'),
        BeritaBlockSubjudul('Perbaiki Gaya Hidup'),
        BeritaBlockBulletList([
          'Berhenti merokok dan tidak mengonsumsi alkohol',
          'Turunkan berat badan jika berlebih',
          'Terapkan pola makan rendah lemak',
          'Olahraga teratur, tidur cukup, dan kelola stres'
        ]),
        BeritaBlockSubjudul('Siapa yang Rentan?'),
        BeritaBlockParagraph(
            'Berdasarkan penelitiannya, penderita GERD umumnya laki-laki, merokok, obesitas, dan berusia di atas 40 tahun. Namun kini banyak anak yang juga mengalaminya, antara lain karena pola makan tidak sehat, kebiasaan tidur setelah makan, dan kurang bergerak akibat terlalu lama bermain gawai.'),
        BeritaBlockSubjudul('Kapan Perlu Endoskopi?'),
        BeritaBlockParagraph(
            'Untuk menilai GERD, dokter penyakit dalam biasanya melakukan endoskopi guna melihat tingkat keparahan luka dan kondisi katup lambung. Pemeriksaan ini dianjurkan bila muncul nyeri dada atau ulu hati, rasa terbakar di dada, atau muntah berulang, dan juga membantu mengantisipasi komplikasi serius, termasuk kemungkinan kanker, akibat luka yang tidak diobati.'),
        BeritaBlockParagraph(
            'Obat penekan asam lambung juga perlu diminum sampai penyakit tuntas. Menurut narasumber, kini telah hadir golongan obat baru bernama P-CAB yang menjadi harapan bagi penderita GERD.'),
      ],
      bacaJuga: ['begadang-asam-lambung'],
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
      konten: [
        BeritaBlockParagraph(
            'Begadang tidak hanya membuat tubuh lelah keesokan harinya. Kebiasaan tidur larut dan kurang tidur juga berkaitan dengan meningkatnya keluhan asam lambung, terutama pada orang yang sudah memiliki GERD. Hubungan ini diperkuat oleh tinjauan sistematis dan meta-analisis yang terbit pada Januari 2026, yang menganalisis 18 studi dengan total 110.417 peserta.'),
        BeritaBlockSubjudul('Mengapa Begadang Memicu Asam Lambung?'),
        BeritaBlockButirAngka(
            nomor: 1,
            judul: 'Kurang tidur meningkatkan paparan asam',
            isi: 'Dalam sebuah penelitian, peserta yang hanya tidur empat jam selama dua malam mengalami peningkatan parameter refluks dibanding yang tidur tujuh sampai delapan jam. Ini tidak berarti setiap orang yang begadang pasti mengalami GERD.'),
        BeritaBlockButirAngka(
            nomor: 2,
            judul: 'Begadang sering diikuti makan larut malam',
            isi: 'Jika langsung berbaring atau tidur tak lama setelah makan, isi lambung lebih mudah naik ke kerongkongan. Pedoman American College of Gastroenterology menyarankan penderita GERD menghindari makan dua hingga tiga jam sebelum tidur.'),
        BeritaBlockButirAngka(
            nomor: 3,
            judul: 'Pembersihan asam berkurang saat tidur',
            isi: 'Saat tidur, gerak peristaltik dan produksi air liur yang membantu membersihkan sisa asam menurun, sehingga asam bertahan lebih lama di kerongkongan.'),
        BeritaBlockButirAngka(
            nomor: 4,
            judul: 'Gejala terasa lebih berat',
            isi: 'Kurang tidur membuat seseorang lebih peka terhadap refluks, sehingga nyeri ulu hati atau rasa terbakar di dada terasa lebih mengganggu.'),
        BeritaBlockSubjudul('Cara Mengurangi Risikonya'),
        BeritaBlockBulletList([
          'Beri jeda sekitar 2–3 jam setelah makan sebelum berbaring',
          'Tinggikan bagian kepala tempat tidur',
          'Berbaring miring ke kiri dapat membantu pada sebagian penderita',
          'Atur jam tidur agar lebih teratur'
        ]),
        BeritaBlockSubjudul('Kapan Perlu ke Dokter?'),
        BeritaBlockTandaBahaya(items: [
          'Keluhan asam lambung muncul berulang atau mengganggu tidur',
          'Sulit menelan atau muntah',
          'Berat badan turun tanpa sebab yang jelas',
          'Disertai nyeri dada'
        ]),
      ],
      bacaJuga: ['air-ph-tinggi-sebelum-terbang'],
    ),
    BeritaArticle(
      id: 'air-ph-tinggi-sebelum-terbang',
      kategori: 'Gizi',
      // TODO: isi tanggal terbit sesuai halaman sumber.
      tanggal: null,
      gambarAsset: 'assets/images/berita/berita_5.png',
      gambarAlignment: const Alignment(0, -0.8),
      sumberNama: 'RRI Pontianak',
      sumberUrl: 'https://rri.co.id/pontianak/kesehatan/2525684/penderita-gerd-disarankan-minum-air-ph-tinggi-sebelum-terbang-benarkah-efektif',
      judul: 'Penderita GERD Disarankan Minum Air pH Tinggi sebelum Terbang, Benarkah Efektif?',
      konten: [
        BeritaBlockParagraph(
            'Tips minum air pH tinggi (air alkali) sebelum naik pesawat ramai dibagikan di media sosial. Cara ini diklaim dapat membantu mencegah asam lambung naik selama penerbangan, terutama bagi penderita GERD.'),
        BeritaBlockSubjudul('Sudah Terbukti Secara Ilmiah?'),
        BeritaBlockParagraph(
            'Hingga saat ini belum ada penelitian yang membuktikan bahwa tekanan kabin pesawat secara langsung menyebabkan refluks asam lambung. Air pH tinggi sendiri adalah air minum yang lebih basa, umumnya berada pada kisaran pH 8–9.'),
        BeritaBlockParagraph(
            'Penelitian yang sering dijadikan rujukan, oleh Dr. Jamie A. Koufman dan Dr. Nikki Johnston (Annals of Otology, Rhinology & Laryngology, 2012), menemukan bahwa air dengan pH 8,8 dapat menonaktifkan enzim pepsin di laboratorium. Pepsin berperan dalam kerusakan jaringan akibat refluks.'),
        BeritaBlockParagraph(
            'Namun temuan itu berasal dari penelitian in vitro, bukan uji klinis pada manusia. Hasilnya menunjukkan adanya potensi mekanisme biologis, tetapi belum membuktikan bahwa minum air alkali dapat mencegah atau mengatasi GERD pada semua orang, termasuk sebelum penerbangan.'),
        // TODO: lengkapi ringkasan dengan bagian akhir artikel sumber.
      ],
      bacaJuga: ['remaja-asam-lambung'],
    ),
  ];

  static List<BeritaArticle> getAll() {
    return _articles;
  }

  static BeritaArticle getById(String id) {
    return _articles.firstWhere(
      (a) => a.id == id,
      orElse: () => _articles.first,
    );
  }
}

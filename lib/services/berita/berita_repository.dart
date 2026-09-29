import 'package:flutter/material.dart';
import '../../models/berita_article_model.dart';

class BeritaRepository {
  // Data disimpan statis lokal. Nanti bisa diganti Firestore tanpa mengubah UI.
  static final List<BeritaArticle> _articles = [
    BeritaArticle(
      id: 'kenapa-genz-sakit-lambung',
      kategori: 'Gaya Hidup',
      tanggal: DateTime(2026, 9, 18),
      gambarAsset: 'assets/images/berita/berita_1.png',
      gambarAlignment: const Alignment(0, -0.6),
      sumberNama: 'ANTARA News',
      sumberUrl: 'https://www.antaranews.com/berita/5747829/kenapa-gen-z-sering-sakit-lambung-ini-4-penyebabnya',
      judul: 'Kenapa Gen Z Sering Sakit Lambung? Ini 4 Penyebabnya',
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
      konten: [
        BeritaBlockParagraph(
            'Sakit maag (dispepsia) adalah gejala tidak nyaman di perut bagian atas seperti rasa terbakar, nyeri ulu hati, mual, dan kembung, umumnya dipicu pola makan tidak teratur, stres, infeksi bakteri H. pylori, atau efek samping obat-obatan tertentu.'),
        BeritaBlockSubjudul('Makanan yang Aman dan Dianjurkan'),
        BeritaBlockBulletList([
          'Karbohidrat kompleks: beras merah, gandum utuh, oatmeal, kentang, dan ubi — membantu menyerap kelebihan asam lambung',
          'Sayuran tinggi antioksidan: bayam, brokoli, labu kuning, wortel — membantu pemulihan peradangan dinding lambung',
          'Protein rendah lemak: ayam tanpa kulit, ikan, tahu, tempe, telur rebus — lebih mudah dicerna',
          'Buah non-sitrus: pisang, pepaya, melon, apel — tingkat keasaman rendah'
        ]),
        BeritaBlockSubjudul('Makanan dan Minuman yang Harus Dihindari'),
        BeritaBlockBulletList([
          'Makanan pedas dan berbumbu tajam: cabai, lada, merica, rempah kuat',
          'Makanan tinggi lemak dan bersantan: gorengan, olahan bersantan kental, makanan cepat saji',
          'Buah dan makanan asam: jeruk, lemon, nanas, tomat, cuka',
          'Minuman berkafein, berkarbonasi, dan beralkohol: kopi, teh pekat, soda, alkohol'
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
      konten: [
        BeritaBlockParagraph(
            'Maag (gastritis/dispepsia) adalah peradangan dinding lambung, sedangkan GERD adalah kondisi kronis ketika asam lambung naik ke kerongkongan akibat melemahnya katup sfingter esofagus bawah.'),
        BeritaBlockSubjudul('Gejalanya Berbeda'),
        BeritaBlockParagraph(
            'Maag bergejala nyeri ulu hati, mual, kembung, dan cepat kenyang; GERD bergejala rasa terbakar di dada, mulut pahit/asam, bau mulut, dan batuk kering kronis.'),
        BeritaBlockSubjudul('Penyebabnya Juga Berbeda'),
        BeritaBlockParagraph(
            'Maag dipicu infeksi bakteri H. pylori, obat pereda nyeri jangka panjang, atau stres; GERD dipicu obesitas, kebiasaan langsung berbaring setelah makan, merokok, kehamilan, dan makanan tinggi lemak/kafein/pedas.'),
        BeritaBlockParagraph(
            'Penanganan mengandalkan perubahan gaya hidup (porsi kecil tapi sering, jeda 2–3 jam sebelum tidur) dan obat penurun asam sesuai anjuran dokter.'),
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
      konten: [
        BeritaBlockParagraph(
            'Nyeri dada sering dikaitkan dengan asam lambung, padahal gangguan jantung bisa menimbulkan keluhan serupa.'),
        BeritaBlockParagraph(
            'Ciri khas refluks asam lambung adalah heartburn di tengah dada belakang tulang dada, disertai rasa asam/pahit di mulut, makanan terasa naik ke tenggorokan, mual, sulit menelan, batuk kronis, atau suara serak. Pola ini lebih terkait aktivitas pencernaan dan posisi tubuh, meski bukan patokan mutlak.'),
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

  static List<BeritaArticle> getAll() {
    return _articles;
  }

  static BeritaArticle? getById(String id) {
    return _articles.where((a) => a.id == id).firstOrNull;
  }
}

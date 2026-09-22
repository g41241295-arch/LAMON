enum GastropediaCategory {
  makanan(
    label: 'Makanan',
    badgeText: 'MAKANAN',
    thumbnailAsset: 'assets/images/gastropedia/cat_makanan.jpg',
  ),
  buah(
    label: 'Buah',
    badgeText: 'BUAH',
    thumbnailAsset: 'assets/images/gastropedia/cat_buah.jpg',
  ),
  sayuran(
    label: 'Sayuran',
    badgeText: 'SAYUR',
    thumbnailAsset: 'assets/images/gastropedia/cat_sayuran.jpg',
  );

  final String label;
  final String badgeText;
  final String thumbnailAsset;

  const GastropediaCategory({
    required this.label,
    required this.badgeText,
    required this.thumbnailAsset,
  });
}

class GastropediaItem {
  final String id;
  final String name;
  final GastropediaCategory category;
  final String imageAsset;
  final String deskripsi;
  final List<String> manfaat;
  final List<String> kandungan;
  final bool isRecommended;

  const GastropediaItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageAsset,
    required this.deskripsi,
    required this.manfaat,
    required this.kandungan,
    this.isRecommended = false,
  });
}

class GastropediaData {
  static final List<GastropediaItem> items = [
    // ==========================================
    // 1. MAKANAN
    // ==========================================
    const GastropediaItem(
      id: 'capcay',
      name: 'Capcay',
      category: GastropediaCategory.makanan,
      imageAsset: 'assets/images/gastropedia/capcay.jpg',
      deskripsi:
          'Capcay adalah masakan yang terdiri dari aneka sayuran, seperti wortel, kembang kol, dan sawi, serta tambahan protein, seperti ayam, udang, atau bakso. Proses pengolahan capcay umumnya menggunakan minyak dan bumbu pelengkap, seperti saus tiram, kecap, atau kaldu.',
      manfaat: [
        '1. Melancarkan pencernaan\nKandungan serat dari wortel, kol, sawi, brokoli, dan sayuran lainnya membantu menjaga kesehatan saluran pencernaan.',
        '2. Meningkatkan daya tahan tubuh\nVitamin C dan berbagai antioksidan membantu mendukung sistem imun.',
        '3. Menjaga kesehatan mata\nSayuran seperti wortel mengandung beta-karoten yang dapat diubah tubuh menjadi vitamin A.',
      ],
      kandungan: [
        '1. Serat -> membantu melancarkan pencernaan dan membuat kenyang lebih lama.',
        '2. Vitamin A -> baik untuk kesehatan mata dan sistem kekebalan tubuh.',
        '3. Vitamin C -> membantu meningkatkan daya tahan tubuh dan berperan sebagai antioksidan.',
        '4. Vitamin K -> berperan dalam pembekuan darah dan kesehatan tulang.',
        '5. Folat (vitamin B9) -> penting untuk pembentukan sel dan jaringan tubuh.',
      ],
    ),
    const GastropediaItem(
      id: 'brokoli-chicken',
      name: 'Brokoli Chicken',
      category: GastropediaCategory.makanan,
      imageAsset: 'assets/images/gastropedia/brokoli_chicken.jpg',
      isRecommended: true,
      deskripsi:
          'Brokoli Chicken adalah kombinasi dada ayam panggang rendah lemak dengan brokoli kukus kaya serat. Hidangan ini sangat ideal untuk penderita asam lambung karena tidak memicu refluks dan kaya nutrisi penyembuh mukosa.',
      manfaat: [
        '1. Menstabilkan asam lambung\nKandungan protein tanpa lemak dari dada ayam membantu mengikat asam lambung tanpa membebani sfingter lambung.',
        '2. Menekan bakteri H. pylori\nSulforaphane pada brokoli secara klinis membantu menekan pertumbuhan bakteri pemicu tukak lambung.',
        '3. Mencegah peradangan dinding lambung\nKombinasi antioksidan alami meredakan iritasi pada lapisan dinding lambung (gastritis).',
      ],
      kandungan: [
        '1. Protein tinggi -> mempercepat regenerasi jaringan mukosa lambung yang rusak.',
        '2. Sulforaphane -> senyawa anti-inflamasi alami pelindung saluran pencernaan.',
        '3. Vitamin C & K -> menjaga elastisitas pembuluh darah dan memperkuat imunitas.',
        '4. Kalium -> menyeimbangkan kadar asam-basa (pH) cairan tubuh.',
      ],
    ),
    const GastropediaItem(
      id: 'nasi-teriyaki',
      name: 'Nasi Teriyaki',
      category: GastropediaCategory.makanan,
      imageAsset: 'assets/images/gastropedia/nasi_teriyaki.jpg',
      deskripsi:
          'Nasi hangat pulen yang disajikan dengan irisan daging ayam tanpa lemak dan saus teriyaki ringan non-pedas. Dibuat dengan takaran bumbu ramah lambung tanpa cabai, merica berlebih, atau cuka.',
      manfaat: [
        '1. Sumber karbohidrat kompleks yang ramah lambung\nNasi mudah dicerna dan memberikan rasa kenyang bertahap tanpa memicu begah.',
        '2. Menjaga kestabilan energi harian\nMembantu mencegah penurunan gula darah mendadak yang kerap memicu stres asam lambung.',
        '3. Asupan protein seimbang\nProtein ayam mendukung metabolisme tubuh tanpa merangsang sekresi asam secara berlebihan.',
      ],
      kandungan: [
        '1. Karbohidrat kompleks -> energi stabil bagi metabolisme tubuh.',
        '2. Protein hewani rendah lemak -> membangun dan memperbaiki sel tubuh.',
        '3. Zat besi & Zinc -> mendukung daya tahan tubuh dan produksi sel darah merah.',
      ],
    ),
    const GastropediaItem(
      id: 'salad',
      name: 'Salad',
      category: GastropediaCategory.makanan,
      imageAsset: 'assets/images/gastropedia/salad.jpg',
      deskripsi:
          'Salad sayuran segar dengan paduan selada hijau, timun iris, jagung manis pipil, dan dressing minyak zaitun ringan. Sangat menyegarkan dan memiliki sifat alkalis alami yang menetralkan keasaman cairan lambung.',
      manfaat: [
        '1. Menetralkan asam lambung tinggi\nSayuran hijau segar bersifat basa yang membantu meredakan sensasi panas di ulu hati.',
        '2. Menghidrasi saluran cerna\nKandungan air alami pada timun dan selada menjaga kelembapan mukosa lambung.',
        '3. Kaya enzim pencernaan alami\nMembantu penyerapan nutrisi makanan secara optimal di usus halus.',
      ],
      kandungan: [
        '1. Air & Klorofil -> detoksifikasi alami dan penyejuk saluran cerna.',
        '2. Vitamin E & C -> antioksidan kuat pelindung membran sel lambung.',
        '3. Serat larut air -> melunakkan feses dan melancarkan motilitas usus.',
      ],
    ),
    const GastropediaItem(
      id: 'brokoli-chicken-roll',
      name: 'Brokoli chiken roll',
      category: GastropediaCategory.makanan,
      imageAsset: 'assets/images/gastropedia/brokoli_chicken_roll.jpg',
      deskripsi:
          'Gulungan dada ayam cincang yang diisi dengan kuntum brokoli kukus lembut dan wortel serut, kemudian dikukus hingga matang sempurna tanpa proses penggorengan minyak jelantah.',
      manfaat: [
        '1. Bebas lemak jenuh pemicu GERD\nMetode pengolahan kukus menjaga sfingter esofagus tetap tertutup rapat.',
        '2. Tekstur empuk yang mudah dicerna\nMeringankan kontraksi mekanik otot dinding lambung saat mencerna makanan.',
        '3. Membantu penyembuhan luka lambung\nAsupan asam amino lengkap dari ayam mempercepat epitelisasi jaringan mukosa.',
      ],
      kandungan: [
        '1. Protein murni tinggi -> bahan baku regenerasi jaringan tubuh.',
        '2. Beta-karoten & Vitamin A -> melindungi integritas selaput lendir lambung.',
        '3. Kalsium & Fosfor -> mendukung kekuatan struktur tulang dan gigi.',
      ],
    ),
    const GastropediaItem(
      id: 'sop-ayam',
      name: 'Sop Ayam',
      category: GastropediaCategory.makanan,
      imageAsset: 'assets/images/gastropedia/sop_ayam.jpg',
      deskripsi:
          'Sup bening berkaldu ayam alami dengan potongan wortel, kentang, buncis, dan seledri. Kuah hangatnya memberikan efek relaksasi yang menenangkan pada saluran lambung yang sedang sensitif.',
      manfaat: [
        '1. Meredakan kram dan perih di perut\nKuah hangat membantu mengendurkan otot lambung yang tegang.',
        '2. Cepat diserap dan mengembalikan stamina\nSangat dianjurkan saat pemulihan sakit maag akut atau gangguan refluks.',
        '3. Menggantikan cairan elektrolit\nMencegah dehidrasi dan menjaga keseimbangan asam lambung.',
      ],
      kandungan: [
        '1. Kolagen & Glisin alami -> memperkuat lapisan mukosa dinding lambung.',
        '2. Vitamin B kompleks -> mengoptimalkan metabolisme energi seluler.',
        '3. Kalium & Magnesium -> relaksasi otot polos saluran pencernaan.',
      ],
    ),
    const GastropediaItem(
      id: 'sayur-asem',
      name: 'Sayur Asem',
      category: GastropediaCategory.makanan,
      imageAsset: 'assets/images/gastropedia/sayur_asem.jpg',
      deskripsi:
          'Sayur bening tradisional khas nusantara berisi labu siam, jagung manis, kacang panjang, dan melinjo dengan sentuhan asam alami yang sangat lembut dan diracik tanpa cabai berlebih.',
      manfaat: [
        '1. Merangsang nafsu makan secara aman\nRasa segar alaminya menggugah selera tanpa menimbulkan iritasi di esofagus.',
        '2. Melancarkan buang air besar\nSerat alami dari labu siam dan kacang panjang mencegah sembelit pemicu tekanan lambung.',
        '3. Memberikan asupan mineral esensial\nMenjaga keseimbangan elektrolit tubuh secara alami.',
      ],
      kandungan: [
        '1. Serat pangan alami -> menjaga keteraturan waktu pengosongan lambung.',
        '2. Vitamin C & Polifenol -> antioksidan penangkal radikal bebas.',
        '3. Kalsium & Zat Besi -> mendukung kekuatan tubuh.',
      ],
    ),

    // ==========================================
    // 2. BUAH
    // ==========================================
    const GastropediaItem(
      id: 'pisang',
      name: 'Pisang',
      category: GastropediaCategory.buah,
      imageAsset: 'assets/images/gastropedia/pisang.jpg',
      deskripsi:
          'Pisang adalah buah bertekstur lembut dan bersifat antasida alami dengan pH sekitar 5.6. Kandungan kalium dan pektinnya sangat efektif melapisi dinding lambung dari gesekan asam lambung.',
      manfaat: [
        '1. Antasida alami lambung\nMembantu menetralkan kelebihan asam dan meredakan rasa panas di dada (heartburn).',
        '2. Melapisi mukosa lambung\nPektin membentuk lapisan lendir pelindung terhadap cairan asam lambung yang agresif.',
        '3. Camilan aman saat perut kosong\nMemberikan energi instan tanpa merangsang kontraksi asam berlebih.',
      ],
      kandungan: [
        '1. Kalium tinggi -> menetralkan keasaman tubuh dan mengatur tekanan darah.',
        '2. Vitamin B6 -> mendukung fungsi saraf dan metabolisme protein.',
        '3. Pektin (serat larut) -> memperlancar motilitas dan kesehatan usus.',
      ],
    ),
    const GastropediaItem(
      id: 'pepaya',
      name: 'Pepaya',
      category: GastropediaCategory.buah,
      imageAsset: 'assets/images/gastropedia/pepaya.jpg',
      deskripsi:
          'Pepaya matang mengandung enzim proteolitik alami bernama papain yang membantu memecah ikatan protein makanan secara cepat, sehingga meringankan tugas asam lambung.',
      manfaat: [
        '1. Mempercepat cerna protein\nEnzim papain membantu mencerna daging dan protein sehingga lambung cepat kosong.',
        '2. Meredakan begah dan kembung\nGas di saluran pencernaan berkurang secara signifikan setelah mengonsumsi pepaya.',
        '3. Mencegah sembelit\nKandungan air dan serat tingginya memperlancar buang air besar tanpa rasa mulas.',
      ],
      kandungan: [
        '1. Enzim Papain -> katalis pemecah protein yang ramah pencernaan.',
        '2. Vitamin C & Beta-karoten -> regenerasi jaringan epitel yang rusak.',
        '3. Asam Folat & Kalium -> menjaga daya tahan sel tubuh.',
      ],
    ),
    const GastropediaItem(
      id: 'apel',
      name: 'Apel',
      category: GastropediaCategory.buah,
      imageAsset: 'assets/images/gastropedia/apel.jpg',
      deskripsi:
          'Apel manis (seperti apel fuji atau apel merah) kaya akan pektin dan serat larut yang mampu mengikat kelebihan asam lambung dan racun di saluran pencernaan.',
      manfaat: [
        '1. Mengikat asam lambung\nPektin bertindak sebagai spons lembut yang menyerap cairan asam lambung berlebih.',
        '2. Menyehatkan mikrobioma usus\nBertindak sebagai prebiotik bagi bakteri baik di usus besar.',
        '3. Memberikan rasa kenyang bertahan lama\nMencegah kebiasaan ngemil makanan berlemak tinggi pemicu maag.',
      ],
      kandungan: [
        '1. Pektin -> serat larut air yang sangat lembut bagi saluran cerna.',
        '2. Quercetin -> antioksidan penenang peradangan lambung.',
        '3. Vitamin C & Kalsium -> memperkuat imunitas dan struktur jaringan tubuh.',
      ],
    ),
    const GastropediaItem(
      id: 'melon',
      name: 'Melon',
      category: GastropediaCategory.buah,
      imageAsset: 'assets/images/gastropedia/melon.jpg',
      deskripsi:
          'Melon memiliki kadar air sangat tinggi (90%+) dan memiliki pH sekitar 6.1 (mendekati netral/alkalin), menjadikannya salah satu buah paling aman dikonsumsi oleh penderita GERD berat.',
      manfaat: [
        '1. Bersifat alkalin penyejuk\nMembantu menyeimbangkan kadar asam lambung dan mendinginkan tenggorokan.',
        '2. Menghidrasi organ pencernaan\nKadar air berlimpah melarutkan asam yang terakumulasi di dalam lambung.',
        '3. Sangat ringan di perut\nMudah dicerna dalam waktu singkat tanpa menghasilkan gas berlebih.',
      ],
      kandungan: [
        '1. Air alami murni (>90%) -> menjaga hidrasi mukosa lambung.',
        '2. Vitamin C & Kalium -> mengontrol tekanan pembuluh darah lambung.',
        '3. Karotenoid -> melindungi selaput lendir dari stres oksidatif.',
      ],
    ),
    const GastropediaItem(
      id: 'alpukat',
      name: 'Alpukat',
      category: GastropediaCategory.buah,
      imageAsset: 'assets/images/gastropedia/alpukat.jpg',
      deskripsi:
          'Alpukat kaya akan lemak tak jenuh tunggal yang sehat serta tekstur lembut yang menenangkan mukosa lambung, tidak menyebabkan refluks selama dikonsumsi dalam porsi wajar.',
      manfaat: [
        '1. Melapisi dinding lambung\nLemak tak jenuh tunggal melapisi mukosa dan melindunginya dari korosi asam.',
        '2. Anti-inflamasi alami\nAsam lemak omega-9 membantu meredakan pembengkakan dinding lambung yang radang.',
        '3. Mengenyangkan lebih stabil\nMengendalikan lonjakan nafsu makan berlebih yang sering memicu asam lambung.',
      ],
      kandungan: [
        '1. Asam Oleat (lemak sehat) -> pelindung mukosa pencernaan.',
        '2. Vitamin E & B6 -> antioksidan larut lemak pelindung membran sel.',
        '3. Kalium tinggi -> lebih tinggi dari pisang untuk menyeimbangkan pH tubuh.',
      ],
    ),
    const GastropediaItem(
      id: 'buah-naga',
      name: 'Buah Naga',
      category: GastropediaCategory.buah,
      imageAsset: 'assets/images/gastropedia/buah_naga.jpg',
      deskripsi:
          'Buah naga manis dengan daging merah atau putih kaya akan serat larut, air, dan biji kecil yang mengandung lemak baik. Sangat efektif mendinginkan perut yang begah.',
      manfaat: [
        '1. Menyejukkan perut dan lambung\nMemberikan rasa nyaman instan bagi penderita heartburn dan dispepsia.',
        '2. Prebiotik alami usus\nKandungan oligosakarida menyuburkan bakteri baik flora usus.',
        '3. Mempercepat penyembuhan iritasi\nKandungan antioksidan betalain melindungi sel lambung dari inflamasi.',
      ],
      kandungan: [
        '1. Betalain & Flavonoid -> antioksidan penangkal inflamasi lambung.',
        '2. Vitamin C & Zat Besi -> pembentukan hemoglobin dan daya tahan.',
        '3. Serat pangan alami -> melancarkan waktu transit makanan.',
      ],
    ),

    // ==========================================
    // 3. SAYURAN
    // ==========================================
    const GastropediaItem(
      id: 'sayur-bayam',
      name: 'Sayur Bayam',
      category: GastropediaCategory.sayuran,
      imageAsset: 'assets/images/gastropedia/sayur_bayam.jpg',
      deskripsi:
          'Sayur bayam bening tanpa santan sangat mudah dicerna dan kaya akan klorofil serta zat besi yang meregenerasi lapisan sel mukosa lambung yang teriritasi.',
      manfaat: [
        '1. Mempercepat regenerasi sel mukosa\nKlorofil dan antioksidannya membantu perbaikan sel lambung yang luka.',
        '2. Sangat mudah dicerna\nTidak memerlukan waktu pengosongan lambung yang lama sehingga mencegah refluks.',
        '3. Mencegah anemia pada penderita maag\nZat besi alami memulihkan kadar hemoglobin tubuh.',
      ],
      kandungan: [
        '1. Klorofil & Zat Besi -> regenerasi sel darah dan jaringan epitel.',
        '2. Vitamin A, C, dan K -> pemulihan pembekuan darah dan integritas membran.',
        '3. Magnesium -> merelaksasi otot pencernaan yang tegang.',
      ],
    ),
    const GastropediaItem(
      id: 'labu-siam',
      name: 'Labu Siam',
      category: GastropediaCategory.sayuran,
      imageAsset: 'assets/images/gastropedia/labu_siam.jpg',
      deskripsi:
          'Labu siam kukus atau rebus memiliki kadar air melimpah dan tekstur yang sangat lunak saat dikunyah. Salah satu sayur rekomendasi nomor satu bagi pasien gastritis dan tukak lambung.',
      manfaat: [
        '1. Tekstur ekstra lembut\nTidak menimbulkan gesekan mekanis pada dinding lambung yang sedang sensitif.',
        '2. Meredakan nyeri ulu hati\nMembantu menetralkan asam dan mendinginkan saluran lambung bagian atas.',
        '3. Rendah kalori & tidak menghasilkan gas\nAman dikonsumsi dalam porsi banyak tanpa takut kembung.',
      ],
      kandungan: [
        '1. Air & Serat lunak -> ramah di lambung dan mudah diserap.',
        '2. Folat & Kalium -> menyeimbangkan cairan tubuh dan mendukung sintesis DNA.',
        '3. Vitamin C alami -> mendukung imunitas jaringan lokal.',
      ],
    ),
    const GastropediaItem(
      id: 'wortel',
      name: 'Wortel',
      category: GastropediaCategory.sayuran,
      imageAsset: 'assets/images/gastropedia/wortel.jpg',
      deskripsi:
          'Wortel rebus atau kukus manis alami dan kaya akan beta-karoten yang berperan vital dalam menjaga kesehatan serta mempercepat perbaikan selaput lendir lambung.',
      manfaat: [
        '1. Memperbaiki mukosa lambung\nBeta-karoten dikonversi tubuh menjadi vitamin A untuk melapisi selaput lendir lambung.',
        '2. Menstabilkan fungsi empedu\nMembantu mengontrol proses pencernaan lemak agar tidak memberatkan lambung.',
        '3. Menenangkan lambung\nSerat halusnya mengikat kelebihan asam tanpa merangsang produksi asam baru.',
      ],
      kandungan: [
        '1. Beta-karoten (Pro-Vitamin A) -> regenerasi jaringan epitel saluran cerna.',
        '2. Pektin (serat larut) -> mengikat asam berlebih di rongga lambung.',
        '3. Vitamin K1 & Kalium -> kesehatan tulang dan regulasi asam tubuh.',
      ],
    ),
    const GastropediaItem(
      id: 'brokoli',
      name: 'Brokoli',
      category: GastropediaCategory.sayuran,
      imageAsset: 'assets/images/gastropedia/brokoli.jpg',
      deskripsi:
          'Brokoli kukus mengandung senyawa sulforaphane yang telah terbukti secara ilmiah mampu menekan kolonisasi bakteri Helicobacter pylori, bakteri utama penyebab tukak lambung kronis.',
      manfaat: [
        '1. Menghambat bakteri H. pylori\nSulforaphane melindungi lambung dari risiko radang lambung kronis.',
        '2. Mengurangi risiko kanker lambung\nKaya fitonutrien antikarsinogenik yang melindungi DNA sel lambung.',
        '3. Membersihkan residu saluran cerna\nSerat pangannya membantu pengosongan usus secara teratur.',
      ],
      kandungan: [
        '1. Sulforaphane & Isothiocyanate -> agen protektif antibakteri lambung.',
        '2. Vitamin C dosis tinggi -> mendukung sintesis kolagen dinding mukosa.',
        '3. Kalsium & Kromium -> metabolisme mineral sel pencernaan.',
      ],
    ),
    const GastropediaItem(
      id: 'kentang',
      name: 'Kentang',
      category: GastropediaCategory.sayuran,
      imageAsset: 'assets/images/gastropedia/kentang.jpg',
      deskripsi:
          'Kentang rebus atau kukus bersifat basa (alkalis) yang sangat ampuh menyerap dan menetralkan asam lambung secara cepat, sangat disarankan sebagai pengganti karbohidrat saat maag kambuh.',
      manfaat: [
        '1. Menetralkan asam lambung tinggi\nSifat alkalisnya menenangkan rasa perih di lambung dalam hitungan menit.',
        '2. Melapisi lambung dengan pati resisten\nPati kentang melindungi lapisan lambung dari pengikisan asam.',
        '3. Memberikan rasa kenyang aman\nKarbohidrat mudah cerna yang tidak memicu fermentasi gas di usus.',
      ],
      kandungan: [
        '1. Pati resisten -> melindungi dan menenangkan permukaan dinding lambung.',
        '2. Kalium tinggi -> menetralkan asam dan menjaga fungsi otot lambung.',
        '3. Vitamin B6 & C -> mendukung metabolisme sel dan imunitas.',
      ],
    ),
    const GastropediaItem(
      id: 'kembang-kol',
      name: 'Kembang Kol',
      category: GastropediaCategory.sayuran,
      imageAsset: 'assets/images/gastropedia/kembang_kol.jpg',
      deskripsi:
          'Kembang kol kukus yang diolah tanpa bumbu pedas kaya akan fitonutrien dan senyawa sulfur alami yang membantu menutrisi sel-sel saluran pencernaan.',
      manfaat: [
        '1. Melindungi lapisan mukosa lambung\nSenyawa glukosinolat menjaga integritas dinding lambung.',
        '2. Mendukung detoksifikasi saluran cerna\nAntioksidannya menangkal radikal bebas sisa metabolisme makanan.',
        '3. Menyehatkan pencernaan\nMembantu melancarkan pengeluaran sisa makanan tanpa rasa mulas.',
      ],
      kandungan: [
        '1. Glukosinolat & Sulforaphane -> senyawa pertahanan mukosa lambung.',
        '2. Vitamin C, K, dan Folat -> regenerasi sel darah dan jaringan tubuh.',
        '3. Kolin -> mendukung fungsi saraf motilitas lambung.',
      ],
    ),
  ];

  static List<GastropediaItem> getByCategory(GastropediaCategory category) {
    return items.where((item) => item.category == category).toList();
  }

  static GastropediaItem getRecommended() {
    return items.firstWhere(
      (item) => item.isRecommended,
      orElse: () => items.first,
    );
  }

  static GastropediaItem? getById(String id) {
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}

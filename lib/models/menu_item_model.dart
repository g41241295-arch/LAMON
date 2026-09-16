import '../constants/app_assets.dart';

class MainMenuItem {
  final String id;
  final String title;
  final String shortTitle;
  final String route;
  final String assetPath;
  final String description;
  final bool implemented;

  const MainMenuItem({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.route,
    required this.assetPath,
    required this.description,
    this.implemented = false,
  });
}

class InfoMenuItem {
  final String id;
  final String title;
  final String route;
  final String assetPath;
  final String description;
  final bool implemented;

  const InfoMenuItem({
    required this.id,
    required this.title,
    required this.route,
    required this.assetPath,
    required this.description,
    this.implemented = false,
  });
}

class AppMenus {
  static const List<MainMenuItem> mainMenus = [
    MainMenuItem(
      id: 'pengingat-jam-makan',
      title: 'Pengingat\nJam Makan',
      shortTitle: 'Pengingat Jam Makan',
      route: '/pengingat-jam-makan',
      assetPath: AppAssets.menuPengingat,
      description: 'Atur jadwal pengingat makan teratur untuk menjaga asam lambung tetap stabil.',
    ),
    MainMenuItem(
      id: 'catat-makananmu',
      title: 'Catat\nMakananmu',
      shortTitle: 'Catat Makananmu',
      route: '/catat-makananmu',
      assetPath: AppAssets.menuCatat,
      description: 'Catat asupan makanan harian Anda untuk melacak pemicu maag atau GERD.',
    ),
    MainMenuItem(
      id: 'konsul-dokter',
      title: 'Konsul\nDokter',
      shortTitle: 'Konsul Dokter',
      route: '/konsul-dokter',
      assetPath: AppAssets.menuKonsul,
      description: 'Konsultasi langsung dengan dokter spesialis lambung dan pencernaan.',
    ),
    MainMenuItem(
      id: 'prediksi-penyakit',
      title: 'Prediksi\nPenyakit',
      shortTitle: 'Prediksi Penyakit',
      route: '/prediksi-penyakit',
      assetPath: AppAssets.menuPrediksi,
      description: 'Cek gejala lambung dan analisis kemungkinan gangguan kesehatan lambung.',
      implemented: true,
    ),
    MainMenuItem(
      id: 'ringkasan-makanan',
      title: 'Ringkasan\nMakanan',
      shortTitle: 'Ringkasan Makanan',
      route: '/ringkasan-makanan',
      assetPath: AppAssets.menuRingkasan,
      description: 'Laporan mingguan dan evaluasi nutrisi ramah lambung.',
    ),
  ];

  static const List<InfoMenuItem> infoMenus = [
    InfoMenuItem(
      id: 'gastropedia',
      title: 'Gastropedia',
      route: '/gastropedia',
      assetPath: AppAssets.infoGastro,
      description: 'Ensiklopedia lengkap seputar kesehatan lambung, GERD, asam lambung, dan pencegahannya.',
    ),
    InfoMenuItem(
      id: 'berita-kesehatan',
      title: 'Berita Kesehatan',
      route: '/berita-kesehatan',
      assetPath: AppAssets.infoBerita,
      description: 'Kumpulan berita dan artikel terkini seputar pola hidup sehat dan kesehatan pencernaan.',
    ),
  ];
}

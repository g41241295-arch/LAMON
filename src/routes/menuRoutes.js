// Registry rute dan menu LAMON
// File ini dibuat modular agar Anda dapat dengan sangat mudah menambahkan halaman-halaman baru
// ketika desain Figma berikutnya selesai dibuat, tanpa merombak alur navigasi yang sudah ada.

export const MAIN_MENUS = [
  {
    id: 'pengingat-jam-makan',
    title: 'Pengingat\nJam Makan',
    shortTitle: 'Pengingat Jam Makan',
    path: '/pengingat-jam-makan',
    imageKey: 'menu-pengingat',
    description: 'Atur jadwal pengingat makan teratur untuk menjaga asam lambung stabil.',
    implemented: false,
  },
  {
    id: 'catat-makananmu',
    title: 'Catat\nMakananmu',
    shortTitle: 'Catat Makananmu',
    path: '/catat-makananmu',
    imageKey: 'menu-catat',
    description: 'Catat asupan makanan harian Anda untuk melacak pemicu maag atau GERD.',
    implemented: false,
  },
  {
    id: 'konsul-dokter',
    title: 'Konsul\nDokter',
    shortTitle: 'Konsul Dokter',
    path: '/konsul-dokter',
    imageKey: 'menu-konsul',
    description: 'Konsultasi langsung dengan dokter spesialis lambung dan pencernaan.',
    implemented: false,
  },
  {
    id: 'prediksi-penyakit',
    title: 'Prediksi\nPenyakit',
    shortTitle: 'Prediksi Penyakit',
    path: '/prediksi-penyakit',
    imageKey: 'menu-prediksi',
    description: 'Cek gejala lambung dan analisis kemungkinan gangguan kesehatan lambung.',
    implemented: false,
  },
  {
    id: 'ringkasan-makanan',
    title: 'Ringkasan\nMakanan',
    shortTitle: 'Ringkasan Makanan',
    path: '/ringkasan-makanan',
    imageKey: 'menu-ringkasan',
    description: 'Laporan mingguan dan evaluasi nutrisi ramah lambung.',
    implemented: false,
  },
];

export const INFO_MENUS = [
  {
    id: 'gastropedia',
    title: 'Gastropedia',
    path: '/gastropedia',
    imageKey: 'info-gastro',
    description: 'Ensiklopedia lengkap seputar kesehatan lambung, GERD, asam lambung, dan pencegahannya.',
    implemented: false,
  },
  {
    id: 'berita-kesehatan',
    title: 'Berita Kesehatan',
    path: '/berita-kesehatan',
    imageKey: 'info-berita',
    description: 'Kumpulan berita dan artikel terkini seputar pola hidup sehat dan kesehatan pencernaan.',
    implemented: false,
  },
];

export const NAV_MENUS = [
  {
    id: 'chat',
    title: 'Pesan & Konsultasi',
    path: '/chat',
    implemented: false,
  },
  {
    id: 'beranda',
    title: 'Beranda',
    path: '/beranda',
    implemented: true,
  },
  {
    id: 'profile',
    title: 'Profil Pengguna',
    path: '/profile',
    implemented: false,
  },
];

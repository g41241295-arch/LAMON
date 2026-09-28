// lib/models/berita_article_model.dart
// Model artikel berita LAMON.
// Sumber data saat ini lokal (BeritaRepository).
// Nanti bisa diganti dengan Firestore tanpa mengubah UI.

// ─────────────────────────────────────────────────────────────────────────────
// Tipe-tipe blok konten artikel
// ─────────────────────────────────────────────────────────────────────────────

/// Basis dari semua blok konten
sealed class BeritaBlock {}

/// Paragraf teks biasa
class BeritaBlockParagraph extends BeritaBlock {
  final String text;
  BeritaBlockParagraph(this.text);
}

/// Subjudul bold (ukuran sama dengan paragraf, style bold lebih besar)
class BeritaBlockSubjudul extends BeritaBlock {
  final String text;
  BeritaBlockSubjudul(this.text);
}

/// Judul bagian (ukuran lebih besar, warna aksen biru)
class BeritaBlockJudulBagian extends BeritaBlock {
  final String text;
  BeritaBlockJudulBagian(this.text);
}

/// Butir berangka: nomor + judul bold + paragraf isi di bawahnya
class BeritaBlockButirAngka extends BeritaBlock {
  final int nomor;
  final String judul;
  final String isi;
  BeritaBlockButirAngka({
    required this.nomor,
    required this.judul,
    required this.isi,
  });
}

/// Daftar dengan bullet "•"
class BeritaBlockBulletList extends BeritaBlock {
  final List<String> items;
  BeritaBlockBulletList(this.items);
}

/// Daftar dengan tanda ">"
class BeritaBlockArrowList extends BeritaBlock {
  final List<String> items;
  BeritaBlockArrowList(this.items);
}

/// Kotak tips (strip biru tebal di kiri, label "Tips:" bold)
class BeritaBlockTips extends BeritaBlock {
  final String isi;
  BeritaBlockTips(this.isi);
}

/// Dua kartu perbandingan berdampingan (hijau vs merah)
class BeritaBlockPerbandingan extends BeritaBlock {
  final String judulHijau;
  final String isiHijau;
  final String judulMerah;
  final String isiMerah;
  BeritaBlockPerbandingan({
    required this.judulHijau,
    required this.isiHijau,
    required this.judulMerah,
    required this.isiMerah,
  });
}

/// Kotak tanda bahaya (latar peach, ikon segitiga merah outline, teks merah tua)
class BeritaBlockTandaBahaya extends BeritaBlock {
  final String judul;
  final List<String> items;
  BeritaBlockTandaBahaya({required this.judul, required this.items});
}

// ─────────────────────────────────────────────────────────────────────────────
// Model utama artikel
// ─────────────────────────────────────────────────────────────────────────────

class BeritaArticle {
  final String id;
  final String judulKartu;
  final String judulDetail;
  final String kategori;
  final DateTime tanggal;
  final String gambarAsset;
  final List<BeritaBlock> konten;
  final List<String> bacaJuga; // list id berita
  final String? sumber; // ditampilkan kecil di akhir artikel jika terisi

  const BeritaArticle({
    required this.id,
    required this.judulKartu,
    required this.judulDetail,
    required this.kategori,
    required this.tanggal,
    required this.gambarAsset,
    required this.konten,
    this.bacaJuga = const [],
    this.sumber,
  });
}

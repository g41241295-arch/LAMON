import 'package:flutter/material.dart';

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

/// Kotak tips (strip biru tebal di kiri, label "Tips:" bold)
class BeritaBlockTips extends BeritaBlock {
  final String isi;
  BeritaBlockTips(this.isi);
}

/// Kotak tanda bahaya (latar peach, ikon segitiga merah outline, teks merah tua)
class BeritaBlockTandaBahaya extends BeritaBlock {
  final List<String> items;
  BeritaBlockTandaBahaya({required this.items});
}

// ─────────────────────────────────────────────────────────────────────────────
// Model utama artikel
// ─────────────────────────────────────────────────────────────────────────────

class BeritaArticle {
  final String id;
  final String judul;
  final String kategori;
  final DateTime? tanggal;
  final String gambarAsset;
  final Alignment gambarAlignment;
  final List<BeritaBlock> konten;
  final List<String> bacaJuga; // list id berita
  final String sumberNama;
  final String sumberUrl;

  const BeritaArticle({
    required this.id,
    required this.judul,
    required this.kategori,
    this.tanggal,
    required this.gambarAsset,
    required this.gambarAlignment,
    required this.konten,
    this.bacaJuga = const [],
    required this.sumberNama,
    required this.sumberUrl,
  });
}

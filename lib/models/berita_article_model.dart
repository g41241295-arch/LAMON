import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// lib/models/berita_article_model.dart
// Model artikel berita LAMON.
// Sumber data: Firestore collection `berita_articles`.

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
  /// Path asset lokal (artikel lama) atau URL Firebase Storage (artikel baru)
  final String gambarAsset;
  final Alignment gambarAlignment;
  final List<BeritaBlock> konten;
  final List<String> bacaJuga; // list id berita
  final String sumberNama;
  final String sumberUrl;
  // ── Field baru untuk CRUD admin ──
  /// Ringkasan 1-2 kalimat untuk preview card
  final String ringkasanSingkat;
  /// Status publikasi: "terbit" | "draft"
  final String status;
  /// Konten markdown mentah dari editor admin (null untuk artikel lama)
  final String? kontenMarkdown;

  const BeritaArticle({
    required this.id,
    required this.judul,
    required this.kategori,
    this.tanggal,
    required this.gambarAsset,
    this.gambarAlignment = Alignment.center,
    required this.konten,
    this.bacaJuga = const [],
    required this.sumberNama,
    this.sumberUrl = '',
    this.ringkasanSingkat = '',
    this.status = 'terbit',
    this.kontenMarkdown,
  });

  /// Membuat BeritaArticle dari dokumen Firestore.
  /// Tangguh terhadap format data: jika ada field kosong/salah tipe, fallback ke default aman.
  factory BeritaArticle.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final Map<String, dynamic> data = (raw is Map<String, dynamic>)
        ? raw
        : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});

    DateTime? tanggal;
    final tanggalRaw = data['tanggal'];
    if (tanggalRaw is Timestamp) {
      tanggal = tanggalRaw.toDate();
    } else if (tanggalRaw is int) {
      tanggal = DateTime.fromMillisecondsSinceEpoch(tanggalRaw);
    } else if (tanggalRaw is String && tanggalRaw.isNotEmpty) {
      tanggal = DateTime.tryParse(tanggalRaw);
    }

    final kontenMarkdown = data['kontenMarkdown']?.toString() ?? '';
    final ringkasanSingkat = data['ringkasanSingkat']?.toString() ?? '';

    List<BeritaBlock> konten;
    if (kontenMarkdown.isNotEmpty) {
      konten = parseMarkdown(kontenMarkdown);
    } else {
      konten = [BeritaBlockParagraph(ringkasanSingkat)];
    }

    List<String> bacaJuga = [];
    final rawBacaJuga = data['bacaJuga'];
    if (rawBacaJuga is Iterable) {
      bacaJuga = rawBacaJuga
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    }

    return BeritaArticle(
      id: doc.id,
      judul: data['judul']?.toString() ?? '',
      kategori: data['kategori']?.toString() ?? '',
      tanggal: tanggal,
      gambarAsset: data['gambarUrl']?.toString() ?? data['gambarAsset']?.toString() ?? '',
      gambarAlignment: Alignment.center,
      konten: konten,
      bacaJuga: bacaJuga,
      sumberNama: data['sumberNama']?.toString() ?? '',
      sumberUrl: data['sumberUrl']?.toString() ?? '',
      ringkasanSingkat: ringkasanSingkat,
      status: data['status']?.toString() ?? 'terbit',
      kontenMarkdown: kontenMarkdown.isEmpty ? null : kontenMarkdown,
    );
  }

  /// Parse konten markdown ringan menjadi list BeritaBlock.
  /// Format: baris berawalan "- " = bullet, selainnya = paragraf.
  static List<BeritaBlock> parseMarkdown(String markdown) {
    final lines = markdown.split('\n');
    final List<BeritaBlock> blocks = [];
    final List<String> bulletBuffer = [];

    void flushBullets() {
      if (bulletBuffer.isNotEmpty) {
        blocks.add(BeritaBlockBulletList(List.from(bulletBuffer)));
        bulletBuffer.clear();
      }
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        flushBullets();
        continue;
      }
      if (trimmed.startsWith('- ')) {
        bulletBuffer.add(trimmed.substring(2).trim());
      } else {
        flushBullets();
        blocks.add(BeritaBlockParagraph(trimmed));
      }
    }
    flushBullets();
    return blocks.isEmpty ? [BeritaBlockParagraph(markdown)] : blocks;
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'judul': judul,
      'judulLower': judul.toLowerCase(),
      'kategori': kategori,
      'tanggal': tanggal != null ? Timestamp.fromDate(tanggal!) : null,
      'gambarUrl': gambarAsset,
      'bacaJuga': bacaJuga,
      'sumberNama': sumberNama,
      'sumberUrl': sumberUrl,
      'ringkasanSingkat': ringkasanSingkat,
      'status': status,
      if (kontenMarkdown != null) 'kontenMarkdown': kontenMarkdown,
    };
  }
}

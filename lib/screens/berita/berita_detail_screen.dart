import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../services/berita/berita_repository.dart';
import '../../models/berita_article_model.dart';
import '../../widgets/berita/berita_image.dart';
import '../../widgets/berita/berita_content_block.dart';
import '../../widgets/berita/berita_card_small.dart';

class BeritaDetailScreen extends StatefulWidget {
  final String articleId;

  const BeritaDetailScreen({super.key, required this.articleId});

  @override
  State<BeritaDetailScreen> createState() => _BeritaDetailScreenState();
}

class _BeritaDetailScreenState extends State<BeritaDetailScreen> {
  BeritaArticle? _article;
  bool _loading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    final article = await BeritaRepository.getById(widget.articleId);
    if (mounted) {
      setState(() {
        _article = article;
        _notFound = article == null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFCFBF7),
        Color(0xFFF7F4EB),
        Color(0xFFF2EEDB),
      ],
    );

    if (_loading) {
      return Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (_notFound || _article == null) {
      return Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryText),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Berita tidak ditemukan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Artikel yang Anda cari mungkin sudah\ntidak tersedia atau terjadi kesalahan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryText.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Kembali'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF276F8F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final article = _article!;

    String? formattedDate;
    if (article.tanggal != null) {
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
      final d = article.tanggal!;
      formattedDate = '${d.day} ${months[d.month - 1]} ${d.year}';
    }

    final publisherName = article.sumberNama.isNotEmpty
        ? article.sumberNama
        : 'LAMON Media';

    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. Hero Image Besar dengan Sudut Bawah Melengkung (Sesuai Referensi) ───
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 310,
                    child: BeritaImage(
                      gambarUrl: article.gambarUrl,
                      gambarAsset: article.gambarAsset,
                      width: double.infinity,
                      height: 310,
                      borderRadius: 0,
                      alignment: article.gambarAlignment,
                    ),
                  ),
                ),

                // Gradasi halus di bagian atas foto untuk tombol back
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Tombol Kembali Bulat Putih di Kiri Atas
                Positioned(
                  top: topInset + 8,
                  left: 16,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEBE3D0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF1C4E68),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ─── 2. Header Penulis / Sumber Berita (Sesuai Referensi) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Avatar / Logo Sumber
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F6F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4E3ED),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        publisherName.isNotEmpty
                            ? publisherName.substring(0, 1).toUpperCase()
                            : 'L',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF276F8F),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Nama Sumber & Waktu Terbit
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          publisherName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C4E68),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (formattedDate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7C8E97),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Kategori Tag Pill di Kanan
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F6F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD4E3ED),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      article.kategori.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF276F8F),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── 3. Headline Judul Berita Besar & Tegas (Sesuai Referensi) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                article.judul,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C4E68),
                  height: 1.35,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Ringkasan Singkat / Lead Paragraph (jika ada)
            if (article.ringkasanSingkat.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4EB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEBE3D0),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    article.ringkasanSingkat,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: Color(0xFF3E2818),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // Garis Pembatas Halus
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: Color(0xFFEBE3D0)),
            ),

            const SizedBox(height: 18),

            // ─── 4. Konten Blok Artikel ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: article.konten.map((block) {
                  return BeritaContentBlockWidget(block: block);
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ─── 5. Tombol Tautan Sumber Resmi ───
            if (article.sumberUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () async {
                    final Uri url = Uri.parse(article.sumberUrl);
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Tidak dapat membuka tautan'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F6F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFD4E3ED),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.open_in_new_rounded,
                          size: 16,
                          color: Color(0xFF276F8F),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Baca selengkapnya di $publisherName',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF276F8F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // ─── 6. Artikel Terkait (Baca Juga) ───
            if (article.bacaJuga.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Artikel Terkait',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C4E68),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Builder(
                  builder: (context) {
                    final validArticles = article.bacaJuga
                        .map((id) => BeritaRepository.getStaticById(id))
                        .whereType<BeritaArticle>()
                        .toList();
                    return Column(
                      children: [
                        for (int i = 0; i < validArticles.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Color(0xFFE0D8C3),
                            ),
                          BeritaCardSmall(
                            article: validArticles[i],
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/berita/detail',
                                arguments: validArticles[i].id,
                              );
                            },
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/berita_article_model.dart';
import '../../services/berita/berita_repository.dart';
import '../../services/berita/berita_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/berita/berita_header.dart';
import '../../widgets/berita/berita_card_small.dart';
import '../../widgets/berita/berita_image.dart';

class BeritaListScreen extends StatefulWidget {
  const BeritaListScreen({super.key});

  @override
  State<BeritaListScreen> createState() => _BeritaListScreenState();
}

class _BeritaListScreenState extends State<BeritaListScreen> {
  int _currentSlide = 0;
  String _selectedCategory = 'Semua';
  final PageController _pageController = PageController(viewportFraction: 0.90);
  final BeritaService _service = BeritaService();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFCFBF7),
          Color(0xFFF7F4EB),
          Color(0xFFF2EEDB),
        ],
      ),
      body: Column(
        children: [
          // ─── Header Top Bar (Back button + Judul Pill) ───
          const SizedBox(height: 6),
          const BeritaHeader(),
          const SizedBox(height: 10),

          // ─── Badan Konten Berita ───
          Expanded(
            child: StreamBuilder<List<BeritaArticle>>(
              stream: _service.streamPublished(),
              initialData: BeritaRepository.getStaticAll()
                  .where((a) => a.status == 'terbit')
                  .toList(),
              builder: (context, snapshot) {
                final rawData = snapshot.data;
                final List<BeritaArticle> articles =
                    (rawData != null && rawData.isNotEmpty)
                        ? rawData
                        : BeritaRepository.getStaticAll()
                            .where((a) => a.status == 'terbit')
                            .toList();

                if (articles.isEmpty) {
                  return _buildEmpty();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  color: AppColors.primary,
                  child: _buildBody(context, articles),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
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
            'Belum ada berita tersedia',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C4E68),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nantikan artikel kesehatan lambung\nterbaru di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B8797),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<BeritaArticle> articles) {
    // Urutkan artikel dari yang terbaru
    final sortedArticles = List<BeritaArticle>.from(articles);
    sortedArticles.sort((a, b) {
      if (a.tanggal == null && b.tanggal == null) return 0;
      if (a.tanggal == null) return 1;
      if (b.tanggal == null) return -1;
      return b.tanggal!.compareTo(a.tanggal!);
    });

    final carouselArticles = sortedArticles.take(5).toList();

    // Ambil kategori unik untuk filter tab
    final categories = <String>['Semua'];
    for (final a in sortedArticles) {
      final cat = a.kategori.trim();
      if (cat.isNotEmpty && !categories.contains(cat)) {
        categories.add(cat);
      }
    }

    // Filter daftar berita berdasarkan kategori terpilih
    final filteredArticles = _selectedCategory == 'Semua'
        ? sortedArticles
        : sortedArticles
            .where((a) => a.kategori.trim().toLowerCase() ==
                _selectedCategory.toLowerCase())
            .toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        const SizedBox(height: 6),

        // ─── 1. Featured Carousel Card (Sesuai Referensi) ───
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: carouselArticles.length,
            onPageChanged: (index) {
              setState(() {
                _currentSlide = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildCarouselCard(context, carouselArticles[index]);
            },
          ),
        ),

        const SizedBox(height: 10),

        // Indicator Dots Carousel
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            carouselArticles.length,
            (index) {
              final isActive = _currentSlide == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive
                      ? const Color(0xFF276F8F)
                      : const Color(0xFFCBD5E1),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // ─── 3. Browse By / Kategori Tab (Sesuai Referensi) ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Telusuri Kategori',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C4E68),
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '${filteredArticles.length} artikel',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B8797),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal Category Filter Pills
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategory == cat;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF276F8F)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF276F8F)
                          : const Color(0xFFEBE3D0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF527F97),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // ─── 3. Daftar Artikel (Bebas tanpa rectangle pembungkus, pemisah garis tipis) ───
        if (filteredArticles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Center(
              child: Text(
                'Tidak ada artikel dalam kategori $_selectedCategory',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B8797),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (int i = 0; i < filteredArticles.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Color(0xFFE0D8C3),
                    ),
                  BeritaCardSmall(
                    article: filteredArticles[i],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/berita/detail',
                        arguments: filteredArticles[i].id,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCarouselCard(BuildContext context, BeritaArticle article) {
    String? formattedDate;
    if (article.tanggal != null) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      final d = article.tanggal!;
      formattedDate = '${d.day} ${months[d.month - 1]} ${d.year}';
    }

    final sourceText = article.sumberNama.isNotEmpty
        ? article.sumberNama
        : 'LAMON';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/berita/detail',
              arguments: article.id,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFEBE3D0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1C4E68).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Gambar Utama Carousel
                  BeritaImage(
                    gambarUrl: article.gambarUrl.isNotEmpty
                        ? article.gambarUrl
                        : null,
                    gambarAsset: article.gambarAsset.isNotEmpty
                        ? article.gambarAsset
                        : null,
                    width: double.infinity,
                    height: double.infinity,
                    alignment: article.gambarAlignment,
                    borderRadius: 21,
                  ),

                  // Gradasi Gelap Elegan di Bawah Foto
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.3, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Floating Category Pill di Kiri Atas
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEBE3D0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        article.kategori.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF276F8F),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),

                  // Judul & Sumber Berita di Bawah
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          article.judul,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              sourceText,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            if (formattedDate != null) ...[
                              Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

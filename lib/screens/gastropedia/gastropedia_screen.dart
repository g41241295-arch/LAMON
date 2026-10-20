import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';
import '../../services/ensiklopedia_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gastropedia/gastropedia_header.dart';
import '../../widgets/gastropedia/category_item.dart';
import '../../widgets/gastropedia/recommendation_card.dart';
import '../../widgets/gastropedia/popular_food_card.dart';
import '../../routes/app_routes.dart';

class GastropediaScreen extends StatefulWidget {
  const GastropediaScreen({super.key});

  @override
  State<GastropediaScreen> createState() => _GastropediaScreenState();
}

class _GastropediaScreenState extends State<GastropediaScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data Rekomendasi: ambil 4 item rekomendasi (isRecommended=true),
  //    fallback agar selalu terisi 4 item.
  static List<GastropediaItem> _getRecommendedItems(List<GastropediaItem> items) {
    final pool = items.isNotEmpty ? items : GastropediaData.items;
    final recommended = pool.where((i) => i.isRecommended).toList();
    if (recommended.isEmpty) {
      return pool.take(4).toList();
    }
    if (recommended.length < 4) {
      final existingIds = recommended.map((r) => r.id).toSet();
      final extras = pool
          .where((i) => !existingIds.contains(i.id))
          .take(4 - recommended.length);
      return [...recommended, ...extras];
    }
    return recommended.take(4).toList();
  }

  // ── Data Makanan Populer dengan model GastropediaItem masing-masing ──
  static List<PopularFoodItem> _getPopularItems() {
    final saladItem = GastropediaData.getById('salad-sayur-segar') ??
        const GastropediaItem(
          id: 'salad-sayur-segar',
          name: 'Salad Sayur Segar',
          category: GastropediaCategory.makanan,
          imageAsset:
              'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200',
          calories: 120,
          protein: 4,
          carbs: 14,
          fat: 5,
          deskripsi:
              'Salad Sayur Segar memadukan selada romaine renyah, timun jepang iris, tomat matang tanpa biji, dan jagung manis pipil dengan sentuhan minyak zaitun extra virgin non-asam. Sayuran hijau segar kaya serat larut dan air membantu menetralkan asam lambung serta mencegah refluks ke esofagus.',
          manfaat: [
            '1. Menetralkan asam lambung berlebih\nKandungan air dan sifat alkalis dari sayuran hijau segar menenangkan sensasi perih pada lambung.',
            '2. Melancarkan motilitas usus\nSerat alami membantu pergerakan makanan di saluran cerna tanpa memicu kontraksi berlebih.',
            '3. Mencegah inflamasi mukosa lambung\nKaya antioksidan flavonoid dan vitamin C alami yang memperkuat lapisan pelindung lambung.',
          ],
          kandungan: [
            '1. Klorofil & Air alami -> membersihkan sisa metabolit dan menyejukkan lambung.',
            '2. Vitamin A, C, & K -> menjaga elastisitas jaringan dinding organ pencernaan.',
            '3. Asam Folat & Magnesium -> membantu relaksasi otot sfingter esofagus.',
            '4. Lemak sehat (Monounsaturated) -> berasal dari minyak zaitun untuk melapisi dinding lambung.',
          ],
        );

    final supItem = GastropediaData.getById('sup-ayam-diet') ??
        const GastropediaItem(
          id: 'sup-ayam-diet',
          name: 'Sup Ayam Diet',
          category: GastropediaCategory.makanan,
          imageAsset:
              'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=200',
          calories: 165,
          protein: 18,
          carbs: 12,
          fat: 4,
          deskripsi:
              'Sup Ayam Diet diracik dari potongan dada ayam rebus tanpa kulit, wortel empuk, labu siam, dan kaldu bening gurih tanpa bumbu merica tajam atau santan. Sangat lembut dan hangat di perut, menjadi pilihan terbaik untuk meredakan rasa perih saat maag kambuh atau GERD.',
          manfaat: [
            '1. Meredakan ketegangan dan kram perut\nKuah kaldu ayam hangat memberikan efek relaksasi pada sfingter esofagus bagian bawah.',
            '2. Sumber protein pemulih mukosa\nProtein tinggi tanpa lemak dari dada ayam mempercepat regenerasi sel lambung yang meradang.',
            '3. Mudah dicerna dan ramah lambung\nKomposisi sayuran empuk dan daging rebus tidak membebani kerja pengosongan lambung.',
          ],
          kandungan: [
            '1. Protein hewani murni -> memperbaiki jaringan selaput lendir lambung yang luka.',
            '2. Kolagen kaldu ayam -> memperkuat lapisan mukosa pelindung asam lambung.',
            '3. Kalium & Elektrolit -> menstabilkan keseimbangan cairan dan asam lambung tubuh.',
            '4. Beta-karoten wortel -> melindungi integritas sel epitel pencernaan.',
          ],
        );

    final smoothieItem = GastropediaData.getById('smoothie-bowl-buah-naga') ??
        const GastropediaItem(
          id: 'smoothie-bowl-buah-naga',
          name: 'Smoothie Bowl Buah Naga',
          category: GastropediaCategory.buah,
          imageAsset:
              'https://images.unsplash.com/photo-1496412705862-e0088f16f791?w=200',
          calories: 145,
          protein: 5,
          carbs: 28,
          fat: 2,
          deskripsi:
              'Smoothie Bowl Buah Naga memadukan pure buah naga merah segar, pisang matang lembut, dan susu almond non-dairy rendah lemak. Teksturnya yang kental dan dingin alami memberikan sensasi sejuk instan pada kerongkongan serta perut bagian atas yang panas akibat refluks asam lambung.',
          manfaat: [
            '1. Mendinginkan sensasi panas di ulu hati (Heartburn)\nSifat buah naga yang menyejukkan meredakan iritasi pada dinding kerongkongan secara instan.',
            '2. Prebiotik alami lambung dan usus\nBiji halus dan serat larut buah naga menutrisi mikrobioma baik di saluran pencernaan.',
            '3. Antasida alami dari pisang & buah naga\nMembantu menetralkan keasaman cairan lambung tanpa bahan kimia sintetis.',
          ],
          kandungan: [
            '1. Betalain & Antioksidan -> zat warna alami penangkal inflamasi kronis lambung.',
            '2. Serat larut & Pektin -> membentuk lapisan gel pelindung dinding mukosa lambung.',
            '3. Kalium & Vitamin C -> menormalkan pH lambung dan meningkatkan daya tahan tubuh.',
            '4. Zat Besi & Fosfor -> mendukung regenerasi sel darah dan energi harian.',
          ],
        );

    return [
      PopularFoodItem(
        name: saladItem.name,
        imageAsset: saladItem.imageAsset,
        rating: 4.8,
        ratingCount: 124,
        gastropediaItem: saladItem,
      ),
      PopularFoodItem(
        name: supItem.name,
        imageAsset: supItem.imageAsset,
        rating: 4.5,
        ratingCount: 89,
        gastropediaItem: supItem,
      ),
      PopularFoodItem(
        name: smoothieItem.name,
        imageAsset: smoothieItem.imageAsset,
        rating: 4.9,
        ratingCount: 230,
        gastropediaItem: smoothieItem,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final isSearching = query.isNotEmpty;

    return AppScaffold(
      body: StreamBuilder<List<GastropediaItem>>(
        stream: EnsiklopediaService().streamPublishedGastropedia(),
        builder: (context, snapshot) {
          final allItems = snapshot.data ?? GastropediaData.items;
          final searchResults = isSearching
              ? allItems
                  .where((item) => item.name.toLowerCase().contains(query))
                  .toList()
              : <GastropediaItem>[];

          final recommendedItems = _getRecommendedItems(allItems);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // ═══════════════════════════════════════════
            // 1. Header (Tombol kembali bulat + pill judul)
            // ═══════════════════════════════════════════
            const SizedBox(height: 6),
            const GastropediaHeader(title: 'Gastropedia'),

            const SizedBox(height: 14),

            // ═══════════════════════════════════════════
            // 2. Kolom Pencarian (Rounded Pill)
            // ═══════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFE2ECF2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF7C8E97),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E5D7D),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Cari makanan atau buah...',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CB3C2),
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (isSearching)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2ECF2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xFF1E5D7D),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════
            // 3. Tampilan Hasil Pencarian (jika aktif)
            // ═══════════════════════════════════════════
            if (isSearching) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionHeading(
                          title: 'Hasil Pencarian ("${_searchController.text.trim()}")',
                        ),
                        Text(
                          '${searchResults.length} ditemukan',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7C8E97),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (searchResults.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFFBEA),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.search_off_rounded,
                                  size: 32,
                                  color: Color(0xFFE5983A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Makanan tidak ditemukan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E5D7D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Coba kata kunci lain seperti bayam, apel, brokoli...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF7C8E97),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final item = searchResults[index];
                          return RecommendationCard(
                            item: item,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.gastropediaDetail,
                                arguments: item,
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ] else ...[
              // ═══════════════════════════════════════════
              // 4. Section "Kategori" (3 Kartu Kotak Sejajar)
              // ═══════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeading(title: 'Kategori'),
                    const SizedBox(height: 14),

                    // 3 kartu kotak sejajar dalam satu baris, lebar dibagi rata
                    Row(
                      children: GastropediaCategory.values.map((category) {
                        final isLast =
                            category == GastropediaCategory.values.last;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : 10),
                            child: CategoryItem(
                              category: category,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.gastropediaCategory,
                                  arguments: category,
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ═══════════════════════════════════════════
              // 5. Section "Rekomendasi" (Scroll Horizontal 4 Item)
              // ═══════════════════════════════════════════
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _SectionHeading(title: 'Rekomendasi'),
              ),

              const SizedBox(height: 14),

              // List horizontal yang bisa di-scroll (geser kiri-kanan) 4 item
              SizedBox(
                height: 165,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: recommendedItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final item = recommendedItems[index];
                    return SizedBox(
                      width: 160,
                      child: RecommendationCard(
                        item: item,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.gastropediaDetail,
                            arguments: item,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // ═══════════════════════════════════════════
              // 6. Section "Makanan Populer"
              // ═══════════════════════════════════════════
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _SectionHeading(title: 'Makanan Populer'),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: _getPopularItems().map((popItem) {
                    return PopularFoodCard(
                      item: popItem,
                      onTap: () {
                        // Buka detail langsung menggunakan data model objek miliknya sendiri
                        Navigator.pushNamed(
                          context,
                          AppRoutes.gastropediaDetail,
                          arguments: popItem.gastropediaItem,
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      );
    },
  ),
);
  }
}

// ─────────────────────────────────────────────────────────────
// Widget Helper: Judul Section heading tebal rata kiri
// ─────────────────────────────────────────────────────────────
class _SectionHeading extends StatelessWidget {
  final String title;

  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E5D7D),
        letterSpacing: -0.3,
      ),
    );
  }
}


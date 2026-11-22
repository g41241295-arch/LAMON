import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';
import '../../services/ensiklopedia_service.dart';
import '../../services/gastropedia_recommendation_service.dart';
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
  final GastropediaRecommendationService _recommendationService =
      GastropediaRecommendationService();

  Future<List<GastropediaItem>>? _recommendationsFuture;
  List<GastropediaItem>? _lastAllItems;
  String? _lastUserId;

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

  // ── Data Rekomendasi bawaan: fallback 4 item rekomendasi ──
  static List<GastropediaItem> _getRecommendedItems(List<GastropediaItem> items) {
    return GastropediaRecommendationService.getDefaultRecommendations(items);
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
          calories: 55,
          protein: 2.2,
          carbs: 7.0,
          fat: 2.1,
          servingUnit: 'per 100g',
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
          calories: 78,
          protein: 9.5,
          carbs: 4.8,
          fat: 2.4,
          servingUnit: 'per 100g',
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
          calories: 72,
          protein: 2.1,
          carbs: 14.5,
          fat: 1.2,
          servingUnit: 'per 100g',
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
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFCFBF7),
          Color(0xFFF7F4EB),
          Color(0xFFF2EEDB),
        ],
      ),
      body: StreamBuilder<List<GastropediaItem>>(
        stream: EnsiklopediaService().streamPublishedGastropedia(),
        builder: (context, snapshot) {
          final allItems = snapshot.data ?? GastropediaData.items;
          final searchResults = isSearching
              ? allItems
                  .where((item) =>
                      item.name.toLowerCase().contains(query) ||
                      item.category.label.toLowerCase().contains(query))
                  .toList()
              : <GastropediaItem>[];

          final currentUid = FirebaseAuth.instance.currentUser?.uid;
          if (_recommendationsFuture == null ||
              _lastAllItems != allItems ||
              _lastUserId != currentUid) {
            _lastAllItems = allItems;
            _lastUserId = currentUid;
            _recommendationsFuture = _recommendationService
                .getPersonalizedRecommendations(
                  userId: currentUid,
                  allItems: allItems,
                );
          }

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

                const SizedBox(height: 12),

                // ═══════════════════════════════════════════
                // 2. Hero Banner "Panduan Gizi Lambung"
                // ═══════════════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFFDF5),
                          Color(0xFFFFFBE8),
                          Color(0xFFFAF3D4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFEBE3D0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1C4E68).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilihan Pangan Sehat',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1C4E68),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Temukan nutrisi tepat untuk pemulihan dan kesehatan lambungmu.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF527F97),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFEBE3D0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1C4E68)
                                    .withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.flatware_rounded,
                              size: 26,
                              color: Color(0xFF276F8F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ═══════════════════════════════════════════
                // 3. Kolom Pencarian Modern (Rounded Pill)
                // ═══════════════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: const Color(0xFFE2ECF2),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1C4E68).withValues(alpha: 0.04),
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
                          color: Color(0xFF276F8F),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1C4E68),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Cari makanan, sayuran, atau buah...',
                              hintStyle: TextStyle(
                                color: Color(0xFF9CB3C2),
                                fontSize: 13.5,
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
                              decoration: const BoxDecoration(
                                color: Color(0xFFE2ECF2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Color(0xFF1C4E68),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ═══════════════════════════════════════════
                // 4. Hasil Pencarian (jika aktif)
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
                              title:
                                  'Hasil Pencarian ("${_searchController.text.trim()}")',
                              subtitle: '${searchResults.length} makanan ditemukan',
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
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1C4E68),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Coba kata kunci lain seperti bayam, apel, brokoli, sup...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B8797),
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
                              childAspectRatio: 0.76,
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
                  // 5. Section "Kategori Pilihan"
                  // ═══════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeading(
                          title: 'Kategori Pilihan',
                          subtitle: 'Eksplorasi gizi sesuai kelompok pangan',
                        ),
                        const SizedBox(height: 14),

                        // 3 kartu kategori sejajar dalam satu baris
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

                  const SizedBox(height: 26),

                  // ═══════════════════════════════════════════
                  // 6. Section "Rekomendasi Pilihan" (Horizontal Scroll)
                  // ═══════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: _SectionHeading(
                            title: 'Rekomendasi Spesial',
                            subtitle: 'Menu terpilih nutrisi lembut untuk lambung',
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.gastropediaCategory,
                              arguments: 'rekomendasi',
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF276F8F),
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: Color(0xFF276F8F),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // List horizontal kartu rekomendasi modern
                  FutureBuilder<List<GastropediaItem>>(
                    future: _recommendationsFuture,
                    initialData: _getRecommendedItems(allItems),
                    builder: (context, recSnapshot) {
                      final displayRecItems =
                          recSnapshot.data ?? _getRecommendedItems(allItems);

                      return SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: displayRecItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final item = displayRecItems[index];
                            return SizedBox(
                              width: 175,
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
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ═══════════════════════════════════════════
                  // 7. Section "Makanan Populer"
                  // ═══════════════════════════════════════════
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionHeading(
                      title: 'Paling Sering Dikunjungi',
                      subtitle: 'Favorit pengguna LAMON dengan kunjungan terbanyak',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: _getPopularItems().map((popItem) {
                        return PopularFoodCard(
                          item: popItem,
                          onTap: () {
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
// Widget Helper: Judul Section heading tebal rata kiri + subtitle
// ─────────────────────────────────────────────────────────────
class _SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeading({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C4E68),
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B8797),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../constants/app_colors.dart';
import '../../services/food_entry_service.dart';
import '../../utils/food_summary_calculator.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/primary_button.dart';

class RingkasanMakananScreen extends StatefulWidget {
  const RingkasanMakananScreen({super.key});

  @override
  State<RingkasanMakananScreen> createState() => _RingkasanMakananScreenState();
}

class _RingkasanMakananScreenState extends State<RingkasanMakananScreen> {
  final FoodEntryService _service = FoodEntryService();
  bool _isLoading = true;
  FoodSummaryCalculator? _calculator;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final entries = await _service.getLast7DaysEntries();
    
    if (mounted) {
      setState(() {
        _calculator = FoodSummaryCalculator(entries: entries);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final calc = _calculator;
    if (calc == null || calc.totalEntries == 0) {
      return Column(
        children: [
          _buildHeader(),
          const Spacer(),
          const Icon(Icons.fastfood_outlined, size: 64, color: AppColors.neutralGray),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data makan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Catat makananmu selama 7 hari terakhir\nuntuk melihat ringkasannya di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.neutralGray),
          ),
          const Spacer(flex: 2),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(calc),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSectionTitle('Jenis Makanan'),
                _buildJenisMakanan(calc),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Sumber Makanan'),
                _buildSumberMakanan(calc),
                const SizedBox(height: 24),

                _buildSectionTitle('Rasa Dominan'),
                const Text(
                  'Rasa dengan skor tertinggi per makan',
                  style: TextStyle(fontSize: 12, color: AppColors.brownSubtext),
                ),
                const SizedBox(height: 12),
                _buildRasaDominan(calc),
                const SizedBox(height: 24),

                _buildSectionTitle('Minuman'),
                _buildMinuman(calc),
                const SizedBox(height: 24),

                _buildSectionTitle('Beban Harian'),
                _buildBebanHarian(calc),
                const SizedBox(height: 32),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/prediksi-penyakit');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Prediksi Sekarang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: 'Konsul Dokter',
                  onPressed: () {},
                ),
                const SizedBox(height: 20),

                // Debug Buttons
                if (kDebugMode) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('Development Only:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            await _service.generateDummyData();
                            await _loadData();
                          },
                          icon: const Icon(Icons.add_box),
                          label: const Text('Isi Dummy'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            await _service.deleteDummyData();
                            await _loadData();
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Hapus Dummy'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader([FoodSummaryCalculator? calc]) {
    // Tombol back (lingkaran putih)
    final backButton = InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD6E2E8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );

    // Pill judul (selalu di tengah)
    final titlePill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE8DCAB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Text(
        'Ringkasan Makanan',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryText,
          letterSpacing: 0.2,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Judul di tengah layar
                Center(child: titlePill),
                // Tombol back di kiri, tidak mempengaruhi posisi judul
                Positioned(left: 0, child: backButton),
              ],
            ),
          ),
          if (calc != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '${calc.dateRangeString}. ${calc.totalEntries} kali makan tercatat',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brownSubtext,
                  height: 1.4,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryText,
        ),
      ),
    );
  }

  Widget _buildJenisMakanan(FoodSummaryCalculator calc) {
    final stats = calc.jenisMakananStats;
    final junkFood = stats['Junk Food'] ?? 0;
    final homemade = stats['Homemade'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: junkFood > 0 ? junkFood : 1,
                  child: Container(
                    height: 24,
                    color: junkFood > 0 ? const Color(0xFFD95030) : Colors.grey.shade200,
                  ),
                ),
                Expanded(
                  flex: homemade > 0 ? homemade : 1,
                  child: Container(
                    height: 24,
                    color: homemade > 0 ? const Color(0xFF53A66B) : Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFFD95030), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 8),
                  Text('Junk food $junkFood%', style: const TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF53A66B), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 8),
                  Text('Homemade $homemade%', style: const TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSumberMakanan(FoodSummaryCalculator calc) {
    final stats = calc.proteinStats;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: stats.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    e.key,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(height: 16, color: const Color(0xFFF0F0F0)),
                        FractionallySizedBox(
                          widthFactor: e.value / 100,
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4B87A6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${e.value}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRasaDominan(FoodSummaryCalculator calc) {
    final stats = calc.rasaDominanStats;

    Color getTasteColor(String taste) {
      switch (taste) {
        case 'Asin': return const Color(0xFFD95030); // Oranye tua
        case 'Pedas': return const Color(0xFFD67C65); // Oranye pudar
        case 'Asam': return const Color(0xFFFFCC00); // Kuning
        case 'Manis': return const Color(0xFF53A66B); // Hijau
        case 'Berlemak': return const Color(0xFF8B5A2B); // Coklat
        default: return Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: stats.map((e) {
          // Dynamic height for the bar based on percentage
          final height = (e.value / 100) * 40 + 4; // minimum 4
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 24,
                height: height,
                decoration: BoxDecoration(
                  color: getTasteColor(e.key),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.key,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownSubtext),
              ),
              Text(
                '${e.value}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMinuman(FoodSummaryCalculator calc) {
    final stats = calc.minumanStats;
    
    Widget buildBar(String title, IconData icon, int percentage, Color color) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryText),
            const SizedBox(width: 8),
            SizedBox(
              width: 50,
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(height: 16, color: const Color(0xFFF0F0F0)),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 32,
              child: Text(
                '$percentage%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          buildBar('Kopi', Icons.coffee, stats['Kopi'] ?? 0, const Color(0xFFD95030)),
          buildBar('Soda', Icons.local_drink, stats['Soda'] ?? 0, const Color(0xFFD67C65)),
          buildBar('Lainnya', Icons.emoji_food_beverage, stats['Lainnya'] ?? 0, const Color(0xFF53A66B)),
        ],
      ),
    );
  }

  Widget _buildBebanHarian(FoodSummaryCalculator calc) {
    final stats = calc.bebanHarianStats;
    final pikiran = stats['Beban Pikiran']!;
    final aktivitas = stats['Beban Aktivitas']!;

    Widget buildCard(String title, Map<String, dynamic> data) {
      final hasData = data['hasData'] as bool;
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                hasData ? '${data['percentage']}%' : '-',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.brownSubtext),
              ),
              Text(
                hasData ? 'rata-rata ${data['average']}/5' : 'belum ada data',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.brownSubtext),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        buildCard('Beban pikiran', pikiran),
        const SizedBox(width: 12),
        buildCard('Beban aktivitas', aktivitas),
      ],
    );
  }
}

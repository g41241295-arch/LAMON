import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/food_entry_model.dart';
import '../../routes/app_routes.dart';
import '../../services/food_entry_service.dart';
import '../../utils/food_summary_calculator.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/primary_button.dart';

/// Jumlah minimal hari unik dengan pencatatan makanan agar Ringkasan terbuka.
const int kMinHariRingkasan = 7;

/// Flag untuk mengaktifkan/menonaktifkan tombol "Lihat Contoh Tampilan".
const bool kTampilkanContohRingkasan = true;

class RingkasanMakananScreen extends StatefulWidget {
  const RingkasanMakananScreen({super.key});

  @override
  State<RingkasanMakananScreen> createState() => _RingkasanMakananScreenState();
}

class _RingkasanMakananScreenState extends State<RingkasanMakananScreen> {
  final FoodEntryService _service = FoodEntryService();

  bool _isLoading = true;
  bool _isError = false;
  String? _errorCode;
  String? _errorMessage;

  FoodSummaryCalculator? _calculator;
  FoodSummaryCalculator? _mockCalculator;

  int _uniqueDatesCount = 0;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorCode = null;
      _errorMessage = null;
      _isPreviewMode = false;
    });

    final result = await _service.getEntriesForSummary();

    if (!mounted) return;

    switch (result) {
      case FoodSummaryFailure(:final code, :final message):
        debugPrint('[RingkasanMakanan] Error query Firestore: [$code] $message');
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorCode = code;
          _errorMessage = message;
        });
        break;

      case FoodSummaryEmpty():
        debugPrint(
            '[RingkasanMakanan] Entri dimuat: 0, Tanggal unik: 0 (min: $kMinHariRingkasan)');
        debugPrint('[RingkasanMakanan] Status layar: Terkunci (belum ada data)');
        setState(() {
          _isLoading = false;
          _uniqueDatesCount = 0;
          _calculator = null;
        });
        break;

      case FoodSummarySuccess(:final entries):
        final mapByDate = <String, List<FoodEntry>>{};
        for (final entry in entries) {
          mapByDate.putIfAbsent(entry.tanggal, () => []).add(entry);
        }

        final sortedDates = mapByDate.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        final uniqueCount = sortedDates.length;

        if (uniqueCount >= kMinHariRingkasan) {
          final top7Dates = sortedDates.take(kMinHariRingkasan).toSet();
          final filteredEntries =
              entries.where((e) => top7Dates.contains(e.tanggal)).toList();

          final calc = FoodSummaryCalculator(
            entries: filteredEntries,
            uniqueDates: top7Dates.toList()..sort(),
          );

          debugPrint(
              '[RingkasanMakanan] Entri dimuat: ${entries.length}, Tanggal unik: $uniqueCount (min: $kMinHariRingkasan)');
          debugPrint(
              '[RingkasanMakanan] Status layar: Siap (entri ringkasan: ${filteredEntries.length})');

          setState(() {
            _isLoading = false;
            _uniqueDatesCount = uniqueCount;
            _calculator = calc;
          });
        } else {
          debugPrint(
              '[RingkasanMakanan] Entri dimuat: ${entries.length}, Tanggal unik: $uniqueCount (min: $kMinHariRingkasan)');
          debugPrint('[RingkasanMakanan] Status layar: Terkunci');

          setState(() {
            _isLoading = false;
            _uniqueDatesCount = uniqueCount;
            _calculator = null;
          });
        }
        break;
    }
  }

  void _activatePreviewMode() {
    final mockEntries = _generateMockEntries();
    final mockDates = mockEntries.map((e) => e.tanggal).toSet().toList()..sort();
    final calc = FoodSummaryCalculator(
      entries: mockEntries,
      uniqueDates: mockDates,
    );

    setState(() {
      _mockCalculator = calc;
      _isPreviewMode = true;
    });
  }

  void _exitPreviewMode() {
    setState(() {
      _isPreviewMode = false;
    });
  }

  /// Membuat 21 entri contoh (3 sesi per hari selama 7 hari terakhir dari hari ini)
  /// yang disimpan secara in-memory untuk menguji kalkulator dan UI.
  List<FoodEntry> _generateMockEntries() {
    final now = DateTime.now();
    final entries = <FoodEntry>[];

    // Data variasi makanan selama 7 hari
    final dayConfigs = [
      {
        'sarapan': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Putih'],
          'protein': ['Telur'],
          'sayur': ['Bayam'],
          'pedas': 0,
          'asin': 1,
          'asam': 0,
          'manis': 2,
          'lemak': 1,
          'kopi': true,
          'soda': false,
        },
        'siang': {
          'jenis': ['Junk Food'],
          'karbo': ['Kentang'],
          'protein': ['Daging Sapi'],
          'sayur': ['Wortel'],
          'pedas': 2,
          'asin': 3,
          'asam': 0,
          'manis': 1,
          'lemak': 3,
          'kopi': false,
          'soda': true,
        },
        'malam': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Merah'],
          'protein': ['Daging Ayam'],
          'sayur': ['Brokoli'],
          'pedas': 1,
          'asin': 1,
          'asam': 2,
          'manis': 1,
          'lemak': 1,
          'kopi': false,
          'soda': false,
          'pikiran': 1,
          'aktivitas': 2,
        },
      },
      {
        'sarapan': {
          'jenis': ['Homemade'],
          'karbo': ['Roti'],
          'protein': ['Telur'],
          'sayur': ['Sawi'],
          'pedas': 0,
          'asin': 2,
          'asam': 0,
          'manis': 3,
          'lemak': 1,
          'kopi': true,
          'soda': false,
        },
        'siang': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Putih'],
          'protein': ['Ikan'],
          'sayur': ['Kangkung'],
          'pedas': 3,
          'asin': 2,
          'asam': 1,
          'manis': 0,
          'lemak': 2,
          'kopi': false,
          'soda': false,
        },
        'malam': {
          'jenis': ['Junk Food'],
          'karbo': ['Mie'],
          'protein': ['Daging Sapi'],
          'sayur': <String>[],
          'pedas': 2,
          'asin': 3,
          'asam': 0,
          'manis': 1,
          'lemak': 4,
          'kopi': false,
          'soda': true,
          'pikiran': 3,
          'aktivitas': 1,
        },
      },
      {
        'sarapan': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Putih'],
          'protein': ['Tahu/Tempe'],
          'sayur': ['Bayam'],
          'pedas': 1,
          'asin': 1,
          'asam': 0,
          'manis': 1,
          'lemak': 1,
          'kopi': false,
          'soda': false,
        },
        'siang': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Putih'],
          'protein': ['Daging Ayam'],
          'sayur': ['Wortel'],
          'pedas': 3,
          'asin': 2,
          'asam': 0,
          'manis': 0,
          'lemak': 2,
          'kopi': false,
          'soda': false,
        },
        'malam': {
          'jenis': ['Homemade'],
          'karbo': ['Kentang'],
          'protein': ['Ikan'],
          'sayur': ['Brokoli'],
          'pedas': 1,
          'asin': 2,
          'asam': 3,
          'manis': 0,
          'lemak': 1,
          'kopi': true,
          'soda': false,
          'pikiran': 2,
          'aktivitas': 3,
        },
      },
      {
        'sarapan': {
          'jenis': ['Junk Food'],
          'karbo': ['Roti'],
          'protein': ['Daging Sapi'],
          'sayur': <String>[],
          'pedas': 0,
          'asin': 2,
          'asam': 1,
          'manis': 2,
          'lemak': 3,
          'kopi': true,
          'soda': false,
        },
        'siang': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Putih'],
          'protein': ['Telur'],
          'sayur': ['Kangkung'],
          'pedas': 2,
          'asin': 2,
          'asam': 0,
          'manis': 1,
          'lemak': 1,
          'kopi': false,
          'soda': false,
        },
        'malam': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Merah'],
          'protein': ['Tahu/Tempe'],
          'sayur': ['Sawi'],
          'pedas': 0,
          'asin': 1,
          'asam': 1,
          'manis': 2,
          'lemak': 1,
          'kopi': false,
          'soda': false,
          'pikiran': 0,
          'aktivitas': 4,
        },
      },
      {
        'sarapan': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Putih'],
          'protein': ['Telur'],
          'sayur': ['Bayam'],
          'pedas': 1,
          'asin': 2,
          'asam': 0,
          'manis': 1,
          'lemak': 1,
          'kopi': false,
          'soda': false,
        },
        'siang': {
          'jenis': ['Junk Food'],
          'karbo': ['Kentang'],
          'protein': ['Daging Ayam'],
          'sayur': <String>[],
          'pedas': 2,
          'asin': 3,
          'asam': 0,
          'manis': 0,
          'lemak': 3,
          'kopi': false,
          'soda': true,
        },
        'malam': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Putih'],
          'protein': ['Ikan'],
          'sayur': ['Wortel'],
          'pedas': 2,
          'asin': 1,
          'asam': 2,
          'manis': 1,
          'lemak': 2,
          'kopi': false,
          'soda': false,
          'pikiran': 2,
          'aktivitas': 2,
        },
      },
      {
        'sarapan': {
          'jenis': ['Homemade'],
          'karbo': ['Roti'],
          'protein': ['Telur'],
          'sayur': <String>[],
          'pedas': 0,
          'asin': 1,
          'asam': 0,
          'manis': 3,
          'lemak': 1,
          'kopi': true,
          'soda': false,
        },
        'siang': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Putih'],
          'protein': ['Daging Sapi'],
          'sayur': ['Brokoli'],
          'pedas': 3,
          'asin': 2,
          'asam': 1,
          'manis': 0,
          'lemak': 2,
          'kopi': false,
          'soda': false,
        },
        'malam': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Putih'],
          'protein': ['Daging Ayam'],
          'sayur': ['Kangkung'],
          'pedas': 1,
          'asin': 2,
          'asam': 1,
          'manis': 1,
          'lemak': 2,
          'kopi': false,
          'soda': false,
          'pikiran': 3,
          'aktivitas': 1,
        },
      },
      {
        'sarapan': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Putih'],
          'protein': ['Tahu/Tempe'],
          'sayur': ['Bayam'],
          'pedas': 0,
          'asin': 1,
          'asam': 0,
          'manis': 2,
          'lemak': 1,
          'kopi': false,
          'soda': false,
        },
        'siang': {
          'jenis': ['Junk Food'],
          'karbo': ['Mie'],
          'protein': ['Daging Sapi'],
          'sayur': <String>[],
          'pedas': 2,
          'asin': 3,
          'asam': 0,
          'manis': 1,
          'lemak': 3,
          'kopi': false,
          'soda': true,
        },
        'malam': {
          'jenis': ['Homemade'],
          'karbo': ['Nasi Putih'],
          'protein': ['Ikan'],
          'sayur': ['Sawi'],
          'pedas': 1,
          'asin': 1,
          'asam': 2,
          'manis': 1,
          'lemak': 1,
          'kopi': false,
          'soda': false,
          'pikiran': 1,
          'aktivitas': 3,
        },
      },
    ];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final cfg = dayConfigs[i];

      // Sarapan
      final s = cfg['sarapan'] as Map<String, dynamic>;
      entries.add(
        FoodEntry(
          id: 'mock_${dateStr}_sarapan',
          userId: 'mock_user',
          tanggal: dateStr,
          waktuPengisian: DateTime(date.year, date.month, date.day, 7, 30),
          sesi: MealSession.sarapan,
          jenisMakanan: List<String>.from(s['jenis'] as List),
          sumberKarbohidrat: List<String>.from(s['karbo'] as List),
          protein: List<String>.from(s['protein'] as List),
          sayuran: List<String>.from(s['sayur'] as List),
          levelPedas: s['pedas'] as int,
          levelAsin: s['asin'] as int,
          levelAsam: s['asam'] as int,
          levelManis: s['manis'] as int,
          levelBerlemak: s['lemak'] as int,
          berbaringSetelahMakan: false,
          konsumsiSoda: s['soda'] as bool,
          konsumsiKopi: s['kopi'] as bool,
        ),
      );

      // Makan Siang
      final m = cfg['siang'] as Map<String, dynamic>;
      entries.add(
        FoodEntry(
          id: 'mock_${dateStr}_siang',
          userId: 'mock_user',
          tanggal: dateStr,
          waktuPengisian: DateTime(date.year, date.month, date.day, 12, 30),
          sesi: MealSession.makanSiang,
          jenisMakanan: List<String>.from(m['jenis'] as List),
          sumberKarbohidrat: List<String>.from(m['karbo'] as List),
          protein: List<String>.from(m['protein'] as List),
          sayuran: List<String>.from(m['sayur'] as List),
          levelPedas: m['pedas'] as int,
          levelAsin: m['asin'] as int,
          levelAsam: m['asam'] as int,
          levelManis: m['manis'] as int,
          levelBerlemak: m['lemak'] as int,
          berbaringSetelahMakan: false,
          konsumsiSoda: m['soda'] as bool,
          konsumsiKopi: m['kopi'] as bool,
        ),
      );

      // Makan Malam
      final d = cfg['malam'] as Map<String, dynamic>;
      entries.add(
        FoodEntry(
          id: 'mock_${dateStr}_malam',
          userId: 'mock_user',
          tanggal: dateStr,
          waktuPengisian: DateTime(date.year, date.month, date.day, 19, 0),
          sesi: MealSession.makanMalam,
          jenisMakanan: List<String>.from(d['jenis'] as List),
          sumberKarbohidrat: List<String>.from(d['karbo'] as List),
          protein: List<String>.from(d['protein'] as List),
          sayuran: List<String>.from(d['sayur'] as List),
          levelPedas: d['pedas'] as int,
          levelAsin: d['asin'] as int,
          levelAsam: d['asam'] as int,
          levelManis: d['manis'] as int,
          levelBerlemak: d['lemak'] as int,
          berbaringSetelahMakan: false,
          konsumsiSoda: d['soda'] as bool,
          konsumsiKopi: d['kopi'] as bool,
          bebanPikiran: d['pikiran'] as int?,
          bebanAktivitas: d['aktivitas'] as int?,
        ),
      );
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_isError) {
      return AppScaffold(
        body: _buildErrorView(),
      );
    }

    if (_isPreviewMode && _mockCalculator != null) {
      return AppScaffold(
        body: _buildReportView(_mockCalculator!, isPreview: true),
      );
    }

    if (_uniqueDatesCount >= kMinHariRingkasan && _calculator != null) {
      return AppScaffold(
        body: _buildReportView(_calculator!, isPreview: false),
      );
    }

    return AppScaffold(
      body: _buildLockedView(),
    );
  }

  // ─── Header Universal (Sesuai Gaya Halaman Lain) ──────────────────────────
  Widget _buildScreenHeader({
    FoodSummaryCalculator? calc,
    VoidCallback? onBack,
  }) {
    final backButton = InkWell(
      onTap: onBack ?? () => Navigator.pop(context),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(child: titlePill),
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
          ],
        ],
      ),
    );
  }

  // ─── 1. State Terkunci (< 7 Hari) ─────────────────────────────────────────
  Widget _buildLockedView() {
    final progress = (_uniqueDatesCount / kMinHariRingkasan).clamp(0.0, 1.0);

    return SafeArea(
      child: Column(
        children: [
          _buildScreenHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Ilustrasi lambung mascot
                  Image.asset(
                    'assets/images/mascot-header.png',
                    height: 130,
                    width: 130,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3CD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_clock_rounded,
                        size: 54,
                        color: AppColors.orangeAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Catat makananmu selama 7 hari\nuntuk melihat ringkasan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Laporan nutrisi mingguan akan terbuka otomatis setelah kamu mencatat makanan pada 7 tanggal berbeda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.brownSubtext,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Progress Bar Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sudah $_uniqueDatesCount dari $kMinHariRingkasan hari tercatat',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE8F1F5),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Hari tidak harus berurutan. Hari yang terlewat tidak mereset progresmu.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.neutralGray,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tombol Lihat Contoh Tampilan
                  if (kTampilkanContohRingkasan) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _activatePreviewMode,
                        icon: const Icon(Icons.remove_red_eye_outlined,
                            size: 20, color: AppColors.primary),
                        label: const Text(
                          'Lihat Contoh Tampilan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                              color: AppColors.primary, width: 1.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Tombol Catat Makanan Hari Ini
                  PrimaryButton(
                    text: 'Catat Makanan Sekarang',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.catatMakanan)
                          .then((_) => _loadData());
                    },
                  ),

                  // Tombol Debug Data (Hanya saat kDebugMode)
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Development Testing:',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
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
                            icon: const Icon(Icons.add_box, size: 16),
                            label: const Text('Isi 7 Dummy',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
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
                            icon: const Icon(Icons.delete, size: 16),
                            label: const Text('Hapus Dummy',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. State Error ────────────────────────────────────────────────────────
  Widget _buildErrorView() {
    return SafeArea(
      child: Column(
        children: [
          _buildScreenHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 64, color: AppColors.adminRed),
                  const SizedBox(height: 16),
                  const Text(
                    'Gagal memuat ringkasan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Terjadi kendala saat mengambil catatan makananmu. Silakan periksa koneksi dan coba lagi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.neutralGray, fontSize: 13),
                  ),
                  if (kDebugMode && _errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDEDED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'Debug Code: ${_errorCode ?? "unknown"}\nMessage: $_errorMessage',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (kTampilkanContohRingkasan) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _activatePreviewMode,
                        icon: const Icon(Icons.remove_red_eye_outlined,
                            size: 20, color: Colors.white),
                        label: const Text(
                          'Lihat Contoh Tampilan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text('Coba Lagi',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. State Siap / Laporan Lengkap (Termasuk Mode Preview) ───────────────
  Widget _buildReportView(FoodSummaryCalculator calc, {required bool isPreview}) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScreenHeader(
              calc: calc,
              onBack: isPreview ? _exitPreviewMode : null,
            ),

            // Banner Simulasi (Khusus Mode Contoh)
            if (isPreview) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7D6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE8DCAB),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.brownDark),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Contoh tampilan dengan data simulasi, bukan catatan Anda.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brownDark,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _exitPreviewMode,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: Text(
                            'Tutup',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildSectionTitle('Jenis Makanan'),
                  _buildJenisMakanan(calc),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Sumber Makanan'),
                  _buildSumberMakanan(calc),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Rasa Dominan'),
                  const Text(
                    'Rasa dengan skor tertinggi per makan',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.brownSubtext),
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

                  // Tombol Aksi: Prediksi Sekarang & Konsul Dokter
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                            context, AppRoutes.diseasePrediction);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                            color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Prediksi Sekarang',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    text: 'Konsul Dokter',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.konsultasi);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Debug Buttons jika di debug mode & bukan preview
                  if (kDebugMode && !isPreview) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Development Testing:',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
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
                            icon: const Icon(Icons.add_box, size: 16),
                            label: const Text('Isi 7 Dummy',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                            ),
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
                            icon: const Icon(Icons.delete, size: 16),
                            label: const Text('Hapus Dummy',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                            ),
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
        color: AppColors.cardBackground,
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
                    color: junkFood > 0
                        ? const Color(0xFFD95030) // Oranye
                        : Colors.grey.shade200,
                  ),
                ),
                Expanded(
                  flex: homemade > 0 ? homemade : 1,
                  child: Container(
                    height: 24,
                    color: homemade > 0
                        ? const Color(0xFF53A66B) // Hijau
                        : Colors.grey.shade200,
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
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD95030),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Junk food $junkFood%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF53A66B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Homemade $homemade%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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

    if (stats.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Belum ada data protein',
          style: TextStyle(fontSize: 12, color: AppColors.neutralGray),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
                  width: 95,
                  child: Text(
                    e.key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(height: 16, color: const Color(0xFFF0F0F0)),
                        FractionallySizedBox(
                          widthFactor: (e.value / 100).clamp(0.0, 1.0),
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4B87A6), // Biru
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
                  width: 36,
                  child: Text(
                    '${e.value}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                    ),
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

    if (stats.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Belum ada data rasa',
          style: TextStyle(fontSize: 12, color: AppColors.neutralGray),
        ),
      );
    }

    Color getTasteColor(String taste) {
      switch (taste) {
        case 'Asam':
          return const Color(0xFFFFCC00); // Kuning
        case 'Manis':
          return const Color(0xFF53A66B); // Hijau
        case 'Pedas':
          return const Color(0xFFD95030); // Oranye tua
        case 'Asin':
          return const Color(0xFFD67C65); // Oranye pudar / koral
        case 'Berlemak':
          return const Color(0xFF8B5A2B); // Coklat
        default:
          return Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
          final height = ((e.value / 100).clamp(0.0, 1.0)) * 40 + 6;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 24,
                height: height,
                decoration: BoxDecoration(
                  color: getTasteColor(e.key),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brownSubtext,
                ),
              ),
              Text(
                '${e.value}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMinuman(FoodSummaryCalculator calc) {
    final stats = calc.minumanStats;

    Widget buildBar(
        String title, IconData icon, int percentage, Color color) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryText),
            const SizedBox(width: 8),
            SizedBox(
              width: 54,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(height: 16, color: const Color(0xFFF0F0F0)),
                    FractionallySizedBox(
                      widthFactor: (percentage / 100).clamp(0.0, 1.0),
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
              width: 36,
              child: Text(
                '$percentage%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
          buildBar('Kopi', Icons.coffee, stats['Kopi'] ?? 0,
              const Color(0xFFD95030)),
          buildBar('Soda', Icons.local_drink, stats['Soda'] ?? 0,
              const Color(0xFFD67C65)),
          buildBar('Lainnya', Icons.emoji_food_beverage, stats['Lainnya'] ?? 0,
              const Color(0xFF53A66B)),
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
                hasData ? '${data['percentage']}%' : 'Belum ada data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: hasData ? 24 : 14,
                  fontWeight: FontWeight.w900,
                  color: hasData
                      ? AppColors.primaryLight
                      : AppColors.neutralGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.brownSubtext,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasData
                    ? 'rata-rata ${data['average']}/5'
                    : 'Belum ada data',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.brownSubtext,
                ),
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../constants/app_colors.dart';
import '../../models/food_entry_model.dart';
import '../../routes/app_routes.dart';
import '../../services/food_entry_service.dart';
import '../../utils/food_summary_calculator.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/primary_button.dart';

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

  /// Semua entri yang didapatkan dari query
  List<FoodEntry> _allEntries = [];

  /// Daftar tanggal unik (format 'yyyy-MM-dd') yang memiliki catatan, terurut descending
  List<String> _availableDates = [];

  /// Tanggal yang sedang ditampilkan
  String? _selectedDate;

  /// Sesi hari ini yang sudah terisi (Set firestoreKey).
  Set<String> _todayFilledSessions = {};

  bool _isPreviewMode = false;
  List<FoodEntry> _mockEntries = [];
  List<String> _mockAvailableDates = [];
  String? _mockSelectedDate;

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
        debugPrint('[RingkasanMakanan] Entri dimuat: 0 → Status: Kosong');
        setState(() {
          _isLoading = false;
          _allEntries = [];
          _availableDates = [];
          _selectedDate = null;
          _todayFilledSessions = {};
          _calculator = null;
        });
        break;

      case FoodSummarySuccess(:final entries):
        final todayStr = FoodEntryService.todayString();
        final todaySessionKeys = entries
            .where((e) => e.tanggal == todayStr)
            .map((e) => e.sesi.firestoreKey)
            .toSet();

        // Ambil semua tanggal unik terurut descending (terbaru di depan)
        final dates = entries
            .map((e) => e.tanggal)
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

        if (dates.isEmpty) {
          setState(() {
            _isLoading = false;
            _allEntries = [];
            _availableDates = [];
            _selectedDate = null;
            _todayFilledSessions = todaySessionKeys;
            _calculator = null;
          });
          return;
        }

        // Tentukan tanggal yang ditampilkan:
        // 1. Jika user sudah memilih tanggal tertentu dan tanggal itu masih ada, pertahankan.
        // 2. Jika hari ini ada catatan makanan, prioritaskan hari ini.
        // 3. Jika hari ini belum ada catatan, tampilkan tanggal terbaru yang memiliki catatan.
        String chosenDate;
        if (_selectedDate != null && dates.contains(_selectedDate)) {
          chosenDate = _selectedDate!;
        } else if (dates.contains(todayStr)) {
          chosenDate = todayStr;
        } else {
          chosenDate = dates.first;
        }

        final dayEntries = entries.where((e) => e.tanggal == chosenDate).toList();
        final calc = FoodSummaryCalculator(
          entries: dayEntries,
          uniqueDates: [chosenDate],
        );

        debugPrint('[RingkasanMakanan] Tanggal dipilih: $chosenDate, entri: ${dayEntries.length}');

        setState(() {
          _isLoading = false;
          _allEntries = entries;
          _availableDates = dates;
          _selectedDate = chosenDate;
          _todayFilledSessions = todaySessionKeys;
          _calculator = calc;
        });
        break;
    }
  }

  void _onSelectDate(String date) {
    if (_isPreviewMode) {
      final dayEntries = _mockEntries.where((e) => e.tanggal == date).toList();
      setState(() {
        _mockSelectedDate = date;
        _mockCalculator = FoodSummaryCalculator(
          entries: dayEntries,
          uniqueDates: [date],
        );
      });
    } else {
      final dayEntries = _allEntries.where((e) => e.tanggal == date).toList();
      setState(() {
        _selectedDate = date;
        _calculator = FoodSummaryCalculator(
          entries: dayEntries,
          uniqueDates: [date],
        );
      });
    }
  }

  void _activatePreviewMode() {
    final mockEntries = _generateMockEntries();
    final mockDates = mockEntries.map((e) => e.tanggal).toSet().toList()
      ..sort((a, b) => b.compareTo(a)); // descending
    final initialDate = mockDates.isNotEmpty ? mockDates.first : FoodEntryService.todayString();
    final dayEntries = mockEntries.where((e) => e.tanggal == initialDate).toList();
    final calc = FoodSummaryCalculator(
      entries: dayEntries,
      uniqueDates: [initialDate],
    );

    setState(() {
      _mockEntries = mockEntries;
      _mockAvailableDates = mockDates;
      _mockSelectedDate = initialDate;
      _mockCalculator = calc;
      _isPreviewMode = true;
    });
  }

  void _exitPreviewMode() {
    setState(() {
      _isPreviewMode = false;
      _mockCalculator = null;
      _mockEntries = [];
      _mockAvailableDates = [];
      _mockSelectedDate = null;
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
        body: _buildReportView(
          _mockCalculator!,
          isPreview: true,
          availableDates: _mockAvailableDates,
          selectedDate: _mockSelectedDate,
          onDateChanged: _onSelectDate,
        ),
      );
    }

    if (_calculator != null) {
      return AppScaffold(
        body: _buildReportView(
          _calculator!,
          isPreview: false,
          availableDates: _availableDates,
          selectedDate: _selectedDate,
          onDateChanged: _onSelectDate,
        ),
      );
    }

    return AppScaffold(
      body: _buildEmptyView(),
    );
  }

  // ─── Header Universal (Sesuai Gaya Halaman Lain) ──────────────────────────
  Widget _buildScreenHeader({
    FoodSummaryCalculator? calc,
    VoidCallback? onBack,
    List<String> availableDates = const [],
    String? selectedDate,
    ValueChanged<String>? onDateChanged,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEBE3D0),
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
      child: const Text(
        'Ringkasan Nutrisi Harian',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryText,
          letterSpacing: 0.2,
        ),
      ),
    );

    final hasMultipleDates = availableDates.length > 1 && selectedDate != null;
    final currentIndex = selectedDate != null ? availableDates.indexOf(selectedDate) : -1;
    final bool canGoNext = hasMultipleDates && currentIndex > 0;
    final bool canGoPrev = hasMultipleDates && currentIndex < availableDates.length - 1;

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
              child: hasMultipleDates
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: canGoPrev
                              ? () => onDateChanged?.call(availableDates[currentIndex + 1])
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 24,
                              color: canGoPrev
                                  ? AppColors.primary
                                  : AppColors.neutralGray.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${calc.dateRangeString} · ${calc.totalEntries} kali makan tercatat',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brownSubtext,
                              height: 1.4,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: canGoNext
                              ? () => onDateChanged?.call(availableDates[currentIndex - 1])
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 24,
                              color: canGoNext
                                  ? AppColors.primary
                                  : AppColors.neutralGray.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '${calc.dateRangeString} · ${calc.totalEntries} kali makan tercatat',
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

  // ─── 1. State Kosong (Belum ada catatan makanan) ──────────────────────────
  Widget _buildEmptyView() {
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
                  const SizedBox(height: 30),
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
                        Icons.restaurant_menu_rounded,
                        size: 54,
                        color: AppColors.orangeAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Belum Ada Catatan Makanan Hari Ini',
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
                    'Catat makananmu hari ini (Sarapan, Makan Siang, atau Makan Malam) untuk melihat analisis status gizi dan kesehatan lambung.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.brownSubtext,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Isi Catat Makananmu',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.catatMakanan)
                          .then((_) => _loadData());
                    },
                  ),
                  if (kTampilkanContohRingkasan) ...[
                    const SizedBox(height: 12),
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
                  ],
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
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
  Widget _buildReportView(
    FoodSummaryCalculator calc, {
    required bool isPreview,
    List<String> availableDates = const [],
    String? selectedDate,
    ValueChanged<String>? onDateChanged,
  }) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScreenHeader(
              calc: calc,
              onBack: isPreview ? _exitPreviewMode : null,
              availableDates: availableDates,
              selectedDate: selectedDate,
              onDateChanged: onDateChanged,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<String>(
                      selectedDate ?? 'report_${calc.totalEntries}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildSectionTitle(
                          'Status Gizi & Kesehatan Lambung Hari Ini'),
                      _buildStatusLambungCard(calc),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Asupan Gizi Hari Ini'),
                      _buildAsupanGiziCard(calc),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Jenis Makanan'),
                      _buildJenisMakanan(calc),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Sumber Makanan'),
                      _buildSumberMakanan(calc),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Rasa Dominan'),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Rasa dengan skor tertinggi per makan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.brownSubtext,
                          ),
                        ),
                      ),
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
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
        ),
      ),
    );
  }

  // ─── Section 1: Status Gizi & Kesehatan Lambung Hari Ini ───────────────────
  Widget _buildStatusLambungCard(FoodSummaryCalculator calc) {
    final risk = calc.calculateLambungRiskScore();
    final nut = calc.calculateDailyNutrition();
    final entryCount = calc.totalEntries;

    final Color primaryTone;
    final Color bgTone;
    final Color borderTone;
    final IconData statusIcon;

    switch (risk.level) {
      case LambungRiskLevel.aman:
        primaryTone = const Color(0xFF53A66B); // Hijau soft
        bgTone = const Color(0xFFF1F8F3);
        borderTone = const Color(0xFFC8E6C9);
        statusIcon = Icons.check_circle_rounded;
        break;
      case LambungRiskLevel.perluDiperhatikan:
        primaryTone = const Color(0xFFD67C65); // Oranye pudar / koral
        bgTone = const Color(0xFFFFF9EE);
        borderTone = const Color(0xFFFFE0B2);
        statusIcon = Icons.warning_amber_rounded;
        break;
      case LambungRiskLevel.berisiko:
        primaryTone = const Color(0xFFD95030); // Oranye-merah soft
        bgTone = const Color(0xFFFDF3F3);
        borderTone = const Color(0xFFFFCDD2);
        statusIcon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgTone,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderTone, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Ikon Besar di Tengah ──
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: borderTone, width: 2),
              boxShadow: [
                BoxShadow(
                  color: primaryTone.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(statusIcon, color: primaryTone, size: 38),
          ),
          const SizedBox(height: 10),

          // ── Label Kecil "STATUS KESEHATAN LAMBUNG" ──
          Text(
            'STATUS KESEHATAN LAMBUNG',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: primaryTone.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 4),

          // ── Teks Status Utama ──
          Text(
            risk.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: primaryTone,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // ── Badge Waktu Makan ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderTone.withOpacity(0.8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded,
                    size: 13, color: primaryTone.withOpacity(0.7)),
                const SizedBox(width: 5),
                Text(
                  'Berdasarkan $entryCount dari 3 waktu makan yang tercatat',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primaryTone.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Kotak Penjelasan Semi-transparan ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderTone.withOpacity(0.5)),
            ),
            child: Text(
              risk.explanation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── 4 Kotak Kecil Kecukupan Gizi ──
          const Text(
            'Kecukupan Gizi Harian Terpenuhi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryLight,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildGiziMiniItem(
                  'Kalori',
                  '${nut.caloriesPercentage}%',
                  const Color(0xFFE5983A),
                  Icons.local_fire_department_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGiziMiniItem(
                  'Protein',
                  '${nut.proteinPercentage}%',
                  const Color(0xFF4B87A6),
                  Icons.fitness_center_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGiziMiniItem(
                  'Karbo',
                  '${nut.carbsPercentage}%',
                  const Color(0xFFE5A83B),
                  Icons.grain_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGiziMiniItem(
                  'Lemak',
                  '${nut.fatPercentage}%',
                  const Color(0xFF8B5A2B),
                  Icons.water_drop_rounded,
                ),
              ),
            ],
          ),

          if (entryCount < 3) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.brownSubtext),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Catatan belum lengkap ($entryCount/3). Lengkapi catatan makanmu hari ini untuk hasil analisis nutrisi yang lebih akurat.',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.brownSubtext,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGiziMiniItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.brownSubtext,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 2: Asupan Gizi Hari Ini ───────────────────────────────────────
  Widget _buildAsupanGiziCard(FoodSummaryCalculator calc) {
    final nut = calc.calculateDailyNutrition();

    Widget buildCircle({
      required String label,
      required int percentage,
      required double current,
      required double target,
      required String unit,
      required Color color,
      required IconData icon,
    }) {
      final pct = (percentage / 100).clamp(0.0, 1.0);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularPercentIndicator(
            radius: 52.0,
            lineWidth: 10.0,
            percent: pct,
            animation: true,
            animationDuration: 1000,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: color,
            backgroundColor: const Color(0xFFF0F0F0),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  '${current.toStringAsFixed(0)}$unit',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brownSubtext,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            '/ ${target.toInt()}$unit',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.brownSubtext,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildCircle(
                label: 'Kalori',
                percentage: nut.caloriesPercentage,
                current: nut.calories.toDouble(),
                target: nut.target.calories.toDouble(),
                unit: 'Kcal',
                color: const Color(0xFFE5983A),
                icon: Icons.local_fire_department_rounded,
              ),
              buildCircle(
                label: 'Protein',
                percentage: nut.proteinPercentage,
                current: nut.protein,
                target: nut.target.protein,
                unit: 'g',
                color: const Color(0xFF4B87A6),
                icon: Icons.fitness_center_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildCircle(
                label: 'Karbohidrat',
                percentage: nut.carbsPercentage,
                current: nut.carbs,
                target: nut.target.carbs,
                unit: 'g',
                color: const Color(0xFFE5A83B),
                icon: Icons.grain_rounded,
              ),
              buildCircle(
                label: 'Lemak',
                percentage: nut.fatPercentage,
                current: nut.fat,
                target: nut.target.fat,
                unit: 'g',
                color: const Color(0xFF8B5A2B),
                icon: Icons.water_drop_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildJenisMakanan(FoodSummaryCalculator calc) {
    final stats = calc.jenisMakananStats;
    final junkFood = stats['Junk Food'] ?? 0;
    final homemade = stats['Homemade'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bar proporsional — lebih tinggi + pill shape
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  flex: junkFood > 0 ? junkFood : 1,
                  child: Container(
                    height: 22,
                    color: junkFood > 0
                        ? const Color(0xFFD95030)
                        : Colors.grey.shade200,
                  ),
                ),
                Expanded(
                  flex: homemade > 0 ? homemade : 1,
                  child: Container(
                    height: 22,
                    color: homemade > 0
                        ? const Color(0xFF53A66B)
                        : Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD95030),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🍔 Junk food $junkFood%',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF53A66B),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🍲 Homemade $homemade%',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
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

    Color getSumberColor(String name) {
      final n = name.toLowerCase();
      if (n.contains('tahu') || n.contains('tempe')) return const Color(0xFF4CAF50);
      if (n.contains('sapi') || n.contains('daging')) return const Color(0xFFE53935);
      if (n.contains('ayam')) return const Color(0xFFFF7043);
      if (n.contains('ikan')) return const Color(0xFF1E88E5);
      if (n.contains('telur')) return const Color(0xFFFFA726);
      if (n.contains('tidak') || n.contains('tida')) return const Color(0xFF90A4AE);
      return const Color(0xFF8D6E63);
    }

    String getSumberEmoji(String name) {
      final n = name.toLowerCase();
      if (n.contains('tahu') || n.contains('tempe')) return '🌱';
      if (n.contains('sapi') || n.contains('daging')) return '🥩';
      if (n.contains('ayam')) return '🍗';
      if (n.contains('ikan')) return '🐟';
      if (n.contains('telur')) return '🥚';
      if (n.contains('tidak') || n.contains('tida')) return '—';
      return '🍽️';
    }

    if (stats.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'Belum ada data protein',
          style: TextStyle(fontSize: 12, color: AppColors.neutralGray),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final e = entry.value;
          final isLast = index == stats.length - 1;
          final barColor = getSumberColor(e.key);
          final emoji = getSumberEmoji(e.key);

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0.0 : 16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    '$emoji ${e.key}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: barColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
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
                              color: barColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${e.value}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: barColor,
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
          return const Color(0xFFFFD600); // Lemon kuning
        case 'Manis':
          return const Color(0xFFE91E63); // Magenta pink
        case 'Pedas':
          return const Color(0xFFE53935); // Merah terang
        case 'Asin':
          return const Color(0xFF00BCD4); // Teal/cyan
        case 'Berlemak':
          return const Color(0xFFFF6F00); // Oranye burnt
        default:
          return Colors.grey;
      }
    }

    String getTasteEmoji(String taste) {
      switch (taste) {
        case 'Asam': return '🍋';
        case 'Manis': return '🍬';
        case 'Pedas': return '🌶️';
        case 'Asin': return '🧂';
        case 'Berlemak': return '🧈';
        default: return '🍽️';
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: stats.map((e) {
          final color = getTasteColor(e.key);
          final emoji = getTasteEmoji(e.key);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.key,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${e.value}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
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

    Widget buildBar(String emoji, String title, int percentage, Color color,
        {bool isLast = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0.0 : 16.0),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 4),
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
            const SizedBox(width: 10),
            SizedBox(
              width: 44,
              child: Text(
                '$percentage%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          buildBar('☕', 'Kopi', stats['Kopi'] ?? 0, const Color(0xFF6D4C41)),
          buildBar('🥤', 'Soda', stats['Soda'] ?? 0, const Color(0xFF42A5F5)),
          buildBar('💧', 'Lainnya', stats['Lainnya'] ?? 0,
              const Color(0xFF26C6DA),
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildBebanHarian(FoodSummaryCalculator calc) {
    final stats = calc.bebanHarianStats;
    final pikiran = stats['Beban Pikiran']!;
    final aktivitas = stats['Beban Aktivitas']!;

    Widget buildGauge({
      required String emoji,
      required String title,
      required Map<String, dynamic> data,
      required Color progressColor,
    }) {
      final hasData = data['hasData'] as bool;
      final percentage = hasData ? (data['percentage'] as int) : 0;
      final pct = (percentage / 100).clamp(0.0, 1.0);

      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 10),
              CircularPercentIndicator(
                radius: 50.0,
                lineWidth: 11.0,
                percent: pct,
                animation: true,
                animationDuration: 1200,
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: progressColor,
                backgroundColor: const Color(0xFFF0F0F0),
                center: Text(
                  hasData ? '$percentage%' : '—',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: hasData ? progressColor : AppColors.neutralGray,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.brownSubtext,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                hasData
                    ? 'rata-rata ${data['average']}/5'
                    : 'Belum ada data',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.brownSubtext,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        buildGauge(
          emoji: '🧠',
          title: 'Beban pikiran',
          data: pikiran,
          progressColor: const Color(0xFF7C4DFF),
        ),
        const SizedBox(width: 14),
        buildGauge(
          emoji: '🏃',
          title: 'Beban aktivitas',
          data: aktivitas,
          progressColor: const Color(0xFFFF6D00),
        ),
      ],
    );
  }
}

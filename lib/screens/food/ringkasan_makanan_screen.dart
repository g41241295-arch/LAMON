import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  static const LinearGradient _bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFCFBF7),
      Color(0xFFF7F4EB),
      Color(0xFFF2EEDB),
    ],
  );

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
          _calculator = null;
        });
        break;

      case FoodSummarySuccess(:final entries):
        final todayStr = FoodEntryService.todayString();

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
        backgroundGradient: _bgGradient,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_isError) {
      return AppScaffold(
        backgroundGradient: _bgGradient,
        body: _buildErrorView(),
      );
    }

    if (_isPreviewMode && _mockCalculator != null) {
      return AppScaffold(
        backgroundGradient: _bgGradient,
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
        backgroundGradient: _bgGradient,
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
      backgroundGradient: _bgGradient,
      body: _buildEmptyView(),
    );
  }

  // ─── Header Universal (Sesuai Gaya Halaman Catat Makanan) ─────────────────
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
          color: Color(0xFF1C4E68),
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
          color: const Color(0xFFE8D7A5),
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
      child: Text(
        'Ringkasan Nutrisi Harian',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1C4E68),
          letterSpacing: 0.2,
        ),
      ),
    );

    final hasMultipleDates = availableDates.length > 1 && selectedDate != null;
    final currentIndex =
        selectedDate != null ? availableDates.indexOf(selectedDate) : -1;
    final bool canGoNext = hasMultipleDates && currentIndex > 0;
    final bool canGoPrev =
        hasMultipleDates && currentIndex < availableDates.length - 1;

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
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEBE3D0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: canGoPrev
                          ? () => onDateChanged
                              ?.call(availableDates[currentIndex + 1])
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 22,
                          color: canGoPrev
                              ? const Color(0xFF1C4E68)
                              : const Color(0xFF90A4AE).withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 13, color: Color(0xFF276F8F)),
                          const SizedBox(width: 6),
                          Text(
                            calc.dateRangeString,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C4E68),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7D6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE8D7A5),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              '${calc.totalEntries} kali makan',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1C4E68),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: canGoNext
                          ? () => onDateChanged
                              ?.call(availableDates[currentIndex - 1])
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: canGoNext
                              ? const Color(0xFF1C4E68)
                              : const Color(0xFF90A4AE).withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ],
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
                  Text(
                    'Belum Ada Catatan Makanan Hari Ini',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C4E68),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Catat makananmu hari ini (Sarapan, Makan Siang, atau Makan Malam) untuk melihat analisis status gizi dan kesehatan lambung.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF5A7184),
                      height: 1.5,
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
                            size: 20, color: Color(0xFF1C4E68)),
                        label: Text(
                          'Lihat Contoh Tampilan',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C4E68),
                            letterSpacing: -0.2,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1C4E68),
                          side: const BorderSide(
                              color: Color(0xFF1C4E68), width: 1.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
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
                  Text(
                    'Gagal memuat ringkasan',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C4E68),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Terjadi kendala saat mengambil catatan makananmu. Silakan periksa koneksi dan coba lagi.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF5A7184), fontSize: 13),
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
                        label: Text(
                          'Lihat Contoh Tampilan',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C4E68),
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
                      label: Text('Coba Lagi',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1C4E68),
                        side: const BorderSide(
                            color: Color(0xFF1C4E68), width: 1.5),
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
                      Expanded(
                        child: Text(
                          'Contoh tampilan dengan data simulasi, bukan catatan Anda.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brownDark,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _exitPreviewMode,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: Text(
                            'Tutup',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C4E68),
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
              padding: const EdgeInsets.symmetric(horizontal: 18),
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
                      const SizedBox(height: 8),

                      // 1. Status Kesehatan Lambung (Hero Health Card)
                      _buildSectionHeader(
                        Icons.health_and_safety_rounded,
                        'Status Kesehatan Lambung',
                      ),
                      _buildStatusLambungCard(calc),
                      const SizedBox(height: 20),

                      // 2. Asupan Nutrisi Harian (Circular Indicators)
                      _buildSectionHeader(
                        Icons.pie_chart_rounded,
                        'Asupan Nutrisi Harian',
                      ),
                      _buildAsupanGiziCard(calc),
                      const SizedBox(height: 20),

                      // 3. Komposisi & Sumber Pangan (Integrated Card)
                      _buildSectionHeader(
                        Icons.restaurant_menu_rounded,
                        'Komposisi & Sumber Pangan',
                      ),
                      _buildKomposisiPanganCard(calc),
                      const SizedBox(height: 20),

                      // 4. Kebiasaan Minum & Pola Rasa (Integrated Card)
                      _buildSectionHeader(
                        Icons.local_cafe_rounded,
                        'Kebiasaan Minum & Pola Rasa',
                      ),
                      _buildKebiasaanRasaCard(calc),
                      const SizedBox(height: 20),

                      // 5. Beban Harian & Gaya Hidup (Side-by-side Tiles)
                      _buildSectionHeader(
                        Icons.self_improvement_rounded,
                        'Beban Harian & Gaya Hidup',
                      ),
                      _buildBebanHarian(calc),
                      const SizedBox(height: 28),

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
                            foregroundColor: const Color(0xFF1C4E68),
                            side: const BorderSide(
                                color: Color(0xFF1C4E68), width: 1.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: Text(
                            'Prediksi Sekarang',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C4E68),
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

  // ─── Modern Section Header With Soft Blue Icon Pill ───────────────────────
  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF276F8F).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF276F8F).withValues(alpha: 0.22),
                width: 1.0,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF276F8F),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C4E68),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 1. Status Kesehatan Lambung (Hero Health Card) ───────────────────────
  Widget _buildStatusLambungCard(FoodSummaryCalculator calc) {
    final risk = calc.calculateLambungRiskScore();
    final entryCount = calc.totalEntries;

    final Color primaryTone;
    final Color bgTone;
    final Color borderTone;
    final IconData statusIcon;

    switch (risk.level) {
      case LambungRiskLevel.aman:
        primaryTone = const Color(0xFF53A66B);
        bgTone = const Color(0xFFF1F8F3);
        borderTone = const Color(0xFFC8E6C9);
        statusIcon = Icons.check_circle_rounded;
        break;
      case LambungRiskLevel.perluDiperhatikan:
        primaryTone = const Color(0xFFD67C65);
        bgTone = const Color(0xFFFFF9EE);
        borderTone = const Color(0xFFFFE0B2);
        statusIcon = Icons.warning_amber_rounded;
        break;
      case LambungRiskLevel.berisiko:
        primaryTone = const Color(0xFFD95030);
        bgTone = const Color(0xFFFDF3F3);
        borderTone = const Color(0xFFFFCDD2);
        statusIcon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderTone.withValues(alpha: 0.9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryTone.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgTone,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderTone),
                ),
                child: Text(
                  'SKOR KLINIS',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: primaryTone,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEBE3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 12, color: primaryTone.withValues(alpha: 0.85)),
                    const SizedBox(width: 4),
                    Text(
                      '$entryCount/3 makan',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5A7184),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Icon Status
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: bgTone,
              shape: BoxShape.circle,
              border: Border.all(color: borderTone, width: 2),
              boxShadow: [
                BoxShadow(
                  color: primaryTone.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(statusIcon, color: primaryTone, size: 32),
          ),
          const SizedBox(height: 10),

          Text(
            risk.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: primaryTone,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Penjelasan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bgTone.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderTone.withValues(alpha: 0.6)),
            ),
            child: Text(
              risk.explanation,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2C3E50),
                height: 1.45,
              ),
            ),
          ),

          if (entryCount < 3) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: Color(0xFF7A8B99)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Catatan belum lengkap ($entryCount/3). Lengkapi catatan makanmu untuk hasil lebih akurat.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF7A8B99),
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

  // ─── 2. Asupan Nutrisi Harian (Circular Indicators Seperti Sebelumnya) ──────
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
            radius: 50.0,
            lineWidth: 9.0,
            percent: pct,
            animation: true,
            animationDuration: 1000,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: color,
            backgroundColor: const Color(0xFFF3F4F6),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percentage%',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  '${current.toStringAsFixed(0)}$unit',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7A8B99),
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
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '/ ${target.toInt()} $unit',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7A8B99),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEBE3D0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
          const SizedBox(height: 18),
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

  // ─── 3. Komposisi & Sumber Pangan (Integrated Card) ───────────────────────
  Widget _buildKomposisiPanganCard(FoodSummaryCalculator calc) {
    final jenisStats = calc.jenisMakananStats;
    final junkFood = jenisStats['Junk Food'] ?? 0;
    final homemade = jenisStats['Homemade'] ?? 0;
    final proteinStats = calc.proteinStats;

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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEBE3D0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-header 1: Jenis Olahan
          Text(
            'KUALITAS OLAHAN MAKANAN',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF5A7184),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  flex: junkFood > 0 ? junkFood : 1,
                  child: Container(
                    height: 18,
                    color: junkFood > 0
                        ? const Color(0xFFD95030)
                        : const Color(0xFFF3F4F6),
                  ),
                ),
                Expanded(
                  flex: homemade > 0 ? homemade : 1,
                  child: Container(
                    height: 18,
                    color: homemade > 0
                        ? const Color(0xFF53A66B)
                        : const Color(0xFFF3F4F6),
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
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD95030),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '🍔 Junk food $junkFood%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF1C4E68),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF53A66B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '🍲 Homemade $homemade%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF1C4E68),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF0EBE1), thickness: 1),
          ),

          // Sub-header 2: Sumber Protein
          Text(
            'DISTRIBUSI SUMBER PROTEIN',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF5A7184),
            ),
          ),
          const SizedBox(height: 10),
          if (proteinStats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada data protein tercatat',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFF7A8B99)),
              ),
            )
          else
            ...proteinStats.asMap().entries.map((entry) {
              final index = entry.key;
              final e = entry.value;
              final isLast = index == proteinStats.length - 1;
              final barColor = getSumberColor(e.key);
              final emoji = getSumberEmoji(e.key);

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0.0 : 12.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 105,
                      child: Text(
                        '$emoji ${e.key}',
                        style: GoogleFonts.poppins(
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
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          children: [
                            Container(height: 12, color: const Color(0xFFF3F4F6)),
                            FractionallySizedBox(
                              widthFactor: (e.value / 100).clamp(0.0, 1.0),
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${e.value}%',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: barColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─── 4. Kebiasaan Minum & Pola Rasa (Integrated Card) ──────────────────────
  Widget _buildKebiasaanRasaCard(FoodSummaryCalculator calc) {
    final statsMinuman = calc.minumanStats;
    final statsRasa = calc.rasaDominanStats;

    Widget buildDrinkBar(String emoji, String title, int percentage, Color color,
        {bool isLast = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0.0 : 12.0),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            SizedBox(
              width: 58,
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(height: 12, color: const Color(0xFFF3F4F6)),
                    FractionallySizedBox(
                      widthFactor: (percentage / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                '$percentage%',
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
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

    Color getTasteColor(String taste) {
      switch (taste) {
        case 'Asam': return const Color(0xFFD4A017);
        case 'Manis': return const Color(0xFFE91E63);
        case 'Pedas': return const Color(0xFFE53935);
        case 'Asin': return const Color(0xFF00ACC1);
        case 'Berlemak': return const Color(0xFFFF6F00);
        default: return Colors.grey;
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEBE3D0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-header 1: Minuman
          Text(
            'KONSUMSI MINUMAN',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF5A7184),
            ),
          ),
          const SizedBox(height: 10),
          buildDrinkBar('☕', 'Kopi', statsMinuman['Kopi'] ?? 0, const Color(0xFF6D4C41)),
          buildDrinkBar('🥤', 'Soda', statsMinuman['Soda'] ?? 0, const Color(0xFF42A5F5)),
          buildDrinkBar('💧', 'Lainnya', statsMinuman['Lainnya'] ?? 0, const Color(0xFF26C6DA), isLast: true),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF0EBE1), thickness: 1),
          ),

          // Sub-header 2: Rasa Dominan
          Text(
            'RASA DOMINAN TERCATAT',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF5A7184),
            ),
          ),
          const SizedBox(height: 12),
          if (statsRasa.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada data rasa',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFF7A8B99)),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: statsRasa.map((e) {
                final color = getTasteColor(e.key);
                final emoji = getTasteEmoji(e.key);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e.key,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${e.value}%',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1C4E68),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ─── 5. Beban Harian (Gaya Hidup & Stres) ──────────────────────────────────
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
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBE3D0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 10),
              CircularPercentIndicator(
                radius: 46.0,
                lineWidth: 8.0,
                percent: pct,
                animation: true,
                animationDuration: 1200,
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: progressColor,
                backgroundColor: const Color(0xFFF3F4F6),
                center: Text(
                  hasData ? '$percentage%' : '—',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: hasData ? progressColor : const Color(0xFF7A8B99),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF1C4E68),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasData
                    ? 'Rata-rata ${data['average']}/5'
                    : 'Belum ada data',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: const Color(0xFF7A8B99),
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
          title: 'Beban Pikiran',
          data: pikiran,
          progressColor: const Color(0xFF7C4DFF),
        ),
        const SizedBox(width: 12),
        buildGauge(
          emoji: '🏃',
          title: 'Beban Aktivitas',
          data: aktivitas,
          progressColor: const Color(0xFFFF6D00),
        ),
      ],
    );
  }
}

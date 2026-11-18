import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/food_entry_model.dart';
import '../../routes/app_routes.dart';
import '../../services/food_entry_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/food/meal_session_tab.dart';
import '../../widgets/food/section_card.dart';
import '../../widgets/food/chip_selector.dart';
import '../../widgets/food/other_text_field.dart';
import '../../widgets/food/discrete_slider.dart';
import '../../widgets/food/toggle_yes_no.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State holder untuk satu tab sesi
// ─────────────────────────────────────────────────────────────────────────────
class _SessionState {
  Set<String> jenisMakanan = {};
  Set<String> sumberKarbohidrat = {};
  Set<String> protein = {};
  Set<String> sayuran = {};
  final TextEditingController proteinLainnyaCtrl = TextEditingController();
  final TextEditingController sayuranLainnyaCtrl = TextEditingController();
  int levelPedas = 0;
  int levelAsin = 0;
  int levelAsam = 0;
  int levelManis = 0;
  int levelBerlemak = 0;
  bool? berbaringSetelahMakan;
  bool? konsumsiSoda;
  bool? konsumsiKopi;
  // Makan Malam only
  int bebanPikiran = 0;
  int bebanAktivitas = 0;

  // Error state per field
  bool errJenis = false;
  bool errKarbo = false;
  bool errProtein = false;
  bool errSayuran = false;
  bool errProteinLainnya = false;
  bool errSayuranLainnya = false;
  bool errBerbaring = false;
  bool errSoda = false;
  bool errKopi = false;

  void dispose() {
    proteinLainnyaCtrl.dispose();
    sayuranLainnyaCtrl.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────
class CatatMakananScreen extends StatefulWidget {
  const CatatMakananScreen({super.key});

  @override
  State<CatatMakananScreen> createState() => _CatatMakananScreenState();
}

class _CatatMakananScreenState extends State<CatatMakananScreen> {
  final FoodEntryService _service = FoodEntryService();
  final ScrollController _scrollController = ScrollController();

  late MealSession _activeSession;
  late DateTime _openedAt;

  // State per sesi (indeks 0=Sarapan, 1=Siang, 2=Malam)
  final List<_SessionState> _states = [
    _SessionState(),
    _SessionState(),
    _SessionState(),
  ];

  // Sesi yang sudah terisi hari ini
  final Map<MealSession, bool> _submittedMap = {};
  // Entri existing (untuk read-only mode)
  final Map<MealSession, FoodEntry?> _existingEntries = {};

  bool _isLoading = true;
  bool _isSaving = false;

  static const _today = FoodEntryService.todayString;

  String get _todayStr => _today();

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _activeSession = MealSessionTab.detectCurrentSession();
    _loadSubmittedSessions();
  }

  @override
  void dispose() {
    for (final s in _states) {
      s.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmittedSessions() async {
    setState(() => _isLoading = true);
    for (final session in MealSession.values) {
      final entry = await _service.getEntryBySessionAndDate(
        session,
        _todayStr,
      );
      _existingEntries[session] = entry;
      _submittedMap[session] = entry != null;

      if (entry != null) {
        final s = _states[session.index];
        s.jenisMakanan = Set.from(entry.jenisMakanan);
        s.sumberKarbohidrat = Set.from(entry.sumberKarbohidrat);
        s.protein = Set.from(entry.protein);
        s.sayuran = Set.from(entry.sayuran);
        if (entry.proteinLainnya != null) s.proteinLainnyaCtrl.text = entry.proteinLainnya!;
        if (entry.sayuranLainnya != null) s.sayuranLainnyaCtrl.text = entry.sayuranLainnya!;
        s.levelPedas = entry.levelPedas;
        s.levelAsin = entry.levelAsin;
        s.levelAsam = entry.levelAsam;
        s.levelManis = entry.levelManis;
        s.levelBerlemak = entry.levelBerlemak;
        s.berbaringSetelahMakan = entry.berbaringSetelahMakan;
        s.konsumsiSoda = entry.konsumsiSoda;
        s.konsumsiKopi = entry.konsumsiKopi;
        if (session == MealSession.makanMalam) {
          s.bebanPikiran = entry.bebanPikiran ?? 0;
          s.bebanAktivitas = entry.bebanAktivitas ?? 0;
        }
      }
    }
    setState(() => _isLoading = false);
  }

  bool get _isCurrentSessionDone =>
      _submittedMap[_activeSession] == true;

  _SessionState get _current =>
      _states[_activeSession.index];

  // ── Validasi ───────────────────────────────────────────────────────────────
  bool _validate() {
    final s = _current;
    bool valid = true;

    setState(() {
      s.errJenis = s.jenisMakanan.isEmpty;
      s.errKarbo = s.sumberKarbohidrat.isEmpty;
      s.errProtein = s.protein.isEmpty;
      s.errSayuran = s.sayuran.isEmpty;
      s.errProteinLainnya = s.protein.contains('Lainnya') &&
          s.proteinLainnyaCtrl.text.trim().isEmpty;
      s.errSayuranLainnya = s.sayuran.contains('Lainnya') &&
          s.sayuranLainnyaCtrl.text.trim().isEmpty;
      s.errBerbaring = s.berbaringSetelahMakan == null;
      s.errSoda = s.konsumsiSoda == null;
      s.errKopi = s.konsumsiKopi == null;
    });

    if (s.errJenis || s.errKarbo || s.errProtein || s.errSayuran ||
        s.errProteinLainnya || s.errSayuranLainnya ||
        s.errBerbaring || s.errSoda || s.errKopi) {
      valid = false;
    }

    return valid;
  }

  // ── Simpan ─────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_validate()) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';
    final now = DateTime.now();
    final s = _current;

    final entryId = FoodEntryService.generateEntryId(
      userId,
      _activeSession,
      _todayStr,
    );

    final entry = FoodEntry(
      id: entryId,
      userId: userId,
      tanggal: _todayStr,
      waktuPengisian: now,
      sesi: _activeSession,
      jenisMakanan: s.jenisMakanan.toList(),
      sumberKarbohidrat: s.sumberKarbohidrat.toList(),
      protein: s.protein.toList(),
      sayuran: s.sayuran.toList(),
      proteinLainnya: s.protein.contains('Lainnya')
          ? s.proteinLainnyaCtrl.text.trim()
          : null,
      sayuranLainnya: s.sayuran.contains('Lainnya')
          ? s.sayuranLainnyaCtrl.text.trim()
          : null,
      levelPedas: s.levelPedas,
      levelAsin: s.levelAsin,
      levelAsam: s.levelAsam,
      levelManis: s.levelManis,
      levelBerlemak: s.levelBerlemak,
      berbaringSetelahMakan: s.berbaringSetelahMakan!,
      konsumsiSoda: s.konsumsiSoda!,
      konsumsiKopi: s.konsumsiKopi!,
      bebanPikiran:
          _activeSession == MealSession.makanMalam ? s.bebanPikiran : null,
      bebanAktivitas:
          _activeSession == MealSession.makanMalam ? s.bebanAktivitas : null,
    );

    try {
      await _service.saveEntry(entry);

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submittedMap[_activeSession] = true;
        _existingEntries[_activeSession] = entry;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Data ${_activeSession.label} berhasil disimpan!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
        ),
      );

      // Cek apakah ketiga sesi hari ini sudah lengkap
      final allDone = MealSession.values
          .every((ses) => _submittedMap[ses] == true);

      if (allDone && mounted) {
        // Tunggu snack bar sebentar, lalu tampilkan dialog tanpa navigasi otomatis
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        await _showRingkasanReadyDialog();
        return;
      }

      // Sedikit delay lalu kembali
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$e',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Bottom sheet yang ditampilkan ketika ketiga sesi hari ini sudah tersimpan.
  Future<void> _showRingkasanReadyDialog() async {
    if (!mounted) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFEBE3D0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE3D0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 40,
                  color: Color(0xFF276F8F),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ringkasan hari ini sudah tersedia!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C4E68),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kamu sudah melengkapi Sarapan, Makan Siang, dan Makan Malam hari ini. Ringkasan nutrisimu sudah bisa dilihat.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF7C8E97),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, 'ringkasan'),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF276F8F),
                          Color(0xFF1C4E68),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF276F8F).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Lihat Ringkasan',
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, 'nanti'),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFEBE3D0),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Nanti Saja',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C4E68),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (action == 'ringkasan') {
      Navigator.pop(context); // kembali dari CatatMakanan
      Navigator.pushNamed(context, AppRoutes.ringkasanMakanan);
    } else {
      Navigator.pop(context); // kembali ke halaman sebelumnya
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _formatDate(DateTime dt) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundGradient: AppColors.pageGradient,
      resizeToAvoidBottomInset: true,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildForm(),
                ),
              ],
            ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final isMalam = _activeSession == MealSession.makanMalam;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        children: [
          // Baris: Tombol Back + Pill Judul "Catat Makanan"
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
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
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF1C4E68),
                      size: 20,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.titlePillYellowBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.titlePillYellowBorder,
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
                  'Catat Makanan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.titlePillYellowText,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Badge Tanggal (+ jam jika Makan Malam)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEBE3D0),
                width: 1.1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: Color(0xFF276F8F),
                ),
                const SizedBox(width: 6),
                Text(
                  isMalam
                      ? '${_formatDate(_openedAt)}, ${_formatTime(_openedAt)} WIB'
                      : _formatDate(_openedAt),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C4E68),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Segmented Control 3 Waktu Makan (Sarapan, Makan Siang, Makan Malam)
          MealSessionTab(
            activeSession: _activeSession,
            submittedMap: _submittedMap,
            onSessionChanged: (session) {
              setState(() {
                _activeSession = session;
                if (session == MealSession.makanMalam) {
                  _openedAt = DateTime.now();
                }
              });
            },
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    final s = _current;
    final isMalam = _activeSession == MealSession.makanMalam;
    final isReadOnly = _isCurrentSessionDone;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner: Sesi Sudah Diisi ─────────────────────────────────────
          if (isReadOnly) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.successGreen.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.successGreen,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data ${_activeSession.label} Sudah Tersimpan',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C4E68),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          () {
                            final entry = _existingEntries[_activeSession];
                            return entry != null
                                ? 'Diisi ${_formatTime(entry.waktuPengisian)} WIB · ${_formatDate(entry.waktuPengisian)}'
                                : 'Entri sesi ini sudah tercatat hari ini.';
                          }(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7C8E97),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Kategori Makanan: Jenis Makanan ──────────────────────────────
          SectionCard(
            child: ChipSelector(
              label: 'Makanan Anda termasuk yang mana?',
              options: const ['Junk Food', 'Homemade'],
              selected: s.jenisMakanan,
              hasError: s.errJenis,
              onChanged: isReadOnly
                  ? null
                  : (v) => setState(() => s.jenisMakanan = v),
            ),
          ),
          const SizedBox(height: 14),

          // ── Kategori Makanan: Sumber Karbohidrat ─────────────────────────
          SectionCard(
            child: ChipSelector(
              label: 'Sumber karbohidrat mana yang Anda makan?',
              options: const ['Nasi putih', 'Roti'],
              selected: s.sumberKarbohidrat,
              hasError: s.errKarbo,
              onChanged: isReadOnly
                  ? null
                  : (v) => setState(() => s.sumberKarbohidrat = v),
            ),
          ),
          const SizedBox(height: 14),

          // ── Kategori Makanan: Protein ─────────────────────────────────────
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChipSelector(
                  label: 'Protein apa yang Anda makan?',
                  options: const [
                    'Daging Ayam',
                    'Daging Sapi',
                    'Ikan',
                    'Telur',
                    'Lainnya',
                  ],
                  selected: s.protein,
                  hasError: s.errProtein,
                  useGrid: true,
                  onChanged: isReadOnly
                      ? null
                      : (v) => setState(() => s.protein = v),
                ),
                if (s.protein.contains('Lainnya'))
                  OtherTextField(
                    controller: s.proteinLainnyaCtrl,
                    hint: 'Contoh: Tempe, Tahu, dll.',
                    hasError: s.errProteinLainnya,
                    enabled: !isReadOnly,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Kategori Makanan: Sayuran ─────────────────────────────────────
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChipSelector(
                  label: 'Sayuran apa yang Anda makan?',
                  options: const [
                    'Bayam',
                    'Kembang Kol',
                    'Sawi',
                    'Lainnya',
                  ],
                  selected: s.sayuran,
                  hasError: s.errSayuran,
                  useGrid: true,
                  onChanged: isReadOnly
                      ? null
                      : (v) => setState(() => s.sayuran = v),
                ),
                if (s.sayuran.contains('Lainnya'))
                  OtherTextField(
                    controller: s.sayuranLainnyaCtrl,
                    hint: 'Contoh: Brokoli, Kangkung, dll.',
                    hasError: s.errSayuranLainnya,
                    enabled: !isReadOnly,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Petunjuk Slider Karakteristik ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF276F8F).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF276F8F).withValues(alpha: 0.18),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF276F8F),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pilihlah, semakin ke kiri semakin rendah dan semakin ke kanan semakin tinggi.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C4E68),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Slider Karakteristik Rasa Makanan ─────────────────────────────
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF276F8F).withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Color(0xFF276F8F),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Karakteristik Rasa Makanan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C4E68),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEBE3D0)),
                const SizedBox(height: 14),

                DiscreteSlider(
                  label: 'Apakah makanan yang Anda makan pedas?',
                  iconEmoji: '🌶️',
                  stepLabels: const [
                    'Tidak pedas',
                    'Sedikit pedas',
                    'Cukup pedas',
                    'Pedas',
                    'Sangat pedas',
                  ],
                  value: s.levelPedas,
                  onChanged: isReadOnly ? null : (v) => setState(() => s.levelPedas = v),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEBE3D0)),
                const SizedBox(height: 14),

                DiscreteSlider(
                  label: 'Apakah makanan yang Anda makan asin?',
                  iconEmoji: '🧂',
                  stepLabels: const [
                    'Tidak asin',
                    'Sedikit asin',
                    'Cukup asin',
                    'Asin',
                    'Sangat asin',
                  ],
                  value: s.levelAsin,
                  onChanged: isReadOnly ? null : (v) => setState(() => s.levelAsin = v),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEBE3D0)),
                const SizedBox(height: 14),

                DiscreteSlider(
                  label: 'Apakah makanan yang Anda makan asam?',
                  customIcon: Image.asset(
                    'assets/images/asam.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (c, e, s) => const Text('🍋', style: TextStyle(fontSize: 18)),
                  ),
                  stepLabels: const [
                    'Tidak asam',
                    'Sedikit asam',
                    'Cukup asam',
                    'Asam',
                    'Sangat asam',
                  ],
                  value: s.levelAsam,
                  onChanged: isReadOnly ? null : (v) => setState(() => s.levelAsam = v),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEBE3D0)),
                const SizedBox(height: 14),

                DiscreteSlider(
                  label: 'Apakah makanan yang Anda makan manis?',
                  customIcon: Image.asset(
                    'assets/images/manis.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (c, e, s) => const Text('🍯', style: TextStyle(fontSize: 18)),
                  ),
                  stepLabels: const [
                    'Tidak manis',
                    'Sedikit manis',
                    'Cukup manis',
                    'Manis',
                    'Sangat manis',
                  ],
                  value: s.levelManis,
                  onChanged: isReadOnly ? null : (v) => setState(() => s.levelManis = v),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEBE3D0)),
                const SizedBox(height: 14),

                DiscreteSlider(
                  label: 'Apakah makanan yang Anda makan berlemak?',
                  customIcon: Image.asset(
                    'assets/images/berlemak.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (c, e, s) => const Text('🥩', style: TextStyle(fontSize: 18)),
                  ),
                  stepLabels: const [
                    'Tidak berlemak',
                    'Sedikit berlemak',
                    'Cukup berlemak',
                    'Berlemak',
                    'Sangat berlemak',
                  ],
                  value: s.levelBerlemak,
                  onChanged: isReadOnly ? null : (v) => setState(() => s.levelBerlemak = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Pertanyaan Kebiasaan Setelah Makan (Iya/Tidak) ─────────────────
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF276F8F).withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF276F8F),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kebiasaan Setelah Makan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C4E68),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEBE3D0)),
                const SizedBox(height: 14),

                ToggleYesNo(
                  label: 'Apakah Anda berbaring dalam waktu 2–3 jam setelah makan?',
                  value: s.berbaringSetelahMakan,
                  hasError: s.errBerbaring,
                  onChanged: isReadOnly
                      ? null
                      : (v) => setState(() => s.berbaringSetelahMakan = v),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEBE3D0)),
                const SizedBox(height: 14),

                ToggleYesNo(
                  label: 'Apakah Anda mengonsumsi minuman yang bersoda?',
                  value: s.konsumsiSoda,
                  hasError: s.errSoda,
                  onChanged: isReadOnly
                      ? null
                      : (v) => setState(() => s.konsumsiSoda = v),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEBE3D0)),
                const SizedBox(height: 14),

                ToggleYesNo(
                  label: 'Apakah Anda mengonsumsi kopi?',
                  value: s.konsumsiKopi,
                  hasError: s.errKopi,
                  onChanged: isReadOnly
                      ? null
                      : (v) => setState(() => s.konsumsiKopi = v),
                ),
              ],
            ),
          ),

          // ── KHUSUS MAKAN MALAM: Beban Pikiran & Aktivitas ─────────────────
          if (isMalam) ...[
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF276F8F).withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.nights_stay_rounded,
                          color: Color(0xFF276F8F),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Evaluasi Khusus Makan Malam',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1C4E68),
                              ),
                            ),
                            Text(
                              'Beban pikiran dan aktivitas harian sebelum istirahat',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF7C8E97),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFEBE3D0)),
                  const SizedBox(height: 14),

                  DiscreteSlider(
                    label: 'Seberapa berat beban pikiran Anda?',
                    iconEmoji: '🧠',
                    stepLabels: const [
                      'Tidak berat',
                      'Sedikit berat',
                      'Cukup berat',
                      'Berat',
                      'Sangat berat',
                    ],
                    value: s.bebanPikiran,
                    onChanged: isReadOnly
                        ? null
                        : (v) => setState(() => s.bebanPikiran = v),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFEBE3D0)),
                  const SizedBox(height: 14),

                  DiscreteSlider(
                    label: 'Seberapa berat beban aktivitas Anda?',
                    iconEmoji: '🏃',
                    stepLabels: const [
                      'Tidak berat',
                      'Sedikit berat',
                      'Cukup berat',
                      'Berat',
                      'Sangat berat',
                    ],
                    value: s.bebanAktivitas,
                    onChanged: isReadOnly
                        ? null
                        : (v) => setState(() => s.bebanAktivitas = v),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Tombol Simpan Modern Berstandar Beranda ───────────────────────
          GestureDetector(
            onTap: _isSaving || isReadOnly ? null : _save,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: isReadOnly
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF7C8E97).withValues(alpha: 0.6),
                          const Color(0xFF7C8E97).withValues(alpha: 0.4),
                        ],
                      )
                    : const LinearGradient(
                        colors: [
                          Color(0xFF276F8F),
                          Color(0xFF1C4E68),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: isReadOnly
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF276F8F).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isReadOnly
                                ? Icons.check_circle_rounded
                                : Icons.save_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isReadOnly
                                ? 'Data Sudah Tersimpan'
                                : 'Simpan Data ${_activeSession.label}',
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

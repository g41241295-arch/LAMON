import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
import '../../models/food_entry_model.dart';
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );

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
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );
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
      resizeToAvoidBottomInset: true,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isCurrentSessionDone
                      ? _buildReadOnlyView()
                      : _buildForm(),
                ),
              ],
            ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final isMalam = _activeSession == MealSession.makanMalam;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris: Back + Judul
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.primaryText,
                        size: 22,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Kembali',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Catat Makananmu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryText,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 72), // balance back button
            ],
          ),

          const SizedBox(height: 4),

          // Tanggal (+ jam jika Makan Malam)
          Center(
            child: Text(
              isMalam
                  ? '${_formatDate(_openedAt)}, ${_formatTime(_openedAt)}'
                  : _formatDate(_openedAt),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.neutralGray,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Segmented Control
          MealSessionTab(
            activeSession: _activeSession,
            submittedMap: _submittedMap,
            onSessionChanged: (session) {
              setState(() {
                _activeSession = session;
                // Perbarui waktu jika Malam dipilih
                    if (session == MealSession.makanMalam) {
                  _openedAt = DateTime.now();
                }
              });
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Read-Only Banner (sesi sudah diisi) ───────────────────────────────────
  Widget _buildReadOnlyView() {
    final entry = _existingEntries[_activeSession];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.successGreen.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.successGreen,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Data ${_activeSession.label} Sudah Tersimpan',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  entry != null
                      ? 'Diisi pada ${_formatTime(entry.waktuPengisian)} WIB, ${_formatDate(entry.waktuPengisian)}'
                      : 'Entri sesi ini sudah tercatat hari ini.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutralGray,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Data makanan ini tidak dapat diubah.\nSilakan isi sesi lain jika belum.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.neutralGray,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    final s = _current;
    final isMalam = _activeSession == MealSession.makanMalam;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pilihan Kategori ─────────────────────────────────────────────
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Jenis Makanan
                ChipSelector(
                  label: 'Makanan Anda termasuk yang mana?',
                  options: const ['Junk Food', 'Homemade'],
                  selected: s.jenisMakanan,
                  hasError: s.errJenis,
                  onChanged: (v) =>
                      setState(() => s.jenisMakanan = v),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.lightGray),
                const SizedBox(height: 16),

                // Sumber Karbohidrat
                ChipSelector(
                  label: 'Sumber karbohidrat mana yang Anda makan?',
                  options: const ['Nasi putih', 'Roti'],
                  selected: s.sumberKarbohidrat,
                  hasError: s.errKarbo,
                  onChanged: (v) =>
                      setState(() => s.sumberKarbohidrat = v),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.lightGray),
                const SizedBox(height: 16),

                // Protein
                ChipSelector(
                  label: 'Protein apa yg Anda makan?',
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
                  onChanged: (v) =>
                      setState(() => s.protein = v),
                ),
                if (s.protein.contains('Lainnya'))
                  OtherTextField(
                    controller: s.proteinLainnyaCtrl,
                    hint: 'Contoh: Tempe, Tahu, dll.',
                    hasError: s.errProteinLainnya,
                  ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.lightGray),
                const SizedBox(height: 16),

                // Sayuran
                ChipSelector(
                  label: 'Sayuran apa yg Anda makan?',
                  options: const [
                    'Bayam',
                    'Kembang Kol',
                    'Sawi',
                    'Lainnya',
                  ],
                  selected: s.sayuran,
                  hasError: s.errSayuran,
                  useGrid: true,
                  onChanged: (v) =>
                      setState(() => s.sayuran = v),
                ),
                if (s.sayuran.contains('Lainnya'))
                  OtherTextField(
                    controller: s.sayuranLainnyaCtrl,
                    hint: 'Contoh: Brokoli, Kangkung, dll.',
                    hasError: s.errSayuranLainnya,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Instruksi Slider ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Pilihlah, semakin ke kiri semakin rendah dan semakin ke kanan semakin tinggi.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Slider Rasa ──────────────────────────────────────────────────
          SectionCard(
            child: Column(
              children: [
                DiscreteSlider(
                  label: 'Apakah makanan Anda pedas?',
                  iconEmoji: '🌶️',
                  stepLabels: const [
                    'Tidak pedas',
                    'Sedikit pedas',
                    'Cukup pedas',
                    'Pedas',
                    'Sangat pedas',
                  ],
                  value: s.levelPedas,
                  onChanged: (v) => setState(() => s.levelPedas = v),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.lightGray),
                const SizedBox(height: 16),

                DiscreteSlider(
                  label: 'Apakah makanan Anda asin?',
                  iconEmoji: '🧂',
                  stepLabels: const [
                    'Tidak asin',
                    'Sedikit asin',
                    'Cukup asin',
                    'Asin',
                    'Sangat asin',
                  ],
                  value: s.levelAsin,
                  onChanged: (v) => setState(() => s.levelAsin = v),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.lightGray),
                const SizedBox(height: 16),

                DiscreteSlider(
                  label: 'Apakah makanan Anda asam?',
                  iconEmoji: '🍋',
                  stepLabels: const [
                    'Tidak asam',
                    'Sedikit asam',
                    'Cukup asam',
                    'Asam',
                    'Sangat asam',
                  ],
                  value: s.levelAsam,
                  onChanged: (v) => setState(() => s.levelAsam = v),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.lightGray),
                const SizedBox(height: 16),

                DiscreteSlider(
                  label: 'Apakah makanan Anda manis?',
                  iconEmoji: '🍯',
                  stepLabels: const [
                    'Tidak manis',
                    'Sedikit manis',
                    'Cukup manis',
                    'Manis',
                    'Sangat manis',
                  ],
                  value: s.levelManis,
                  onChanged: (v) => setState(() => s.levelManis = v),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.lightGray),
                const SizedBox(height: 16),

                DiscreteSlider(
                  label: 'Apakah makanan Anda berlemak?',
                  iconEmoji: '🥩',
                  stepLabels: const [
                    'Tidak berlemak',
                    'Sedikit berlemak',
                    'Cukup berlemak',
                    'Berlemak',
                    'Sangat berlemak',
                  ],
                  value: s.levelBerlemak,
                  onChanged: (v) => setState(() => s.levelBerlemak = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Toggle Ya/Tidak ───────────────────────────────────────────────
          SectionCard(
            child: Column(
              children: [
                ToggleYesNo(
                  label: 'Apakah Anda berbaring dalam waktu 2–3 jam setelah makan?',
                  value: s.berbaringSetelahMakan,
                  hasError: s.errBerbaring,
                  onChanged: (v) =>
                      setState(() => s.berbaringSetelahMakan = v),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.lightGray),
                const SizedBox(height: 16),

                ToggleYesNo(
                  label: 'Apakah Anda mengonsumsi minuman bersoda?',
                  value: s.konsumsiSoda,
                  hasError: s.errSoda,
                  onChanged: (v) => setState(() => s.konsumsiSoda = v),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.lightGray),
                const SizedBox(height: 16),

                ToggleYesNo(
                  label: 'Apakah Anda mengonsumsi kopi?',
                  value: s.konsumsiKopi,
                  hasError: s.errKopi,
                  onChanged: (v) => setState(() => s.konsumsiKopi = v),
                ),
              ],
            ),
          ),

          // ── Conditional: Slider Makan Malam ──────────────────────────────
          if (isMalam) ...[
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: [
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
                    onChanged: (v) =>
                        setState(() => s.bebanPikiran = v),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.lightGray),
                  const SizedBox(height: 16),
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
                    onChanged: (v) =>
                        setState(() => s.bebanAktivitas = v),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Tombol Simpan ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 2,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Simpan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/reflux_prediction_model.dart';
import '../../services/reflux_prediction_service.dart';
import '../../widgets/app_scaffold.dart';
import 'widgets/step_progress_bar.dart';
import 'widgets/discrete_level_slider.dart';
import 'widgets/diet_selection_card.dart';

class DiseasePredictionScreen extends StatefulWidget {
  const DiseasePredictionScreen({super.key});

  @override
  State<DiseasePredictionScreen> createState() =>
      _DiseasePredictionScreenState();
}

class _DiseasePredictionScreenState extends State<DiseasePredictionScreen> {
  int _currentStep = 1; // 1, 2, atau 3
  bool _isLoading = false;
  bool _hasShownCompletionNotification = false;

  // State kuesioner disimpan dalam DTO
  UserDietInput _dietInput = const UserDietInput();

  // Tracking pertanyaan yang sudah dijawab oleh user (untuk notifikasi konfirmasi)
  final Set<String> _touchedFields = {};

  /// Notifikasi hijau tampil saat SEMUA 10 pertanyaan slider/toggle sudah dijawab
  bool get _allAnswered {
    const required = {
      'fruitFrequency',
      'vegetableFrequency',
      'homecookedMealsFrequency',
      'oneLiterWaterFrequency',
      'redMeatFrequency',
      'highFatRedMeat',
      'saltedSnacksFrequency',
      'frozenDessertFrequency',
      'milkCheeseFrequency',
      'alcoholFrequency',
    };
    return required.every(_touchedFields.contains);
  }

  void _onFieldTouched(String field) {
    _touchedFields.add(field);
    if (_allAnswered && !_hasShownCompletionNotification) {
      _hasShownCompletionNotification = true;
      _showCompletionNotification();
    }
  }

  void _showCompletionNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF276F8F),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semua indikator telah terisi',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tekan "Analisis Sekarang" untuk memproses data.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE8F3F7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1C4E68),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 6,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _onBack() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onNext() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    }
  }

  Future<void> _submitAnalysis() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await RefluxPredictionService.predictReflux(_dietInput);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Pindah ke Result Screen
      Navigator.pushNamed(
        context,
        '/prediksi-penyakit/result',
        arguments: {
          'result': result,
          'dietInput': _dietInput,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kendala saat menganalisis: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBack();
      },
      child: AppScaffold(
        backgroundGradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFCFBF7),
            Color(0xFFF7F4EB),
            Color(0xFFF2EEDB),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ─── 1. Header Kuesioner (Back, Pill Kuning, Spacer) ───
              _buildHeader(),

              // ─── Stepper 3 Langkah ───
              StepProgressBar(currentStep: _currentStep),

              // ─── Label Langkah Aktif ───
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD4E5EE),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    _getStepLabel(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF276F8F),
                    ),
                  ),
                ),
              ),

              // ─── 2. Konten Langkah (Scrollable) ───
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      if (_currentStep == 1) _buildStep1(),
                      if (_currentStep == 2) _buildStep2(),
                      if (_currentStep == 3) _buildStep3(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ─── 3. Floating Bottom Action Button ───
              _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// Header dengan tombol back bulat dan badge pill kuning Catat Makanan
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tombol Back Lingkaran
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: _onBack,
              borderRadius: BorderRadius.circular(24),
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

          // Badge Pill Judul "Prediksi Penyakit" (Kuning Catat Makanan)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
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
              'Prediksi Penyakit',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C4E68),
                letterSpacing: 0.2,
              ),
            ),
          ),

          // Spacer kanan
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  String _getStepLabel() {
    switch (_currentStep) {
      case 1:
        return 'Langkah 1/3: Pola Makan Sehari-hari';
      case 2:
        return 'Langkah 2/3: Identifikasi Makanan Berisiko';
      case 3:
        return 'Langkah 3/3: Gaya Hidup & Minuman';
      default:
        return '';
    }
  }

  // =========================================================
  // LANGKAH 1: POLA MAKAN SEHARI-HARI
  // =========================================================
  Widget _buildStep1() {
    return Column(
      children: [
        // 1. Pilihan jenis pola makan (3 card sejajar)
        DietSelectionCard(
          selectedDiet: _dietInput.dietType,
          onSelected: (diet) {
            setState(() {
              _dietInput = _dietInput.copyWith(dietType: diet);
            });
            _onFieldTouched('dietType');
          },
        ),
        const SizedBox(height: 14),

        // 2. Slider Makan Buah
        DiscreteLevelSlider(
          imagePath: 'assets/images/buah.png',
          title: 'Seberapa sering makan buah segar?',
          subtitle: 'Frekuensi asupan buah dalam seminggu',
          value: _dietInput.fruitFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(fruitFrequency: val);
            });
            _onFieldTouched('fruitFrequency');
          },
        ),
        const SizedBox(height: 14),

        // 3. Slider Makan Sayur
        DiscreteLevelSlider(
          imagePath: 'assets/images/sayur.png',
          title: 'Seberapa sering makan sayur-mayur?',
          subtitle: 'Frekuensi asupan sayuran dalam seminggu',
          value: _dietInput.vegetableFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(vegetableFrequency: val);
            });
            _onFieldTouched('vegetableFrequency');
          },
        ),
        const SizedBox(height: 14),

        // 4. Slider Masak dan Makan di Rumah
        DiscreteLevelSlider(
          imagePath: 'assets/images/masak.png',
          title: 'Seberapa sering makan masakan rumah?',
          subtitle: 'Dibandingkan membeli makanan jadi / santap di luar',
          value: _dietInput.homecookedMealsFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(homecookedMealsFrequency: val);
            });
            _onFieldTouched('homecookedMealsFrequency');
          },
        ),
        const SizedBox(height: 14),

        // 5. Slider Minum Air > 1 Liter
        DiscreteLevelSlider(
          imagePath: 'assets/images/air.png',
          title: 'Seberapa sering minum air > 1 liter/hari?',
          subtitle: 'Rutinitas kecukupan cairan harian',
          value: _dietInput.oneLiterWaterFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(oneLiterWaterFrequency: val);
            });
            _onFieldTouched('oneLiterWaterFrequency');
          },
        ),
      ],
    );
  }

  // =========================================================
  // LANGKAH 2: MAKANAN BERISIKO
  // =========================================================
  Widget _buildStep2() {
    return Column(
      children: [
        // 1. Slider Daging Merah
        DiscreteLevelSlider(
          imagePath: 'assets/images/daging merah.png',
          title: 'Seberapa sering konsumsi daging merah?',
          subtitle: 'Sapi, kambing, olahan daging merah lainnya',
          value: _dietInput.redMeatFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(redMeatFrequency: val);
            });
            _onFieldTouched('redMeatFrequency');
          },
        ),
        const SizedBox(height: 14),

        // 2. Toggle Daging Tinggi Lemak (Tidak / Ya)
        _buildHighFatMeatToggle(),
        const SizedBox(height: 14),

        // 3. Slider Camilan Asin
        DiscreteLevelSlider(
          imagePath: 'assets/images/camilan asin.png',
          title: 'Seberapa sering makan camilan asin / gurih?',
          subtitle: 'Keripik, gorengan, kacang asin, snack olahan',
          value: _dietInput.saltedSnacksFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(saltedSnacksFrequency: val);
            });
            _onFieldTouched('saltedSnacksFrequency');
          },
        ),
        const SizedBox(height: 14),

        // 4. Slider Makanan Beku Manis
        DiscreteLevelSlider(
          imagePath: 'assets/images/beku manis.png',
          title: 'Seberapa sering makan makanan beku manis?',
          subtitle: 'Es krim, dessert beku, atau minuman manis dingin',
          value: _dietInput.frozenDessertFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(frozenDessertFrequency: val);
            });
            _onFieldTouched('frozenDessertFrequency');
          },
        ),
      ],
    );
  }

  Widget _buildHighFatMeatToggle() {
    final isYes = _dietInput.highFatRedMeat;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul dengan Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEBE3D0),
                    width: 1.0,
                  ),
                ),
                child: Image.asset(
                  'assets/images/daging tinggi lemak.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: Color(0xFF1C4E68),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sering Konsumsi Daging Berlemak Tinggi?',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C4E68),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Daging olahan seperti sosis, kornet, bacon, atau jeroan',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B8797),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2 Opsi Toggle: Tidak / Ya (Segmented Modern)
          Row(
            children: [
              Expanded(
                child: _buildToggleOption(
                  label: 'Tidak Sering',
                  icon: Icons.close_rounded,
                  isSelected: !isYes,
                  onTap: () {
                    setState(() {
                      _dietInput = _dietInput.copyWith(highFatRedMeat: false);
                    });
                    _onFieldTouched('highFatRedMeat');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToggleOption(
                  label: 'Ya, Cukup Sering',
                  icon: Icons.check_rounded,
                  isSelected: isYes,
                  onTap: () {
                    setState(() {
                      _dietInput = _dietInput.copyWith(highFatRedMeat: true);
                    });
                    _onFieldTouched('highFatRedMeat');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F6F9) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF276F8F) : const Color(0xFFEBE3D0),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF276F8F).withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF276F8F)
                  : const Color(0xFF9CB3C2),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF1C4E68)
                    : const Color(0xFF6B8797),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LANGKAH 3: HAMPIR SELESAI
  // =========================================================
  Widget _buildStep3() {
    return Column(
      children: [
        // 1. Slider Susu & Keju
        DiscreteLevelSlider(
          imagePath: 'assets/images/susu keju.png',
          title: 'Seberapa sering konsumsi susu & keju?',
          subtitle: 'Susu cair, keju, mentega, atau dairy product lainnya',
          value: _dietInput.milkCheeseFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(milkCheeseFrequency: val);
            });
            _onFieldTouched('milkCheeseFrequency');
          },
        ),
        const SizedBox(height: 14),

        // 2. Slider Konsumsi Alkohol
        DiscreteLevelSlider(
          imagePath: 'assets/images/alkohol.png',
          title: 'Seberapa sering konsumsi minuman beralkohol?',
          subtitle: 'Bir, anggur, atau minuman beralkohol jenis lainnya',
          value: _dietInput.alcoholFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(alcoholFrequency: val);
            });
            _onFieldTouched('alcoholFrequency');
          },
        ),
      ],
    );
  }

  // =========================================================
  // FLOATING BOTTOM ACTION BUTTON
  // =========================================================
  Widget _buildBottomActionBar() {
    final isLastStep = _currentStep == 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF276F8F),
                Color(0xFF1C4E68),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1C4E68).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : isLastStep
                    ? _submitAnalysis
                    : _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Memproses Model Prediksi...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastStep ? 'Analisis Risiko Sekarang' : 'Lanjut ke Langkah Selanjutnya',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLastStep ? Icons.analytics_rounded : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

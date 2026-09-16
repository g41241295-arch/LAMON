import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/reflux_prediction_model.dart';
import '../../services/reflux_prediction_service.dart';
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

  // State kuesioner disimpan dalam DTO
  UserDietInput _dietInput = const UserDietInput();

  // Tracking pertanyaan yang sudah dijawab oleh user (untuk banner konfirmasi)
  final Set<String> _touchedFields = {};

  /// Banner hijau tampil HANYA setelah semua 10 pertanyaan slider/toggle dijawab
  bool get _allAnswered {
    const required = {
      'fruitFrequency', 'vegetableFrequency',
      'homecookedMealsFrequency', 'oneLiterWaterFrequency',
      'redMeatFrequency', 'highFatRedMeat', 'saltedSnacksFrequency',
      'frozenDessertFrequency', 'milkCheeseFrequency', 'alcoholFrequency',
    };
    return required.every(_touchedFields.contains);
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
      child: Scaffold(
        backgroundColor: AppColors.desktopBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 520;
            final contentWidget = _buildScreenBody(context);

            if (isLargeScreen) {
              final maxH = constraints.maxHeight.isFinite
                  ? constraints.maxHeight.clamp(0.0, 920.0)
                  : 880.0;
              return Center(
                child: Container(
                  width: 420,
                  height: maxH,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.12),
                      width: 3,
                    ),
                  ),
                  child: contentWidget,
                ),
              );
            }

            return contentWidget;
          },
        ),
      ),
    );
  }

  Widget _buildScreenBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgGradientTop,
            AppColors.bgGradientMiddle,
            AppColors.bgGradientBottom,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // =========================================================
            // 1. HEADER KUESIONER
            // =========================================================
            _buildHeader(),

            // Stepper 3 langkah
            StepProgressBar(currentStep: _currentStep),

            // Label Langkah Aktif
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                _getStepLabel(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
            ),

            // =========================================================
            // 2. KONTEN LANGKAH KUESIONER (SCROLLABLE)
            // =========================================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    if (_currentStep == 1) _buildStep1(),
                    if (_currentStep == 2) _buildStep2(),
                    if (_currentStep == 3) _buildStep3(),
                    const SizedBox(height: 100), // Ruang untuk sticky button
                  ],
                ),
              ),
            ),

            // =========================================================
            // 3. STICKY BOTTOM ACTION BAR
            // =========================================================
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  /// Header dengan tombol back dan badge pill "Prediksi Penyakit"
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Back Lingkaran
          InkWell(
            onTap: _onBack,
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
          ),

          // Badge Pill Judul "Prediksi Penyakit"
          Container(
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
              'Prediksi Penyakit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
                letterSpacing: 0.2,
              ),
            ),
          ),

          // Spacer agar title tetap di tengah
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  String _getStepLabel() {
    switch (_currentStep) {
      case 1:
        return 'Langkah 1 — Pola makan sehari-hari';
      case 2:
        return 'Langkah 2 — Makanan Berisiko';
      case 3:
        return 'Langkah 3 — Hampir selesai';
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
              _touchedFields.add('dietType');
            });
          },
        ),
        const SizedBox(height: 14),

        // 2. Slider Makan Buah
        DiscreteLevelSlider(
          icon: Icons.spa_rounded,
          title: 'Seberapa sering makan buah?',
          subtitle: 'Dalam seminggu terakhir',
          value: _dietInput.fruitFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(fruitFrequency: val);
              _touchedFields.add('fruitFrequency');
            });
          },
        ),
        const SizedBox(height: 14),

        // 3. Slider Makan Sayur
        DiscreteLevelSlider(
          icon: Icons.eco_rounded,
          title: 'Seberapa sering makan sayur?',
          subtitle: 'Dalam seminggu terakhir',
          value: _dietInput.vegetableFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(vegetableFrequency: val);
              _touchedFields.add('vegetableFrequency');
            });
          },
        ),
        const SizedBox(height: 14),

        // 4. Slider Masak dan Makan di Rumah
        DiscreteLevelSlider(
          icon: Icons.home_rounded,
          title: 'Seberapa sering masak dan makan di rumah?',
          subtitle: 'Dibanding makan di luar/pesan makanan',
          value: _dietInput.homecookedMealsFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(homecookedMealsFrequency: val);
              _touchedFields.add('homecookedMealsFrequency');
            });
          },
        ),
        const SizedBox(height: 14),

        // 5. Slider Minum Air > 1 Liter
        DiscreteLevelSlider(
          icon: Icons.water_drop_rounded,
          title: 'Seberapa sering minum air >1 liter/hari?',
          subtitle: 'Kebiasaan minum air putih harian',
          value: _dietInput.oneLiterWaterFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(oneLiterWaterFrequency: val);
              _touchedFields.add('oneLiterWaterFrequency');
            });
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
          icon: Icons.kebab_dining_rounded,
          title: 'Seberapa sering makan daging merah?',
          subtitle: 'Sapi, kambing, domba, dll',
          value: _dietInput.redMeatFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(redMeatFrequency: val);
              _touchedFields.add('redMeatFrequency');
            });
          },
        ),
        const SizedBox(height: 14),

        // 2. Toggle Daging Tinggi Lemak (Tidak / Ya)
        _buildHighFatMeatToggle(),
        const SizedBox(height: 14),

        // 3. Slider Camilan Asin
        DiscreteLevelSlider(
          icon: Icons.cookie_outlined,
          title: 'Seberapa sering makan camilan asin?',
          subtitle: 'Kripik, kerupuk, kacang asin, gorengan, dll',
          value: _dietInput.saltedSnacksFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(saltedSnacksFrequency: val);
              _touchedFields.add('saltedSnacksFrequency');
            });
          },
        ),
        const SizedBox(height: 14),

        // 4. Slider Makanan Beku Manis
        DiscreteLevelSlider(
          icon: Icons.icecream_outlined,
          title: 'Seberapa sering makan makanan beku manis?',
          subtitle: 'Es krim, dessert dingin olahan',
          value: _dietInput.frozenDessertFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(frozenDessertFrequency: val);
              _touchedFields.add('frozenDessertFrequency');
            });
          },
        ),
      ],
    );
  }

  Widget _buildHighFatMeatToggle() {
    final isYes = _dietInput.highFatRedMeat;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul dengan Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.lunch_dining_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sering konsumsi daging tinggi lemak?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Daging olahan/berlemak seperti bacon, sosis, jeroan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.brownSubtext,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),

          // 2 Opsi Toggle: Tidak / Ya
          Row(
            children: [
              Expanded(
                child: _buildToggleOption(
                  label: 'Tidak',
                  isSelected: !isYes,
                  onTap: () {
                    setState(() {
                      _dietInput = _dietInput.copyWith(highFatRedMeat: false);
                      _touchedFields.add('highFatRedMeat');
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleOption(
                  label: 'Ya',
                  isSelected: isYes,
                  onTap: () {
                    setState(() {
                      _dietInput = _dietInput.copyWith(highFatRedMeat: true);
                      _touchedFields.add('highFatRedMeat');
                    });
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
          color: isSelected ? const Color(0xFFDCEDF7) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryDark : const Color(0xFF475569),
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
          icon: Icons.local_drink_rounded,
          title: 'Seberapa sering konsumsi susu & keju?',
          subtitle: 'Susu, keju, yoghurt, produk olahan susu lainnya',
          value: _dietInput.milkCheeseFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(milkCheeseFrequency: val);
              _touchedFields.add('milkCheeseFrequency');
            });
          },
        ),
        const SizedBox(height: 14),

        // 2. Slider Konsumsi Alkohol
        DiscreteLevelSlider(
          icon: Icons.local_bar_rounded,
          title: 'Seberapa sering konsumsi alkohol?',
          subtitle: 'Bir, anggur, minuman keras beralkohol lainnya',
          value: _dietInput.alcoholFrequency,
          onChanged: (val) {
            setState(() {
              _dietInput = _dietInput.copyWith(alcoholFrequency: val);
              _touchedFields.add('alcoholFrequency');
            });
          },
        ),
        const SizedBox(height: 20),

        // 3. Banner Konfirmasi Hijau — hanya tampil setelah SEMUA pertanyaan dijawab
        if (_allAnswered)
          Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF8EE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFBCE6C0),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon centang hijau bulat
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successGreen,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Teks Konfirmasi
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semua pertanyaan sudah terisi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E5D22),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tekan tombol di bawah untuk melihat hasil analisis risiko refluks asam lambungmu.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF388E3C),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // STICKY BOTTOM ACTION BAR
  // =========================================================
  Widget _buildBottomActionBar() {
    final isLastStep = _currentStep == 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : isLastStep
                  ? _submitAnalysis
                  : _onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const Row(
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
                      'Menganalisis dengan Machine Learning...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Text(
                  isLastStep ? 'Analisis Sekarang' : 'Lanjut',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

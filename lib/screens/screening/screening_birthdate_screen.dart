import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state.dart';
import 'screening_scaffold.dart';

class ScreeningBirthdateScreen extends StatefulWidget {
  const ScreeningBirthdateScreen({super.key});

  @override
  State<ScreeningBirthdateScreen> createState() => _ScreeningBirthdateScreenState();
}

class _ScreeningBirthdateScreenState extends State<ScreeningBirthdateScreen> {
  final TextEditingController _dayCtrl = TextEditingController();
  final TextEditingController _monthCtrl = TextEditingController();
  final TextEditingController _yearCtrl = TextEditingController();

  final FocusNode _dayFocus = FocusNode();
  final FocusNode _monthFocus = FocusNode();
  final FocusNode _yearFocus = FocusNode();

  String? _errorMessage;
  int? _calculatedAge;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = AppState.of(context);
      if (mounted) {
        if (appState.draftDay != null) _dayCtrl.text = appState.draftDay.toString().padLeft(2, '0');
        if (appState.draftMonth != null) _monthCtrl.text = appState.draftMonth.toString().padLeft(2, '0');
        if (appState.draftYear != null) _yearCtrl.text = appState.draftYear.toString();
        _updateAgePreview();
      }
    });

    _dayCtrl.addListener(() {
      if (_dayCtrl.text.length == 2) {
        FocusScope.of(context).requestFocus(_monthFocus);
      }
      _updateAgePreview();
    });

    _monthCtrl.addListener(() {
      if (_monthCtrl.text.length == 2) {
        FocusScope.of(context).requestFocus(_yearFocus);
      }
      if (_monthCtrl.text.isEmpty) {
        FocusScope.of(context).requestFocus(_dayFocus);
      }
      _updateAgePreview();
    });

    _yearCtrl.addListener(() {
      if (_yearCtrl.text.length == 4) {
        _yearFocus.unfocus();
        _saveDate();
      }
      if (_yearCtrl.text.isEmpty) {
        FocusScope.of(context).requestFocus(_monthFocus);
      }
      _updateAgePreview();
    });
  }

  void _updateAgePreview() {
    final day = int.tryParse(_dayCtrl.text);
    final month = int.tryParse(_monthCtrl.text);
    final year = int.tryParse(_yearCtrl.text);
    final now = DateTime.now();

    if (day != null && month != null && year != null && year > 1900 && year <= now.year && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
      try {
        final birthDate = DateTime(year, month, day);
        int age = now.year - birthDate.year;
        if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
          age--;
        }
        if (age >= 0 && age < 120) {
          setState(() {
            _calculatedAge = age;
            _errorMessage = null;
          });
          return;
        }
      } catch (_) {}
    }

    if (_calculatedAge != null) {
      setState(() {
        _calculatedAge = null;
      });
    }
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    _dayFocus.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  int _maxDaysInMonth(int month, int year) {
    if (month == 2) {
      final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    if ([4, 6, 9, 11].contains(month)) return 30;
    return 31;
  }

  bool _validate() {
    final day = int.tryParse(_dayCtrl.text);
    final month = int.tryParse(_monthCtrl.text);
    final year = int.tryParse(_yearCtrl.text);
    final currentYear = DateTime.now().year;

    if (day == null || day < 1 || day > 31) {
      setState(() => _errorMessage = 'Tanggal harus diisi antara 1–31.');
      return false;
    }
    if (month == null || month < 1 || month > 12) {
      setState(() => _errorMessage = 'Bulan harus diisi antara 1–12.');
      return false;
    }
    if (year == null || year < 1920 || year > currentYear) {
      setState(() => _errorMessage = 'Tahun harus antara 1920–$currentYear.');
      return false;
    }
    final maxDays = _maxDaysInMonth(month, year);
    if (day > maxDays) {
      setState(() => _errorMessage = 'Tanggal $day tidak valid untuk bulan $month/$year.');
      return false;
    }
    setState(() => _errorMessage = null);
    return true;
  }

  void _saveDate() {
    final day = int.tryParse(_dayCtrl.text);
    final month = int.tryParse(_monthCtrl.text);
    final year = int.tryParse(_yearCtrl.text);
    if (day != null && month != null && year != null) {
      AppState.of(context).setDraftBirthDate(day: day, month: month, year: year);
    }
  }

  void _onNext() {
    if (!_validate()) return;
    _saveDate();
    Navigator.pushReplacementNamed(context, '/screening/history');
  }

  Future<void> _pickDateFromPicker() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 20, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF276F8F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C4E68),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _dayCtrl.text = picked.day.toString().padLeft(2, '0');
      _monthCtrl.text = picked.month.toString().padLeft(2, '0');
      _yearCtrl.text = picked.year.toString();
      _saveDate();
      _updateAgePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasInputs = _dayCtrl.text.isNotEmpty && _monthCtrl.text.isNotEmpty && _yearCtrl.text.length == 4;

    return ScreeningScaffold(
      currentStep: 2,
      totalSteps: 3,
      title: 'Kapan tanggal lahir Anda?',
      isButtonEnabled: hasInputs,
      onNext: _onNext,
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Calendar Icon Circle
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF276F8F).withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF276F8F).withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 34,
                color: Color(0xFF276F8F),
              ),
            ),

            const SizedBox(height: 24),

            // Tiga Input Box: Tanggal, Bulan, Tahun
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildInputBox(
                    label: 'TANGGAL',
                    hint: 'HH',
                    controller: _dayCtrl,
                    focusNode: _dayFocus,
                    maxLength: 2,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _buildInputBox(
                    label: 'BULAN',
                    hint: 'BB',
                    controller: _monthCtrl,
                    focusNode: _monthFocus,
                    maxLength: 2,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: _buildInputBox(
                    label: 'TAHUN',
                    hint: 'TTTT',
                    controller: _yearCtrl,
                    focusNode: _yearFocus,
                    maxLength: 4,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Indikator Usia Terhitung
            if (_calculatedAge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7D6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8D7A5), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cake_rounded, size: 16, color: Color(0xFFB8630A)),
                    const SizedBox(width: 8),
                    Text(
                      'Usia Anda: $_calculatedAge Tahun',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C4E68),
                      ),
                    ),
                  ],
                ),
              ),

            // Pesan Error
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Tombol Pintasan Pilih dari Kalender
            TextButton.icon(
              onPressed: _pickDateFromPicker,
              icon: const Icon(Icons.event_note_rounded, size: 18, color: Color(0xFF276F8F)),
              label: Text(
                'Buka Kalender Pemilih',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF276F8F),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required int maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF7A8B99),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focusNode.hasFocus ? const Color(0xFF276F8F) : const Color(0xFFCBD5E1),
              width: focusNode.hasFocus ? 1.8 : 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            maxLength: maxLength,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C4E68),
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

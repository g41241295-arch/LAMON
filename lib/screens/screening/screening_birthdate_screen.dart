import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = AppState.of(context);
      if (mounted) {
        _dayCtrl.text = appState.draftDay.toString().padLeft(2, '0');
        _monthCtrl.text = appState.draftMonth.toString().padLeft(2, '0');
        _yearCtrl.text = appState.draftYear.toString();
      }
    });

    _dayCtrl.addListener(() {
      if (_dayCtrl.text.length == 2) {
        FocusScope.of(context).requestFocus(_monthFocus);
      }
    });

    _monthCtrl.addListener(() {
      if (_monthCtrl.text.length == 2) {
        FocusScope.of(context).requestFocus(_yearFocus);
      }
      if (_monthCtrl.text.isEmpty) {
        FocusScope.of(context).requestFocus(_dayFocus);
      }
    });

    _yearCtrl.addListener(() {
      if (_yearCtrl.text.length == 4) {
        _yearFocus.unfocus();
        _saveDate();
      }
      if (_yearCtrl.text.isEmpty) {
        FocusScope.of(context).requestFocus(_monthFocus);
      }
    });
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
      setState(() => _errorMessage = 'Tanggal harus antara 1–31.');
      return false;
    }
    if (month == null || month < 1 || month > 12) {
      setState(() => _errorMessage = 'Bulan harus antara 1–12.');
      return false;
    }
    if (year == null || year < 1900 || year > currentYear) {
      setState(() => _errorMessage = 'Tahun harus antara 1900–$currentYear.');
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
    Navigator.pushNamed(context, '/screening/history');
  }

  @override
  Widget build(BuildContext context) {
    return ScreeningScaffold(
      title: 'Kapan Tanggal Lahir Anda?',
      isButtonEnabled: true,
      onNext: _onNext,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: _buildInputBox(
                label: 'Tanggal',
                controller: _dayCtrl,
                focusNode: _dayFocus,
                maxLength: 2,
                hint: 'HH',
              )),
              const SizedBox(width: 10),
              Flexible(child: _buildInputBox(
                label: 'Bulan',
                controller: _monthCtrl,
                focusNode: _monthFocus,
                maxLength: 2,
                hint: 'BB',
              )),
              const SizedBox(width: 10),
              Flexible(child: _buildInputBox(
                label: 'Tahun',
                controller: _yearCtrl,
                focusNode: _yearFocus,
                maxLength: 4,
                hint: 'TTTT',
              )),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBox({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required int maxLength,
    required String hint,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: maxLength,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFFCBD5E1),
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onChanged: (_) => setState(() => _errorMessage = null),
          ),
        ),
      ],
    );
  }
}

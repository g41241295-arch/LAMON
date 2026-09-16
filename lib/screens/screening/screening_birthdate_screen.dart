import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import 'screening_scaffold.dart';

class ScreeningBirthdateScreen extends StatefulWidget {
  const ScreeningBirthdateScreen({super.key});

  @override
  State<ScreeningBirthdateScreen> createState() => _ScreeningBirthdateScreenState();
}

class _ScreeningBirthdateScreenState extends State<ScreeningBirthdateScreen> {
  int _day = 1;
  int _month = 1;
  int _year = 1990;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = AppState.of(context);
      if (mounted) {
        setState(() {
          _day = appState.draftDay;
          _month = appState.draftMonth;
          _year = appState.draftYear;
        });
      }
    });
  }

  int _maxDaysInMonth(int month, int year) {
    if (month == 2) {
      final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    if ([4, 6, 9, 11].contains(month)) return 30;
    return 31;
  }

  void _updateDate({int? day, int? month, int? year}) {
    setState(() {
      if (year != null) _year = year.clamp(1920, DateTime.now().year);
      if (month != null) _month = month.clamp(1, 12);

      final maxDays = _maxDaysInMonth(_month, _year);
      if (day != null) {
        _day = day.clamp(1, maxDays);
      } else if (_day > maxDays) {
        _day = maxDays;
      }
    });

    AppState.of(context).setDraftBirthDate(
      day: _day,
      month: _month,
      year: _year,
    );
  }

  void _onNext() {
    Navigator.pushNamed(context, '/screening/history');
  }

  @override
  Widget build(BuildContext context) {
    return ScreeningScaffold(
      title: 'Kapan Tanggal Lahir Anda?',
      isButtonEnabled: true,
      onNext: _onNext,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Picker Tanggal
          Flexible(
            child: _buildPickerColumn(
              label: 'Tanggal',
              valueText: _day.toString().padLeft(2, '0'),
              onPrev: () => _updateDate(day: _day - 1),
              onNext: () => _updateDate(day: _day + 1),
            ),
          ),
          const SizedBox(width: 10),

          // Picker Bulan
          Flexible(
            child: _buildPickerColumn(
              label: 'Bulan',
              valueText: _month.toString().padLeft(2, '0'),
              onPrev: () => _updateDate(month: _month - 1),
              onNext: () => _updateDate(month: _month + 1),
            ),
          ),
          const SizedBox(width: 10),

          // Picker Tahun
          Flexible(
            child: _buildPickerColumn(
              label: 'Tahun',
              valueText: _year.toString(),
              onPrev: () => _updateDate(year: _year - 1),
              onNext: () => _updateDate(year: _year + 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerColumn({
    required String label,
    required String valueText,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Label atas (Tanggal / Bulan / Tahun)
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),

        // Kotak Picker: < Nilai >
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Panah Kiri (<)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPrev,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),

              // Teks Nilai
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),

              // Panah Kanan (>)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onNext,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

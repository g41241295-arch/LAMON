import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import 'screening_scaffold.dart';
import 'widgets/screening_avatars.dart';

class ScreeningGenderScreen extends StatefulWidget {
  const ScreeningGenderScreen({super.key});

  @override
  State<ScreeningGenderScreen> createState() => _ScreeningGenderScreenState();
}

class _ScreeningGenderScreenState extends State<ScreeningGenderScreen> {
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = AppState.of(context);
      if (appState.draftGender != null && mounted) {
        setState(() {
          _selectedGender = appState.draftGender;
        });
      }
    });
  }

  void _onSelect(String gender) {
    setState(() {
      _selectedGender = gender;
    });
    AppState.of(context).setDraftGender(gender);
  }

  void _onNext() {
    if (_selectedGender == null) return;
    Navigator.pushNamed(context, '/screening/birthdate');
  }

  @override
  Widget build(BuildContext context) {
    return ScreeningScaffold(
      title: 'Apa jenis kelamin Anda?',
      isButtonEnabled: _selectedGender != null,
      onNext: _onNext,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionCard(
            label: 'Pria',
            avatar: const BoyAvatar(size: 42),
            isSelected: _selectedGender == 'Pria',
            onTap: () => _onSelect('Pria'),
          ),
          const SizedBox(height: 18),
          _buildOptionCard(
            label: 'Wanita',
            avatar: const GirlAvatar(size: 42),
            isSelected: _selectedGender == 'Wanita',
            onTap: () => _onSelect('Wanita'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String label,
    required Widget avatar,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCEDF7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B95AF) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF276F8F).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF153E54) : const Color(0xFF334155),
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF276F8F),
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              )
            else
              const SizedBox(width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    Navigator.pushReplacementNamed(context, '/screening/birthdate');
  }

  @override
  Widget build(BuildContext context) {
    return ScreeningScaffold(
      currentStep: 1,
      totalSteps: 3,
      title: 'Apa jenis kelamin Anda?',
      isButtonEnabled: _selectedGender != null,
      onNext: _onNext,
      content: Column(
        children: [
          _buildOptionCard(
            label: 'Laki-laki',
            subLabel: 'Profil fisiologi pria',
            avatarContainerColor: const Color(0xFFEBF3FA),
            avatarBorderColor: const Color(0xFFBED8ED),
            avatar: const BoyAvatar(size: 48),
            isSelected: _selectedGender == 'Pria' || _selectedGender == 'Laki-laki',
            onTap: () => _onSelect('Laki-laki'),
          ),

          const SizedBox(height: 16),

          _buildOptionCard(
            label: 'Perempuan',
            subLabel: 'Profil fisiologi wanita',
            avatarContainerColor: const Color(0xFFFDE8E8),
            avatarBorderColor: const Color(0xFFF7C2C2),
            avatar: const GirlAvatar(size: 48),
            isSelected: _selectedGender == 'Wanita' || _selectedGender == 'Perempuan',
            onTap: () => _onSelect('Perempuan'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String label,
    required String subLabel,
    required Color avatarContainerColor,
    required Color avatarBorderColor,
    required Widget avatar,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF4F8) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF276F8F) : const Color(0xFFEBE3D0),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF276F8F).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar Badge
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: avatarContainerColor,
                shape: BoxShape.circle,
                border: Border.all(color: avatarBorderColor, width: 1.2),
              ),
              child: Center(child: avatar),
            ),

            const SizedBox(width: 16),

            // Teks Label & SubLabel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: const Color(0xFF1C4E68),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5A7184),
                    ),
                  ),
                ],
              ),
            ),

            // Indikator Radio / Centang
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF276F8F) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF276F8F) : const Color(0xFFCBD5E1),
                  width: isSelected ? 0 : 2.0,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state.dart';
import 'screening_scaffold.dart';
import 'widgets/screening_avatars.dart';

class ScreeningHistoryScreen extends StatefulWidget {
  const ScreeningHistoryScreen({super.key});

  @override
  State<ScreeningHistoryScreen> createState() => _ScreeningHistoryScreenState();
}

class _ScreeningHistoryScreenState extends State<ScreeningHistoryScreen> {
  bool? _hasHistory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = AppState.of(context);
      if (appState.draftHasHistory != null && mounted) {
        setState(() {
          _hasHistory = appState.draftHasHistory;
        });
      }
    });
  }

  void _onSelect(bool value) {
    setState(() {
      _hasHistory = value;
    });
    AppState.of(context).setDraftHasHistory(value);
  }

  void _onNext() async {
    if (_hasHistory == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final appState = AppState.of(context);
    final saved = await appState.completeScreening();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Koneksi internet bermasalah. Data tersimpan lokal & akan disinkronkan otomatis.',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    Navigator.pushReplacementNamed(context, '/screening/success');
  }

  @override
  Widget build(BuildContext context) {
    return ScreeningScaffold(
      currentStep: 3,
      totalSteps: 3,
      title: 'Apakah Anda punya riwayat penyakit lambung?',
      buttonText: 'Selesaikan Skrining',
      isButtonEnabled: _hasHistory != null,
      isLoading: _isLoading,
      onNext: _onNext,
      content: Column(
        children: [
          _buildOptionCard(
            label: 'Ya, Memiliki Riwayat',
            subLabel: 'Pernah didiagnosis Maag, GERD, atau sering mengeluhkan nyeri ulu hati',
            avatarContainerColor: const Color(0xFFFEF3C7),
            avatarBorderColor: const Color(0xFFFDE68A),
            avatar: const DoctorAvatar(size: 48),
            isSelected: _hasHistory == true,
            onTap: () => _onSelect(true),
          ),

          const SizedBox(height: 16),

          _buildOptionCard(
            label: 'Tidak Ada Riwayat',
            subLabel: 'Kondisi lambung prima, tidak pernah ada keluhan penyakit lambung sebelumnya',
            avatarContainerColor: const Color(0xFFD1FAE5),
            avatarBorderColor: const Color(0xFFA7F3D0),
            avatar: const PersonAvatar(size: 48),
            isSelected: _hasHistory == false,
            onTap: () => _onSelect(false),
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
                      fontSize: 15.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: const Color(0xFF1C4E68),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5A7184),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

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

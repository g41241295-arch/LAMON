import 'package:flutter/material.dart';
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
    if (_hasHistory == null) return;
    final appState = AppState.of(context);

    // Tampilkan loading sebelum Firestore selesai
    final saved = await appState.completeScreening();

    if (!mounted) return;

    if (!saved) {
      // Simpan ke Firestore gagal — beri tahu user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal menyimpan data. Periksa koneksi internet Anda dan coba lagi.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
      // Tetap navigasi ke success page karena data sudah tersimpan secara lokal,
      // namun user sudah diberitahu bahwa sinkronisasi cloud gagal
    }

    Navigator.pushNamed(context, '/screening/success');
  }

  @override
  Widget build(BuildContext context) {
    return ScreeningScaffold(
      title: 'Apakah Anda punya riwayat\npenyakit lambung?',
      isButtonEnabled: _hasHistory != null,
      onNext: _onNext,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionCard(
            label: 'Iya',
            avatar: const DoctorAvatar(size: 42),
            isSelected: _hasHistory == true,
            onTap: () => _onSelect(true),
          ),
          const SizedBox(height: 18),
          _buildOptionCard(
            label: 'Tidak',
            avatar: const PersonAvatar(size: 42),
            isSelected: _hasHistory == false,
            onTap: () => _onSelect(false),
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

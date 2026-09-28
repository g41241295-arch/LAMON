import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/practice_slot_constants.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_date_formatter.dart';

/// Layar Pilih Jam Praktik Dokter untuk suatu tanggal.
class PilihJamPraktikScreen extends StatefulWidget {
  final String doctorId;
  final DateTime date;
  final List<String> initialSlots;

  const PilihJamPraktikScreen({
    super.key,
    required this.doctorId,
    required this.date,
    required this.initialSlots,
  });

  @override
  State<PilihJamPraktikScreen> createState() => _PilihJamPraktikScreenState();
}

class _PilihJamPraktikScreenState extends State<PilihJamPraktikScreen> {
  final DoctorService _doctorService = DoctorService();
  late final Set<String> _selectedSlots;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSlots = Set<String>.from(widget.initialSlots);
  }

  void _toggleSlot(String slotId) {
    setState(() {
      if (_selectedSlots.contains(slotId)) {
        _selectedSlots.remove(slotId);
      } else {
        _selectedSlots.add(slotId);
      }
    });
  }

  Future<void> _handleSave() async {
    final dateKey = AppDateFormatter.formatDateKey(widget.date);

    // Jika tidak ada slot dipilih, konfirmasi apakah ini hari libur
    if (_selectedSlots.isEmpty) {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Jadikan Hari Libur?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: const Text(
            'Tidak ada slot praktik yang dipilih. Jadwal untuk tanggal ini akan dihapus dan ditandai sebagai hari libur.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Simpan Libur'),
            ),
          ],
        ),
      );

      if (shouldDelete != true) return;
    }

    setState(() => _isLoading = true);
    try {
      await _doctorService.saveSchedule(
        doctorId: widget.doctorId,
        dateKey: dateKey,
        date: widget.date,
        slotIds: _selectedSlots.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedSlots.isEmpty
                  ? 'Jadwal dihapus (hari libur).'
                  : 'Jadwal praktik berhasil disimpan.',
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan jadwal: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = AppDateFormatter.formatLongDate(widget.date);

    return Scaffold(
      backgroundColor: AppColors.bgGradientTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali',
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Bagian Atas (Header Kuning) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih jam praktik untuk tanggal ini',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.summaryCardSubtext,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Panel Bawah Gradasi Biru Bulat ──
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE2F0F9),
                      Color(0xFFB8DBEE),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Slot Waktu Tersedia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Daftar 3 Slot Kartu
                      Expanded(
                        child: ListView.separated(
                          itemCount: PracticeSlotConstants.allSlots.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final slot = PracticeSlotConstants.allSlots[index];
                            final isSelected = _selectedSlots.contains(slot.id);
                            return _buildSlotCard(slot, isSelected);
                          },
                        ),
                      ),

                      // ── Tombol Batal & Simpan ──
                      SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            // Tombol Batal
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryText,
                                  side: const BorderSide(
                                    color: AppColors.inputBorder,
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Tombol Simpan
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFACC15), // Kuning
                                  foregroundColor: const Color(0xFF713F12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF713F12)),
                                        ),
                                      )
                                    : const Text(
                                        'Simpan',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotCard(PracticeSlot slot, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleSlot(slot.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Kotak Ikon Biru Rounded
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(slot.icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),

            // Judul & Rentang Jam
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    slot.timeRangeDisplay,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.summaryCardSubtext,
                    ),
                  ),
                ],
              ),
            ),

            // Centang status terpilih
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.inputBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

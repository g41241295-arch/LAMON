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

  // State untuk Slot Kustom "Lainnya"
  bool _isCustomSelected = false;
  String? _customStartTime;
  String? _customEndTime;

  @override
  void initState() {
    super.initState();
    _selectedSlots = <String>{};

    for (final raw in widget.initialSlots) {
      if (raw == 'pagi' || raw == 'siang' || raw == 'malam') {
        _selectedSlots.add(raw);
      } else if (raw.startsWith('custom') || raw.contains('.')) {
        // Inisialisasi slot kustom dari data jadwal yang tersimpan
        final parsed = PracticeSlot.fromDynamic(raw);
        if (parsed.startTime.isNotEmpty && parsed.endTime.isNotEmpty) {
          _customStartTime = parsed.startTime;
          _customEndTime = parsed.endTime;
          _isCustomSelected = true;
        }
      }
    }
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

  TimeOfDay _parseTimeOfDay(String str, {TimeOfDay fallback = const TimeOfDay(hour: 8, minute: 0)}) {
    try {
      final parts = str.replaceAll(':', '.').split('.');
      if (parts.length >= 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}
    return fallback;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  Future<void> _pickCustomTimeRange() async {
    final initialStart = _customStartTime != null
        ? _parseTimeOfDay(_customStartTime!)
        : const TimeOfDay(hour: 8, minute: 0);

    final pickedStart = await showTimePicker(
      context: context,
      initialTime: initialStart,
      helpText: 'PILIH JAM MULAI PRAKTIK',
      confirmText: 'LANJUT',
      cancelText: 'BATAL',
    );
    if (pickedStart == null) return;

    if (!mounted) return;

    final initialEnd = _customEndTime != null
        ? _parseTimeOfDay(_customEndTime!)
        : TimeOfDay(hour: (pickedStart.hour + 2) % 24, minute: pickedStart.minute);

    final pickedEnd = await showTimePicker(
      context: context,
      initialTime: initialEnd,
      helpText: 'PILIH JAM SELESAI PRAKTIK',
      confirmText: 'SIMPAN JAM',
      cancelText: 'BATAL',
    );
    if (pickedEnd == null) return;

    final startMinutes = pickedStart.hour * 60 + pickedStart.minute;
    final endMinutes = pickedEnd.hour * 60 + pickedEnd.minute;

    if (endMinutes <= startMinutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jam selesai harus setelah jam mulai.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _customStartTime = _formatTimeOfDay(pickedStart);
      _customEndTime = _formatTimeOfDay(pickedEnd);
      _isCustomSelected = true;
    });
  }

  Future<void> _handleSave() async {
    final dateKey = AppDateFormatter.formatDateKey(widget.date);

    // Kumpulkan seluruh slot yang dipilih
    final slotsToSave = <dynamic>[];
    for (final s in _selectedSlots) {
      if (s == 'pagi' || s == 'siang' || s == 'malam') {
        slotsToSave.add(s);
      }
    }

    if (_isCustomSelected &&
        _customStartTime != null &&
        _customEndTime != null &&
        _customStartTime!.isNotEmpty &&
        _customEndTime!.isNotEmpty) {
      final customId = 'custom_${_customStartTime}_$_customEndTime';
      slotsToSave.add({
        'id': customId,
        'label': 'Lainnya',
        'startTime': _customStartTime!,
        'endTime': _customEndTime!,
        'isCustom': true,
      });
    }

    // Jika tidak ada slot dipilih, konfirmasi apakah ini hari libur
    if (slotsToSave.isEmpty) {
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
        slotIds: slotsToSave,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              slotsToSave.isEmpty
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
      backgroundColor: AppColors.bgGradientMiddle,
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
            // ── Bagian Atas (Header Tanggal) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.12),
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
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Pilih jam praktik untuk tanggal ini',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.summaryCardSubtext,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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

                      // Daftar 4 Slot Kartu (3 Tetap + 1 Lainnya)
                      Expanded(
                        child: ListView(
                          children: [
                            ...PracticeSlotConstants.allSlots.map((slot) {
                              final isSelected = _selectedSlots.contains(slot.id);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildSlotCard(slot, isSelected),
                              );
                            }),
                            _buildCustomSlotCard(),
                            const SizedBox(height: 14),
                          ],
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
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  disabledForegroundColor: Colors.white70,
                                  elevation: 1,
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
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Simpan',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
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
          color: AppColors.cardBackground,
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

  /// Kartu ke-4: "Lainnya" (Jam Praktik Kustom)
  Widget _buildCustomSlotCard() {
    final hasCustomTime = _customStartTime != null && _customEndTime != null;
    final timeDisplay = hasCustomTime
        ? '$_customStartTime - $_customEndTime WIB'
        : 'Atur jam praktik kustom sendiri';

    return GestureDetector(
      onTap: () {
        if (!_isCustomSelected || !hasCustomTime) {
          _pickCustomTimeRange();
        } else {
          // Jika sudah terpilih dan diketuk, buka picker untuk mengubah jam
          _pickCustomTimeRange();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isCustomSelected ? AppColors.primary : Colors.transparent,
            width: _isCustomSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isCustomSelected
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
              child: const Icon(Icons.more_time_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),

            // Judul & Rentang Jam
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Lainnya',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      if (hasCustomTime && _isCustomSelected) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _pickCustomTimeRange,
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeDisplay,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: hasCustomTime && _isCustomSelected
                          ? AppColors.primary
                          : AppColors.summaryCardSubtext,
                    ),
                  ),
                ],
              ),
            ),

            // Centang status terpilih
            GestureDetector(
              onTap: () {
                if (!hasCustomTime) {
                  _pickCustomTimeRange();
                } else {
                  setState(() => _isCustomSelected = !_isCustomSelected);
                }
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isCustomSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: _isCustomSelected
                        ? AppColors.primary
                        : AppColors.inputBorder,
                    width: 2,
                  ),
                ),
                child: _isCustomSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

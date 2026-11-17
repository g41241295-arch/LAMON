import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/doctor_theme.dart';
import '../../constants/practice_slot_constants.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_date_formatter.dart';
import '../../widgets/app_header_pill.dart';

/// Layar Pilih Jam Praktik Dokter untuk suatu tanggal.
/// Menggunakan Design System Formal LAMON (Warm Off-White + Deep Teal).
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: DoctorTheme.primary,
              onPrimary: Colors.white,
              onSurface: DoctorTheme.primaryText,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: DoctorTheme.primary,
              onPrimary: Colors.white,
              onSurface: DoctorTheme.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedEnd == null) return;

    final startMinutes = pickedStart.hour * 60 + pickedStart.minute;
    final endMinutes = pickedEnd.hour * 60 + pickedEnd.minute;

    if (endMinutes <= startMinutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jam selesai harus setelah jam mulai.'),
            backgroundColor: DoctorTheme.alertRed,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Jadikan Hari Libur?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: DoctorTheme.primaryText,
            ),
          ),
          content: Text(
            'Tidak ada slot praktik yang dipilih. Jadwal untuk tanggal ini akan dihapus dan ditandai sebagai hari libur.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: DoctorTheme.secondaryText,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  color: DoctorTheme.neutralGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: DoctorTheme.primaryButtonStyle(borderRadius: 12),
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
            backgroundColor: DoctorTheme.successGreen,
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
            backgroundColor: DoctorTheme.alertRed,
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

    return DoctorBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Header Pill ──
              AppHeaderPill(
                title: 'Atur Jam Praktik',
                onBack: () => Navigator.pop(context),
              ),

              // ── Info Tanggal ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: DoctorTheme.cardBorder,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: DoctorTheme.primary,
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
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: DoctorTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tentukan slot praktik untuk tanggal ini',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: DoctorTheme.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Panel Bawah Bersih Formal (Card Putih Rounded) ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilihan Slot Waktu',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: DoctorTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Daftar 4 Slot Kartu (3 Tetap + 1 Kustom Lainnya)
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              ...PracticeSlotConstants.allSlots.map((slot) {
                                final isSelected = _selectedSlots.contains(slot.id);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
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
                                  style: DoctorTheme.secondaryButtonStyle(borderRadius: 16),
                                  child: const Text('Batal'),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Tombol Simpan
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSave,
                                  style: DoctorTheme.primaryButtonStyle(borderRadius: 16),
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
                                      : const Text('Simpan'),
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
      ),
    );
  }

  Widget _buildSlotCard(PracticeSlot slot, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleSlot(slot.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? DoctorTheme.primary.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? DoctorTheme.primary : DoctorTheme.cardBorder,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? DoctorTheme.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                color: DoctorTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(slot.icon, color: DoctorTheme.primary, size: 22),
            ),
            const SizedBox(width: 14),

            // Judul & Rentang Jam
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: DoctorTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    slot.timeRangeDisplay,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: DoctorTheme.secondaryText,
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
                color: isSelected ? DoctorTheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? DoctorTheme.primary : DoctorTheme.cardBorder,
                  width: 1.8,
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
          _pickCustomTimeRange();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isCustomSelected ? DoctorTheme.primary.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isCustomSelected ? DoctorTheme.primary : DoctorTheme.cardBorder,
            width: _isCustomSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isCustomSelected
                  ? DoctorTheme.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                color: DoctorTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.more_time_rounded,
                  color: DoctorTheme.primary, size: 22),
            ),
            const SizedBox(width: 14),

            // Judul & Rentang Jam
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Lainnya',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DoctorTheme.primaryText,
                        ),
                      ),
                      if (hasCustomTime && _isCustomSelected) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _pickCustomTimeRange,
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: DoctorTheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeDisplay,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: hasCustomTime && _isCustomSelected
                          ? DoctorTheme.primary
                          : DoctorTheme.secondaryText,
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
                  color: _isCustomSelected ? DoctorTheme.primary : Colors.transparent,
                  border: Border.all(
                    color: _isCustomSelected
                        ? DoctorTheme.primary
                        : DoctorTheme.cardBorder,
                    width: 1.8,
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

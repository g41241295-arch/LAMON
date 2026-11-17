import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../debug/alarm_debug.dart';
import '../models/meal_reminder_plan.dart';
import '../services/meal_reminder_service.dart';
import '../widgets/meal_time_bottom_sheet.dart';
import '../../widgets/app_scaffold.dart';

/// Layar 3: Pengaturan Jam Makan dan Jam Tidur
class AturJamMakanScreen extends StatefulWidget {
  final MealCondition condition;
  final DateTime startDate;
  final DateTime endDate;

  const AturJamMakanScreen({
    super.key,
    required this.condition,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<AturJamMakanScreen> createState() => _AturJamMakanScreenState();
}

class _AturJamMakanScreenState extends State<AturJamMakanScreen> {
  // Pilihan tetap jam makan (dengan default sesuai spek)
  MealTimeOption _sarapan = MealPresetOptions.sarapanOptions.first;
  MealTimeOption _makanSiang = MealPresetOptions.makanSiangOptions.first;
  MealTimeOption _makanMalam = MealPresetOptions.makanMalamOptions.first;

  // Khusus kondisi sakit: Jam tidur default 20.00
  int _sleepHour = 20;

  // Khusus kondisi sehat: "Atur untuk hari berikutnya" (1 - 30 hari)
  bool _isRepeatEnabled = false;
  int _repeatDays = 1;

  bool _isLoading = false;

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String _formatSingleDate(DateTime d) {
    return '${d.day} ${_monthNames[d.month - 1]} ${d.year}';
  }

  String get _datePillText {
    if (widget.condition == MealCondition.sehat) {
      return _formatSingleDate(widget.startDate);
    } else {
      final startStr = _formatSingleDate(widget.startDate);
      final endStr = _formatSingleDate(widget.endDate);
      if (startStr == endStr) {
        return startStr;
      }
      return '$startStr s/d $endStr';
    }
  }

  DateTime get _effectiveEndDate {
    if (widget.condition == MealCondition.sehat) {
      if (_isRepeatEnabled && _repeatDays > 1) {
        return widget.startDate.add(Duration(days: _repeatDays - 1));
      }
      return widget.startDate;
    } else {
      return widget.endDate;
    }
  }

  Future<void> _onSelesaiPressed() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetStart =
        DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day);

    // 1. Validasi tanggal mulai belum lewat
    if (targetStart.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal mulai sudah lewat, silakan pilih ulang.'),
        ),
      );
      return;
    }

    // 2. Cek apakah sudah ada jadwal yang tersimpan pada tanggal ini
    final hasExisting =
        await MealReminderService.instance.hasExistingScheduleOn(targetStart);

    if (hasExisting && mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFEFDF8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Ganti Jadwal?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            content: Text(
              'Ganti jadwal yang sudah ada pada tanggal ini?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF334155),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF276F8F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Ganti',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final plan = MealReminderPlan(
        condition: widget.condition,
        startDate: targetStart,
        endDate: _effectiveEndDate,
        repeatDays: _isRepeatEnabled ? _repeatDays : 1,
        isRepeatEnabled: _isRepeatEnabled,
        sarapan: _sarapan,
        makanSiang: _makanSiang,
        makanMalam: _makanMalam,
        sleepHour: _sleepHour,
        enabled: true,
        updatedAt: DateTime.now(),
      );

      await MealReminderService.instance.savePlan(plan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal jam makan berhasil disimpan.'),
            backgroundColor: Color(0xFF276F8F),
          ),
        );
        // Kembali ke menu dengan nilai true (trigger reload di Beranda)
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan jadwal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHealthy = widget.condition == MealCondition.sehat;

    return AppScaffold(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFCFBF7),
          Color(0xFFF7F4EB),
          Color(0xFFF2EEDB),
        ],
      ),
      body: Stack(
        children: [
          // 1. Konten Utama (Scrollable)
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Header: Tombol Back (Kiri), Pill "Jadwal Harian" (Tengah), & Ikon Alarm (Kanan)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Tombol Kembali di Kiri
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEBE3D0),
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
                              Icons.arrow_back_rounded,
                              color: Color(0xFF1C4E68),
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      // Pill Judul di Tengah
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7D6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE8D7A5),
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
                        child: Text(
                          'Jadwal Harian',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C4E68),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),

                      // Ikon Alarm Minimalis & Profesional di Kanan Atas Header
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => showScheduledAlarmsDialog(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEBE3D0),
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
                              Icons.alarm_rounded,
                              color: Color(0xFF1C4E68),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pill Tanggal (Dipertahankan bentuk, posisi, & format sesuai ketentuan)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEBE3D0),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: Color(0xFF276F8F),
                          ),
                          const SizedBox(width: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _datePillText,
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1C4E68),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Judul Bagian: "Atur Jam Makan"
                  Text(
                    'Atur Jam Makan',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C4E68),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sesuaikan waktu makan harian sesuai kenyamananmu',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF7C8E97),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tiga Kartu Jam Makan Modern & Terstruktur
                  // 1. Sarapan
                  _buildMealCard(
                    title: 'Sarapan',
                    assetPath: 'assets/images/meal_sarapan.png',
                    timeLabel: 'Jam ${_sarapan.label}',
                    onTap: () async {
                      final selected = await MealTimeBottomSheet.show(
                        context: context,
                        title: 'Sarapan',
                        options: MealPresetOptions.sarapanOptions,
                        selectedOption: _sarapan,
                      );
                      if (selected != null) {
                        setState(() => _sarapan = selected);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // 2. Makan Siang
                  _buildMealCard(
                    title: 'Makan Siang',
                    assetPath: 'assets/images/meal_makan_siang.png',
                    timeLabel: 'Jam ${_makanSiang.label}',
                    onTap: () async {
                      final selected = await MealTimeBottomSheet.show(
                        context: context,
                        title: 'Makan Siang',
                        options: MealPresetOptions.makanSiangOptions,
                        selectedOption: _makanSiang,
                      );
                      if (selected != null) {
                        setState(() => _makanSiang = selected);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3. Makan Malam
                  _buildMealCard(
                    title: 'Makan Malam',
                    assetPath: 'assets/images/meal_makan_malam.png',
                    timeLabel: 'Jam ${_makanMalam.label}',
                    onTap: () async {
                      final selected = await MealTimeBottomSheet.show(
                        context: context,
                        title: 'Makan Malam',
                        options: MealPresetOptions.makanMalamOptions,
                        selectedOption: _makanMalam,
                      );
                      if (selected != null) {
                        setState(() => _makanMalam = selected);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Bagian Bawah:
                  // Kondisi Sehat -> Pengaturan Jadwal Hari Berikutnya
                  if (isHealthy) ...[
                    _buildRepeatCard(),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Kondisi Sakit -> Kartu ke-4 "Atur Jam Tidur"
                    _buildSleepCard(),
                    const SizedBox(height: 26),
                  ],

                  // Tombol Simpan Jadwal Bergaya Identik Catat Makanan
                  _buildSelesaiButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),

          // Loading overlay bila proses simpan berlangsung
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF276F8F),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMealCard({
    required String title,
    required String assetPath,
    required String timeLabel,
    required VoidCallback onTap,
  }) {
    const thumbSize = 62.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFEBE3D0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail Makanan di Sisi Kiri
            Container(
              width: thumbSize,
              height: thumbSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEBE3D0),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Judul dan Pill Waktu Makan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C4E68),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  // Tombol Pilihan Jam
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF276F8F).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF276F8F).withValues(alpha: 0.22),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13.5,
                          color: Color(0xFF276F8F),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            timeLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C4E68),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.edit_outlined,
                          size: 13,
                          color: Color(0xFF276F8F),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Chevron Indikator Interaksi di Sisi Kanan
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFB5C5CE),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEBE3D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox Interaktif + Teks Judul & Deskripsi
          GestureDetector(
            onTap: () {
              setState(() => _isRepeatEnabled = !_isRepeatEnabled);
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _isRepeatEnabled
                        ? const Color(0xFF276F8F)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isRepeatEnabled
                          ? const Color(0xFF276F8F)
                          : const Color(0xFFC3D0D8),
                      width: 1.8,
                    ),
                  ),
                  child: _isRepeatEnabled
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atur untuk hari berikutnya',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1C4E68),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Terapkan jadwal makan ini untuk beberapa hari ke depan',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7C8E97),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stepper Jumlah Hari Modern & Ringkas
          if (_isRepeatEnabled) ...[
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: const Color(0xFFF1ECE1),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jumlah Hari',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C4E68),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF276F8F).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF276F8F).withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Kurang <
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.chevron_left_rounded, size: 22),
                        color: const Color(0xFF1C4E68),
                        onPressed: _repeatDays > 1
                            ? () {
                                setState(() => _repeatDays--);
                              }
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$_repeatDays Hari',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C4E68),
                          ),
                        ),
                      ),
                      // Tombol Tambah >
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.chevron_right_rounded, size: 22),
                        color: const Color(0xFF1C4E68),
                        onPressed: _repeatDays < 30
                            ? () {
                                setState(() => _repeatDays++);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_repeatDays > 1) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Aktif sampai ${_formatSingleDate(_effectiveEndDate)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF276F8F),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSleepCard() {
    return _buildMealCard(
      title: 'Atur Jam Tidur',
      assetPath: 'assets/images/meal_tidur.png',
      timeLabel: 'Jam ${_sleepHour.toString().padLeft(2, '0')}.00',
      onTap: () async {
        final selected = await MealTimeBottomSheet.showSleepHour(
          context: context,
          selectedHour: _sleepHour,
        );
        if (selected != null) {
          setState(() => _sleepHour = selected);
        }
      },
    );
  }

  Widget _buildSelesaiButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onSelesaiPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF276F8F),
              Color(0xFF1C4E68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF276F8F).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Simpan Jadwal',
                      style: GoogleFonts.poppins(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

}

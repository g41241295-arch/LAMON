import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_reminder_plan.dart';
import '../services/meal_reminder_service.dart';
import '../services/notification_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/meal_time_bottom_sheet.dart';

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

    return Scaffold(
      body: Stack(
        children: [
          // 1. Latar Belakang Gradasi Butter Yellow Lembut
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFEF08A),
                    Color(0xFFFEF9C3),
                    Color(0xFFFFFBEB),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 2. Konten Utama (Scrollable)
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tombol Back & Pill "Jadwal Harian"
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.arrow_back,
                            color: Color(0xFF1E3A8A),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GlassContainer(
                        borderRadius: 22,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        backgroundColor:
                            const Color(0xFFFFF7D6).withValues(alpha: 0.88),
                        child: Text(
                          'Jadwal Harian',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pill Tanggal (tanpa angka nol di depan)
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      border: Border.all(
                        color: const Color(0xFF93C5FD).withValues(alpha: 0.7),
                        width: 1.2,
                      ),
                      child: Text(
                        _datePillText,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Judul Bagian: "Atur jam makan"
                  Text(
                    'Atur jam makan',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tiga Kartu Jam Makan Glass
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
                  const SizedBox(height: 16),

                  // 2. Makan Siang
                  _buildMealCard(
                    title: 'Makan siang',
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
                  const SizedBox(height: 16),

                  // 3. Makan Malam
                  _buildMealCard(
                    title: 'Makan malam',
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
                  const SizedBox(height: 18),

                  // Bagian Bawah:
                  // Versi SEHAT -> Kartu "Atur untuk hari berikutnya"
                  if (isHealthy) ...[
                    _buildRepeatCard(),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Versi SAKIT -> Kartu ke-4 "Atur jam tidur"
                    _buildSleepCard(),
                    const SizedBox(height: 28),
                  ],

                  // Tombol "Selesai" (Pill Glass)
                  Center(
                    child: _buildSelesaiButton(),
                  ),
                  const SizedBox(height: 16),

                  // ── DEBUG ONLY: Tombol Uji Alarm ──────────────────────
                  if (kDebugMode)
                    Center(
                      child: _buildTestAlarmButton(),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
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
    final screenW = MediaQuery.of(context).size.width;
    final thumbSize = (screenW * 0.165).clamp(58.0, 70.0);

    return GlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.all(12),
      backgroundColor: const Color(0xFFFFFBEB).withValues(alpha: 0.9),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.95),
        width: 1.5,
      ),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
      child: Row(
        children: [
          // Thumbnail Kiri: gambar meal_* persegi, sudut membulat ±14dp, border halus
          Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Judul dan Tombol Pilihan Jam
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                // Tombol Pilihan Jam (Biru Pucat dengan Chevron)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEBF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF93C5FD).withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            timeLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E3A8A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Color(0xFF1E3A8A),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatCard() {
    return GlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      backgroundColor: const Color(0xFFFFFBEB).withValues(alpha: 0.9),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.95),
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox + Label "Atur untuk hari berikutnya"
          Row(
            children: [
              Checkbox(
                value: _isRepeatEnabled,
                activeColor: const Color(0xFF276F8F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (val) {
                  setState(() {
                    _isRepeatEnabled = val ?? false;
                  });
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Atur untuk hari berikutnya',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stepper: < 1 > Hari
          Opacity(
            opacity: _isRepeatEnabled ? 1.0 : 0.45,
            child: Row(
              children: [
                const SizedBox(width: 44),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEBF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF93C5FD).withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Kurang <
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.chevron_left, size: 20),
                        color: const Color(0xFF1E3A8A),
                        onPressed: _isRepeatEnabled && _repeatDays > 1
                            ? () {
                                setState(() => _repeatDays--);
                              }
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_repeatDays',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                      // Tombol Tambah >
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.chevron_right, size: 20),
                        color: const Color(0xFF1E3A8A),
                        onPressed: _isRepeatEnabled && _repeatDays < 30
                            ? () {
                                setState(() => _repeatDays++);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Hari',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),

          if (_isRepeatEnabled && _repeatDays > 1) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(
                'Aktif sampai ${_formatSingleDate(_effectiveEndDate)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF276F8F),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSleepCard() {
    return _buildMealCard(
      title: 'Atur jam tidur',
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
    return GlassContainer(
      borderRadius: 24,
      height: 48,
      width: 220,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      border: Border.all(
        color: const Color(0xFF93C5FD).withValues(alpha: 0.8),
        width: 1.5,
      ),
      shadows: [
        BoxShadow(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      onTap: _isLoading ? null : _onSelesaiPressed,
      child: Center(
        child: Text(
          'Selesai',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E3A8A),
          ),
        ),
      ),
    );
  }

  // ── DEBUG ONLY ─────────────────────────────────────────────────────────────
  /// Tombol uji alarm: menjadwalkan satu notifikasi 60 detik dari sekarang
  /// dengan pengaturan SAMA seperti alarm asli. Hanya tampil di kDebugMode.
  Widget _buildTestAlarmButton() {
    return GlassContainer(
      borderRadius: 24,
      height: 48,
      width: 260,
      backgroundColor: const Color(0xFFFF6B35).withValues(alpha: 0.12),
      border: Border.all(
        color: const Color(0xFFFF6B35).withValues(alpha: 0.6),
        width: 1.5,
      ),
      shadows: [
        BoxShadow(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.10),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      onTap: _onTestAlarmPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.alarm,
            size: 18,
            color: Color(0xFFB84A00),
          ),
          const SizedBox(width: 8),
          Text(
            '🧪 Uji alarm 1 menit',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB84A00),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTestAlarmPressed() async {
    if (!kDebugMode) return;
    try {
      await NotificationService.instance.scheduleTestAlarm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🧪 Alarm uji dijadwalkan — akan berbunyi ~60 detik lagi',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF276F8F),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menjadwalkan uji alarm: $e')),
        );
      }
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/consultation_constants.dart';
import '../../constants/consultation_theme.dart';
import '../../constants/practice_slot_constants.dart';
import '../../models/doctor_model.dart';
import '../../services/consultation_service.dart';
import '../../services/doctor_service.dart';
import '../../services/payment_service.dart';
import '../../utils/app_date_formatter.dart';
import '../../utils/currency_formatter.dart';
import 'widgets/doctor_avatar.dart';
import 'widgets/payment_method_item.dart';

/// Layar Ringkasan Pembayaran — review booking + pilih metode bayar.
class RingkasanPembayaranScreen extends StatefulWidget {
  final DoctorModel doctor;

  const RingkasanPembayaranScreen({super.key, required this.doctor});

  @override
  State<RingkasanPembayaranScreen> createState() =>
      _RingkasanPembayaranScreenState();
}

class _RingkasanPembayaranScreenState extends State<RingkasanPembayaranScreen> {
  final ConsultationService _consultationService = ConsultationService();

  String? _selectedMethodId;
  String? _selectedMethodName;
  int _selectedHourIndex = 0;
  bool _isLoading = false;
  late List<OperatingHour> _activeHours;

  @override
  void initState() {
    super.initState();
    if (ConsultationConstants.paymentMethods.isNotEmpty) {
      _selectedMethodId = ConsultationConstants.paymentMethods.first.id;
      _selectedMethodName = ConsultationConstants.paymentMethods.first.name;
    }
    _activeHours = _doctor.operatingHours;
    _checkTodaySchedule();
  }

  void _checkTodaySchedule() async {
    final now = DateTime.now();
    final todayKey = AppDateFormatter.formatDateKey(now);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(_doctor.id)
          .collection('schedule')
          .doc(todayKey)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final isDayOff = data['dayOff'] == true;
        if (!isDayOff) {
          final rawSlots = data['slots'] as List<dynamic>? ?? [];
          if (rawSlots.isNotEmpty) {
            final parsedSlots = PracticeSlotConstants.parseSlots(rawSlots);
            final mapped = parsedSlots
                .where((slot) => DoctorService.isSlotAvailableNow(slot.endTime, now))
                .map((slot) => OperatingHour(start: slot.startTime, end: slot.endTime))
                .toList();
            if (mounted) {
              setState(() {
                _activeHours = mapped.isNotEmpty
                    ? mapped
                    : _doctor.operatingHours
                        .where((h) => DoctorService.isSlotAvailableNow(h.end, now))
                        .toList();
                if (_selectedHourIndex >= _activeHours.length) {
                  _selectedHourIndex = 0;
                }
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _activeHours = _doctor.operatingHours
                    .where((h) => DoctorService.isSlotAvailableNow(h.end, now))
                    .toList();
                _selectedHourIndex = 0;
              });
            }
          }
        } else {
          if (mounted) setState(() => _activeHours = []);
        }
      } else {
        if (mounted) {
          setState(() {
            _activeHours = _doctor.operatingHours
                .where((h) => DoctorService.isSlotAvailableNow(h.end, now))
                .toList();
            if (_selectedHourIndex >= _activeHours.length) {
              _selectedHourIndex = 0;
            }
          });
        }
      }
    } catch (_) {}
  }

  DoctorModel get _doctor => widget.doctor;
  int get _totalFee => _doctor.price + ConsultationConstants.serviceFee;

  String get _selectedTime => _activeHours.isNotEmpty
      ? _activeHours[_selectedHourIndex.clamp(0, _activeHours.length - 1)].display
      : (_doctor.operatingHours.isNotEmpty ? _doctor.operatingHours.first.display : '18.00 – 21.00');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConsultationTheme.scaffoldBg,
      appBar: const ConsultationHeader(
        title: 'Ringkasan Pembayaran',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. Kotak Peringatan Amber Langsung di Bawah Header ─────────────
                    const InfoNotice(
                      text:
                          'Selesaikan pembayaran untuk mengamankan jadwal konsultasi dengan dokter ini.',
                    ),
                    const SizedBox(height: 16),

                    // ── 2. Kartu "Detail Konsultasi" ──────────────────────────────────
                    _buildDetailKonsultasiCard(),
                    const SizedBox(height: 16),

                    // ── 3. Kartu "Rincian Biaya" Bergaya Invoice ───────────────────────
                    _buildRincianBiayaCard(),
                    const SizedBox(height: 10),

                    // ── Catatan kecil dengan ikon info abu ─────────────────────────────
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: ConsultationTheme.secondaryText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Batas waktu pembayaran 1 jam setelah Virtual Account dibuat.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: ConsultationTheme.secondaryText,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── 4. Pilihan Metode Pembayaran ───────────────────────────────────
                    const MicroLabel('PILIH METODE PEMBAYARAN'),
                    const SizedBox(height: 10),
                    ...ConsultationConstants.paymentMethods.map(
                      (method) => PaymentMethodItem(
                        method: method,
                        isSelected: _selectedMethodId == method.id,
                        onTap: () {
                          setState(() {
                            _selectedMethodId = method.id;
                            _selectedMethodName = method.name;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bar Bawah Melekat ──────────────────────────────────────────────
            _buildStickyBottomBar(context),
          ],
        ),
      ),
    );
  }

  /// Kartu "Detail Konsultasi": label mikro, baris dokter (DoctorAvatar 48x48 radius 14 + nama bold 15 + spesialis),
  /// garis pemisah, baris "Jam Konsultasi" dengan nilai bold ("18.00 – 21.00").
  Widget _buildDetailKonsultasiCard() {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MicroLabel('DETAIL KONSULTASI'),
          const SizedBox(height: 12),
          Row(
            children: [
              DoctorAvatar(
                doctor: _doctor,
                size: 48,
                borderRadius: 14,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _doctor.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ConsultationTheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _doctor.specialty,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ConsultationTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SectionDivider(verticalPadding: 12),

          // Baris Jam Konsultasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: ConsultationTheme.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Jam Konsultasi',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ConsultationTheme.secondaryText,
                    ),
                  ),
                ],
              ),
              Text(
                _selectedTime,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: ConsultationTheme.primary,
                ),
              ),
            ],
          ),

          // Opsi pilihan slot jam jika dokter punya > 1 slot aktif hari ini
          if (_activeHours.length > 1) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_activeHours.length, (idx) {
                final isSelected = _selectedHourIndex == idx;
                return GestureDetector(
                  onTap: () => setState(() => _selectedHourIndex = idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? ConsultationTheme.primary : ConsultationTheme.softBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? ConsultationTheme.primary
                            : ConsultationTheme.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _activeHours[idx].display,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : ConsultationTheme.primary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  /// Kartu "Rincian Biaya" bergaya invoice: label mikro, baris Biaya Sesi dan Biaya Layanan
  /// (label #5E7585, nilai bold biru tua), garis putus-putus (dashed #E2D6C1),
  /// lalu baris total "Pembayaranmu" bold dengan nilai teal #2E85A8 ukuran 20.
  Widget _buildRincianBiayaCard() {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MicroLabel('RINCIAN BIAYA'),
          const SizedBox(height: 12),

          // Baris Biaya Sesi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biaya Sesi Konsultasi',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ConsultationTheme.secondaryText,
                ),
              ),
              Text(
                formatRupiah(_doctor.price),
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: ConsultationTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Baris Biaya Layanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biaya Layanan Aplikasi',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ConsultationTheme.secondaryText,
                ),
              ),
              Text(
                formatRupiah(ConsultationConstants.serviceFee),
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: ConsultationTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Garis Putus-putus (dashed #E2D6C1)
          const _DashedLine(color: Color(0xFFE2D6C1)),
          const SizedBox(height: 12),

          // Baris Total "Pembayaranmu"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pembayaranmu',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: ConsultationTheme.primary,
                ),
              ),
              Text(
                formatRupiah(_totalFee),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ConsultationTheme.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bar bawah melekat (putih, border atas krem, padding 14x20):
  /// kiri "Pembayaranmu" kecil + nominal bold 20 biru tua,
  /// kanan tombol "Lanjut" (nonaktif #A9C4D2 sampai metode dipilih, lalu biru tua).
  Widget _buildStickyBottomBar(BuildContext context) {
    final isEnabled = _selectedMethodId != null && !_isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: ConsultationTheme.cardBorder,
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Kiri: Pembayaranmu kecil + nominal bold 20 biru tua
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembayaranmu',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: ConsultationTheme.secondaryText,
                  ),
                ),
                Text(
                  formatRupiah(_totalFee),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ConsultationTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Kanan: Tombol "Lanjut"
          SizedBox(
            width: 140,
            child: ElevatedButton(
              onPressed: isEnabled ? _onLanjut : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ConsultationTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ConsultationTheme.disabledButton,
                disabledForegroundColor: Colors.white70,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Lanjut',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onLanjut() async {
    if (_selectedMethodId == null) return;
    setState(() => _isLoading = true);
    final nav = Navigator.of(context);
    try {
      final now = DateTime.now();
      final scheduledDate = DateTime(now.year, now.month, now.day);
      final consultationId = await _consultationService.createConsultation(
        doctorId: _doctor.id,
        doctorName: _doctor.name,
        doctorSpecialty: _doctor.specialty,
        scheduledTime: _selectedTime,
        sessionFee: _doctor.price,
        paymentMethod: _selectedMethodId!,
        paymentMethodName: _selectedMethodName!,
        scheduledDate: scheduledDate,
      );

      // Buat transaksi pembayaran Midtrans Snap via Backend
      SnapTransactionResult? snapResult;
      try {
        snapResult = await PaymentService.instance.createTransaction(
          consultationId: consultationId,
        );

        if (snapResult.redirectUrl.isNotEmpty) {
          // Buka halaman pembayaran Snap di In-App Browser
          await PaymentService.instance.openSnapPaymentUrl(snapResult.redirectUrl);
        }
      } catch (err) {
        debugPrint('[RingkasanPembayaran] Catatan Snap: $err');
      }

      if (mounted) {
        nav.pushNamed(
          '/konsultasi/virtual-account/$consultationId',
          arguments: {
            'consultationId': consultationId,
            'paymentMethodName': _selectedMethodName,
            'redirectUrl': snapResult?.redirectUrl,
            'orderId': snapResult?.orderId,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        String mainMsg = 'Gagal memulai pembayaran.';
        String? subMsg;
        if (e is PaymentException) {
          mainMsg = e.message;
          if (e.debugCode != null) subMsg = 'Kode: ${e.debugCode}';
        } else {
          mainMsg = e
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('HttpException: ', '');
        }
        showConsultationSnackBar(
          context,
          message: mainMsg,
          subMessage: subMsg,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Garis putus-putus horizontal untuk invoice
class _DashedLine extends StatelessWidget {
  final Color color;

  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    const dashWidth = 6.0;
    const dashGap = 4.0;
    const height = 1.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final count = (boxWidth / (dashWidth + dashGap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

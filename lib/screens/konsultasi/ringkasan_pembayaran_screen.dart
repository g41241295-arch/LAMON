import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/consultation_constants.dart';
import '../../models/doctor_model.dart';
import '../../services/consultation_service.dart';
import '../../widgets/app_scaffold.dart';
import 'widgets/doctor_card.dart';
import 'widgets/payment_method_item.dart';

/// Layar Ringkasan Pembayaran — review booking + pilih metode bayar.
class RingkasanPembayaranScreen extends StatefulWidget {
  final DoctorModel doctor;

  const RingkasanPembayaranScreen({super.key, required this.doctor});

  @override
  State<RingkasanPembayaranScreen> createState() =>
      _RingkasanPembayaranScreenState();
}

class _RingkasanPembayaranScreenState
    extends State<RingkasanPembayaranScreen> {
  final ConsultationService _consultationService = ConsultationService();

  String? _selectedMethodId;
  String? _selectedMethodName;
  int _selectedHourIndex = 0;
  bool _isLoading = false;

  DoctorModel get _doctor => widget.doctor;
  int get _totalFee => _doctor.price + ConsultationConstants.serviceFee;

  String get _selectedTime =>
      _doctor.operatingHours.isNotEmpty
          ? _doctor.operatingHours[_selectedHourIndex].display
          : '-';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali',
        ),
        title: const Text('Ringkasan Pembayaran'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Banner peringatan ──
                  _WarningBanner(),
                  const SizedBox(height: 16),

                  // ── Kartu dokter mini ──
                  _DoctorSummaryCard(doctor: _doctor),
                  const SizedBox(height: 16),

                  // ── Jadwal konsultasi ──
                  _buildScheduleSection(),
                  const SizedBox(height: 16),

                  // ── Rincian biaya ──
                  _buildFeeSection(),
                  const SizedBox(height: 20),

                  // ── Metode pembayaran ──
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Sticky bottom bar ──
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2ECF2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konsultasi pada',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neutralGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          if (_doctor.operatingHours.isEmpty)
            const Text(
              'Jam tidak tersedia',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: List.generate(_doctor.operatingHours.length, (i) {
                final hour = _doctor.operatingHours[i];
                final isSelected = i == _selectedHourIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedHourIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      hour.display,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.primaryText,
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildFeeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2ECF2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _FeeRow(
            label: 'Biaya Sesi',
            amount: _doctor.price,
          ),
          const Divider(height: 20, color: Color(0xFFF0F4F7)),
          _FeeRow(
            label: 'Biaya Layanan',
            amount: ConsultationConstants.serviceFee,
          ),
          const Divider(height: 20, color: Color(0xFFF0F4F7)),
          _FeeRow(
            label: 'Pembayaranmu',
            amount: _totalFee,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Metode Pembayaran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        ...ConsultationConstants.paymentMethods.map((method) {
          return PaymentMethodItem(
            method: method,
            isSelected: _selectedMethodId == method.id,
            onTap: () {
              setState(() {
                _selectedMethodId = method.id;
                _selectedMethodName = method.name;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isEnabled = _selectedMethodId != null && !_isLoading;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Total
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pembayaranmu',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutralGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatRupiah(_totalFee),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Tombol Lanjut
            Expanded(
              child: Semantics(
                label: 'Lanjut ke pembayaran',
                button: true,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isEnabled ? () => _onLanjut(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.4),
                      disabledForegroundColor: Colors.white70,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Lanjut',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onLanjut(BuildContext context) async {
    if (_selectedMethodId == null) return;
    setState(() => _isLoading = true);
    // Capture navigator dan messenger sebelum async gap
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final consultationId = await _consultationService.createConsultation(
        doctorId: _doctor.id,
        doctorName: _doctor.name,
        doctorSpecialty: _doctor.specialty,
        scheduledTime: _selectedTime,
        sessionFee: _doctor.price,
        paymentMethod: _selectedMethodId!,
        paymentMethodName: _selectedMethodName!,
      );
      if (mounted) {
        nav.pushNamed(
          '/konsultasi/virtual-account/$consultationId',
          arguments: {
            'consultationId': consultationId,
            'paymentMethodName': _selectedMethodName,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal membuat konsultasi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(int amount) {
    final s = amount.toString();
    final buf = StringBuffer('Rp');
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return String.fromCharCodes(buf.toString().codeUnits.reversed);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCCCC), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFD32F2F), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Selesaikan pembayaran untuk mengamankan jadwal konsultasi dengan dokter ini.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFC62828),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorSummaryCard extends StatelessWidget {
  final DoctorModel doctor;
  const _DoctorSummaryCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2ECF2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          DoctorAvatar(photoUrl: doctor.photoUrl, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  doctor.specialty,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutralGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool isTotal;

  const _FeeRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isTotal ? AppColors.primaryText : AppColors.neutralGray,
          ),
        ),
        Text(
          _formatRupiah(amount),
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            color: isTotal ? AppColors.primary : AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  String _formatRupiah(int amount) {
    final s = amount.toString();
    final buf = StringBuffer('Rp');
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return String.fromCharCodes(buf.toString().codeUnits.reversed);
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../models/consultation_model.dart';
import '../../services/consultation_service.dart';
import '../../utils/app_date_formatter.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/app_header_pill.dart';
import '../../widgets/app_scaffold.dart';
import '../screening/widgets/screening_avatars.dart';

/// Layar Nomor Virtual Account — tampil setelah booking dibuat.
class VirtualAccountScreen extends StatefulWidget {
  final String consultationId;

  const VirtualAccountScreen({super.key, required this.consultationId});

  @override
  State<VirtualAccountScreen> createState() => _VirtualAccountScreenState();
}

class _VirtualAccountScreenState extends State<VirtualAccountScreen>
    with WidgetsBindingObserver {
  final ConsultationService _consultationService = ConsultationService();
  ConsultationModel? _consultation;
  bool _isLoading = true;
  bool _isConfirming = false;

  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _isExpired = false;
  bool _hasMarkedExpired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConsultation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recalculateRemaining();
    }
  }

  Future<void> _loadConsultation() async {
    final data = await _consultationService.fetchById(widget.consultationId);
    if (mounted) {
      setState(() {
        _consultation = data;
        _isLoading = false;
      });
      _startCountdownTimer();
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _recalculateRemaining();
    if (!_isExpired) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _recalculateRemaining();
      });
    }
  }

  void _recalculateRemaining() {
    if (_consultation == null) return;

    if (_consultation!.isExpired) {
      _countdownTimer?.cancel();
      if (!_isExpired && mounted) {
        setState(() {
          _isExpired = true;
          _remaining = Duration.zero;
        });
      }
      return;
    }

    final expiresAt = _consultation!.effectivePaymentExpiresAt;
    final now = DateTime.now();
    final diff = expiresAt.difference(now);

    if (diff.isNegative || diff == Duration.zero) {
      _countdownTimer?.cancel();
      if (!_isExpired && mounted) {
        setState(() {
          _remaining = Duration.zero;
          _isExpired = true;
        });
      }
      _handleTimeExpired();
    } else {
      if (mounted) {
        setState(() {
          _remaining = diff;
          _isExpired = false;
        });
      }
    }
  }

  Future<void> _handleTimeExpired() async {
    if (_hasMarkedExpired) return;
    _hasMarkedExpired = true;
    try {
      await _consultationService.markAsExpired(widget.consultationId);
    } catch (e) {
      debugPrint('[VirtualAccountScreen] Error markAsExpired: $e');
    }
  }

  void _onBuatPesananBaru(BuildContext context) {
    // Kembali ke daftar dokter
    Navigator.of(context).popUntil((route) =>
        route.isFirst ||
        route.settings.name == '/konsultasi' ||
        route.settings.name == '/beranda');
  }

  Future<void> _onMengerti(BuildContext context) async {
    if (_isConfirming) return;

    // Guard (A.6): Periksa lagi batas waktu pembayaran
    if (_consultation != null) {
      final now = DateTime.now();
      if (_consultation!.effectivePaymentExpiresAt.isBefore(now)) {
        setState(() {
          _isExpired = true;
          _remaining = Duration.zero;
        });
        _handleTimeExpired();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waktu pembayaran telah habis. Silakan buat pesanan baru.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isConfirming = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _consultationService.markAsPaid(widget.consultationId);
      if (mounted) {
        nav.pushNamed(
          '/konsultasi/payment-success/${widget.consultationId}',
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal memproses: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppHeaderPill(title: 'Nomor Virtual Account'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _consultation == null
              ? const Center(child: Text('Data tidak ditemukan.'))
              : _buildContent(context, _consultation!),
    );
  }

  Widget _buildContent(BuildContext context, ConsultationModel c) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // ── Ikon status ──
                _isExpired
                    ? Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFFFCDD2), width: 2),
                        ),
                        child: const Icon(
                          Icons.timer_off_rounded,
                          color: Color(0xFFD32F2F),
                          size: 48,
                        ),
                      )
                    : const GreenCheckmark3DBadge(size: 90),
                const SizedBox(height: 16),

                Text(
                  _isExpired
                      ? 'Waktu Pembayaran Habis'
                      : 'Virtual Account Berhasil Dibuat!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _isExpired
                      ? 'Batas waktu 1 jam telah terlewati. Silakan buat pesanan baru.'
                      : 'Salin nomor VA di bawah dan selesaikan pembayaran',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutralGray,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // ── Kartu Hitung Mundur Batas Waktu Pembayaran (A.3) ──
                _buildCountdownCard(),
                const SizedBox(height: 16),

                // ── Kartu Nomor VA ──
                _buildVACard(context, c.virtualAccountNumber, c.paymentMethodName),
                const SizedBox(height: 16),

                // ── Kartu Detail Pembayaran ──
                _buildDetailCard(c),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Tombol Bawah (Saya Mengerti / Buat Pesanan Baru) ──
        Container(
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
            child: Semantics(
              label: _isExpired ? 'Buat Pesanan Baru' : 'Saya Mengerti dan lanjutkan',
              button: true,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isConfirming
                      ? null
                      : (_isExpired
                          ? () => _onBuatPesananBaru(context)
                          : () => _onMengerti(context)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isExpired
                        ? AppColors.primary
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isConfirming
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isExpired ? 'Buat Pesanan Baru' : 'Saya Mengerti',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Kartu hitung mundur (A.3 & A.5)
  Widget _buildCountdownCard() {
    if (_isExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFD32F2F), size: 22),
            SizedBox(width: 8),
            Text(
              'Waktu pembayaran habis',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD32F2F),
              ),
            ),
          ],
        ),
      );
    }

    final isUrgent = _remaining < const Duration(minutes: 10);
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final bgColor = isUrgent ? const Color(0xFFFFF3E0) : const Color(0xFFE8F4F8);
    final borderColor =
        isUrgent ? const Color(0xFFFFB74D) : const Color(0xFFBCE0F0);
    final textColor =
        isUrgent ? const Color(0xFFE65100) : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: textColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Selesaikan pembayaran dalam',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUrgent ? const Color(0xFFFFE0B2) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVACard(
      BuildContext context, String vaNumber, String bankName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2ECF2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nomor Virtual Account ($bankName)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutralGray,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Nomor VA 1 baris tidak terpotong
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    vaNumber,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                      letterSpacing: 1.0,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Salin Ringkas
              Semantics(
                label: 'Salin nomor virtual account',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () => _copyVA(context, vaNumber),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Salin'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(ConsultationModel c) {
    final deadlineStr = AppDateFormatter.formatPaymentDeadline(c.effectivePaymentExpiresAt);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2ECF2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Pembayaran',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          _BankDetailRow(
            label: 'Bank',
            bankName: c.paymentMethodName,
            bankId: c.paymentMethod,
          ),
          const Divider(height: 16, color: Color(0xFFF0F4F7)),
          _DetailRow(label: 'Nama Dokter', value: c.doctorName),
          const Divider(height: 16, color: Color(0xFFF0F4F7)),
          _DetailRow(
            label: 'Total Transaksi',
            value: formatRupiah(c.totalFee),
            isHighlight: true,
          ),
          const Divider(height: 16, color: Color(0xFFF0F4F7)),
          _DetailRow(label: 'Order ID', value: c.orderId),
          const Divider(height: 16, color: Color(0xFFF0F4F7)),
          _DetailRow(
            label: 'Batas Waktu Bayar',
            value: deadlineStr,
            valueColor: const Color(0xFFC62828),
          ),
        ],
      ),
    );
  }

  void _copyVA(BuildContext context, String vaNumber) {
    Clipboard.setData(ClipboardData(text: vaNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Nomor VA berhasil disalin!'),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  final String label;
  final String bankName;
  final String bankId;

  const _BankDetailRow({
    required this.label,
    required this.bankName,
    required this.bankId,
  });

  /// Nama file logo bank dengan suffix -removebg-preview.png
  String get _bankAssetPath {
    final fileName = bankId == 'jatim'
        ? 'bank_jatim-removebg-preview.png'
        : '$bankId-removebg-preview.png';
    return 'assets/images/banks/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.neutralGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Logo saja (tanpa teks nama bank) — nama tetap tersedia
        // via Semantics untuk aksesibilitas (pembaca layar)
        Semantics(
          label: bankName,
          child: Container(
            height: 32,
            width: 72,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE8EFF5),
                width: 1,
              ),
            ),
            child: Image.asset(
              _bankAssetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.account_balance_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.neutralGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isHighlight ? 15 : 13,
              fontWeight:
                  isHighlight ? FontWeight.w900 : FontWeight.w700,
              color: valueColor ??
                  (isHighlight ? AppColors.primary : AppColors.primaryText),
            ),
          ),
        ),
      ],
    );
  }
}


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/consultation_theme.dart';
import '../../models/consultation_model.dart';
import '../../services/consultation_service.dart';
import '../../services/payment_service.dart';
import '../../utils/app_date_formatter.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/app_scaffold.dart';

/// Layar Status & Pembayaran Konsultasi (Midtrans Snap Sandbox).
class VirtualAccountScreen extends StatefulWidget {
  final String consultationId;

  const VirtualAccountScreen({super.key, required this.consultationId});

  @override
  State<VirtualAccountScreen> createState() => _VirtualAccountScreenState();
}

class _VirtualAccountScreenState extends State<VirtualAccountScreen>
    with WidgetsBindingObserver {
  final ConsultationService _consultationService = ConsultationService();
  final PaymentService _paymentService = PaymentService.instance;

  ConsultationModel? _consultation;
  StreamSubscription<ConsultationModel?>? _consultationSub;

  bool _isLoading = true;
  bool _isCheckingStatus = false;
  bool _isCreatingSnap = false;
  bool _hasNavigatedToSuccess = false;

  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _isExpired = false;
  String? _redirectUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Dapatkan data live dari Firestore stream
    _subscribeConsultation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      if (args['redirectUrl'] is String && (args['redirectUrl'] as String).isNotEmpty) {
        _redirectUrl = args['redirectUrl'] as String;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _consultationSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recalculateRemaining();
      // Saat pengguna kembali dari browser Snap, periksa status otomatis
      _handleCheckPaymentStatus(silent: true);
    }
  }

  void _subscribeConsultation() {
    _consultationSub?.cancel();
    _consultationSub = _consultationService
        .watchConsultation(widget.consultationId)
        .listen((data) {
      if (!mounted) return;

      setState(() {
        _consultation = data;
        _isLoading = false;
      });

      _startCountdownTimer();

      // Jika status menjadi PAID dari backend / webhook, arahkan ke layar sukses
      if (data != null && data.isPaid && !_hasNavigatedToSuccess) {
        _hasNavigatedToSuccess = true;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              '/konsultasi/payment-success/${widget.consultationId}',
            );
          }
        });
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _recalculateRemaining();
    if (!_isExpired && (_consultation?.isPaymentPending ?? true)) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _recalculateRemaining();
      });
    }
  }

  void _recalculateRemaining() {
    if (_consultation == null) return;

    if (_consultation!.isExpired || _consultation!.isPaymentFailed) {
      _countdownTimer?.cancel();
      if (!_isExpired && mounted) {
        setState(() {
          _isExpired = true;
          _remaining = Duration.zero;
        });
      }
      return;
    }

    if (_consultation!.isPaid) {
      _countdownTimer?.cancel();
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
    } else {
      if (mounted) {
        setState(() {
          _remaining = diff;
          _isExpired = false;
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00:00';
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Membuka halaman pembayaran Snap Midtrans
  Future<void> _openMidtransPayment() async {
    if (_redirectUrl != null && _redirectUrl!.isNotEmpty) {
      await _paymentService.openSnapPaymentUrl(_redirectUrl!);
      return;
    }

    setState(() => _isCreatingSnap = true);
    try {
      final snap = await _paymentService
          .createTransaction(
            consultationId: widget.consultationId,
          )
          .timeout(const Duration(seconds: 35));
      _redirectUrl = snap.redirectUrl;
      if (mounted && snap.redirectUrl.isNotEmpty) {
        await _paymentService.openSnapPaymentUrl(snap.redirectUrl);
      }
    } catch (e) {
      if (mounted) {
        String mainMsg = 'Gagal membuka halaman pembayaran.';
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
      if (mounted) setState(() => _isCreatingSnap = false);
    }
  }

  /// Memanggil endpoint POST /api/check-payment di backend
  Future<void> _handleCheckPaymentStatus({bool silent = false}) async {
    if (_isCheckingStatus) return;
    setState(() => _isCheckingStatus = true);

    try {
      final result = await _paymentService
          .checkPaymentStatus(
            consultationId: widget.consultationId,
          )
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;

      if (result.paymentStatus == 'paid') {
        if (!silent) {
          showConsultationSnackBar(
            context,
            message: 'Pembayaran berhasil dikonfirmasi!',
            isSuccess: true,
          );
        }
      } else if (result.paymentStatus == 'pending') {
        if (!silent) {
          showConsultationSnackBar(
            context,
            message: 'Pembayaran masih berstatus pending. Silakan selesaikan tagihan.',
          );
        }
      } else {
        if (!silent) {
          showConsultationSnackBar(
            context,
            message: 'Status pembayaran: ${result.paymentStatus}',
          );
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        String mainMsg = 'Gagal memeriksa status pembayaran.';
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
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  void _copyText(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showConsultationSnackBar(
      context,
      message: '$label berhasil disalin!',
      isSuccess: true,
    );
  }

  void _onBuatPesananBaru(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/konsultasi',
      (route) => route.settings.name == '/beranda' || route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _consultation;

    return AppScaffold(
      backgroundGradient: AppColors.pageGradient,
      appBar: const ConsultationHeader(
        title: 'Status Pembayaran',
        isYellowPill: true,
      ),
      bottomNavigationBar:
          c != null ? SafeArea(top: false, child: _buildBottomBar(context, c)) : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ConsultationTheme.primary),
            )
          : c == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: ConsultationTheme.red),
                        const SizedBox(height: 12),
                        Text(
                          'Data konsultasi tidak ditemukan.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ConsultationTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. Kartu Status Ringkas ────────────────────────────────
                      _buildStatusCard(c),
                      const SizedBox(height: 16),

                      // ── 2. Kartu Timer Hitung Mundur ────────────────────────────
                      if (!c.isPaid) ...[
                        _buildTimerCard(c),
                        const SizedBox(height: 16),
                      ],

                      // ── 3. Kartu Fokus Transaksi & Aksi Bayar ────────────────────
                      _buildTransactionCard(c),
                      const SizedBox(height: 16),

                      // ── 4. Kartu "Detail Pembayaran" ────────────────────────────
                      _buildDetailPembayaranCard(c),
                    ],
                  ),
                ),
    );
  }

  /// Kartu status ringkas
  Widget _buildStatusCard(ConsultationModel c) {
    Color iconBg = ConsultationTheme.green;
    IconData iconData = Icons.check_rounded;
    String title = 'Menunggu Pembayaran';
    String subtitle = 'Selesaikan pembayaran untuk mengonfirmasi sesi.';

    if (c.isPaid) {
      iconBg = ConsultationTheme.green;
      iconData = Icons.check_rounded;
      title = 'Pembayaran Berhasil';
      subtitle = 'Jadwal konsultasi Anda telah diamankan.';
    } else if (c.isPaidAfterExpiry) {
      iconBg = const Color(0xFFE0913A);
      iconData = Icons.warning_amber_rounded;
      title = 'Pembayaran Selesai Lewat Batas';
      subtitle = 'Pembayaran diterima setelah batas waktu. Hubungi kami untuk bantuan.';
    } else if (_isExpired || c.isExpired) {
      iconBg = ConsultationTheme.red;
      iconData = Icons.access_time_filled_rounded;
      title = 'Waktu Pembayaran Habis';
      subtitle = 'Batas waktu bayar telah lewat. Silakan buat pesanan baru.';
    } else if (c.isPaymentFailed) {
      iconBg = ConsultationTheme.red;
      iconData = Icons.cancel_rounded;
      title = 'Pembayaran Gagal / Dibatalkan';
      subtitle = 'Transaksi gagal diproses. Anda dapat mencoba kembali.';
    }

    return InfoCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ConsultationTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: ConsultationTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu timer: hitung mundur batas pembayaran
  Widget _buildTimerCard(ConsultationModel c) {
    final timerString = _formatDuration(_remaining);
    final expired = _isExpired || c.isExpired || c.isPaymentFailed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: expired ? const Color(0xFFFFEBEE) : ConsultationTheme.lightBlueBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expired ? const Color(0xFFFFCDD2) : ConsultationTheme.lightBlueBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 20,
            color: expired ? ConsultationTheme.red : ConsultationTheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              expired ? 'Batas waktu:' : 'Selesaikan pembayaran dalam',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: expired ? ConsultationTheme.red : ConsultationTheme.primary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: expired ? const Color(0xFFFFCDD2) : ConsultationTheme.lightBlueBorder,
                width: 1,
              ),
            ),
            child: Text(
              expired ? '00:00:00' : timerString,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: expired ? ConsultationTheme.red : ConsultationTheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu fokus transaksi Midtrans Snap
  Widget _buildTransactionCard(ConsultationModel c) {
    final orderId = c.paymentOrderId ?? c.orderId;
    final totalStr = formatRupiah(c.totalFee);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F5C7A),
            Color(0xFF2E85A8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F5C7A).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MIDTRANS PAYMENT GATEWAY',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c.isPaid ? 'LUNAS' : (c.isExpired ? 'EXPIRED' : 'SANDBOX'),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Tagihan Besar
          Text(
            totalStr,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            orderId.isNotEmpty ? 'Order ID: $orderId' : 'Konsultasi ID: ${c.id}',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Aksi Buka Halaman Bayar jika masih pending
          if (!c.isPaid && !_isExpired && !c.isExpired && !c.isPaymentFailed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreatingSnap ? null : _openMidtransPayment,
                icon: _isCreatingSnap
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ConsultationTheme.primary,
                        ),
                      )
                    : const Icon(Icons.payment_rounded, size: 18),
                label: Text(
                  _isCreatingSnap ? 'Menyiapkan...' : 'Buka Halaman Pembayaran',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ConsultationTheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Kartu "Detail Pembayaran"
  Widget _buildDetailPembayaranCard(ConsultationModel c) {
    final deadlineStr = AppDateFormatter.formatDateTime(c.effectivePaymentExpiresAt);
    final orderId = c.paymentOrderId ?? c.orderId;

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MicroLabel('DETAIL TRANSAKSI'),
          const SizedBox(height: 12),

          // Baris Dokter
          _buildDetailRow(
            label: 'Dokter',
            value: c.doctorName,
          ),
          const SectionDivider(verticalPadding: 8),

          // Baris Total Biaya
          _buildDetailRow(
            label: 'Total Tagihan',
            value: formatRupiah(c.totalFee),
            valueColor: ConsultationTheme.teal,
            isBold: true,
          ),
          const SectionDivider(verticalPadding: 8),

          // Baris Order ID
          _buildDetailRow(
            label: 'Order ID',
            value: orderId.isNotEmpty ? orderId : '-',
            trailingAction: orderId.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16, color: ConsultationTheme.secondaryText),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _copyText(context, orderId, 'Order ID'),
                  )
                : null,
          ),
          const SectionDivider(verticalPadding: 8),

          // Baris Metode
          _buildDetailRow(
            label: 'Gateway / Jalur',
            value: c.paymentType != null && c.paymentType!.isNotEmpty
                ? c.paymentType!.toUpperCase()
                : 'Midtrans Snap',
          ),
          const SectionDivider(verticalPadding: 8),

          // Baris Batas Waktu Bayar
          _buildDetailRow(
            label: c.isPaid ? 'Waktu Lunas' : 'Batas Waktu Bayar',
            value: c.isPaid && c.paidAt != null
                ? AppDateFormatter.formatDateTime(c.paidAt!)
                : deadlineStr,
            valueColor: c.isPaid ? ConsultationTheme.green : ConsultationTheme.darkRed,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    Widget? trailingAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: ConsultationTheme.secondaryText,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                    color: valueColor ?? ConsultationTheme.primary,
                  ),
                ),
              ),
              if (trailingAction != null) ...[
                const SizedBox(width: 6),
                trailingAction,
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Bar bawah melekat
  Widget _buildBottomBar(BuildContext context, ConsultationModel c) {
    if (c.isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: ConsultationTheme.cardBorder, width: 1.2)),
        ),
        child: PrimaryButton(
          text: 'Buka Ruang Chat',
          icon: Icons.chat_bubble_rounded,
          onPressed: () {
            Navigator.of(context).pushReplacementNamed(
              '/konsultasi/chat/${c.id}',
              arguments: {
                'initialConsultation': c,
                'patientUid': c.patientUid,
              },
            );
          },
        ),
      );
    }

    final isFailedOrExpired = _isExpired || c.isExpired || c.isPaymentFailed;

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
      child: isFailedOrExpired
          ? Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Pesanan Baru',
                    onPressed: () => _onBuatPesananBaru(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Coba Bayar Lagi',
                    icon: Icons.refresh_rounded,
                    onPressed: _openMidtransPayment,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isCheckingStatus ? null : () => _handleCheckPaymentStatus(),
                        icon: _isCheckingStatus
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_rounded, size: 16),
                        label: Text(
                          _isCheckingStatus ? 'Memeriksa...' : 'Cek Status',
                          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ConsultationTheme.primary,
                          side: const BorderSide(color: ConsultationTheme.primary, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        text: 'Bayar Sekarang',
                        onPressed: _openMidtransPayment,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

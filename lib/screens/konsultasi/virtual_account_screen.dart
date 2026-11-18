import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/consultation_theme.dart';
import '../../models/consultation_model.dart';
import '../../services/consultation_service.dart';
import '../../utils/app_date_formatter.dart';
import '../../utils/currency_formatter.dart';

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

  void _handleTimeExpired() {
    if (_hasMarkedExpired) return;
    _hasMarkedExpired = true;
    _consultationService.markConsultationExpired(widget.consultationId);
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00:00';
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _copyVA(BuildContext context, String vaNumber) {
    Clipboard.setData(ClipboardData(text: vaNumber));
    showConsultationSnackBar(
      context,
      message: 'Nomor Virtual Account berhasil disalin!',
      isSuccess: true,
    );
  }

  Future<void> _onMengerti(BuildContext context) async {
    if (_consultation != null) {
      final now = DateTime.now();
      if (_consultation!.effectivePaymentExpiresAt.isBefore(now)) {
        setState(() {
          _isExpired = true;
          _remaining = Duration.zero;
        });
        _handleTimeExpired();
        showConsultationSnackBar(
          context,
          message: 'Waktu pembayaran telah habis. Silakan buat pesanan baru.',
          isError: true,
        );
        return;
      }
    }

    setState(() => _isConfirming = true);
    final nav = Navigator.of(context);
    try {
      await _consultationService.simulatePaymentSuccess(widget.consultationId);
      if (mounted) {
        nav.pushNamedAndRemoveUntil(
          '/konsultasi/payment-success/${widget.consultationId}',
          (route) => route.settings.name == '/beranda' || route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        showConsultationSnackBar(
          context,
          message: 'Gagal memproses pembayaran: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
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

    return Scaffold(
      backgroundColor: ConsultationTheme.scaffoldBg,
      appBar: const ConsultationHeader(
        title: 'Nomor Virtual Account',
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
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
                            'Data Virtual Account tidak ditemukan.',
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
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── 1. Kartu Status Ringkas ────────────────────────────────
                              _buildStatusCard(),
                              const SizedBox(height: 16),

                              // ── 2. Kartu Timer Hitung Mundur ────────────────────────────
                              _buildTimerCard(),
                              const SizedBox(height: 16),

                              // ── 3. Kartu Nomor VA Sebagai Fokus ─────────────────────────
                              _buildVACard(c),
                              const SizedBox(height: 16),

                              // ── 4. Kartu "Detail Pembayaran" ────────────────────────────
                              _buildDetailPembayaranCard(c),
                            ],
                          ),
                        ),
                      ),

                      // ── Bar Bawah Melekat: Tombol "Saya Mengerti" ────────────────
                      _buildBottomBar(context),
                    ],
                  ),
      ),
    );
  }

  /// Kartu status ringkas: lingkaran hijau 44 berikon centang putih,
  /// judul "Virtual Account berhasil dibuat" (bold 15), subteks "Salin nomor VA dan selesaikan pembayaran".
  Widget _buildStatusCard() {
    return InfoCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isExpired ? ConsultationTheme.red : ConsultationTheme.green,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isExpired ? Icons.access_time_filled_rounded : Icons.check_rounded,
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
                  _isExpired
                      ? 'Waktu Pembayaran Habis'
                      : 'Virtual Account berhasil dibuat',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ConsultationTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isExpired
                      ? 'Batas waktu bayar telah lewat. Silakan buat pesanan baru.'
                      : 'Salin nomor VA dan selesaikan pembayaran',
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

  /// Kartu timer: latar #EAF3F8, border #BFD9E6, radius 16, ikon stopwatch,
  /// teks "Selesaikan pembayaran dalam", dan kotak putih bergaris biru muda berisi hitung mundur (bold 16).
  Widget _buildTimerCard() {
    final timerString = _formatDuration(_remaining);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isExpired ? const Color(0xFFFFEBEE) : ConsultationTheme.lightBlueBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpired ? const Color(0xFFFFCDD2) : ConsultationTheme.lightBlueBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 20,
            color: _isExpired ? ConsultationTheme.red : ConsultationTheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isExpired ? 'Status batas waktu:' : 'Selesaikan pembayaran dalam',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _isExpired ? ConsultationTheme.red : ConsultationTheme.primary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isExpired ? const Color(0xFFFFCDD2) : ConsultationTheme.lightBlueBorder,
                width: 1,
              ),
            ),
            child: Text(
              _isExpired ? '00:00:00' : timerString,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _isExpired ? ConsultationTheme.red : ConsultationTheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu nomor VA sebagai fokus: gradient biru tua ke teal (#1F5C7A ke #2E85A8),
  /// radius 20, bayangan lembut.
  /// Isi: label mikro putih transparan "NOMOR VIRTUAL ACCOUNT · BANK [NAMA BANK]",
  /// nomor VA besar putih bold 24 dengan letterSpacing,
  /// baris bawah berisi "Total Rp55.000" (kecil) di kiri serta tombol "Salin" putih (teks biru tua, ikon salin, radius 12) di kanan.
  Widget _buildVACard(ConsultationModel c) {
    final bankName = c.paymentMethodName.toUpperCase();
    final vaNumber = c.virtualAccountNumber;
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
          // Label mikro putih transparan
          Text(
            'NOMOR VIRTUAL ACCOUNT · BANK $bankName',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 12),

          // Nomor VA Besar putih bold 24 dengan letterSpacing
          SelectableText(
            vaNumber,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 16),

          // Baris bawah: Total di kiri + tombol "Salin" putih di kanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalStr,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _copyVA(context, vaNumber),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.copy_rounded,
                        size: 15,
                        color: ConsultationTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Salin',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ConsultationTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Kartu "Detail Pembayaran": label mikro, baris Bank (nama/logo), Nama Dokter,
  /// Total Transaksi (teal), Order ID, Batas Waktu Bayar (merah #B42318), dipisah garis #F1E8DA.
  Widget _buildDetailPembayaranCard(ConsultationModel c) {
    final deadlineStr = AppDateFormatter.formatDateTime(c.effectivePaymentExpiresAt);

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MicroLabel('DETAIL PEMBAYARAN'),
          const SizedBox(height: 12),

          // Baris Bank
          _buildDetailRow(
            label: 'Bank',
            value: c.paymentMethodName,
          ),
          const SectionDivider(verticalPadding: 8),

          // Baris Nama Dokter
          _buildDetailRow(
            label: 'Nama Dokter',
            value: c.doctorName,
          ),
          const SectionDivider(verticalPadding: 8),

          // Baris Total Transaksi (teal)
          _buildDetailRow(
            label: 'Total Transaksi',
            value: formatRupiah(c.totalFee),
            valueColor: ConsultationTheme.teal,
            isBold: true,
          ),
          const SectionDivider(verticalPadding: 8),

          // Baris Order ID
          _buildDetailRow(
            label: 'Order ID',
            value: c.orderId.isNotEmpty ? c.orderId : '-',
          ),
          const SectionDivider(verticalPadding: 8),

          // Baris Batas Waktu Bayar (merah #B42318)
          _buildDetailRow(
            label: 'Batas Waktu Bayar',
            value: deadlineStr,
            valueColor: ConsultationTheme.darkRed,
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
      ],
    );
  }

  /// Bar bawah melekat dengan tombol "Saya Mengerti"
  Widget _buildBottomBar(BuildContext context) {
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isConfirming
              ? null
              : (_isExpired
                  ? () => _onBuatPesananBaru(context)
                  : () => _onMengerti(context)),
          style: ElevatedButton.styleFrom(
            backgroundColor: ConsultationTheme.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: ConsultationTheme.disabledButton,
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isConfirming
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _isExpired ? 'Buat Pesanan Baru' : 'Saya Mengerti',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

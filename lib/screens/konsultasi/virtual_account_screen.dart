import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../models/consultation_model.dart';
import '../../services/consultation_service.dart';
import '../../widgets/app_scaffold.dart';

/// Layar Nomor Virtual Account — tampil setelah booking dibuat.
class VirtualAccountScreen extends StatefulWidget {
  final String consultationId;

  const VirtualAccountScreen({super.key, required this.consultationId});

  @override
  State<VirtualAccountScreen> createState() => _VirtualAccountScreenState();
}

class _VirtualAccountScreenState extends State<VirtualAccountScreen> {
  final ConsultationService _consultationService = ConsultationService();
  ConsultationModel? _consultation;
  bool _isLoading = true;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _loadConsultation();
  }

  Future<void> _loadConsultation() async {
    final data =
        await _consultationService.fetchById(widget.consultationId);
    if (mounted) {
      setState(() {
        _consultation = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _onMengerti(BuildContext context) async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);
    // Capture navigator dan messenger sebelum async gap
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // SIMULASI: tandai pembayaran sebagai lunas
      // TODO(payment-gateway): Hapus ini. Status paid seharusnya di-set
      // melalui webhook dari payment gateway (Midtrans/Xendit), bukan dari client.
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali',
        ),
        title: const Text('Nomor Virtual Account'),
        centerTitle: true,
      ),
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

                // ── Ikon sukses ──
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 52,
                    color: AppColors.successGreen,
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Virtual Account Berhasil Dibuat!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Salin nomor VA di bawah dan selesaikan pembayaran',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.neutralGray,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

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

        // ── Tombol Saya Mengerti ──
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
              label: 'Saya Mengerti dan lanjutkan',
              button: true,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isConfirming ? null : () => _onMengerti(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                      : const Text(
                          'Saya Mengerti',
                          style: TextStyle(
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

  Widget _buildVACard(
      BuildContext context, String vaNumber, String bankName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Text(
                'Nomor Virtual Account ($bankName)',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.neutralGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  vaNumber,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryText,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              // Tombol Salin
              Semantics(
                label: 'Salin nomor virtual account',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () => _copyVA(context, vaNumber),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Salin'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(
                      fontSize: 13,
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
    final deadlineStr = _formatDateTime(c.paymentDeadline);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
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
          _DetailRow(label: 'Bank', value: c.paymentMethodName),
          const Divider(height: 16, color: Color(0xFFF0F4F7)),
          _DetailRow(label: 'Nama Dokter', value: c.doctorName),
          const Divider(height: 16, color: Color(0xFFF0F4F7)),
          _DetailRow(
            label: 'Total Transaksi',
            value: _formatRupiah(c.totalFee),
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

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day}/${dt.month}/${dt.year} – $h.$m $ampm';
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

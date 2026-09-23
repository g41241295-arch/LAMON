import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../widgets/app_scaffold.dart';
import 'widgets/doctor_card.dart';

/// Layar Detail Dokter — menampilkan profil lengkap satu dokter.
class DetailDokterScreen extends StatefulWidget {
  final String doctorId;
  final DoctorModel? initialDoctor; // argumen dari navigasi kartu

  const DetailDokterScreen({
    super.key,
    required this.doctorId,
    this.initialDoctor,
  });

  @override
  State<DetailDokterScreen> createState() => _DetailDokterScreenState();
}

class _DetailDokterScreenState extends State<DetailDokterScreen> {
  final DoctorService _doctorService = DoctorService();
  DoctorModel? _doctor;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialDoctor != null) {
      _doctor = widget.initialDoctor;
      _isLoading = false;
    } else {
      _loadDoctor();
    }
  }

  Future<void> _loadDoctor() async {
    try {
      final doc = await _doctorService.fetchById(widget.doctorId);
      if (mounted) {
        setState(() {
          _doctor = doc;
          _isLoading = false;
          if (doc == null) _error = 'Data dokter tidak ditemukan.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat data: $e';
        });
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
        title: const Text('Konsultasi Dokter'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: AppColors.neutralGray)),
                  ),
                )
              : _buildContent(context, _doctor!),
    );
  }

  Widget _buildContent(BuildContext context, DoctorModel doctor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Foto besar ──
          DoctorAvatar(photoUrl: doctor.photoUrl, size: 100),
          const SizedBox(height: 14),

          // ── Nama ──
          Text(
            doctor.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // ── Spesialisasi + pengalaman ──
          Text(
            doctor.specialtyDisplay,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutralGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // ── Jam Operasional ──
          if (doctor.operatingHours.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: doctor.operatingHours
                  .map((h) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 5),
                            Text(
                              h.display,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),

          const SizedBox(height: 16),

          // ── Harga (highlight box) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primaryLight.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Harga Konsultasi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  _formatRupiah(doctor.price),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Detail Info ──
          _buildInfoCard([
            _InfoRow(
              icon: Icons.school_rounded,
              label: 'Alumni',
              value: doctor.alumni.isNotEmpty ? doctor.alumni : '-',
            ),
            _InfoRow(
              icon: Icons.local_hospital_rounded,
              label: 'Tempat Praktik',
              value: doctor.practiceLocation.isNotEmpty
                  ? doctor.practiceLocation
                  : '-',
            ),
            _InfoRow(
              icon: Icons.badge_rounded,
              label: 'Nomor STR',
              value: doctor.strNumber.isNotEmpty ? doctor.strNumber : '-',
            ),
          ]),

          const SizedBox(height: 24),

          // ── Tombol Chat Dokter ──
          Semantics(
            label: 'Mulai Chat dengan ${doctor.name}',
            button: true,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/konsultasi/pembayaran/${doctor.id}',
                    arguments: doctor,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Chat Dokter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        children: rows
            .expand((row) => [
                  row,
                  if (rows.last != row)
                    Divider(
                      height: 20,
                      color: AppColors.lightGray.withValues(alpha: 0.8),
                    ),
                ])
            .toList(),
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutralGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

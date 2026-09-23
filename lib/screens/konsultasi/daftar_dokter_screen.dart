import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../widgets/app_scaffold.dart';
import 'widgets/doctor_card.dart';

/// Layar Daftar Dokter — entry point fitur Konsultasi Dokter.
/// Menampilkan dua tab: "Pilih Dokter" (semua) dan "Rekomendasi" (isRecommended: true).
class DaftarDokterScreen extends StatefulWidget {
  const DaftarDokterScreen({super.key});

  @override
  State<DaftarDokterScreen> createState() => _DaftarDokterScreenState();
}

class _DaftarDokterScreenState extends State<DaftarDokterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final DoctorService _doctorService = DoctorService();
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runSeed() async {
    setState(() => _isSeeding = true);
    try {
      await _doctorService.seedDoctors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data dokter berhasil di-seed!'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Seed gagal: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  void _showJamLainnya(BuildContext context, DoctorModel doctor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _JamLainnyaSheet(doctor: doctor),
    );
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
        title: const Text('Chat Dokter'),
        centerTitle: true,
        actions: [
          // Tombol seed HANYA muncul di debug mode
          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _isSeeding
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.cloud_upload_outlined),
                      tooltip: '[DEBUG] Seed data dokter',
                      onPressed: _runSeed,
                    ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.neutralGray,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: 'Pilih Dokter'),
            Tab(text: 'Rekomendasi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Semua dokter
          _DoctorListTab(
            stream: _doctorService.watchAll(),
            onTapJamLainnya: _showJamLainnya,
          ),
          // Tab 2: Rekomendasi
          _DoctorListTab(
            stream: _doctorService.watchRecommended(),
            onTapJamLainnya: _showJamLainnya,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab list dokter
// ─────────────────────────────────────────────────────────────────────────────

class _DoctorListTab extends StatelessWidget {
  final Stream<List<DoctorModel>> stream;
  final void Function(BuildContext, DoctorModel) onTapJamLainnya;

  const _DoctorListTab({
    required this.stream,
    required this.onTapJamLainnya,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DoctorModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.neutralGray),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat data dokter.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.neutralGray),
                  ),
                ],
              ),
            ),
          );
        }

        final doctors = snapshot.data ?? [];

        if (doctors.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.medical_services_outlined,
                      size: 64,
                      color: AppColors.neutralGray.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada dokter tersedia.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutralGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Tap ikon upload di pojok kanan atas\nuntuk mengisi data dokter (debug only).',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.neutralGray),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            return DoctorCard(
              doctor: doctor,
              onTapCard: () {
                Navigator.pushNamed(
                  context,
                  '/konsultasi/dokter/${doctor.id}',
                  arguments: doctor,
                );
              },
              onTapChatButton: () {
                Navigator.pushNamed(
                  context,
                  '/konsultasi/pembayaran/${doctor.id}',
                  arguments: doctor,
                );
              },
              onTapJamLainnya: doctor.operatingHours.length > 1
                  ? () => onTapJamLainnya(context, doctor)
                  : null,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: Jam Lainnya
// ─────────────────────────────────────────────────────────────────────────────

class _JamLainnyaSheet extends StatelessWidget {
  final DoctorModel doctor;
  const _JamLainnyaSheet({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Jam Operasional\n${doctor.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          ...doctor.operatingHours.map((h) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      h.display,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

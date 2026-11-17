import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/doctor_theme.dart';
import '../../models/consultation_model.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_date_formatter.dart';
import '../konsultasi/chat_dokter_screen.dart';

/// Halaman Menunggu Konfirmasi (Design System Formal LAMON - Gambar 5)
/// Menampilkan daftar permintaan konsultasi yang menunggu respons dokter.
class DoctorWaitingConfirmationScreen extends StatefulWidget {
  final String doctorId;
  final List<ConsultationModel>? initialConsultations;

  const DoctorWaitingConfirmationScreen({
    super.key,
    required this.doctorId,
    this.initialConsultations,
  });

  @override
  State<DoctorWaitingConfirmationScreen> createState() =>
      _DoctorWaitingConfirmationScreenState();
}

class _DoctorWaitingConfirmationScreenState
    extends State<DoctorWaitingConfirmationScreen> {
  final DoctorService _doctorService = DoctorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorTheme.scaffoldBg,
      body: SafeArea(
        child: StreamBuilder<List<ConsultationModel>>(
          stream: _doctorService.watchDoctorConsultations(widget.doctorId),
          initialData: widget.initialConsultations,
          builder: (context, snapshot) {
            final all = snapshot.data ?? widget.initialConsultations ?? [];
            final waitingList = all.where((c) {
              return c.paymentStatus == PaymentStatus.paid && c.isWaiting;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, waitingList.length),
                Expanded(
                  child: waitingList.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                          itemCount: waitingList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = waitingList[index];
                            return _buildRequestCard(context, item);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 14),
      decoration: const BoxDecoration(
        color: DoctorTheme.scaffoldBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 32,
                  color: DoctorTheme.primary,
                ),
                splashRadius: 24,
                tooltip: 'Kembali',
              ),
              Text(
                'Menunggu Konfirmasi',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: DoctorTheme.primaryText,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              '$count permintaan konsultasi menunggu respons Anda',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: DoctorTheme.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, ConsultationModel item) {
    final dateStr = AppDateFormatter.formatScheduledDateTime(
      item.effectiveScheduledDate,
      item.scheduledTime,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF2D9B0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Atas: Avatar Inisial + Nama + Jadwal + Badge Baru
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Bulat Inisial Pasien (Krem / Cokelat)
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: DoctorTheme.patientAvatarBeige,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  item.patientInitials,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DoctorTheme.patientAvatarBrown,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nama Pasien & Jadwal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayPatientName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DoctorTheme.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateStr,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: DoctorTheme.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Badge "Baru"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DoctorTheme.konsultasiChipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Baru',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DoctorTheme.patientAvatarBrown,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Baris Tombol Seimbang (Tolak & Terima)
          Row(
            children: [
              // Tombol Tolak (Outline Deep Teal)
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => _handleReject(context, item),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: DoctorTheme.primary,
                        width: 1.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
                      'Tolak',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DoctorTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Tombol Terima (Solid Deep Teal)
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _handleAccept(context, item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DoctorTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Terima',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFDCEBF3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                size: 34,
                color: DoctorTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada permintaan baru',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DoctorTheme.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Permintaan konsultasi pasien akan muncul di sini',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: DoctorTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAccept(
    BuildContext context,
    ConsultationModel item,
  ) async {
    try {
      await _doctorService.confirmConsultation(
        patientUid: item.patientUid,
        consultationId: item.id,
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDokterScreen(
              consultationId: item.id,
              isDoctor: true,
              patientUid: item.patientUid,
              initialConsultation: item.copyWith(
                status: 'active',
                doctorConfirmedAt: DateTime.now(),
                unreadForDoctor: 0,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[DoctorWaitingConfirmation] Error accepting: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menerima konsultasi: $e'),
            backgroundColor: DoctorTheme.alertRed,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    ConsultationModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Tolak Permintaan Konsultasi?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: DoctorTheme.primaryText,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menolak permintaan konsultasi dari ${item.displayPatientName}?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: DoctorTheme.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: DoctorTheme.secondaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorTheme.alertRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Tolak',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      String pUid = item.patientUid.trim();
      if (pUid.isEmpty) {
        final snap = await FirebaseFirestore.instance
            .collectionGroup('consultations')
            .where(FieldPath.documentId, isEqualTo: item.id)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final segments = snap.docs.first.reference.path.split('/');
          final idx = segments.indexOf('users');
          if (idx != -1 && idx + 1 < segments.length) {
            pUid = segments[idx + 1];
          }
        }
      }

      if (pUid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(pUid)
            .collection('consultations')
            .doc(item.id)
            .update({
          'status': 'cancelled',
          'unreadForDoctor': 0,
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan konsultasi telah ditolak'),
            backgroundColor: DoctorTheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('[DoctorWaitingConfirmation] Error rejecting: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menolak konsultasi: $e'),
            backgroundColor: DoctorTheme.alertRed,
          ),
        );
      }
    }
  }
}

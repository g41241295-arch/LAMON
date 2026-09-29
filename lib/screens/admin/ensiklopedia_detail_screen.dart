import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../models/ensiklopedia_entry_model.dart';
import '../../services/ensiklopedia_service.dart';
import '../../utils/app_exception.dart';
import '../../widgets/admin/admin_widgets.dart';
import 'ensiklopedia_form_screen.dart';

class EnsiklopediaDetailScreen extends StatefulWidget {
  final String entryId;
  final String adminName;
  final String adminId;

  const EnsiklopediaDetailScreen({
    super.key,
    required this.entryId,
    required this.adminName,
    required this.adminId,
  });

  @override
  State<EnsiklopediaDetailScreen> createState() => _EnsiklopediaDetailScreenState();
}

class _EnsiklopediaDetailScreenState extends State<EnsiklopediaDetailScreen> {
  final EnsiklopediaService _service = EnsiklopediaService();

  String _formatTanggal(DateTime? dt) {
    if (dt == null) return '\u2013';
    const bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  Future<void> _handleDelete(EnsiklopediaEntry entry) async {
    bool isLoading = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => DeleteConfirmDialog(
          entryName: entry.istilah,
          isLoading: isLoading,
          onDelete: () async {
            setS(() => isLoading = true);
            try {
              await _service.deleteEntry(
                entry.id,
                entry.istilah,
                widget.adminName,
                widget.adminId,
              );
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            } on AppException catch (e) {
              if (ctx.mounted) {
                Navigator.of(ctx).pop(false);
                _showError(ctx, e.message);
              }
            } catch (_) {
              if (ctx.mounted) {
                Navigator.of(ctx).pop(false);
                _showError(ctx, 'Gagal menghapus entri. Silakan coba lagi.');
              }
            }
          },
        ),
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Entri "${entry.istilah}" berhasil dihapus.',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      // Kembali ke list setelah hapus
      Navigator.of(context).pop();
    }
  }

  void _showError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppColors.adminRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const AdminAppBar(title: 'Detail Entri'),
      body: AdminGradientBackground(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('encyclopedia')
              .doc(widget.entryId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.adminBlue));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded, size: 56, color: AppColors.adminBlue.withValues(alpha: 0.35)),
                    const SizedBox(height: 12),
                    Text(
                      'Entri tidak ditemukan.',
                      style: GoogleFonts.poppins(fontSize: 15, color: AppColors.neutralGray),
                    ),
                  ],
                ),
              );
            }

            final entry = EnsiklopediaEntry.fromFirestore(snapshot.data!);

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainCard(entry),
                        const SizedBox(height: 14),
                        _buildMetadataCard(entry),
                      ],
                    ),
                  ),
                ),

                // Tombol bawah
                _buildBottomActions(entry),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainCard(EnsiklopediaEntry entry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Istilah
          Text(
            entry.istilah,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.adminBlue,
            ),
          ),

          // "Juga dikenal sebagai" — sembunyikan jika kosong
          if (entry.namaLain != null && entry.namaLain!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Juga dikenal sebagai : ${entry.namaLain}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.adminOrangeText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Chip kategori
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.adminBlueLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.adminBlue.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              entry.kategori,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.adminBlue,
              ),
            ),
          ),

          const SizedBox(height: 16),
          _sectionLabel('Definisi Singkat'),
          const SizedBox(height: 4),
          Text(
            entry.definisiSingkat,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.primaryText,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 14),
          _sectionLabel('Penjelasan Lengkap'),
          const SizedBox(height: 4),
          Text(
            entry.penjelasanLengkap,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.primaryText,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.adminBlue,
      ),
    );
  }

  Widget _buildMetadataCard(EnsiklopediaEntry entry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metadata',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.adminOrangeText,
            ),
          ),
          const SizedBox(height: 10),
          ..._buildMetadataRows(entry),
        ],
      ),
    );
  }

  List<Widget> _buildMetadataRows(EnsiklopediaEntry entry) {
    final rows = <Widget>[];
    final type = entry.createdByType;

    if (type == 'admin') {
      // "Dibuat : {tanggal} oleh {nama admin}"
      rows.add(_metaRow(
        'Dibuat : ${_formatTanggal(entry.createdAt)} oleh ${entry.createdBy}',
        isLink: false,
      ));
      // "Terakhir diubah : {tanggal} oleh {nama}" jika updatedAt ada
      if (entry.updatedAt != null) {
        rows.add(const SizedBox(height: 4));
        rows.add(_metaRow(
          'Terakhir diubah : ${_formatTanggal(entry.updatedAt)} oleh ${entry.updatedBy ?? '–'}',
          isLink: false,
          isDim: true,
        ));
      }
    } else if (type == 'dokter') {
      // Nama dokter bergaya link/underline, tanpa baris diubah jika belum pernah diedit
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dibuat : ${_formatTanggal(entry.createdAt)} oleh ',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.brownSubtext),
          ),
          Text(
            entry.createdBy,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.adminOrangeText,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.adminOrangeText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ));
      if (entry.updatedAt != null) {
        rows.add(const SizedBox(height: 4));
        rows.add(_metaRow(
          'Terakhir diubah : ${_formatTanggal(entry.updatedAt)} oleh ${entry.updatedBy ?? '–'}',
          isLink: false,
          isDim: true,
        ));
      }
    } else {
      // redaksi
      rows.add(_metaRow(
        'Dibuat : ${_formatTanggal(entry.createdAt)} oleh Redaksi Holodoc',
        isLink: false,
      ));
      if (entry.updatedAt != null) {
        rows.add(const SizedBox(height: 4));
        rows.add(_metaRow(
          'Terakhir diubah : ${_formatTanggal(entry.updatedAt)} oleh ${entry.updatedBy ?? '–'}',
          isLink: false,
          isDim: true,
        ));
      }
    }

    return rows;
  }

  Widget _metaRow(String text, {bool isLink = false, bool isDim = false}) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        color: isDim
            ? AppColors.neutralGray
            : AppColors.brownSubtext,
        decoration: isLink ? TextDecoration.underline : null,
        fontWeight: isDim ? FontWeight.w400 : FontWeight.w500,
      ),
    );
  }

  Widget _buildBottomActions(EnsiklopediaEntry entry) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF4C8),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          // Hapus
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleDelete(entry),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(
                'Hapus',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.adminRed,
                side: const BorderSide(color: AppColors.adminRed, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Edit
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EnsiklopediaFormScreen(
                    initialEntry: entry,
                    adminName: widget.adminName,
                    adminId: widget.adminId,
                  ),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(
                'Edit',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

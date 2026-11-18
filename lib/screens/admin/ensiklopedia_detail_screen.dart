import 'dart:convert';
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
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Data gastropedia "${entry.istilah}" berhasil dihapus.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        content: Text(
          msg,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Kembali (bulat putih)
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.softBlue, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ),

          // Pill Judul: disamakan persis dengan pill "Catat Makanan" Pengguna
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7D6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE8D7A5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Detail Gastropedia',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C4E68),
                  ),
                ),
              ),
            ),
          ),

          // Penyeimbang lebar kanan
          const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.bgGradientTop,
          AppColors.bgGradientMiddle,
          AppColors.bgGradientBottom,
        ],
      ),
      header: _buildHeader(),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('encyclopedia')
            .doc(widget.entryId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.textPrimary),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.softBlue, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Data gastropedia tidak ditemukan.',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final entry = EnsiklopediaEntry.fromFirestore(snapshot.data!);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainCard(entry),
                      const SizedBox(height: 20),
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
    );
  }

  Widget _buildMainCard(EnsiklopediaEntry entry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBlue, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          // "Juga dikenal sebagai" — sembunyikan jika kosong
          if (entry.namaLain != null && entry.namaLain!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Juga dikenal sebagai : ${entry.namaLain}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          if ((entry.imageBase64 != null && entry.imageBase64!.isNotEmpty) ||
              (entry.imageAsset != null && entry.imageAsset!.isNotEmpty)) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (() {
                try {
                  final b64 = entry.imageBase64;
                  if (b64 != null && b64.isNotEmpty) {
                    return Image.memory(
                      base64Decode(b64),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    );
                  }
                } catch (_) {}
                final url = entry.imageAsset ?? '';
                if (url.startsWith('http')) {
                  return Image.network(
                    url,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  );
                }
                return Image.asset(
                  url,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                );
              })(),
            ),
          ],

          const SizedBox(height: 12),

          // Chip kategori & status (radius 10, warna dari palet)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  entry.kategori,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: entry.status == 'terbit'
                      ? AppColors.textPrimary
                      : AppColors.bgAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  entry.status == 'terbit' ? 'Terbit' : 'Draft',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: entry.status == 'terbit'
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (entry.isRecommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.bgAccent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accentGold, width: 1),
                  ),
                  child: Text(
                    '★ Rekomendasi',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          _sectionLabel('Definisi Singkat'),
          const SizedBox(height: 4),
          Text(
            entry.definisiSingkat,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 16),
          _sectionLabel('Penjelasan Lengkap'),
          const SizedBox(height: 4),
          Text(
            entry.penjelasanLengkap,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),

          if (entry.manfaat.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionLabel('Manfaat'),
            const SizedBox(height: 4),
            ...entry.manfaat.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        m,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (entry.kandungan.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionLabel('Kandungan Gizi / Senyawa'),
            const SizedBox(height: 4),
            ...entry.kandungan.map(
              (k) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        k,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Informasi Nutrisi
          const SizedBox(height: 16),
          _sectionLabel('Informasi Nutrisi (${entry.servingUnit})'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _nutrientChip('Kalori', '${entry.calories} kkal'),
              _nutrientChip('Protein', '${entry.protein}g'),
              _nutrientChip('Karbo', '${entry.carbs}g'),
              _nutrientChip('Lemak', '${entry.fat}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutrientChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildMetadataCard(EnsiklopediaEntry entry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBlue, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metadata',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildMetadataRows(entry),
        ],
      ),
    );
  }

  List<Widget> _buildMetadataRows(EnsiklopediaEntry entry) {
    final rows = <Widget>[];
    final type = entry.createdByType;

    if (type == 'admin') {
      rows.add(_metaRow(
        'Dibuat : ${_formatTanggal(entry.createdAt)} oleh ${entry.createdBy}',
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
    } else if (type == 'dokter') {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dibuat : ${_formatTanggal(entry.createdAt)} oleh ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            entry.createdBy,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textPrimary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textPrimary,
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
        fontSize: 13,
        color: AppColors.textSecondary,
        decoration: isLink ? TextDecoration.underline : null,
        fontWeight: isDim ? FontWeight.normal : FontWeight.w500,
      ),
    );
  }

  Widget _buildBottomActions(EnsiklopediaEntry entry) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: const Border(
          top: BorderSide(color: AppColors.softBlue, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hapus (Tombol Sekunder Outline Navy)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleDelete(entry),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(
                'Hapus',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side:
                    const BorderSide(color: AppColors.textPrimary, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Edit (Tombol Utama Navy Solid)
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
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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

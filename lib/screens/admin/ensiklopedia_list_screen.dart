import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../models/ensiklopedia_entry_model.dart';
import '../../services/ensiklopedia_service.dart';
import '../../widgets/admin/admin_widgets.dart';
import 'ensiklopedia_form_screen.dart';
import 'ensiklopedia_detail_screen.dart';

class EnsiklopediaListScreen extends StatefulWidget {
  const EnsiklopediaListScreen({super.key});

  @override
  State<EnsiklopediaListScreen> createState() => _EnsiklopediaListScreenState();
}

class _EnsiklopediaListScreenState extends State<EnsiklopediaListScreen> {
  final EnsiklopediaService _service = EnsiklopediaService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'Semua';

  String? _adminName;
  String? _adminId;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAdminInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _adminId = user.uid;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _adminName = (data['nama'] ?? data['name'] ?? 'Admin').toString();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _adminName = 'Admin');
    }
  }

  List<EnsiklopediaEntry> _applyFilters(List<EnsiklopediaEntry> all) {
    List<EnsiklopediaEntry> result = all;

    // Filter berdasarkan kategori
    if (_activeFilter != 'Semua') {
      result = result.where((e) {
        return e.kategori.toLowerCase() == _activeFilter.toLowerCase();
      }).toList();
    }

    // Search cocokkan istilah dan definisi singkat
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) {
        return e.istilah.toLowerCase().contains(q) ||
            e.definisiSingkat.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  Future<void> _deleteEntry(EnsiklopediaEntry entry) async {
    if (_adminName == null || _adminId == null) return;

    bool isLoading = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return DeleteConfirmDialog(
            entryName: entry.istilah,
            isLoading: isLoading,
            onDelete: () async {
              setS(() => isLoading = true);
              try {
                await _service.deleteEntry(entry.id, entry.istilah, _adminName!, _adminId!);
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.of(ctx).pop(false);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    _errorSnackbar('Gagal menghapus: ${e.toString()}'),
                  );
                }
              }
            },
          );
        });
      },
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
    }
  }

  SnackBar _errorSnackbar(String msg) => SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      );

  Future<void> _seedInitialData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sinkron Data Gastropedia',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Akan menambahkan 19 data bawaan (makanan, buah, sayuran) ke database jika belum ada. Dokumen yang sudah diedit atau ditambahkan admin tidak akan ditimpa atau diduplikasi.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.textPrimary, width: 1.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sinkronkan',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final count = await _service.seedGastropediaData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Berhasil menyinkronkan $count data baru ke database.'
                : 'Seluruh data bawaan sudah tersinkron sebelumnya.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _errorSnackbar('Gagal menyinkronkan data: $e'),
      );
    }
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
                  'Kelola Gastropedia',
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

          // Tombol Sinkron Data Bawaan di kanan
          Tooltip(
            message: 'Sinkron 19 Data Bawaan',
            child: InkWell(
              onTap: _seedInitialData,
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
                    Icons.cloud_download_outlined,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
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
      body: StreamBuilder<List<EnsiklopediaEntry>>(
        stream: _service.streamEnsiklopedia(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.textPrimary),
            );
          }

          final all = snapshot.data ?? [];
          final filtered = _applyFilters(all);

          // Hitung jumlah per kategori (case-insensitive)
          int countMakanan = all
              .where((e) => e.kategori.toLowerCase() == 'makanan')
              .length;
          int countBuah =
              all.where((e) => e.kategori.toLowerCase() == 'buah').length;
          int countSayuran =
              all.where((e) => e.kategori.toLowerCase() == 'sayuran').length;

          final filters = [
            ('Semua', 'Semua (${all.length})'),
            ('Makanan', 'Makanan ($countMakanan)'),
            ('Buah', 'Buah ($countBuah)'),
            ('Sayuran', 'Sayuran ($countSayuran)'),
          ];

          return Column(
            children: [
              // Search + filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminSearchBar(
                      hint: 'Cari makanan, buah, atau sayuran...',
                      controller: _searchCtrl,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.trim()),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filters.map((f) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AdminFilterChip(
                              label: f.$2,
                              isActive: _activeFilter == f.$1,
                              onTap: () =>
                                  setState(() => _activeFilter = f.$1),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty(all.isEmpty)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _EntryCard(
                          entry: filtered[i],
                          adminName: _adminName ?? 'Admin',
                          adminId: _adminId ?? '',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EnsiklopediaDetailScreen(
                                entryId: filtered[i].id,
                                adminName: _adminName ?? 'Admin',
                                adminId: _adminId ?? '',
                              ),
                            ),
                          ),
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EnsiklopediaFormScreen(
                                initialEntry: filtered[i],
                                adminName: _adminName ?? 'Admin',
                                adminId: _adminId ?? '',
                              ),
                            ),
                          ),
                          onDelete: () => _deleteEntry(filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty(bool noData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
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
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.softBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  noData ? Icons.menu_book_outlined : Icons.search_off_rounded,
                  size: 28,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                noData ? 'Belum ada data gastropedia' : 'Tidak ditemukan',
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!noData) ...[
                const SizedBox(height: 6),
                Text(
                  'Coba kata kunci lain atau ubah filter.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _seedInitialData,
                  icon: const Icon(Icons.cloud_download_outlined, size: 18),
                  label: Text(
                    'Muat 19 Data Bawaan',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final EnsiklopediaEntry entry;
  final String adminName;
  final String adminId;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.entry,
    required this.adminName,
    required this.adminId,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter =
        entry.istilah.isNotEmpty ? entry.istilah[0].toUpperCase() : '?';

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.softBlue.withOpacity(0.75),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail gambar atau kotak huruf awal (radius 12)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 52,
                  height: 52,
                  color: AppColors.softBlue,
                  child: (() {
                    try {
                      final b64 = entry.imageBase64;
                      if (b64 != null && b64.isNotEmpty) {
                        return Image.memory(
                          base64Decode(b64),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        );
                      }
                    } catch (_) {}
                    final url = entry.imageAsset;
                    if (url != null && url.isNotEmpty) {
                      if (url.startsWith('http')) {
                        return Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              firstLetter,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }
                      return Image.asset(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            firstLetter,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: Text(
                        firstLetter,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  })(),
                ),
              ),
              const SizedBox(width: 14),
              // Istilah + kategori/draft badge + definisi singkat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.istilah,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (entry.status == 'draft')
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bgAccent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.accentGold,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Draft',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            entry.kategori,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.definisiSingkat,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Ikon aksi (Edit & Hapus)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIcon(
                    icon: Icons.edit_outlined,
                    backgroundColor: AppColors.softBlue,
                    borderColor: AppColors.softBlue,
                    iconColor: AppColors.textPrimary,
                    tooltip: 'Edit',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 6),
                  _ActionIcon(
                    icon: Icons.delete_outline_rounded,
                    backgroundColor: AppColors.surfaceCard,
                    borderColor: AppColors.softBlue,
                    iconColor: AppColors.textPrimary,
                    tooltip: 'Hapus',
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Center(
              child: Icon(icon, size: 18, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

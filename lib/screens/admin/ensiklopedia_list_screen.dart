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

    // Filter huruf awal
    if (_activeFilter != 'Semua') {
      result = result.where((e) {
        final first = e.istilah.isNotEmpty ? e.istilah[0].toUpperCase() : '';
        if (_activeFilter == 'A-D') return first.compareTo('A') >= 0 && first.compareTo('E') < 0;
        if (_activeFilter == 'E-M') return first.compareTo('E') >= 0 && first.compareTo('N') < 0;
        if (_activeFilter == 'N-Z') return first.compareTo('N') >= 0;
        return true;
      }).toList();
    }

    // Search cocokkan istilah DAN namaLain
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) {
        return e.istilah.toLowerCase().contains(q) ||
            (e.namaLain?.toLowerCase().contains(q) ?? false);
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
    }
  }

  SnackBar _errorSnackbar(String msg) => SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppColors.adminRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: AdminAppBar(
        title: 'Kelola Ensiklopedia',
        trailing: IconButton(
          icon: const Icon(Icons.add_rounded, size: 26),
          color: AppColors.adminBlue,
          tooltip: 'Tambah Entri',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EnsiklopediaFormScreen(
                adminName: _adminName ?? 'Admin',
                adminId: _adminId ?? '',
              ),
            ),
          ),
        ),
      ),
      body: AdminGradientBackground(
        child: StreamBuilder<List<EnsiklopediaEntry>>(
          stream: _service.streamEnsiklopedia(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.adminBlue));
            }

            final all = snapshot.data ?? [];
            final filtered = _applyFilters(all);
            final filters = ['Semua', 'A-D', 'E-M', 'N-Z'];

            return Column(
              children: [
                // Search + filter
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Column(
                    children: [
                      AdminSearchBar(
                        hint: 'Cari istilah medis',
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: filters.map((f) {
                            final label = f == 'Semua' ? 'Semua (${all.length})' : f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AdminFilterChip(
                                label: label,
                                isActive: _activeFilter == f,
                                onTap: () => setState(() => _activeFilter = f),
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
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
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
      ),
    );
  }

  Widget _buildEmpty(bool noData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noData ? Icons.menu_book_outlined : Icons.search_off_rounded,
              size: 56,
              color: AppColors.adminBlue.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              noData ? 'Belum ada entri' : 'Tidak ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText.withValues(alpha: 0.6),
              ),
            ),
            if (!noData) ...[
              const SizedBox(height: 6),
              Text(
                'Coba kata kunci lain atau ubah filter.',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.neutralGray),
                textAlign: TextAlign.center,
              ),
            ],
          ],
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
    final firstLetter = entry.istilah.isNotEmpty ? entry.istilah[0].toUpperCase() : '?';

    return Material(
      color: AppColors.adminCardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.07), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Kotak huruf awal
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.adminBlueDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    firstLetter,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Istilah + definisi singkat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.istilah,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.definisiSingkat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.neutralGray,
                      ),
                    ),
                  ],
                ),
              ),
              // Ikon aksi
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIcon(
                    icon: Icons.edit_outlined,
                    color: AppColors.adminBlue,
                    tooltip: 'Edit',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 4),
                  _ActionIcon(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.adminRed,
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
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

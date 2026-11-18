import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/berita_article_model.dart';
import '../../services/berita/berita_service.dart';
import '../../widgets/admin/admin_widgets.dart';
import '../../widgets/berita/berita_image.dart';
import 'berita_form_screen.dart';

class BeritaListAdminScreen extends StatefulWidget {
  final String adminName;
  final String adminId;

  const BeritaListAdminScreen({
    super.key,
    this.adminName = 'Admin',
    this.adminId = '',
  });

  @override
  State<BeritaListAdminScreen> createState() => _BeritaListAdminScreenState();
}

class _BeritaListAdminScreenState extends State<BeritaListAdminScreen> {
  final BeritaService _service = BeritaService();
  final TextEditingController _searchCtrl = TextEditingController();

  String _query = '';
  String _activeStatus = 'semua'; // 'semua' | 'terbit' | 'draft'
  String _deletingId = '';

  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _checkAndAutoSeed();
  }

  Future<void> _checkAndAutoSeed() async {
    try {
      await _service.ensureAutoSeeded();
    } catch (e) {
      debugPrint('[KelolaBerita] Auto-seeding check error: $e');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Pemulihan Berita Bawaan ────────────────────────────────────────────────

  Future<void> _onRestoreArticles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Pulihkan Berita Bawaan?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Tindakan ini akan membuat kembali artikel dari 9 berita bawaan yang belum ada di Firestore tanpa menimpa atau menghapus artikel lain.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.textPrimary, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
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
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Pulihkan',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSeeding = true);
    try {
      final res = await _service.restoreStaticArticles();
      if (!mounted) return;
      final msg = '${res.restored} berita dipulihkan, ${res.alreadyExist} sudah ada.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      debugPrint('[KelolaBerita] Gagal pulihkan artikel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Gagal memulihkan berita: $e',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  // ── Filter dan Pencarian ───────────────────────────────────────────────────

  List<BeritaArticle> _filtered(List<BeritaArticle> all) {
    return all.where((a) {
      // 1. Filter status (Semua / Terbit / Draft)
      if (_activeStatus == 'terbit' && a.status != 'terbit') return false;
      if (_activeStatus == 'draft' && a.status != 'draft') return false;

      // 2. Filter pencarian judul
      if (_query.trim().isNotEmpty) {
        if (!a.judul.toLowerCase().contains(_query.trim().toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ── Format Tanggal Indonesia ───────────────────────────────────────────────

  String _formatDateIndo(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _onDelete(BeritaArticle artikel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmDialog(
        entryName: artikel.judul,
        isLoading: _deletingId == artikel.id,
        onDelete: () => Navigator.of(context).pop(true),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = artikel.id);
    try {
      await _service.deleteArtikel(
        artikelId: artikel.id,
        judul: artikel.judul,
        adminName: widget.adminName,
        adminId: widget.adminId,
        gambarUrl: artikel.gambarUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Artikel berhasil dihapus.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ]),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      debugPrint('[KelolaBerita] Gagal menghapus artikel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gagal menghapus artikel: $e',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
              ),
            ),
          ]),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _deletingId = '');
    }
  }

  Future<void> _onEdit(BeritaArticle artikel) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BeritaFormScreen(
          initialArtikel: artikel,
          adminName: widget.adminName,
          adminId: widget.adminId,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  Widget _buildHeaderMenu() {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      color: AppColors.surfaceCard,
      icon: _isSeeding
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textPrimary,
              ),
            )
          : const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        if (val == 'restore') {
          _onRestoreArticles();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'restore',
          child: Row(
            children: [
              const Icon(
                Icons.restore_page_outlined,
                color: AppColors.textPrimary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Pulihkan berita bawaan',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
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
                  'Berita Kesehatan',
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

          // Tombol Menu di kanan (bulat putih)
          Container(
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
            child: Center(child: _buildHeaderMenu()),
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
      body: StreamBuilder<List<BeritaArticle>>(
        stream: _service.streamAll(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];

          final totalCount = all.length;
          final terbitCount = all.where((a) => a.status == 'terbit').length;
          final draftCount = all.where((a) => a.status == 'draft').length;

          return Column(
            children: [
              // ── Search Bar & Status Filter Chips ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.softBlue, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Cari judul artikel...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.normal,
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: AppColors.textSecondary,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Status Filter Tabs: Semua / Terbit / Draft ───────────
                    Row(
                      children: [
                        _buildFilterPill(
                          label: 'Semua ($totalCount)',
                          statusKey: 'semua',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: 'Terbit ($terbitCount)',
                          statusKey: 'terbit',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: 'Draft ($draftCount)',
                          statusKey: 'draft',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Konten List / Error / Loading ──────────────────────────────
              Expanded(
                child: _buildBody(snapshot, all),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Filter Pill Widget ─────────────────────────────────────────────────────

  Widget _buildFilterPill({
    required String label,
    required String statusKey,
  }) {
    final bool isActive = _activeStatus == statusKey;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeStatus = statusKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.textPrimary : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppColors.textPrimary : AppColors.softBlue,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ── Body Builder ───────────────────────────────────────────────────────────

  Widget _buildBody(AsyncSnapshot<List<BeritaArticle>> snapshot, List<BeritaArticle> all) {
    if (snapshot.connectionState == ConnectionState.waiting && all.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.textPrimary),
      );
    }

    if (snapshot.hasError) {
      final err = snapshot.error;
      String errorCode = '';
      String errorMsg = err.toString();
      if (err is FirebaseException) {
        errorCode = err.code;
        errorMsg = err.message ?? err.toString();
        debugPrint('[KelolaBerita] FirebaseException code: ${err.code}, message: ${err.message}');
      } else {
        debugPrint('[KelolaBerita] Snapshot error: $err');
      }
      return _buildErrorState(errorCode: errorCode, errorMessage: errorMsg);
    }

    final filtered = _filtered(all);

    if (all.isEmpty) {
      return _buildEmpty(
        icon: Icons.article_outlined,
        title: 'Belum ada artikel berita',
        subtitle: 'Koleksi berita masih kosong. Muat 9 artikel bawaan atau buat baru.',
        action: ElevatedButton.icon(
          onPressed: _isSeeding ? null : _onRestoreArticles,
          icon: _isSeeding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.restore_page_outlined, size: 18),
          label: Text(
            _isSeeding ? 'Memulihkan...' : 'Pulihkan 9 Berita Bawaan',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      final String subtitle = _query.isNotEmpty
          ? 'Tidak ada artikel yang cocok dengan kata kunci "$_query".'
          : _activeStatus == 'draft'
              ? 'Belum ada artikel berstatus draft.'
              : 'Tidak ada artikel untuk filter ini.';

      return _buildEmpty(
        icon: Icons.search_off_rounded,
        title: 'Tidak ada artikel',
        subtitle: subtitle,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildArtikelCard(filtered[index]),
    );
  }

  Widget _buildErrorState({String errorCode = '', String errorMessage = ''}) {
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
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 28,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat data',
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pastikan aturan Firestore sudah di-deploy dan koneksi internet stabil.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (errorCode.isNotEmpty || errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.softBlue.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorCode.isNotEmpty ? 'Kode: $errorCode' : errorMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      'Coba Lagi',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(
                        color: AppColors.textPrimary,
                        width: 1.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSeeding ? null : _onRestoreArticles,
                    icon: const Icon(Icons.restore_page_outlined, size: 18),
                    label: Text(
                      'Pulihkan Bawaan',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
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
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
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
                  icon,
                  size: 28,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 16),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Artikel Card (Formal & Seragam) ─────────────────────────────────────────

  Widget _buildArtikelCard(BeritaArticle artikel) {
    final bool isDraft = artikel.status == 'draft';
    final bool isDeleting = _deletingId == artikel.id;

    final String dateText = artikel.tanggal != null
        ? _formatDateIndo(artikel.tanggal!)
        : 'Belum tayang';
    final String metaText = artikel.sumberNama.trim().isNotEmpty
        ? '$dateText  •  ${artikel.sumberNama.trim()}'
        : dateText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.softBlue.withOpacity(0.75),
          width: 1.0,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Thumbnail gambar sampul (radius 12) ────────────────────────
          _buildThumbnail(artikel, isDraft),
          const SizedBox(width: 14),

          // ── Judul + Badge Kategori & Status + Tanggal/Ringkasan ───────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  artikel.judul,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                if (artikel.ringkasanSingkat.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    artikel.ringkasanSingkat.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusBadge(isDraft: isDraft),
                    if (artikel.kategori.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          artikel.kategori.trim(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    Text(
                      metaText,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Action Buttons: Edit & Hapus (radius 10, ukuran 36x36) ────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionIconBerita(
                icon: Icons.edit_outlined,
                backgroundColor: AppColors.softBlue,
                borderColor: AppColors.softBlue,
                iconColor: AppColors.textPrimary,
                tooltip: 'Edit artikel',
                onTap: () => _onEdit(artikel),
              ),
              const SizedBox(width: 6),
              _ActionIconBerita(
                icon: isDeleting ? null : Icons.delete_outline_rounded,
                backgroundColor: AppColors.surfaceCard,
                borderColor: AppColors.softBlue,
                iconColor: AppColors.textPrimary,
                tooltip: 'Hapus artikel',
                isLoading: isDeleting,
                onTap: isDeleting ? null : () => _onDelete(artikel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Thumbnail Kotak 64x64 (radius 12) ──────────────────────────────────────

  Widget _buildThumbnail(BeritaArticle artikel, bool isDraft) {
    return SizedBox(
      width: 64,
      height: 64,
      child: BeritaImage(
        gambarUrl: artikel.gambarUrl.isNotEmpty ? artikel.gambarUrl : null,
        gambarAsset: artikel.gambarAsset.isNotEmpty ? artikel.gambarAsset : null,
        borderRadius: 12,
        width: 64,
        height: 64,
        alignment: artikel.gambarAlignment,
        fit: BoxFit.cover,
      ),
    );
  }
}

// ── Status Badge (Radius 10, Palet Kontras Formal) ───────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isDraft;
  const _StatusBadge({required this.isDraft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDraft ? AppColors.bgAccent : AppColors.textPrimary,
        borderRadius: BorderRadius.circular(10),
        border: isDraft
            ? Border.all(color: AppColors.accentGold, width: 1)
            : null,
      ),
      child: Text(
        isDraft ? 'Draft' : 'Terbit',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDraft ? AppColors.textPrimary : Colors.white,
        ),
      ),
    );
  }
}

// ── Action Icon Berita (Radius 10, Ukuran Konsisten 36x36) ───────────────────

class _ActionIconBerita extends StatelessWidget {
  final IconData? icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionIconBerita({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.tooltip,
    this.onTap,
    this.isLoading = false,
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
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(icon, size: 18, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

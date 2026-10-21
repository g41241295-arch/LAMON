import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/berita_article_model.dart';
import '../../services/berita/berita_service.dart';
import '../../widgets/admin/admin_widgets.dart';
import '../../widgets/app_header_pill.dart';
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
  bool _hasCheckedAutoSeed = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Auto-seeding jika collection kosong ────────────────────────────────────

  void _triggerAutoSeedIfEmpty(List<BeritaArticle> articles) {
    if (_hasCheckedAutoSeed) return;
    _hasCheckedAutoSeed = true;

    if (articles.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onSeedArticles(isSilent: true);
      });
    }
  }

  Future<void> _onSeedArticles({bool isSilent = false}) async {
    setState(() => _isSeeding = true);
    try {
      final res = await _service.seedStaticArticles();
      if (!mounted) return;
      if (!isSilent || res.inserted > 0) {
        final String successText = res.inserted > 0
            ? '${res.inserted} artikel berhasil disinkronkan'
            : '9 artikel bawaan sudah mutakhir di Firestore';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            successText,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (e is FirebaseException) {
        debugPrint('[KelolaBerita] seedStaticArticles FirebaseException code: ${e.code}, message: ${e.message}');
      } else {
        debugPrint('[KelolaBerita] Gagal seed artikel: $e');
      }
      if (!mounted) return;
      if (!isSilent) {
        final errorMsg = e is FirebaseException ? '[${e.code}] ${e.message ?? e.toString()}' : '$e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal memuat artikel: $errorMsg', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppColors.adminRed,
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
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Artikel berhasil dihapus.',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          backgroundColor: AppColors.successGreen,
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
            Expanded(child: Text('Gagal menghapus artikel: $e', style: GoogleFonts.poppins(fontSize: 13))),
          ]),
          backgroundColor: AppColors.adminRed,
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

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      header: AppHeaderPill(
        title: 'Kelola Berita',
        rightAction: IconButton(
          icon: _isSeeding
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF134563)),
                )
              : const Icon(Icons.cloud_download_outlined, color: Color(0xFF134563), size: 22),
          tooltip: 'Muat 9 Artikel Bawaan',
          onPressed: _isSeeding ? null : () => _onSeedArticles(isSilent: false),
        ),
      ),
      body: StreamBuilder<List<BeritaArticle>>(
        stream: _service.streamAll(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];

          // Pemicu auto-seeding jika koleksi pertama kali dibuka dan kosong
          if (snapshot.hasData) {
            _triggerAutoSeedIfEmpty(all);
          }

          final totalCount = all.length;
          final terbitCount = all.where((a) => a.status == 'terbit').length;
          final draftCount = all.where((a) => a.status == 'draft').length;

          return Column(
            children: [
              // ── Search Bar: Cari judul artikel ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Cari judul artikel',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Status Filter Pills: Semua / Terbit / Draft ─────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
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
              ),
              const SizedBox(height: 12),

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
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF134563) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? const Color(0xFF134563) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF134563).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.white : const Color(0xFF134563),
            ),
          ),
        ),
      ),
    );
  }

  // ── Body Builder ───────────────────────────────────────────────────────────

  Widget _buildBody(AsyncSnapshot<List<BeritaArticle>> snapshot, List<BeritaArticle> all) {
    if (snapshot.connectionState == ConnectionState.waiting && all.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF134563)));
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
          onPressed: _isSeeding ? null : () => _onSeedArticles(isSilent: false),
          icon: _isSeeding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.cloud_download_outlined, size: 18),
          label: Text(
            _isSeeding ? 'Memuat...' : 'Muat 9 Artikel Bawaan',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF134563),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 110),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildArtikelCard(filtered[index]),
    );
  }

  Widget _buildErrorState({String errorCode = '', String errorMessage = ''}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.adminRed.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.adminRed),
            ),
            const SizedBox(height: 6),
            Text(
              'Pastikan aturan Firestore sudah di-deploy dan koneksi internet stabil.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.neutralGray),
            ),
            if (errorCode.isNotEmpty || errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.adminRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorCode.isNotEmpty ? 'Kode: $errorCode' : errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.adminRed,
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
                  label: Text('Coba Lagi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF134563),
                    side: const BorderSide(color: Color(0xFF134563)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSeeding ? null : () => _onSeedArticles(isSilent: false),
                  icon: const Icon(Icons.cloud_download_outlined, size: 18),
                  label: Text('Muat Bawaan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF134563),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: const Color(0xFF134563).withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.neutralGray)),
            if (action != null) ...[
              const SizedBox(height: 20),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // ── Artikel Card (Sesuai Layout Figma) ──────────────────────────────────────

  Widget _buildArtikelCard(BeritaArticle artikel) {
    final bool isDraft = artikel.status == 'draft';
    final bool isDeleting = _deletingId == artikel.id;

    final String dateText = artikel.tanggal != null
        ? _formatDateIndo(artikel.tanggal!)
        : 'Belum tayang';

    final Widget cardContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Thumbnail kotak 64x64 (radius 10) ─────────────────────────
          _buildThumbnail(artikel, isDraft),
          const SizedBox(width: 12),

          // ── Judul + Status Badge + Tanggal ────────────────────────────
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF134563),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatusBadge(isDraft: isDraft),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        dateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // ── Action Buttons: Edit (Pensil) & Hapus (Tempat Sampah) ─────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionIconBerita(
                icon: Icons.edit_outlined,
                color: const Color(0xFF134563),
                tooltip: 'Edit artikel',
                onTap: () => _onEdit(artikel),
              ),
              const SizedBox(width: 4),
              _ActionIconBerita(
                icon: isDeleting ? null : Icons.delete_outline_rounded,
                color: const Color(0xFFDC2626),
                tooltip: 'Hapus artikel',
                isLoading: isDeleting,
                onTap: isDeleting ? null : () => _onDelete(artikel),
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: isDraft
          ? CustomPaint(
              painter: _DashedBorderPainter(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                strokeWidth: 1.4,
                radius: 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: cardContent,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: cardContent,
            ),
    );
  }

  // ── Thumbnail Kotak 64x64 ──────────────────────────────────────────────────

  Widget _buildThumbnail(BeritaArticle artikel, bool isDraft) {
    final bool hasImage = artikel.gambarAsset.trim().isNotEmpty;

    if (!hasImage) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isDraft ? const Color(0xFFFEF3C7) : const Color(0xFFE8F4FB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 28,
            color: isDraft ? const Color(0xFFD97706) : const Color(0xFF134563),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
        child: artikel.gambarAsset.startsWith('http')
            ? Image.network(
                artikel.gambarAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDraft ? const Color(0xFFFEF3C7) : const Color(0xFFE8F4FB),
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 26,
                      color: isDraft ? const Color(0xFFD97706) : const Color(0xFF134563),
                    ),
                  ),
                ),
              )
            : Image.asset(
                artikel.gambarAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDraft ? const Color(0xFFFEF3C7) : const Color(0xFFE8F4FB),
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 26,
                      color: isDraft ? const Color(0xFFD97706) : const Color(0xFF134563),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isDraft;
  const _StatusBadge({required this.isDraft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDraft ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isDraft ? 'Draft' : 'Terbit',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDraft ? const Color(0xFFD97706) : const Color(0xFF059669),
        ),
      ),
    );
  }
}

// ── Custom Painter untuk Border Putus-putus Kartu Draft ───────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  static const double _dashWidth = 5.0;
  static const double _dashSpace = 4.0;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.4,
    this.radius = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + _dashWidth < metric.length)
            ? _dashWidth
            : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += _dashWidth + _dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

// ── Action Icon Berita (bergaya pill seperti Ensiklopedia) ───────────────────

class _ActionIconBerita extends StatelessWidget {
  final IconData? icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionIconBerita({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
    this.isLoading = false,
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
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                : Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/admin_theme.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../services/ensiklopedia_service.dart';
import '../models/activity_log_model.dart';
import '../models/berita_article_model.dart';
import '../models/gastropedia_item_model.dart';
import '../services/berita/berita_service.dart';
import '../widgets/admin/activity_item.dart';
import '../widgets/admin/admin_widgets.dart';
import '../services/profile_photo_service.dart';

// ─── Warna Utama Beranda Admin (Mengacu pada AppColors) ────────────────────
const Color _kNavy = AppColors.textPrimary;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _adminName = 'Admin';
  String _adminId = '';
  String _adminEmail = '';
  String? _photoUrl;
  bool _loadingAdmin = true;
  final _ensiklopediaService = EnsiklopediaService();
  final _beritaService = BeritaService();
  bool _snackBarCleared = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_snackBarCleared) {
      _snackBarCleared = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
      });
    }
  }

  Future<void> _loadAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _adminId = user.uid;
    String email = user.email ?? '';
    String? photoUrl;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      String name = 'Admin';
      if (doc.exists) {
        final data = doc.data()!;
        final rawNama = (data['nama'] ?? '').toString().trim();
        final rawEmail = (data['email'] ?? '').toString().trim();
        if (rawEmail.isNotEmpty) {
          email = rawEmail;
        }
        final rawPhotoUrl = data['photo_url']?.toString().trim() ?? '';
        if (rawPhotoUrl.isNotEmpty) {
          photoUrl = rawPhotoUrl;
        }
        if (rawNama.isNotEmpty) {
          name = rawNama;
        } else {
          final local = email.split('@').first.toLowerCase();
          final cleaned = local.startsWith('admin') ? local.substring('admin'.length) : local;
          name = cleaned.isEmpty ? 'Admin' : cleaned[0].toUpperCase() + cleaned.substring(1);
        }
      } else {
        name = user.displayName ?? 'Admin';
      }
      setState(() {
        _adminName = name;
        _adminEmail = email;
        _photoUrl = photoUrl;
        _adminId = user.uid;
        _loadingAdmin = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingAdmin = false);
    }
  }

  String? _resolvePhotoAsset() {
    final emailLower = _adminEmail.toLowerCase();
    if (emailLower.contains('laras')) {
      return 'assets/images/profil_admin/admin_laras.jpg';
    }
    if (emailLower.contains('rani')) {
      return 'assets/images/profil_admin/admin_rani.jpg';
    }
    final nameLower = _adminName.toLowerCase();
    if (nameLower.contains('laras')) {
      return 'assets/images/profil_admin/admin_laras.jpg';
    }
    if (nameLower.contains('rani')) {
      return 'assets/images/profil_admin/admin_rani.jpg';
    }
    return null;
  }

  Widget _buildDefaultAvatar() {
    return const CircleAvatar(
      radius: 14,
      backgroundColor: Color(0xFF276F8F),
      child: Icon(Icons.person, size: 16, color: Colors.white),
    );
  }

  Widget _buildAvatar() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      return RealtimeHeaderAvatar(
        collection: 'users',
        docId: uid,
        size: 28,
        borderRadius: 14,
        fallback: _buildLegacyAvatar(),
      );
    }
    return _buildLegacyAvatar();
  }

  Widget _buildLegacyAvatar() {
    final assetPath = _resolvePhotoAsset();

    Widget? imageContent;
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      imageContent = Image.network(
        _photoUrl!,
        width: 28,
        height: 28,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          if (assetPath != null) {
            return Image.asset(
              assetPath,
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
            );
          }
          return _buildDefaultAvatar();
        },
      );
    } else if (assetPath != null) {
      imageContent = Image.asset(
        assetPath,
        width: 28,
        height: 28,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    }

    if (imageContent != null) {
      return ClipOval(
        child: SizedBox(
          width: 28,
          height: 28,
          child: imageContent,
        ),
      );
    }

    return _buildDefaultAvatar();
  }

  void _openAddEnsiklopedia() {
    Navigator.pushNamed(
      context,
      AppRoutes.adminEnsiklopediaForm,
      arguments: {'adminName': _adminName, 'adminId': _adminId},
    );
  }

  void _openAddBerita() {
    Navigator.pushNamed(
      context,
      AppRoutes.adminBeritaForm,
      arguments: {'adminName': _adminName, 'adminId': _adminId},
    );
  }

  void _openKelolaBerita() {
    Navigator.pushNamed(
      context,
      AppRoutes.adminBerita,
      arguments: {'adminName': _adminName, 'adminId': _adminId},
    );
  }

  void _openKelolaGastropedia() {
    Navigator.pushNamed(context, AppRoutes.adminEnsiklopedia);
  }

  Future<void> _openAdminProfile() async {
    await Navigator.pushNamed(context, AppRoutes.adminProfile);
    if (mounted) {
      _loadAdminData();
    }
  }

  String get _displayAdminName {
    final trimmed = _adminName.trim();
    if (trimmed.isEmpty) return 'Admin';
    return trimmed[0].toUpperCase() + trimmed.substring(1);
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
      body: Stack(
        children: [
          // ── KONTEN SCROLLABLE ─────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // A. Header & Profil
                _buildHeader(),
                const SizedBox(height: 24),

                // B. Welcome Section
                _buildWelcomeBanner(),
                const SizedBox(height: 24),

                // C. Card Highlight Statistik (1 Card Navy Kontras)
                _buildStatCards(),
                const SizedBox(height: 24),

                // D. Tambah Konten
                _buildSectionHeader(
                  icon: Icons.bolt_rounded,
                  title: 'Tambah Konten',
                ),
                const SizedBox(height: 12),
                _buildQuickActions(),
                const SizedBox(height: 24),

                // E. Kelola Konten
                _buildSectionHeader(
                  icon: Icons.folder_rounded,
                  title: 'Kelola Konten',
                ),
                const SizedBox(height: 12),
                _buildManageContent(),
                const SizedBox(height: 24),

                // F. Aktivitas Terbaru
                _buildActivitySectionHeader(),
                const SizedBox(height: 12),
                _buildRecentActivity(),

                // Padding bawah rapi sebelum akhir scroll
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── A. PROFIL HEADER ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return GestureDetector(
      onTap: _openAdminProfile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.softBlue, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(width: 10),
            _loadingAdmin
                ? Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      _displayAdminName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primaryText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── B. KARTU SAPAAN (DISAMAKAN DENGAN FORMALSAPAANCARD PENGGUNA) ──────────
  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEBE3D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFDF5),
                Color(0xFFFFFBE8),
                Color(0xFFFAF3D4),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Teks sapaan sebelah kiri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Halo, $_displayAdminName !',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9E652B),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Kelola Konten, Jaga\nLambung Pengguna',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Pantau dan kelola berita serta gastropedia',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B5839),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Maskot sebelah kanan (110x110)
              Image.asset(
                'assets/images/mascot-header.png',
                width: 110,
                height: 110,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shield_rounded,
                  size: 64,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── C. SATU KARTU HIGHLIGHT STATISTIK BERWARNA NAVY KONTRAS ───────────────
  Widget _buildStatCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Kiri: Artikel Berita
            Expanded(
              child: StreamBuilder<List<BeritaArticle>>(
                stream: _beritaService.streamAll(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.length : null;
                  return _buildHighlightStatItem(
                    iconImg: 'assets/images/admin-berita-kesehatan.png',
                    iconBgColor: AppColors.softBlue,
                    count: count,
                    label: 'Artikel Berita',
                    accentColor: AppColors.softBlue,
                    onTap: _openKelolaBerita,
                  );
                },
              ),
            ),

            // Garis pemisah vertikal tipis putih transparan di tengah
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              color: Colors.white.withOpacity(0.18),
            ),

            // Kanan: Gastropedia
            Expanded(
              child: StreamBuilder<List<GastropediaItem>>(
                stream: _ensiklopediaService.streamPublishedGastropedia(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.length : null;
                  return _buildHighlightStatItem(
                    iconImg: 'assets/images/admin-data-gastropedia.png',
                    iconBgColor: AppColors.bgAccent,
                    count: count,
                    label: 'Gastropedia',
                    accentColor: AppColors.accentGold,
                    onTap: _openKelolaGastropedia,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightStatItem({
    required String iconImg,
    required Color iconBgColor,
    required int? count,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                iconImg,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.analytics_rounded,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                count == null
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        count.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          height: 1.1,
                        ),
                      ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER SEKSI UMUM (IKON DENGAN LINGKARAN SOFT BLUE) ───────────────────
  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.softBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryText),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  // ── D. TOMBOL TAMBAH KONTEN ───────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Row(
      children: [
        // Tambah Berita: Card Putih, lingkaran ikon & badge aksen biru (softBlue)
        Expanded(
          child: _QuickActionButton(
            iconImg: 'assets/images/admin-berita-kesehatan.png',
            label: 'Tambah\nBerita',
            backgroundColor: AppColors.surfaceCard,
            borderColor: AppColors.softBlue,
            iconBgColor: AppColors.softBlue,
            badgeColor: AppColors.softBlue,
            onTap: _openAddBerita,
          ),
        ),
        const SizedBox(width: 12),

        // Tambah Gastropedia: Card Warm Cream (bgAccent), badge kuning/emas (accentGold)
        Expanded(
          child: _QuickActionButton(
            iconImg: 'assets/images/admin-data-gastropedia.png',
            label: 'Tambah\nGastropedia',
            backgroundColor: AppColors.bgAccent,
            borderColor: AppColors.accentGold,
            iconBgColor: AppColors.surfaceCard,
            badgeColor: AppColors.accentGold,
            onTap: _openAddEnsiklopedia,
          ),
        ),
      ],
    );
  }

  // ── E. KELOLA KONTEN ──────────────────────────────────────────────────────
  Widget _buildManageContent() {
    return Column(
      children: [
        // Kartu Berita Kesehatan: Background putih (surfaceCard), lingkaran ikon softBlue
        StreamBuilder<List<BeritaArticle>>(
          stream: _beritaService.streamAll(),
          builder: (context, snapshot) {
            String subtitle;
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              subtitle = 'Memuat data...';
            } else if (snapshot.hasError) {
              subtitle = 'Gagal memuat data';
            } else {
              final articles = snapshot.data ?? [];
              final total = articles.length;
              final draft = articles.where((a) => a.status == 'draft').length;
              subtitle = '$total artikel  •  $draft draft';
            }

            return _ManageCard(
              iconImg: 'assets/images/admin-berita-kesehatan.png',
              title: 'Berita Kesehatan',
              subtitle: subtitle,
              cardBackgroundColor: AppColors.surfaceCard,
              borderColor: AppColors.softBlue,
              iconCircleColor: AppColors.softBlue,
              onTap: _openKelolaBerita,
            );
          },
        ),
        const SizedBox(height: 12),

        // Kartu Gastropedia: Background warm cream (bgAccent), lingkaran ikon kuning/emas (accentGold)
        StreamBuilder<List<GastropediaItem>>(
          stream: _ensiklopediaService.streamPublishedGastropedia(),
          builder: (context, snapshot) {
            String subtitle;
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              subtitle = 'Memuat data...';
            } else if (snapshot.hasError) {
              subtitle = 'Gagal memuat data';
            } else {
              final total = snapshot.data?.length ?? 0;
              subtitle = '$total data gastropedia';
            }

            return _ManageCard(
              iconImg: 'assets/images/admin-data-gastropedia.png',
              title: 'Gastropedia',
              subtitle: subtitle,
              cardBackgroundColor: AppColors.bgAccent,
              borderColor: AppColors.accentGold,
              iconCircleColor: AppColors.accentGold.withOpacity(0.55),
              onTap: _openKelolaGastropedia,
            );
          },
        ),
      ],
    );
  }

  // ── F. HEADER AKTIVITAS TERBARU + LIHAT SEMUA ─────────────────────────────
  Widget _buildActivitySectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Aktivitas Terbaru',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ActivityHistoryScreen()),
            );
          },
          child: Row(
            children: [
              Text(
                'Lihat semua',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  // ── F. LIST AKTIVITAS TERBARU (KARTU PUTIH BERSIH) ────────────────────────
  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: StreamBuilder<List<ActivityLogModel>>(
        stream: _ensiklopediaService.streamRecentActivity(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            );
          }
          final logs = snapshot.data!.take(3).toList();
          if (logs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'Belum ada aktivitas',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < logs.length; i++) ...[
                _buildActivityRow(
                  logs[i],
                  isFirst: i == 0,
                  isLast: i == logs.length - 1,
                ),
                if (i < logs.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityRow(
    ActivityLogModel log, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final desc = _buildLogDescription(log);
    final time = _formatRelativeTime(log.createdAt);

    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 0 : 12,
        bottom: isLast ? 0 : 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.history_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ganti istilah "entri ensiklopedia" menjadi "data gastropedia" pada tampilan saja
  static String _buildLogDescription(ActivityLogModel log) {
    final aksiMap = {'tambah': 'Menambahkan', 'ubah': 'Mengubah', 'hapus': 'Menghapus'};
    final modulMap = {'ensiklopedia': 'data gastropedia'};
    final aksi = aksiMap[log.aksi.toLowerCase()] ?? log.aksi;
    final modul = modulMap[log.modul.toLowerCase()] ?? log.modul;
    String text = '$aksi $modul \u201c${log.judul}\u201d';
    text = text.replaceAll('entri ensiklopedia', 'data gastropedia');
    text = text.replaceAll('Entri ensiklopedia', 'Data gastropedia');
    return text;
  }

  /// Format waktu relatif: "Baru saja", "X menit lalu", "X jam lalu", "X hari lalu", "X bulan lalu"
  static String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return '...';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari lalu';
    final months = (diff.inDays / 30).floor();
    return '$months bulan lalu';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET BANTU: KARTU STATISTIK (SEKSI C)
// ═══════════════════════════════════════════════════════════════════════════════
// ignore: unused_element
class _StatCard extends StatelessWidget {
  final String imageBg;
  final String iconImg;
  final int? count;
  final String label;
  final VoidCallback onTap;

  const _StatCard({
    required this.imageBg,
    required this.iconImg,
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gambar latar belakang
              Image.asset(
                imageBg,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: const Color(0xFFD9EAF7)),
              ),

              // Konten kartu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Image.asset(
                      iconImg,
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.analytics_rounded, size: 28, color: _kNavy),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          count == null
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _kNavy,
                                  ),
                                )
                              : Text(
                                  count.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: _kNavy,
                                    height: 1.1,
                                  ),
                                ),
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: _kNavy,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _kNavy,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET BANTU: TOMBOL TAMBAH KONTEN (SEKSI D)
// ═══════════════════════════════════════════════════════════════════════════════
class _QuickActionButton extends StatelessWidget {
  final String iconImg;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBgColor;
  final Color badgeColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.iconImg,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBgColor,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
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
            // Ikon kategori dalam bingkai lingkaran + indikator "+" berwarna di pojok
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      iconImg,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.article_outlined,
                        size: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textPrimary,
                        width: 1.4,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        size: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primaryText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET BANTU: KARTU KELOLA KONTEN (SEKSI E)
// ═══════════════════════════════════════════════════════════════════════════════
class _ManageCard extends StatelessWidget {
  final String iconImg;
  final String title;
  final String subtitle;
  final Color cardBackgroundColor;
  final Color borderColor;
  final Color iconCircleColor;
  final VoidCallback onTap;

  const _ManageCard({
    required this.iconImg,
    required this.title,
    required this.subtitle,
    required this.cardBackgroundColor,
    required this.borderColor,
    required this.iconCircleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
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
            // Lingkaran kecil berbackground berbeda untuk tiap kategori
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconCircleColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  iconImg,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.folder_open_rounded,
                    size: 22,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutralGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LAYAR RIWAYAT AKTIVITAS
// ═══════════════════════════════════════════════════════════════════════════════
class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      header: AdminAppBar(title: 'Riwayat Aktivitas'),
      body: StreamBuilder<List<ActivityLogModel>>(
        stream: EnsiklopediaService().streamRecentActivity(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data!;
          if (logs.isEmpty) {
            return Center(
              child: Text(
                'Belum ada aktivitas',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                color: AdminTheme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ActivityItem(log: log),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

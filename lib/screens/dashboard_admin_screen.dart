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
import '../services/rating_monitoring_service.dart';
import '../services/admin_notification_service.dart';

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
  final _ratingMonitoringService = RatingMonitoringService();
  final _notificationService = AdminNotificationService.instance;
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
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.person, size: 20, color: Colors.white),
    );
  }

  Widget _buildAvatar() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      return RealtimeHeaderAvatar(
        collection: 'users',
        docId: uid,
        size: 38,
        borderRadius: 19,
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
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          if (assetPath != null) {
            return Image.asset(
              assetPath,
              width: 38,
              height: 38,
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
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    }

    if (imageContent != null) {
      return ClipOval(
        child: SizedBox(
          width: 38,
          height: 38,
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

  void _openPemantauanPenilaian() {
    Navigator.pushNamed(context, AppRoutes.adminPenilaian);
  }

  void _openAdminNotifications() {
    Navigator.pushNamed(
      context,
      AppRoutes.adminNotifikasi,
      arguments: {'adminName': _adminName, 'adminId': _adminId},
    );
  }

  String _formatTodayHeaderDate() {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final now = DateTime.now();
    return 'Hari Ini, ${now.day} ${months[now.month]}';
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
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // A. Header & Profil (Disamakan dengan Beranda Pengguna)
                _buildHeader(),
                const SizedBox(height: 18),

                // B. Welcome Section
                _buildWelcomeBanner(),
                const SizedBox(height: 20),

                // C. Card Highlight Statistik (Executive Dashboard Hero Card)
                _buildStatCards(),
                const SizedBox(height: 22),

                // D. Tambah Konten
                _buildSectionHeader(
                  icon: Icons.bolt_rounded,
                  title: 'Tambah Konten',
                ),
                const SizedBox(height: 12),
                _buildQuickActions(),
                const SizedBox(height: 22),

                // E. Kelola Konten
                _buildSectionHeader(
                  icon: Icons.folder_rounded,
                  title: 'Kelola Konten',
                ),
                const SizedBox(height: 12),
                _buildManageContent(),
                const SizedBox(height: 22),

                // F. Aktivitas Terbaru
                _buildActivitySectionHeader(),
                const SizedBox(height: 12),
                _buildRecentActivity(),

                // Padding bawah rapi sebelum akhir scroll
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── A. HEADER BERANDA ADMIN (DISAMAKAN DENGAN FORMALHEADERBAR PENGGUNA) ───
  Widget _buildHeader() {
    return Row(
      children: [
        // Kiri: Avatar Profil Admin (dengan ripple saat ditekan) + Teks LAMON
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _openAdminProfile,
                customBorder: const CircleBorder(),
                child: _buildAvatar(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _openAdminProfile,
              child: Text(
                'LAMON',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),

        const Spacer(),

        // Kanan: Pill Tanggal Hari Ini (hanya informasi, tanpa panah & tanpa tap)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEBE3D0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatTodayHeaderDate(),
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Paling Kanan: Tombol Lonceng Bulat + Titik Oranye jika ada notifikasi belum dibaca
        StreamBuilder<bool>(
          stream: _notificationService.watchHasUnreadNotifications(),
          builder: (context, snapshot) {
            final hasUnread = snapshot.data == true;
            return GestureDetector(
              onTap: _openAdminNotifications,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEBE3D0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: AppColors.primaryText,
                    ),
                    if (hasUnread)
                      Positioned(
                        top: 8,
                        right: 9,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── B. KARTU SAPAAN (EXECUTIVE ADMIN WELCOME BANNER) ──────────────────────
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
              // Teks sapaan sebelah kiri (lengkap, berimbang, & tidak kosong)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge Peran Administrator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9E652B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PANEL ADMINISTRATOR',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9E652B),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Halo, $_displayAdminName 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1C4E68),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Kelola Konten & Edukasi Lambung',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF276F8F),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pantau artikel berita, kelola data gastropedia, dan awasi evaluasi layanan secara terpadu.',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5A7184),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Indikator status sistem aktif
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Sistem Siap Digunakan',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Maskot sebelah kanan (proporsional 105x105)
              Image.asset(
                'assets/images/mascot-header.png',
                width: 105,
                height: 105,
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

  // ── C. SATU KARTU HIGHLIGHT STATISTIK (EXECUTIVE DASHBOARD HERO CARD) ─────
  Widget _buildStatCards() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF134563), // Deep Teal
            Color(0xFF1D5A7A), // Mid Teal
            Color(0xFF276F8F), // Primary Teal LAMON
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF134563).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                    icon: Icons.newspaper_rounded,
                    count: count,
                    label: 'Artikel Berita',
                    tagLabel: 'Publikasi',
                    tagColor: const Color(0xFFBCE3F5),
                  );
                },
              ),
            ),

            // Garis pemisah vertikal elegan
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              color: Colors.white.withValues(alpha: 0.20),
            ),

            // Kanan: Gastropedia
            Expanded(
              child: StreamBuilder<List<GastropediaItem>>(
                stream: _ensiklopediaService.streamPublishedGastropedia(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.length : null;
                  return _buildHighlightStatItem(
                    icon: Icons.menu_book_rounded,
                    count: count,
                    label: 'Gastropedia',
                    tagLabel: 'Ensiklopedia',
                    tagColor: const Color(0xFFFFE8A3),
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
    required IconData icon,
    required int? count,
    required String label,
    required String tagLabel,
    required Color tagColor,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: Colors.white,
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
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tagLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── HEADER SEKSI UMUM (KONSISTEN DENGAN PENGGUNA & DOKTER) ─────────────────
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF276F8F).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF276F8F)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C4E68),
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  // ── D. TOMBOL TAMBAH KONTEN (AKSI CEPAT ADMINISTRATOR) ────────────────────
  Widget _buildQuickActions() {
    return Row(
      children: [
        // 1. Tambah Berita
        Expanded(
          child: _QuickActionCard(
            title: 'Tambah Berita',
            subtitle: 'Tulis artikel baru',
            badgeText: '+ Artikel',
            icon: Icons.post_add_rounded,
            iconColor: const Color(0xFF276F8F),
            iconBgColor: const Color(0xFFEBF5F9),
            onTap: _openAddBerita,
          ),
        ),
        const SizedBox(width: 12),

        // 2. Tambah Gastropedia
        Expanded(
          child: _QuickActionCard(
            title: 'Tambah Gastropedia',
            subtitle: 'Entri edukasi baru',
            badgeText: '+ Edukasi',
            icon: Icons.bookmark_add_outlined,
            iconColor: const Color(0xFF9E652B),
            iconBgColor: const Color(0xFFFFF8E7),
            onTap: _openAddEnsiklopedia,
          ),
        ),
      ],
    );
  }

  // ── E. KELOLA KONTEN (MANAJEMEN KONTEN BERSIH & PROFESIONAL) ─────────────
  Widget _buildManageContent() {
    return Column(
      children: [
        // 1. Berita Kesehatan
        StreamBuilder<List<BeritaArticle>>(
          stream: _beritaService.streamAll(),
          builder: (context, snapshot) {
            final articles = snapshot.data ?? [];
            final total = articles.length;
            final draft = articles.where((a) => a.status == 'draft').length;
            final published = total - draft;

            return _ManageContentCard(
              title: 'Berita Kesehatan',
              icon: Icons.newspaper_rounded,
              iconColor: const Color(0xFF276F8F),
              iconBgColor: const Color(0xFFEBF5F9),
              badgeWidget: Row(
                children: [
                  _buildStatusPill(
                    label: '$published Terbit',
                    bgColor: const Color(0xFFE8F5E9),
                    textColor: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 6),
                  _buildStatusPill(
                    label: '$draft Draft',
                    bgColor: draft > 0 ? const Color(0xFFFFF3E0) : const Color(0xFFF1F5F9),
                    textColor: draft > 0 ? const Color(0xFFD97706) : const Color(0xFF64748B),
                  ),
                ],
              ),
              onTap: _openKelolaBerita,
            );
          },
        ),
        const SizedBox(height: 10),

        // 2. Gastropedia
        StreamBuilder<List<GastropediaItem>>(
          stream: _ensiklopediaService.streamPublishedGastropedia(),
          builder: (context, snapshot) {
            final total = snapshot.data?.length ?? 0;

            return _ManageContentCard(
              title: 'Gastropedia',
              icon: Icons.menu_book_rounded,
              iconColor: const Color(0xFF9E652B),
              iconBgColor: const Color(0xFFFFF8E7),
              badgeWidget: Row(
                children: [
                  _buildStatusPill(
                    label: '$total Data Terdaftar',
                    bgColor: const Color(0xFFFFF8E7),
                    textColor: const Color(0xFF9E652B),
                  ),
                ],
              ),
              onTap: _openKelolaGastropedia,
            );
          },
        ),
        const SizedBox(height: 10),

        // 3. Pemantauan Penilaian
        StreamBuilder<int>(
          stream: _ratingMonitoringService.watchTotalCombinedRatingsCount(),
          builder: (context, snapshot) {
            final total = snapshot.data ?? 0;

            return _ManageContentCard(
              title: 'Pemantauan Penilaian',
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFEF3C7),
              badgeWidget: Row(
                children: [
                  _buildStatusPill(
                    label: '$total Penilaian Masuk',
                    bgColor: const Color(0xFFFEF3C7),
                    textColor: const Color(0xFFB45309),
                  ),
                ],
              ),
              onTap: _openPemantauanPenilaian,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ── F. HEADER AKTIVITAS TERBARU + LIHAT SEMUA ─────────────────────────────
  Widget _buildActivitySectionHeader() {
    return _buildSectionHeader(
      icon: Icons.history_rounded,
      title: 'Aktivitas Terbaru',
      trailing: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActivityHistoryScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lihat semua',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF276F8F),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF276F8F),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── F. LIST AKTIVITAS TERBARU (AUDIT TRAIL MINIMALIS & BERSIH) ───────────
  Widget _buildRecentActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
      child: StreamBuilder<List<ActivityLogModel>>(
        stream: _ensiklopediaService.streamRecentActivity(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF276F8F),
                  ),
                ),
              ),
            );
          }
          final logs = snapshot.data!.take(3).toList();
          if (logs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Belum ada aktivitas',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8C9BA5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < logs.length; i++) ...[
                _buildActivityRow(logs[i]),
                if (i < logs.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0EBE1),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityRow(ActivityLogModel log) {
    final desc = _buildLogDescription(log);
    final time = _formatRelativeTime(log.createdAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtle dot indicator alih-alih kotak warna mencolok
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF276F8F),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                desc,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C4E68),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8C9BA5),
                ),
              ),
            ],
          ),
        ),
      ],
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
// WIDGET BANTU: TOMBOL TAMBAH KONTEN (SEKSI D) - AKSI CEPAT ADMINISTRATOR
// ═══════════════════════════════════════════════════════════════════════════════
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas: Icon tunggal di kiri & Badge kecil di kanan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(icon, size: 20, color: iconColor),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Judul & subjudul
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C4E68),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7A8B99),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET BANTU: KARTU KELOLA KONTEN (SEKSI E) - MANAJEMEN KONTEN PROFESIONAL
// ═══════════════════════════════════════════════════════════════════════════════
class _ManageContentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Widget badgeWidget;
  final VoidCallback onTap;

  const _ManageContentCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.badgeWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
          child: Row(
            children: [
              // Single clean category icon box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 22,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Content: Title & Text Status Pills
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C4E68),
                      ),
                    ),
                    const SizedBox(height: 5),
                    badgeWidget,
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Clean subtle chevron
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
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

  Widget _buildHeader(BuildContext context) {
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
                    color: Colors.black.withValues(alpha: 0.05),
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

          // Pill Judul: disamakan persis dengan pill "Catat Makanan" & halaman admin lainnya
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
                  'Riwayat Aktivitas',
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

          // Penyeimbang kanan agar pill judul tetap berada tepat di tengah
          const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }

  /// Mengelompokkan aktivitas berdasarkan tanggal ("HARI INI", "KEMARIN", "MINGGU INI", "SEBELUMNYA")
  /// tanpa mengubah urutan data dari stream Firestore.
  List<({String label, List<ActivityLogModel> items})> _groupLogsByTime(
    List<ActivityLogModel> logs,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayItems = <ActivityLogModel>[];
    final yesterdayItems = <ActivityLogModel>[];
    final thisWeekItems = <ActivityLogModel>[];
    final olderItems = <ActivityLogModel>[];

    for (final log in logs) {
      final dt = log.createdAt;
      if (dt == null) {
        olderItems.add(log);
        continue;
      }
      final logDay = DateTime(dt.year, dt.month, dt.day);
      final diffDays = today.difference(logDay).inDays;

      if (diffDays <= 0) {
        todayItems.add(log);
      } else if (diffDays == 1) {
        yesterdayItems.add(log);
      } else if (diffDays <= 7) {
        thisWeekItems.add(log);
      } else {
        olderItems.add(log);
      }
    }

    final groups = <({String label, List<ActivityLogModel> items})>[];
    if (todayItems.isNotEmpty) {
      groups.add((label: 'HARI INI', items: todayItems));
    }
    if (yesterdayItems.isNotEmpty) {
      groups.add((label: 'KEMARIN', items: yesterdayItems));
    }
    if (thisWeekItems.isNotEmpty) {
      groups.add((label: 'MINGGU INI', items: thisWeekItems));
    }
    if (olderItems.isNotEmpty) {
      groups.add((label: 'SEBELUMNYA', items: olderItems));
    }
    return groups;
  }

  Widget _buildGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.softBlue.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityLogModel log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.softBlue.withValues(alpha: 0.75),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ActivityItem(
        log: log,
        showIconCircle: true,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.softBlue, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.softBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 28,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Belum ada aktivitas',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Riwayat perubahan konten berita dan gastropedia oleh admin akan tampil di sini.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.softBlue, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.softBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 28,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Gagal memuat aktivitas',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
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
      header: _buildHeader(context),
      body: StreamBuilder<List<ActivityLogModel>>(
        stream: EnsiklopediaService().streamRecentActivity(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.textPrimary,
                strokeWidth: 2.5,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return _buildEmptyState();
          }

          final groups = _groupLogsByTime(logs);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: groups.length,
            itemBuilder: (context, groupIndex) {
              final group = groups[groupIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (groupIndex > 0) const SizedBox(height: 22),
                  _buildGroupHeader(group.label),
                  for (int i = 0; i < group.items.length; i++) ...[
                    _buildActivityCard(group.items[i]),
                    if (i < group.items.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

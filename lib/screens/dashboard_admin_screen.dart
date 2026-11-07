import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/admin_theme.dart';
import '../routes/app_routes.dart';
import '../services/ensiklopedia_service.dart';
import '../models/activity_log_model.dart';
import '../models/berita_article_model.dart';
import '../models/gastropedia_item_model.dart';
import '../services/berita/berita_service.dart';
import '../widgets/admin/activity_item.dart';
import '../widgets/admin/admin_widgets.dart';
import '../services/profile_photo_service.dart';

// ─── Warna Utama Beranda Admin ─────────────────────────────────────────────
const Color _kNavy = Color(0xFF1E3A5F);
const Color _kBlueText = Color(0xFF2E7DA6);
const Color _kBottomBorderBlue = Color(0xFF7BA7C7);
const Color _kBottomBorderYellow = Color(0xFFF2B705);
const Color _kGradientEndBlue = Color(0xFFD9EAF7);
const Color _kGradientEndYellow = Color(0xFFFFF1B8);

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
      body: Stack(
        children: [
          // ── G. ILUSTRASI BAWAH (tetap diam saat layar digulir) ─────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/beranda_ilustrasi_makan_trim.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── KONTEN SCROLLABLE ─────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // A. Profil Kapsul (Tetap seperti aslinya)
                _buildHeader(),
                const SizedBox(height: 14),

                // B. Kartu Sapaan
                _buildWelcomeBanner(),
                const SizedBox(height: 12),

                // C. Dua Kartu Statistik Berdampingan
                _buildStatCards(),
                const SizedBox(height: 16),

                // D. Tambah Konten
                _buildSectionHeader(
                  icon: Icons.flash_on_rounded,
                  title: 'Tambah Konten',
                ),
                const SizedBox(height: 10),
                _buildQuickActions(),
                const SizedBox(height: 16),

                // E. Kelola Konten
                _buildSectionHeader(
                  icon: Icons.folder_rounded,
                  title: 'Kelola Konten',
                ),
                const SizedBox(height: 10),
                _buildManageContent(),
                const SizedBox(height: 16),

                // F. Aktivitas Terbaru
                _buildActivitySectionHeader(),
                const SizedBox(height: 10),
                _buildRecentActivity(),

                // Padding bawah setara ilustrasi agar kartu paling bawah tidak tertutup
                const SizedBox(height: 165),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── A. PROFIL HEADER (TIDAK DIUBAH) ───────────────────────────────────────
  Widget _buildHeader() {
    return GestureDetector(
      onTap: _openAdminProfile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(),
            const SizedBox(width: 8),
            _loadingAdmin
                ? Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
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
                        color: const Color(0xFF276F8F),
                      ),
                    ),
                  ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF276F8F),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── B. KARTU SAPAAN ───────────────────────────────────────────────────────
  Widget _buildWelcomeBanner() {
    return Container(
      height: 138,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Latar belakang kartu
            Positioned.fill(
              child: Image.asset(
                'assets/images/card_sapaan_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFF3B0), Color(0xFFFFE57A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),

            // Teks sebelah kiri
            Positioned(
              left: 18,
              top: 0,
              bottom: 0,
              right: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Halo, $_displayAdminName !',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A4E1A),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Kelola Konten, Jaga\nLambung Pengguna',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _kNavy,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pantau dan kelola berita serta gastropedia',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),

            // Maskot sebelah kanan
            Positioned(
              right: 2,
              top: 2,
              bottom: 2,
              child: Image.asset(
                'assets/images/mascot-header.png',
                width: 132,
                height: 132,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shield_rounded,
                  size: 72,
                  color: _kNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── C. DUA KARTU STATISTIK BERDAMPINGAN ───────────────────────────────────
  Widget _buildStatCards() {
    return Row(
      children: [
        // Kiri: Artikel Berita
        Expanded(
          child: StreamBuilder<List<BeritaArticle>>(
            stream: _beritaService.streamAll(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.length : null;
              return _StatCard(
                imageBg: 'assets/images/rectangle-berita.png',
                iconImg: 'assets/images/admin-berita-kesehatan.png',
                count: count,
                label: 'Artikel Berita',
                onTap: _openKelolaBerita,
              );
            },
          ),
        ),
        const SizedBox(width: 8),

        // Kanan: Gastropedia (menggunakan stream published yang sama dengan pengguna)
        Expanded(
          child: StreamBuilder<List<GastropediaItem>>(
            stream: _ensiklopediaService.streamPublishedGastropedia(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.length : null;
              return _StatCard(
                imageBg: 'assets/images/rectangle-gastropedia.png',
                iconImg: 'assets/images/admin-data-gastropedia.png',
                count: count,
                label: 'Gastropedia',
                onTap: _openKelolaGastropedia,
              );
            },
          ),
        ),
      ],
    );
  }

  // ── HEADER SEKSI UMUM ─────────────────────────────────────────────────────
  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _kNavy),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kNavy,
          ),
        ),
      ],
    );
  }

  // ── D. TOMBOL TAMBAH KONTEN ───────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Row(
      children: [
        // Tambah Berita
        Expanded(
          child: _QuickActionButton(
            imageBg: 'assets/images/Rectangle-artikelberita.png',
            iconImg: 'assets/images/admin-tambah-berita.png',
            label: 'Tambah\nBerita',
            onTap: _openAddBerita,
          ),
        ),
        const SizedBox(width: 8),

        // Tambah Gastropedia
        Expanded(
          child: _QuickActionButton(
            imageBg: 'assets/images/Rectangle-jumlahgastropedia.png',
            iconImg: 'assets/images/admin-tambah-gastropedia.png',
            label: 'Tambah\nGastropedia',
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
        // Kartu Berita Kesehatan
        StreamBuilder<List<BeritaArticle>>(
          stream: _beritaService.streamAll(),
          builder: (context, snapshot) {
            String subtitle;
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
              iconBoxColor: const Color(0xFFC7E2F5),
              bottomBarColor: _kBottomBorderBlue,
              gradientEndColor: _kGradientEndBlue,
              title: 'Berita Kesehatan',
              subtitle: subtitle,
              onTap: _openKelolaBerita,
            );
          },
        ),
        const SizedBox(height: 8),

        // Kartu Gastropedia
        StreamBuilder<List<GastropediaItem>>(
          stream: _ensiklopediaService.streamPublishedGastropedia(),
          builder: (context, snapshot) {
            String subtitle;
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              subtitle = 'Memuat data...';
            } else if (snapshot.hasError) {
              subtitle = 'Gagal memuat data';
            } else {
              final total = snapshot.data?.length ?? 0;
              subtitle = '$total data gastropedia';
            }

            return _ManageCard(
              iconImg: 'assets/images/admin-data-gastropedia.png',
              iconBoxColor: const Color(0xFFFFF2B8),
              bottomBarColor: _kBottomBorderYellow,
              gradientEndColor: _kGradientEndYellow,
              title: 'Gastropedia',
              subtitle: subtitle,
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
            const Icon(Icons.history_rounded, size: 20, color: _kNavy),
            const SizedBox(width: 6),
            Text(
              'Aktivitas Terbaru',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kNavy,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ActivityHistoryScreen()),
            );
          },
          child: Row(
            children: [
              Text(
                'Lihat semua',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _kNavy,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 16, color: _kNavy),
            ],
          ),
        ),
      ],
    );
  }

  // ── F. LIST AKTIVITAS TERBARU (KARTU GRADASI) ─────────────────────────────
  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, _kGradientEndBlue],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: StreamBuilder<List<ActivityLogModel>>(
        stream: _ensiklopediaService.streamRecentActivity(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kNavy),
                ),
              ),
            );
          }
          final logs = snapshot.data!.take(3).toList();
          if (logs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Belum ada aktivitas',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                ),
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < logs.length; i++) ...[
                _buildActivityRow(logs[i]),
                if (i < logs.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 0.8,
                    color: Color(0xFFD1E3F0),
                    indent: 14,
                    endIndent: 14,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.history_rounded, size: 16, color: _kNavy),
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
                    color: _kBlueText,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
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
  final String imageBg;
  final String iconImg;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.imageBg,
    required this.iconImg,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gambar latar belakang
              Image.asset(
                imageBg,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Color(0xFFD9EAF7)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),

              // Konten tombol
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    // Ikon dengan badge + di pojok kanan bawah
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          iconImg,
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.add_circle_outline_rounded, size: 28, color: _kNavy),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: const BoxDecoration(
                              color: _kNavy,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.add, size: 8, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kNavy,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _kNavy,
                      size: 18,
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
// WIDGET BANTU: KARTU KELOLA KONTEN (SEKSI E)
// ═══════════════════════════════════════════════════════════════════════════════
class _ManageCard extends StatelessWidget {
  final String iconImg;
  final Color iconBoxColor;
  final Color bottomBarColor;
  final Color gradientEndColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManageCard({
    required this.iconImg,
    required this.iconBoxColor,
    required this.bottomBarColor,
    required this.gradientEndColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 59,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, gradientEndColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Garis tebal di bawah kartu (6dp melengkung mengikuti kartu)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: bottomBarColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                ),
              ),

              // Konten kartu
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 12, 6),
                child: Row(
                  children: [
                    // Kotak ikon membulat
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBoxColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Image.asset(
                          iconImg,
                          width: 25,
                          height: 25,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.folder_open_rounded, size: 22, color: _kNavy),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: _kNavy,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: Colors.black54,
                            ),
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

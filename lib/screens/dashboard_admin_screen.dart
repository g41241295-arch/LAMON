import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/admin_theme.dart';
import '../routes/app_routes.dart';
import '../services/ensiklopedia_service.dart';
import '../models/activity_log_model.dart';
import '../models/berita_article_model.dart';
import '../services/berita/berita_service.dart';
import '../widgets/admin/activity_item.dart';
import '../widgets/admin/admin_widgets.dart';
import '../widgets/admin/content_menu_tile.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _adminName = 'Admin';
  String _adminId = '';
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
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      String name = 'Admin';
      if (doc.exists) {
        final data = doc.data()!;
        final rawNama = (data['nama'] ?? '').toString().trim();
        if (rawNama.isNotEmpty) {
          name = rawNama;
        } else {
          final email = user.email ?? '';
          final local = email.split('@').first.toLowerCase();
          final cleaned = local.startsWith('admin') ? local.substring('admin'.length) : local;
          name = cleaned.isEmpty ? 'Admin' : cleaned[0].toUpperCase() + cleaned.substring(1);
        }
      } else {
        name = user.displayName ?? 'Admin';
      }
      setState(() {
        _adminName = name;
        _adminId = user.uid;
        _loadingAdmin = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingAdmin = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 24),
            _buildWelcomeBanner(),
            const SizedBox(height: 24),
            _buildDraftCard(),
            _buildStatCards(),
            const SizedBox(height: 24),
            _buildSectionTitle('Tambah Konten'),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildSectionTitle('Kelola Konten'),
            const SizedBox(height: 12),
            _buildManageContent(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Aktivitas Terbaru'),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityHistoryScreen()));
                  },
                  child: Text(
                    'Lihat semua >',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AdminTheme.navyText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRecentActivity(),
            const SizedBox(height: 80), // bottom padding for nav bar
          ],
        ),
      ),
    );
  }

  String get _displayAdminName {
    final trimmed = _adminName.trim();
    if (trimmed.isEmpty) return 'Admin';
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  Future<void> _openAdminProfile() async {
    await Navigator.pushNamed(context, AppRoutes.adminProfile);
    if (mounted) {
      _loadAdminData();
    }
  }

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
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF276F8F),
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
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
                : Text(
                    _displayAdminName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF276F8F),
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


  Widget _buildWelcomeBanner() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3B0), Color(0xFFFFE57A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dekorasi latar dalam kartu
          Positioned(
            top: -16, right: -12,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          // Konten teks kiri
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 140, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Halo, $_adminName!',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8D5B20),
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola Konten,\nJaga Lambung Pengguna',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF134563),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pantau dan kelola berita\nserta gastropedia.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF625232),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          // Maskot menonjol di pojok kanan
          Positioned(
            right: -8,
            top: -12,
            bottom: -4,
            child: Image.asset(
              'assets/images/logo-admin-beranda.png',
              width: 130,
              fit: BoxFit.contain,
              errorBuilder: (_, e, s) => const Icon(Icons.shield, size: 80, color: Color(0xFF134563)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCard() {
    return StreamBuilder<List<BeritaArticle>>(
      stream: _beritaService.streamAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final draftArticles = snapshot.data!.where((a) => a.status == 'draft').toList();
        final draftCount = draftArticles.length;
        if (draftCount == 0) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            gradient: AdminTheme.blueGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$draftCount draft menunggu',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.navyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tinjau lalu terbitkan agar tampil di aplikasi pengguna.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AdminTheme.navyText.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _openKelolaBerita,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.cardColor,
                  foregroundColor: AdminTheme.navyText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Tinjau >', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<List<BeritaArticle>>(
            stream: _beritaService.streamAll(),
            builder: (context, snapshot) {
              Widget countWidget;
              if (snapshot.hasError) {
                countWidget = Text(
                  '-',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.navyText,
                  ),
                );
              } else if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                countWidget = const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.navyText),
                );
              } else {
                final articles = snapshot.data ?? [];
                final terbitCount = articles.where((a) => a.status == 'terbit').length;
                countWidget = Text(
                  terbitCount.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.navyText,
                  ),
                );
              }

              return GestureDetector(
                onTap: _openKelolaBerita,
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: AdminTheme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      countWidget,
                      Text(
                        'Artikel berita',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AdminTheme.navyText.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('encyclopedia').snapshots(),
            builder: (context, snapshot) {
              int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminEnsiklopedia),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: AdminTheme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        count.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.navyText,
                        ),
                      ),
                      Text(
                        'Gastropedia',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AdminTheme.navyText.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AdminTheme.navyText,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _openAddBerita,
              icon: const Icon(Icons.add, size: 18, color: AdminTheme.navyText),
              label: Text('Tambah Berita', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.navyText)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AdminTheme.navyText,
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF337AA3)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _openAddEnsiklopedia,
              icon: const Icon(Icons.add, size: 18, color: AdminTheme.navyText),
              label: Text('Tambah Gastropedia', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.navyText)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF337AA3)),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManageContent() {
    return Column(
      children: [
        StreamBuilder<List<BeritaArticle>>(
          stream: _beritaService.streamAll(),
          builder: (context, snapshot) {
            String subtitle;
            if (snapshot.hasError) {
              subtitle = 'Gagal memuat data';
            } else if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
              subtitle = 'Memuat data...';
            } else {
              final articles = snapshot.data ?? [];
              final count = articles.length;
              final draftCount = articles.where((a) => a.status == 'draft').length;
              subtitle = '$count artikel · $draftCount draft';
            }

            return ContentMenuTile(
              imagePath: 'assets/images/admin-berita.png',
              title: 'Berita Kesehatan',
              subtitle: subtitle,
              onTap: _openKelolaBerita,
            );
          },
        ),
        const SizedBox(height: 12),
        _buildContentStreamCard(
          title: 'Gastropedia',
          stream: FirebaseFirestore.instance.collection('encyclopedia').snapshots(),
          imagePath: 'assets/images/admin-pisang.png',
          onTap: () => Navigator.pushNamed(context, AppRoutes.adminEnsiklopedia),
          isBerita: false,
        ),
      ],
    );
  }

  Widget _buildContentStreamCard({
    required String title,
    required Stream<QuerySnapshot> stream,
    required String imagePath,
    required VoidCallback onTap,
    required bool isBerita,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        int count = 0;
        int draftCount = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
          if (isBerita) {
            draftCount = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'draft';
            }).length;
          }
        }
        
        String subtitle = isBerita 
            ? '$count artikel · $draftCount draft'
            : '$count data gastropedia';

        return ContentMenuTile(
          imagePath: imagePath,
          title: title,
          subtitle: subtitle,
          onTap: onTap,
        );
      }
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: StreamBuilder<List<ActivityLogModel>>(
        stream: _ensiklopediaService.streamRecentActivity(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data!.take(3).toList();
          if (logs.isEmpty) {
            return Text('Belum ada aktivitas', style: GoogleFonts.poppins(color: Colors.grey));
          }
          return Column(
            children: logs.map((log) => _buildActivityItem(log)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildActivityItem(ActivityLogModel log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ActivityItem(log: log),
    );
  }
}

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      header: AdminAppBar(title: 'Riwayat Aktivitas'),
      body: StreamBuilder<List<ActivityLogModel>>(
        stream: EnsiklopediaService().streamRecentActivity(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final logs = snapshot.data!;
          if (logs.isEmpty) {
            return Center(child: Text('Belum ada aktivitas', style: GoogleFonts.poppins(color: Colors.grey)));
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

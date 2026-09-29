import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/admin_theme.dart';
import '../routes/app_routes.dart';
import '../services/ensiklopedia_service.dart';
import '../models/activity_log_model.dart';
import '../widgets/admin/activity_item.dart';
import '../widgets/admin/admin_background.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _adminName = 'Admin';
  String _adminId = '';
  String? _adminPhotoUrl;
  bool _loadingAdmin = true;
  final _ensiklopediaService = EnsiklopediaService();
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
    _adminPhotoUrl = user.photoURL;
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
        if (data['foto'] != null && data['foto'].toString().isNotEmpty) {
          _adminPhotoUrl = data['foto'];
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

  void _showComingSoon() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur segera hadir', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.adminBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openAddEnsiklopedia() {
    Navigator.pushNamed(
      context,
      AppRoutes.adminEnsiklopediaForm,
      arguments: {'adminName': _adminName, 'adminId': _adminId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
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
                _buildSectionTitle('Aksi Cepat'),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: AdminTheme.blueGradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _adminPhotoUrl != null && _adminPhotoUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(_adminPhotoUrl!),
                  backgroundColor: AdminTheme.cardColor,
                  onBackgroundImageError: (e, s) {},
                )
              : CircleAvatar(
                  radius: 22,
                  backgroundColor: AdminTheme.cardColor,
                  child: Text(
                    _adminName.isNotEmpty ? _adminName[0].toUpperCase() : 'A',
                    style: GoogleFonts.poppins(
                      color: AdminTheme.navyText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AdminTheme.navyText.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_loadingAdmin)
                  Container(width: 80, height: 16, color: Colors.grey.withValues(alpha: 0.3))
                else
                  Text(
                    _adminName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.navyText,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/Mask group.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: AdminTheme.blueGradient.colors.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Halo, $_adminName!',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AdminTheme.navyText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kelola Konten,\nJaga Lambung\nPengguna',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AdminTheme.navyText,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/logo-admin-beranda.png',
                    width: 125,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, size: 80, color: AdminTheme.navyText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('berita').where('status', isEqualTo: 'draft').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        int draftCount = snapshot.data!.docs.length;
        
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
                onPressed: _showComingSoon,
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('berita').snapshots(),
            builder: (context, snapshot) {
              int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return GestureDetector(
                onTap: _showComingSoon,
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
            }
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ensiklopedia').snapshots(),
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
            }
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AdminTheme.navyText,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              gradient: AdminTheme.blueGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: _showComingSoon,
              icon: const Icon(Icons.add, size: 18, color: AdminTheme.navyText),
              label: Text('Tambah Berita', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.navyText)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              label: Text('Tambah Makanan', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.navyText)),
              style: OutlinedButton.styleFrom(
                backgroundColor: AdminTheme.cardColor,
                side: const BorderSide(color: AdminTheme.borderBlue),
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
        _buildContentCard(
          title: 'Berita Kesehatan',
          stream: FirebaseFirestore.instance.collection('berita').snapshots(),
          iconPath: 'assets/images/admin-berita.png',
          onTap: _showComingSoon,
          isBerita: true,
        ),
        const SizedBox(height: 12),
        _buildContentCard(
          title: 'Gastropedia',
          stream: FirebaseFirestore.instance.collection('ensiklopedia').snapshots(),
          iconPath: 'assets/images/admin-pisang.png',
          onTap: () => Navigator.pushNamed(context, AppRoutes.adminEnsiklopedia),
          isBerita: false,
        ),
      ],
    );
  }

  Widget _buildContentCard({
    required String title,
    required Stream<QuerySnapshot> stream,
    required String iconPath,
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
            : '$count makanan rekomendasi';

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AdminTheme.cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    gradient: AdminTheme.blueGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    iconPath,
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.folder, color: AdminTheme.navyText),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.navyText,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AdminTheme.navyText.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AdminTheme.navyText),
              ],
            ),
          ),
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
    return AdminBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Riwayat Aktivitas', style: GoogleFonts.poppins(color: AdminTheme.navyText, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AdminTheme.navyText),
        ),
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
      ),
    );
  }
}

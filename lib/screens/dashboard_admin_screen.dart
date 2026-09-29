import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../services/ensiklopedia_service.dart';
import '../models/activity_log_model.dart';
import '../models/ensiklopedia_entry_model.dart';
import '../widgets/admin/stat_card.dart';
import '../widgets/admin/quick_action_button.dart';
import '../widgets/admin/content_menu_tile.dart';
import '../widgets/admin/activity_item.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // ── Admin identity ────────────────────────────────────────────────────────
  String _adminName = 'Admin';
  String _adminId = '';
  bool _loadingAdmin = true;

  // ── Services ──────────────────────────────────────────────────────────────
  final _ensiklopediaService = EnsiklopediaService();

  // ── Seed state (debug only) ───────────────────────────────────────────────
  bool _isSeedingData = false;

  // ── Flag para membersihkan snackbar login hanya sekali ───────────────────
  bool _snackBarCleared = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hapus snackbar dari layar sebelumnya (mis. login error) – hanya sekali
    if (!_snackBarCleared) {
      _snackBarCleared = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
      });
    }
  }

  // ── Fetch admin name dari Firestore (fresh setiap kali layar dibuka) ──────
  Future<void> _loadAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _adminId = user.uid;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      String name = 'Admin';
      if (doc.exists) {
        final data = doc.data()!;
        final rawNama = (data['nama'] ?? '').toString().trim();
        if (rawNama.isNotEmpty) {
          name = rawNama;
        } else {
          // Fallback: ambil bagian email sebelum '@', hilangkan prefix "admin"
          final email = user.email ?? '';
          final local = email.split('@').first.toLowerCase();
          final cleaned = local.startsWith('admin')
              ? local.substring('admin'.length)
              : local;
          name = cleaned.isEmpty
              ? 'Admin'
              : cleaned[0].toUpperCase() + cleaned.substring(1);
        }
      } else {
        // dok tidak ada: fallback sama
        final email = user.email ?? '';
        final local = email.split('@').first.toLowerCase();
        final cleaned = local.startsWith('admin')
            ? local.substring('admin'.length)
            : local;
        name = cleaned.isEmpty
            ? 'Admin'
            : cleaned[0].toUpperCase() + cleaned.substring(1);
        debugPrint('[AdminDashboard] WARN: field `nama` belum ada di dokumen users/${user.uid}');
      }

      setState(() {
        _adminName = name;
        _adminId = user.uid;
        _loadingAdmin = false;
      });
    } catch (e) {
      debugPrint('[AdminDashboard] gagal load admin data: $e');
      if (mounted) setState(() => _loadingAdmin = false);
    }
  }

  // ── Logout dengan konfirmasi ───────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konfirmasi Keluar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppColors.neutralGray),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Ya, Keluar',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (r) => false);
      }
    }
  }

  // ── Snackbar helper ───────────────────────────────────────────────────────
  void _showComingSoon() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Fitur berita segera hadir',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.adminBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Buka form tambah ensiklopedia ─────────────────────────────────────────
  void _openAddEnsiklopedia() {
    Navigator.pushNamed(
      context,
      AppRoutes.adminEnsiklopediaForm,
      arguments: {
        'adminName': _adminName,
        'adminId': _adminId,
      },
    );
  }

  // ── Seed data (debug only) ────────────────────────────────────────────────
  Future<void> _seedData() async {
    if (!kDebugMode) return;
    setState(() => _isSeedingData = true);
    try {
      await _ensiklopediaService.seedData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '3 entri contoh berhasil ditambahkan!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seed gagal: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.adminRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeedingData = false);
    }
  }

  // ── Hitung entri baru dalam 7 hari terakhir ───────────────────────────────
  int _countNewEntries(List<EnsiklopediaEntry> entries) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return entries.where((e) => e.createdAt.isAfter(cutoff)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.55, 1.0],
            colors: [
              Color(0xFFF9E79F), // kuning hangat atas
              Color(0xFFFFF8D0), // krem tengah
              Color(0xFFFFFEF5), // hampir putih bawah
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ─── 1. HEADER ───────────────────────────────────────────
                _buildHeader(),

                const SizedBox(height: 24),

                // ─── 2. STATISTIK ────────────────────────────────────────
                _buildStatCards(),

                const SizedBox(height: 24),

                // ─── 3. AKSI CEPAT ───────────────────────────────────────
                _buildSectionTitle('Aksi Cepat'),
                const SizedBox(height: 12),
                _buildQuickActions(),

                const SizedBox(height: 24),

                // ─── 4. KELOLA KONTEN ────────────────────────────────────
                _buildSectionTitle('Kelola Konten'),
                const SizedBox(height: 12),
                _buildKelolaTiles(),

                const SizedBox(height: 24),

                // ─── 5. AKTIVITAS TERBARU ────────────────────────────────
                _buildSectionTitle('Aktivitas Terbaru'),
                const SizedBox(height: 12),
                _buildActivityFeed(),

                const SizedBox(height: 32),

                // ─── 6. SEED BUTTON (debug only) ─────────────────────────
                if (kDebugMode) _buildSeedButton(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widget builders ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar/shield box biru
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.adminBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),

        // Label "Admin" + Nama
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.adminTealLabel,
                ),
              ),
              _loadingAdmin
                  ? _NameShimmer()
                  : Text(
                      _adminName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.adminBlue,
                        height: 1.15,
                      ),
                    ),
            ],
          ),
        ),

        // Tombol logout bulat putih
        GestureDetector(
          onTap: _logout,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.adminBlue,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return StreamBuilder<List<EnsiklopediaEntry>>(
      stream: _ensiklopediaService.streamEnsiklopedia(),
      builder: (context, snapshot) {
        final entries = snapshot.data;
        final count = entries?.length;
        final newCount =
            entries != null ? _countNewEntries(entries) : 0;
        final badge = newCount > 0 ? '+$newCount' : null;

        return Row(
          children: [
            // Kartu berita (placeholder)
            Expanded(
              child: StatCard(
                icon: Icons.article_outlined,
                statValue: '–',
                label: 'Artikel berita',
                badgeText: 'Segera',
              ),
            ),
            const SizedBox(width: 14),
            // Kartu ensiklopedia (realtime)
            Expanded(
              child: StatCard(
                icon: Icons.menu_book_rounded,
                statValue: count?.toString(),
                label: 'Entri ensiklopedia',
                badgeText: badge,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.adminBlue,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        // Tambah Berita – PLACEHOLDER
        QuickActionButton(
          label: 'Tambah Berita',
          icon: Icons.add_rounded,
          isPrimary: true,
          onTap: _showComingSoon,
        ),
        const SizedBox(width: 14),
        // Tambah Ensiklopedia – BERFUNGSI
        QuickActionButton(
          label: 'Tambah Ensiklopedia',
          icon: Icons.add_rounded,
          isPrimary: false,
          onTap: _openAddEnsiklopedia,
        ),
      ],
    );
  }

  Widget _buildKelolaTiles() {
    return StreamBuilder<List<EnsiklopediaEntry>>(
      stream: _ensiklopediaService.streamEnsiklopedia(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;

        return Column(
          children: [
            // Berita Kesehatan – PLACEHOLDER
            ContentMenuTile(
              icon: Icons.newspaper_rounded,
              title: 'Berita Kesehatan',
              subtitle: 'Segera hadir',
              onTap: _showComingSoon,
            ),
            const SizedBox(height: 12),
            // Ensiklopedia – BERFUNGSI
            ContentMenuTile(
              icon: Icons.menu_book_rounded,
              title: 'Ensiklopedia',
              subtitle: '$count entri',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.adminEnsiklopedia),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityFeed() {
    return StreamBuilder<List<ActivityLogModel>>(
      stream: _ensiklopediaService.streamRecentActivity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _ActivityShimmer();
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Belum ada aktivitas',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.neutralGray,
              ),
            ),
          );
        }

        return Column(
          children: logs
              .map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ActivityItem(log: log),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildSeedButton() {
    return Center(
      child: GestureDetector(
        onTap: _isSeedingData ? null : _seedData,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _isSeedingData
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.neutralGray,
                  ),
                )
              : Text(
                  'Seed 3 entri contoh (debug)',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.neutralGray,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Shimmer nama admin ──────────────────────────────────────────────────────
class _NameShimmer extends StatefulWidget {
  @override
  State<_NameShimmer> createState() => _NameShimmerState();
}

class _NameShimmerState extends State<_NameShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(
        opacity: _anim.value,
        child: Container(
          height: 22,
          width: 110,
          decoration: BoxDecoration(
            color: AppColors.adminBlueLight,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer baris aktivitas ─────────────────────────────────────────────────
class _ActivityShimmer extends StatefulWidget {
  @override
  State<_ActivityShimmer> createState() => _ActivityShimmerState();
}

class _ActivityShimmerState extends State<_ActivityShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _shimmerLine(double width) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(
        opacity: _anim.value,
        child: Container(
          height: 12,
          width: width,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: AppColors.adminBlueLight,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _anim,
                builder: (_, child) => Opacity(
                  opacity: _anim.value,
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppColors.adminBlueLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerLine(200),
                  _shimmerLine(80),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

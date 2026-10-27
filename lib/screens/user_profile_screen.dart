import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_header_pill.dart';
import '../routes/app_routes.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  String? _photoUrl;
  String? _gender; // 'Pria'/'Laki-laki' atau 'Wanita'/'Perempuan'
  dynamic _rawHistory; // bool, String, List, atau null

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    String name = user.displayName ?? '';
    String email = user.email ?? '';
    String? photo = user.photoURL;
    String? gender;
    dynamic history;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};

        final rawNama = (data['nama'] ?? data['name'] ?? '').toString().trim();
        if (rawNama.isNotEmpty) name = rawNama;

        final rawEmail = (data['email'] ?? '').toString().trim();
        if (rawEmail.isNotEmpty) email = rawEmail;

        final rawPhoto = (data['photo_url'] ?? data['photoUrl'] ?? '').toString().trim();
        if (rawPhoto.isNotEmpty) photo = rawPhoto;

        // Jenis Kelamin: prioritas root 'jenis_kelamin', lalu 'screeningData' -> 'gender'
        final rawGender = data['jenis_kelamin'] ?? data['screeningData']?['gender'];
        if (rawGender != null) {
          gender = rawGender.toString().trim();
        }

        // Riwayat Penyakit: prioritas root 'riwayat_penyakit_lambung' / 'riwayat_penyakit', lalu 'screeningData' -> 'hasHistory'
        if (data.containsKey('riwayat_penyakit_lambung')) {
          history = data['riwayat_penyakit_lambung'];
        } else if (data.containsKey('riwayat_penyakit')) {
          history = data['riwayat_penyakit'];
        } else if (data['screeningData'] != null && data['screeningData'] is Map) {
          history = data['screeningData']['hasHistory'] ?? data['screeningData']['riwayat_penyakit'];
        }
      }
    } catch (e) {
      debugPrint('[UserProfileScreen] Gagal memuat data pengguna: $e');
    }

    if (name.isEmpty) {
      final local = email.split('@').first;
      name = local.isNotEmpty ? local[0].toUpperCase() + local.substring(1) : 'Pengguna';
    }

    if (mounted) {
      setState(() {
        _userName = name;
        _userEmail = email;
        _photoUrl = photo;
        _gender = gender;
        _rawHistory = history;
        _isLoading = false;
      });
    }
  }

  String get _displayName {
    final trimmed = _userName.trim();
    if (trimmed.isEmpty) return 'Pengguna';
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  bool get _isMale {
    if (_gender == null) return false;
    final lower = _gender!.toLowerCase();
    return lower == 'laki-laki' || lower == 'pria';
  }

  bool get _isFemale {
    if (_gender == null) return false;
    final lower = _gender!.toLowerCase();
    return lower == 'perempuan' || lower == 'wanita';
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        color: Color(0xFF134563),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        size: 54,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAvatarImage() {
    final cleanPhoto = (_photoUrl ?? '').trim();
    if (cleanPhoto.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 96,
          height: 96,
          child: Image.network(
            cleanPhoto,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 96,
                height: 96,
                color: const Color(0xFF134563).withValues(alpha: 0.1),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
          ),
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildGenderChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isFemale,
  }) {
    // Nilai warna persis dari doctor_profile_tab.dart
    final selectedColor = isFemale ? const Color(0xFFD63384) : AppColors.primary;
    final selectedBgColor = isFemale
        ? const Color(0xFFFCE4EF)
        : AppColors.primary.withValues(alpha: 0.12);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? selectedBgColor : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? selectedColor : AppColors.inputBorder,
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? selectedColor : AppColors.neutralGray,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? selectedColor : const Color(0xFF1C4E68),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryWidget() {
    String historyText;
    IconData historyIcon;
    Color iconColor;

    if (_rawHistory == null) {
      historyText = 'Belum diisi';
      historyIcon = Icons.help_outline_rounded;
      iconColor = AppColors.neutralGray;
    } else if (_rawHistory is bool) {
      if (_rawHistory == true) {
        historyText = 'Ada riwayat penyakit lambung';
        historyIcon = Icons.health_and_safety_outlined;
        iconColor = const Color(0xFFE65100);
      } else {
        historyText = 'Tidak ada riwayat penyakit';
        historyIcon = Icons.check_circle_outline_rounded;
        iconColor = AppColors.successGreen;
      }
    } else if (_rawHistory is List) {
      final list = (_rawHistory as List).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      if (list.isEmpty || list.contains('tidak ada') || list.contains('tidak')) {
        historyText = 'Tidak ada riwayat penyakit';
        historyIcon = Icons.check_circle_outline_rounded;
        iconColor = AppColors.successGreen;
      } else {
        historyText = list.join(', ');
        historyIcon = Icons.health_and_safety_outlined;
        iconColor = const Color(0xFFE65100);
      }
    } else {
      final str = _rawHistory.toString().trim();
      final lower = str.toLowerCase();
      if (str.isEmpty || lower == '-' || lower == 'belum diisi') {
        historyText = 'Belum diisi';
        historyIcon = Icons.help_outline_rounded;
        iconColor = AppColors.neutralGray;
      } else if (lower.contains('tidak ada') || lower == 'tidak' || lower == 'false') {
        historyText = 'Tidak ada riwayat penyakit';
        historyIcon = Icons.check_circle_outline_rounded;
        iconColor = AppColors.successGreen;
      } else if (lower == 'iya' || lower == 'ya' || lower == 'true') {
        historyText = 'Ada riwayat penyakit lambung';
        historyIcon = Icons.health_and_safety_outlined;
        iconColor = const Color(0xFFE65100);
      } else {
        historyText = str;
        historyIcon = Icons.health_and_safety_outlined;
        iconColor = const Color(0xFFE65100);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(historyIcon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              historyText,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1C4E68),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Konfirmasi Keluar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(
                color: const Color(0xFFD32F2F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppHeaderPill(title: 'Profil Pengguna'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar Bulat Pengguna
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildAvatarImage(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nama Pengguna di Bawah Foto
                  Text(
                    _displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C4E68),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Kartu Putih Berisi Form "PROFIL"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE8EFF5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul Form "PROFIL" (sesuai ukuran dokter/admin: 19 w900)
                        Center(
                          child: Text(
                            'PROFIL',
                            style: GoogleFonts.poppins(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: const Color(0xFF1C4E68),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Field Nama Lengkap (Read-Only)
                        Text(
                          'Nama Lengkap',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C4E68),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          initialValue: _displayName,
                          readOnly: true,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF1C4E68),
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.inputBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.inputBorder),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Field Email (Akun) (Read-Only)
                        Text(
                          'Email (Akun)',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C4E68),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          initialValue: _userEmail,
                          readOnly: true,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF1C4E68),
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFEEF2F6),
                            suffixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: AppColors.neutralGray,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Field Jenis Kelamin (Read-Only dari Skrining)
                        Text(
                          'Jenis Kelamin',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C4E68),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildGenderChip(
                                label: 'Laki-laki',
                                icon: Icons.male_rounded,
                                isSelected: _isMale,
                                isFemale: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGenderChip(
                                label: 'Perempuan',
                                icon: Icons.female_rounded,
                                isSelected: _isFemale,
                                isFemale: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Field Riwayat Penyakit (Read-Only dari Skrining)
                        Text(
                          'Riwayat Penyakit',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C4E68),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildHistoryWidget(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Keluar dari Akun Pengguna
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _confirmLogout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFD32F2F),
                        size: 20,
                      ),
                      label: Text(
                        'Keluar dari Akun Pengguna',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFD32F2F),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF8F8),
                        side: const BorderSide(
                          color: Color(0xFFFFCDD2),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

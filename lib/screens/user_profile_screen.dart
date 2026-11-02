import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../services/profile_photo_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_header_pill.dart';
import '../routes/app_routes.dart';
import '../services/fcm_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  String _userName = '';
  String _userEmail = '';
  String? _uploadedPhotoUrl;
  String? _googlePhotoUrl;
  String? _photoBase64;
  String? _gender; // 'Pria'/'Laki-laki' atau 'Wanita'/'Perempuan'
  dynamic _rawBirthDate; // Timestamp, String, atau null
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
    String? googlePhoto = user.photoURL;
    String? uploadedPhoto;
    String? photoBase64;
    String? gender;
    dynamic rawBirthDate;
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
        if (rawPhoto.isNotEmpty) uploadedPhoto = rawPhoto;

        final rawPhotoBase64 = data['photoBase64']?.toString().trim();
        if (rawPhotoBase64 != null && rawPhotoBase64.isNotEmpty) {
          photoBase64 = rawPhotoBase64;
        }

        // Jenis Kelamin: prioritas root 'jenis_kelamin', lalu 'screeningData' -> 'gender'
        final rawGender = data['jenis_kelamin'] ?? data['screeningData']?['gender'];
        if (rawGender != null) {
          gender = rawGender.toString().trim();
        }

        // Tanggal Lahir: prioritas root 'tanggal_lahir', 'birthDate', lalu 'screeningData' -> 'birthDate' / 'tanggal_lahir'
        rawBirthDate = data['tanggal_lahir'] ??
            data['birthDate'] ??
            data['birth_date'] ??
            data['screeningData']?['birthDate'] ??
            data['screeningData']?['tanggal_lahir'];

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
        _uploadedPhotoUrl = uploadedPhoto;
        _googlePhotoUrl = googlePhoto;
        _photoBase64 = photoBase64;
        _gender = gender;
        _rawBirthDate = rawBirthDate;
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

  String _formatIndonesianDate(dynamic rawDate) {
    if (rawDate == null) return 'Belum diisi';

    DateTime? dt;
    if (rawDate is Timestamp) {
      dt = rawDate.toDate();
    } else if (rawDate is DateTime) {
      dt = rawDate;
    } else if (rawDate is String) {
      final trimmed = rawDate.trim();
      if (trimmed.isEmpty || trimmed == '-' || trimmed.toLowerCase() == 'belum diisi') {
        return 'Belum diisi';
      }
      dt = DateTime.tryParse(trimmed);
      if (dt == null) {
        final parts = trimmed.split(RegExp(r'[-/]'));
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            final y = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final d = int.tryParse(parts[2]);
            if (y != null && m != null && d != null) {
              dt = DateTime(y, m, d);
            }
          } else if (parts[2].length == 4) {
            final d = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final y = int.tryParse(parts[2]);
            if (y != null && m != null && d != null) {
              dt = DateTime(y, m, d);
            }
          }
        }
      }
    }

    if (dt == null) {
      final str = rawDate.toString().trim();
      return str.isNotEmpty ? str : 'Belum diisi';
    }

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    if (dt.month >= 1 && dt.month <= 12) {
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
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
    // 1. Prioritas utama: Base64 dari dokumen pemilik
    final imageProvider = ProfilePhotoService.provider(_photoBase64);
    if (imageProvider != null) {
      return Image(
        image: imageProvider,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    }

    // 2. Fallback jika Base64 belum ada: URL foto lama atau foto Google
    final cleanUploaded = (_uploadedPhotoUrl ?? '').trim();
    final cleanGoogle = (_googlePhotoUrl ?? '').trim();
    final targetUrl = cleanUploaded.isNotEmpty ? cleanUploaded : cleanGoogle;

    if (targetUrl.isNotEmpty) {
      return Image.network(
        targetUrl,
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
        errorBuilder: (context, error, stackTrace) {
          if (cleanUploaded.isNotEmpty && cleanGoogle.isNotEmpty && targetUrl != cleanGoogle) {
            return Image.network(
              cleanGoogle,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => _buildDefaultAvatar(),
            );
          }
          return _buildDefaultAvatar();
        },
      );
    }

    // 3. Ikon orang default jika belum ada foto
    return _buildDefaultAvatar();
  }

  // Bottom sheet pilihan sumber foto (persis gaya Profil Dokter)
  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ganti Foto Profil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryText,
                        ),
                      ),
                      if (_photoBase64 != null && _photoBase64!.trim().isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFD32F2F),
                            size: 22,
                          ),
                          tooltip: 'Hapus Foto Profil',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmAndDeletePhoto();
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Ambil foto langsung',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Pilih dari galeri HP',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDeletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus foto profil?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Foto profil akan dihapus dan diganti dengan foto default.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isUploadingPhoto = true);
      await ProfilePhotoService.deletePhoto(
        collection: 'users',
      );
      if (!mounted) return;
      setState(() {
        _photoBase64 = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil dihapus'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('[UserProfileScreen] Gagal menghapus foto: $e');
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty ? message : 'Gagal menghapus foto profil'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  // Pilih + kompres + simpan Base64 ke Firestore tanpa Storage
  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      setState(() => _isUploadingPhoto = true);
      final b64 = await ProfilePhotoService.pickAndSave(
        collection: 'users',
        source: source,
      );
      if (b64 == null) return;
      if (!mounted) return;
      setState(() {
        _photoBase64 = b64;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil diperbarui'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('[UserProfileScreen] Gagal mengganti foto: $e');
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty ? message : 'Gagal memperbarui foto profil'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Widget _buildGenderChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isFemale,
  }) {
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
      final list = (_rawHistory as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      try {
        if (uid != null) {
          await FcmService.instance.cleanUpBeforeLogout(uid);
        }
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
                  // Avatar Bulat Pengguna dengan tombol kamera di pojok kanan bawah
                  Center(
                    child: GestureDetector(
                      onTap: _isUploadingPhoto ? null : _showPhotoSourceSheet,
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? Container(
                                      width: 96,
                                      height: 96,
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      width: 96,
                                      height: 96,
                                      child: _buildAvatarImage(),
                                    ),
                            ),
                          ),
                          if (!_isUploadingPhoto)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
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
                        // Judul Form "PROFIL"
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

                        // Field Tanggal Lahir (Read-Only dari Skrining)
                        Text(
                          'Tanggal Lahir',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C4E68),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: ValueKey(_formatIndonesianDate(_rawBirthDate)),
                          initialValue: _formatIndonesianDate(_rawBirthDate),
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

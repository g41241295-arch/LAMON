import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../widgets/gastropedia/gastropedia_header.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  static const Color _pageBgColor = Color(0xFFFFF3BF);
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  String? _selectedGender;
  String _adminName = '';
  String _adminEmail = '';
  String? _photoUrl; // URL foto dari Firebase Storage (null = pakai aset default)
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _adminEmail = user.email ?? '';
    _emailController.text = _adminEmail;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data() ?? {};
        final rawName = (data['nama'] ?? '').toString().trim();
        _adminName = rawName.isNotEmpty ? rawName : (user.displayName ?? 'Admin');
        _nameController.text = _adminName;

        final rawEmail = (data['email'] ?? '').toString().trim();
        if (rawEmail.isNotEmpty) {
          _adminEmail = rawEmail;
          _emailController.text = _adminEmail;
        }

        final gender = data['jenis_kelamin']?.toString();
        if (gender != null && (gender == 'Laki-laki' || gender == 'Perempuan')) {
          _selectedGender = gender;
        }

        // Baca URL foto profil yang sudah diunggah (jika ada)
        final rawPhotoUrl = data['photo_url']?.toString().trim() ?? '';
        if (rawPhotoUrl.isNotEmpty) {
          _photoUrl = rawPhotoUrl;
        }
      } else {
        _adminName = user.displayName ?? 'Admin';
        _nameController.text = _adminName;
      }
    } catch (_) {
      // Abaikan error jaringan saat inisialisasi, gunakan fallback
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _displayName {
    final name = _adminName.trim();
    if (name.isEmpty) return 'Admin';
    return name[0].toUpperCase() + name.substring(1);
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
      width: 96,
      height: 96,
      color: const Color(0xFF276F8F),
      child: const Icon(
        Icons.person,
        size: 54,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAvatarImage() {
    // Prioritas: (1) foto yang diunggah admin (URL), (2) asset per nama, (3) ikon default
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return Image.network(
        _photoUrl!,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          final assetPath = _resolvePhotoAsset();
          if (assetPath != null) {
            return Image.asset(assetPath, width: 96, height: 96, fit: BoxFit.cover);
          }
          return _buildDefaultAvatar();
        },
      );
    }
    final assetPath = _resolvePhotoAsset();
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    }
    return _buildDefaultAvatar();
  }

  // ── Bottom sheet pilihan sumber foto ──────────────────────────────────────
  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text('Ganti Foto Profil',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryText)),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF276F8F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Color(0xFF276F8F)),
                  ),
                  title: const Text('Kamera',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Ambil foto langsung',
                      style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF276F8F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.photo_library_rounded,
                        color: Color(0xFF276F8F)),
                  ),
                  title: const Text('Galeri',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pilih dari galeri HP',
                      style: TextStyle(fontSize: 12)),
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

  // ── Pilih, kompres, upload, dan simpan URL foto profil admin ─────────────
  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (picked == null) return;

      // Validasi format
      final ext = picked.path.split('.').last.toLowerCase();
      if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format gambar harus JPG atau PNG.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final Uint8List imageBytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _isUploadingPhoto = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String downloadUrl;
      try {
        // Upload ke Firebase Storage: profil_admin/{uid}.jpg
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profil_admin/${user.uid}.jpg');
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uid': user.uid},
        );
        final task = await storageRef.putData(imageBytes, metadata);
        downloadUrl = await task.ref.getDownloadURL();
      } catch (storageError) {
        debugPrint('[AdminProfile] Firebase Storage gagal: $storageError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengunggah foto: $storageError'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Simpan URL ke Firestore di koleksi 'users', field 'photo_url'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photo_url': downloadUrl});

      if (mounted) {
        setState(() => _photoUrl = downloadUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui.'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengganti foto: $e'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Widget _buildGenderChip(String gender) {
    final isSelected = _selectedGender == gender;
    final isFemale = gender == 'Perempuan';
    // Perempuan terpilih = pink, Laki-laki terpilih = biru (nilai persis dari Profil Dokter)
    final selectedColor = isFemale ? const Color(0xFFD63384) : AppColors.primary;
    final selectedBgColor = isFemale
        ? const Color(0xFFFCE4EF)
        : AppColors.primary.withValues(alpha: 0.12);

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: AnimatedContainer(
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
              gender == 'Laki-laki'
                  ? Icons.male_rounded
                  : Icons.female_rounded,
              size: 18,
              color: isSelected ? selectedColor : AppColors.neutralGray,
            ),
            const SizedBox(width: 6),
            Text(
              gender,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? selectedColor
                    : const Color(0xFF1C4E68),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final newName = _nameController.text.trim();
      final Map<String, dynamic> updateData = {
        'nama': newName,
      };
      if (_selectedGender != null) {
        updateData['jenis_kelamin'] = _selectedGender;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      if (mounted) {
        setState(() {
          _adminName = newName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil admin berhasil diperbarui.'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          'Apakah Anda yakin ingin keluar dari akun admin?',
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
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _pageBgColor,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 6),
              GastropediaHeader(
                title: 'Profil Admin',
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF276F8F),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                        child: Column(
                          children: [
                  // Avatar Besar Bulat Admin dengan tombol kamera
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
                                color: const Color(0xFF276F8F),
                                width: 2.5,
                              ),
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? Container(
                                      width: 96,
                                      height: 96,
                                      color: const Color(0xFF276F8F)
                                          .withValues(alpha: 0.1),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF276F8F),
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    )
                                  : _buildAvatarImage(),
                            ),
                          ),
                          if (!_isUploadingPhoto)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF276F8F),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.15),
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

                  // Nama Admin di Bawah Foto (tanpa teks spesialisasi dokter)
                  Text(
                    _displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C4E68),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kartu Putih Berisi Form "PROFIL"
                  Container(
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                          // Field Nama Lengkap (Editable)
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
                            controller: _nameController,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF1C4E68),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nama admin...',
                              hintStyle: GoogleFonts.poppins(
                                color: AppColors.inputPlaceholder,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.inputBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.inputBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF276F8F),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nama tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Field Email (Read-Only)
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
                            controller: _emailController,
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
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Field Jenis Kelamin (Laki-laki / Perempuan)
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
                              Expanded(child: _buildGenderChip('Laki-laki')),
                              const SizedBox(width: 12),
                              Expanded(child: _buildGenderChip('Perempuan')),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Tombol Simpan Perubahan
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF276F8F),
                                foregroundColor: Colors.white,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Simpan Perubahan',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Keluar dari Akun Admin
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
                        'Keluar dari Akun Admin',
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
          ),
        ],
      ),
    ),
  ),
);
  }
}

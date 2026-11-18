import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/doctor_theme.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../services/profile_photo_service.dart';
import '../../services/fcm_service.dart';
import '../konsultasi/widgets/doctor_avatar.dart';

/// Tab 3: Profil Dokter (Design System Formal LAMON)
class DoctorProfileTab extends StatefulWidget {
  final DoctorModel doctor;
  final VoidCallback onProfileUpdated;

  const DoctorProfileTab({
    super.key,
    required this.doctor,
    required this.onProfileUpdated,
  });

  @override
  State<DoctorProfileTab> createState() => _DoctorProfileTabState();
}

class _DoctorProfileTabState extends State<DoctorProfileTab> {
  final DoctorService _doctorService = DoctorService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _strController;
  late final TextEditingController _emailController;
  String? _selectedGender;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.doctor.name);
    _strController = TextEditingController(text: widget.doctor.strNumber);
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    _emailController = TextEditingController(text: userEmail);
    _selectedGender = widget.doctor.gender ?? 'Laki-laki';
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctor.id)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        final rawB64 = data['photoBase64']?.toString().trim();
        if (rawB64 != null && rawB64.isNotEmpty) {
          setState(() {
            _photoBase64 = rawB64;
          });
        }
      }
    } catch (e) {
      debugPrint('[DoctorProfileTab] Gagal memuat photoBase64: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _doctorService.updateDoctorProfile(
        doctorId: widget.doctor.id,
        name: _nameController.text.trim(),
        strNumber: _strController.text.trim(),
        gender: _selectedGender,
      );
      widget.onProfileUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil dokter berhasil diperbarui.'),
            backgroundColor: DoctorTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: DoctorTheme.alertRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konfirmasi Keluar',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: DoctorTheme.primaryText,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun dokter?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: DoctorTheme.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                color: DoctorTheme.neutralGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorTheme.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      if (uid != null) {
        await FcmService.instance.cleanUpBeforeLogout(uid);
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal keluar: $e'),
            backgroundColor: DoctorTheme.alertRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                      Text(
                        'Ganti Foto Profil',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: DoctorTheme.primaryText,
                        ),
                      ),
                      if (_photoBase64 != null && _photoBase64!.trim().isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: DoctorTheme.alertRed,
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
                const Divider(color: DoctorTheme.cardBorder),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: DoctorTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: DoctorTheme.primary),
                  ),
                  title: Text(
                    'Kamera',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: DoctorTheme.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    'Ambil foto langsung',
                    style: GoogleFonts.poppins(fontSize: 12, color: DoctorTheme.secondaryText),
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
                        color: DoctorTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.photo_library_rounded,
                        color: DoctorTheme.primary),
                  ),
                  title: Text(
                    'Galeri',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: DoctorTheme.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    'Pilih dari galeri HP',
                    style: GoogleFonts.poppins(fontSize: 12, color: DoctorTheme.secondaryText),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus foto profil?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: DoctorTheme.primaryText,
          ),
        ),
        content: Text(
          'Foto profil akan dihapus dan diganti dengan foto default.',
          style: GoogleFonts.poppins(fontSize: 13, color: DoctorTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                color: DoctorTheme.neutralGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorTheme.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
        collection: 'doctors',
        docId: widget.doctor.id,
      );
      if (!mounted) return;
      setState(() {
        _photoBase64 = null;
      });
      widget.onProfileUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil dihapus'),
          backgroundColor: DoctorTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('[DoctorProfileTab] Gagal menghapus foto: $e');
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty ? message : 'Gagal menghapus foto profil'),
            backgroundColor: DoctorTheme.alertRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      setState(() => _isUploadingPhoto = true);
      final b64 = await ProfilePhotoService.pickAndSave(
        collection: 'doctors',
        docId: widget.doctor.id,
        source: source,
      );
      if (b64 == null) return;
      if (!mounted) return;
      setState(() {
        _photoBase64 = b64;
      });
      widget.onProfileUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil diperbarui'),
          backgroundColor: DoctorTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('[DoctorProfileTab] Gagal mengganti foto: $e');
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty ? message : 'Gagal memperbarui foto profil'),
            backgroundColor: DoctorTheme.alertRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Widget _buildDoctorAvatarImage() {
    final imageProvider = ProfilePhotoService.provider(_photoBase64);
    if (imageProvider != null) {
      return Image(
        image: imageProvider,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => DoctorAvatar(
          photoUrl: widget.doctor.effectivePhotoUrl,
          doctorId: widget.doctor.id,
          doctorName: widget.doctor.name,
          size: 96,
          borderRadius: 48,
        ),
      );
    }
    return DoctorAvatar(
      photoUrl: widget.doctor.effectivePhotoUrl,
      doctorId: widget.doctor.id,
      doctorName: widget.doctor.name,
      size: 96,
      borderRadius: 48,
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF276F8F).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF276F8F).withValues(alpha: 0.22),
                width: 1.0,
              ),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF276F8F)),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C4E68),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String gender) {
    final isSelected = _selectedGender == gender;
    final isFemale = gender == 'Perempuan';
    final selectedColor = isFemale ? const Color(0xFFD63384) : const Color(0xFF276F8F);
    final selectedBgColor = isFemale
        ? const Color(0xFFFCE4EF)
        : const Color(0xFF276F8F).withValues(alpha: 0.10);

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? selectedColor : const Color(0xFFEBE3D0),
            width: isSelected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              gender == 'Laki-laki' ? Icons.male_rounded : Icons.female_rounded,
              size: 18,
              color: isSelected ? selectedColor : const Color(0xFF7A8B99),
            ),
            const SizedBox(width: 8),
            Text(
              gender,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? selectedColor : const Color(0xFF5A7184),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(18, 12, 18, 36 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Hero Avatar Besar (tap ganti foto) ──
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
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1C4E68).withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _isUploadingPhoto
                          ? Container(
                              width: 96,
                              height: 96,
                              color: const Color(0xFF276F8F).withValues(alpha: 0.1),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF276F8F),
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : SizedBox(
                              width: 96,
                              height: 96,
                              child: _buildDoctorAvatarImage(),
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
                          color: const Color(0xFF1C4E68),
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

          // Nama Dokter
          Text(
            widget.doctor.formattedNameWithDoctorTitle,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C4E68),
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Badge Dokter (Centered, Clean & Aesthetic)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFC8E6C9),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.medical_services_rounded,
                  size: 14,
                  color: Color(0xFF53A66B),
                ),
                const SizedBox(width: 5),
                Text(
                  'Dokter',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF53A66B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── SECTION 1: INFORMASI PRIBADI ──
          _buildSectionHeader(Icons.person_outline_rounded, 'Informasi Pribadi'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFEBE3D0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Lengkap
                  Text(
                    'Nama Lengkap',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A7184),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C4E68),
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF276F8F)),
                      filled: true,
                      fillColor: const Color(0xFFFBFBFD),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF276F8F), width: 1.4),
                      ),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Color(0xFFF0EBE1), thickness: 1),
                  ),

                  // Spesialisasi Medis
                  Text(
                    'Spesialisasi Medis',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A7184),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.medical_information_outlined,
                          size: 18,
                          color: Color(0xFF276F8F),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.doctor.specialty.isNotEmpty
                                ? widget.doctor.specialty
                                : 'Spesialis Penyakit Dalam',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C4E68),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Color(0xFFF0EBE1), thickness: 1),
                  ),

                  // Email Akun (Read-only)
                  Text(
                    'Email Akun Terdaftar',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A7184),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 18,
                          color: Color(0xFF276F8F),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _emailController.text.isNotEmpty
                                ? _emailController.text
                                : (FirebaseAuth.instance.currentUser?.email ?? ''),
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5A7184),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD0E4EE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 12,
                                color: Color(0xFF276F8F),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Terkunci',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF276F8F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Color(0xFFF0EBE1), thickness: 1),
                  ),

                  // Jenis Kelamin
                  Text(
                    'Jenis Kelamin',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A7184),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildGenderChip('Laki-laki')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildGenderChip('Perempuan')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── SECTION 2: LEGALITAS & PRAKTIK MEDIS ──
          _buildSectionHeader(Icons.health_and_safety_outlined, 'Legalitas & Praktik Medis'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFEBE3D0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nomor STR
                Text(
                  'Nomor STR Dokter',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A7184),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _strController,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C4E68),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.credit_card_rounded, size: 18, color: Color(0xFF276F8F)),
                    hintText: 'Contoh: 331110022334455',
                    hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFFBFBFD),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF276F8F), width: 1.4),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFF0EBE1), thickness: 1),
                ),

                // Status Verifikasi Klinis Card
                Text(
                  'Status Praktik Medis',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A7184),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF53A66B).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF53A66B)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STR Aktif & Terverifikasi',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1C4E68),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dokter terdaftar resmi di Konsil Kedokteran Indonesia (KKI) untuk layanan konsultasi LAMON',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF5A7184),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFF0EBE1), thickness: 1),
                ),

                // Statistik Konsultasi & Reputasi
                Text(
                  'Statistik Konsultasi & Reputasi',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A7184),
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('doctors')
                      .doc(widget.doctor.id)
                      .snapshots(),
                  builder: (context, snap) {
                    final docData = snap.data?.data();
                    final expYears = (docData?['experienceYears'] as num?)?.toInt() ?? widget.doctor.experienceYears;
                    final handled = (docData?['consultationsHandled'] as num?)?.toInt() ?? widget.doctor.consultationsHandled;
                    final ratingSum = (docData?['ratingSum'] as num?)?.toInt() ?? widget.doctor.ratingSum;
                    final ratingCount = (docData?['ratingCount'] as num?)?.toInt() ?? widget.doctor.ratingCount;
                    final ratingAvg = ratingCount > 0 ? (ratingSum / ratingCount).toStringAsFixed(1) : '5.0';

                    return Row(
                      children: [
                        // Pasien Ditangani
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.people_alt_outlined, size: 14, color: Color(0xFF276F8F)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$handled Pasien',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1C4E68),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ditangani',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF7A8B99),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Rating Bintang
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                                    const SizedBox(width: 3),
                                    Text(
                                      ratingAvg,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ratingCount > 0 ? '$ratingCount ulasan' : 'Rating',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Pengalaman Praktik
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.work_history_outlined, size: 14, color: Color(0xFF276F8F)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$expYears Thn',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1C4E68),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pengalaman',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF7A8B99),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Tombol Simpan Perubahan ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF276F8F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Simpan Perubahan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Tombol Keluar dari Akun Dokter ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _handleSignOut,
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFD32F2F),
                size: 18,
              ),
              label: Text(
                'Keluar dari Akun Dokter',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFD32F2F),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
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
          const SizedBox(height: 16),

          // App Version Footer
          Text(
            'LAMON • Aplikasi Monitoring Lambung',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF90A4AE),
            ),
          ),
        ],
      ),
    );
  }
}

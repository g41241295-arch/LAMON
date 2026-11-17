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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 40 + bottomInset),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ── Avatar Besar (tap ganti foto) ──
          Center(
            child: GestureDetector(
              onTap: _isUploadingPhoto ? null : _showPhotoSourceSheet,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: DoctorTheme.primary, width: 2.5),
                    ),
                    child: ClipOval(
                      child: _isUploadingPhoto
                          ? Container(
                              width: 96,
                              height: 96,
                              color: DoctorTheme.primary.withValues(alpha: 0.1),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: DoctorTheme.primary, strokeWidth: 2.5),
                              ),
                            )
                          : _buildDoctorAvatarImage(),
                    ),
                  ),
                  if (!_isUploadingPhoto)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: DoctorTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            widget.doctor.formattedNameWithDoctorTitle,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: DoctorTheme.primaryText,
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle profil dokter live dari data
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .doc(widget.doctor.id)
                .snapshots(),
            builder: (context, snap) {
              final docData = snap.data?.data();
              final specialty = docData?['specialty'] as String? ?? widget.doctor.specialty;
              final expYears = (docData?['experienceYears'] as num?)?.toInt() ?? widget.doctor.experienceYears;
              final handled = (docData?['consultationsHandled'] as num?)?.toInt() ?? widget.doctor.consultationsHandled;
              final ratingSum = (docData?['ratingSum'] as num?)?.toInt() ?? widget.doctor.ratingSum;
              final ratingCount = (docData?['ratingCount'] as num?)?.toInt() ?? widget.doctor.ratingCount;
              final ratingText = ratingCount > 0
                  ? ' • ★ ${(ratingSum / ratingCount).toStringAsFixed(1)} ($ratingCount)'
                  : '';
              final subtitle = '$specialty • $expYears tahun • $handled konsultasi ditangani$ratingText';

              return Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: DoctorTheme.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Kartu Form Profil ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: DoctorTheme.cardDecoration(
              borderRadius: 22,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'PROFIL',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: DoctorTheme.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _fieldLabel('Nama Lengkap'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.poppins(fontSize: 13, color: DoctorTheme.primaryText),
                    decoration: DoctorTheme.inputDecoration(hintText: 'Nama dokter...'),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty)
                            ? 'Nama tidak boleh kosong'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Email (Akun)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    style: GoogleFonts.poppins(fontSize: 13, color: DoctorTheme.secondaryText),
                    decoration: DoctorTheme.inputDecoration(
                      fillColor: const Color(0xFFEEF2F6),
                      suffixIcon: const Icon(Icons.lock_outline_rounded,
                          size: 18, color: DoctorTheme.neutralGray),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Nomor STR'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _strController,
                    style: GoogleFonts.poppins(fontSize: 13, color: DoctorTheme.primaryText),
                    decoration: DoctorTheme.inputDecoration(hintText: 'Contoh: 331110022334455'),
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Jenis Kelamin'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildGenderChip('Laki-laki')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildGenderChip('Perempuan')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: DoctorTheme.primaryButtonStyle(borderRadius: 16),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)))
                        : const Text('Simpan Perubahan'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _handleSignOut,
              icon: const Icon(Icons.logout_rounded,
                  color: DoctorTheme.alertRed, size: 20),
              label: Text(
                'Keluar dari Akun Dokter',
                style: GoogleFonts.poppins(
                  color: DoctorTheme.alertRed,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: DoctorTheme.alertRedBorder, width: 1.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: DoctorTheme.primaryText,
        ),
      );

  Widget _buildGenderChip(String gender) {
    final isSelected = _selectedGender == gender;
    final isFemale = gender == 'Perempuan';
    final selectedColor = isFemale ? const Color(0xFFD63384) : DoctorTheme.primary;
    final selectedBgColor = isFemale
        ? const Color(0xFFFCE4EF)
        : DoctorTheme.primary.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? selectedColor : DoctorTheme.cardBorder,
              width: isSelected ? 1.8 : 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                gender == 'Laki-laki'
                    ? Icons.male_rounded
                    : Icons.female_rounded,
                size: 18,
                color: isSelected ? selectedColor : DoctorTheme.neutralGray),
            const SizedBox(width: 6),
            Text(
              gender,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? selectedColor : DoctorTheme.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../konsultasi/widgets/doctor_avatar.dart';

/// Tab 3: Profil Dokter
/// C1: Judul PROFIL center+besar
/// C2: Chip Jenis Kelamin sama lebar (Expanded)
/// C3: Ganti foto profil (Storage/base64 fallback)
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
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _strController;
  late final TextEditingController _emailController;
  String? _selectedGender;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.doctor.name);
    _strController = TextEditingController(text: widget.doctor.strNumber);
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    _emailController = TextEditingController(text: userEmail);
    _selectedGender = widget.doctor.gender ?? 'Laki-laki';
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

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keluar',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun dokter?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal keluar: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // C3: Bottom sheet pilihan sumber foto
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppColors.primary),
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.photo_library_rounded,
                        color: AppColors.primary),
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

  // C3: Pilih + kompres + upload foto profil
  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _isUploadingPhoto = true);
      await _doctorService.updateDoctorPhotoUrl(
        doctorId: widget.doctor.id,
        imageBytes: bytes,
      );
      // Reload profil dokter → foto baru ikut tampil di kartu pasien, chat, dsb.
      widget.onProfileUpdated();
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                        border: Border.all(color: AppColors.primary, width: 2.5)),
                    child: ClipOval(
                      child: _isUploadingPhoto
                          ? Container(
                              width: 96,
                              height: 96,
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary, strokeWidth: 2.5),
                              ),
                            )
                          : DoctorAvatar(
                              photoUrl: widget.doctor.effectivePhotoUrl,
                              doctorId: widget.doctor.id,
                              doctorName: widget.doctor.name,
                              size: 96,
                              borderRadius: 48,
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

          Text(widget.doctor.formattedNameWithDoctorTitle,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText)),
          const SizedBox(height: 4),
          Text(widget.doctor.specialtyDisplay,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.summaryCardSubtext)),
          const SizedBox(height: 24),

          // ── Kartu Form Profil ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EFF5), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // C1: Judul Center + besar
                  const Center(
                    child: Text(
                      'PROFIL',
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.primaryText),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Nama Lengkap'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDeco('Nama dokter...'),
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
                    decoration: _inputDeco('').copyWith(
                      fillColor: const Color(0xFFEEF2F6),
                      suffixIcon: const Icon(Icons.lock_outline_rounded,
                          size: 18, color: AppColors.neutralGray),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Nomor STR'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _strController,
                    decoration: _inputDeco('Contoh: 331110022334455'),
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Jenis Kelamin'),
                  const SizedBox(height: 8),
                  // C2: Expanded agar lebar sama dan membentang penuh
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)))
                        : const Text('Simpan Perubahan',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
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
                  color: Color(0xFFD32F2F), size: 20),
              label: const Text('Keluar dari Akun Dokter',
                  style: TextStyle(
                      color: Color(0xFFD32F2F),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF8F8),
                side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.2),
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

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText));

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Widget _buildGenderChip(String gender) {
    final isSelected = _selectedGender == gender;
    final isFemale = gender == 'Perempuan';
    // Perempuan terpilih = pink, Laki-laki terpilih = biru
    final selectedColor = isFemale ? const Color(0xFFD63384) : AppColors.primary;
    final selectedBgColor = isFemale
        ? const Color(0xFFFCE4EF)
        : AppColors.primary.withValues(alpha: 0.12);
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? selectedColor : AppColors.inputBorder,
              width: isSelected ? 1.8 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                gender == 'Laki-laki'
                    ? Icons.male_rounded
                    : Icons.female_rounded,
                size: 18,
                color:
                    isSelected ? selectedColor : AppColors.neutralGray),
            const SizedBox(width: 6),
            Text(gender,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? selectedColor
                        : AppColors.primaryText)),
          ],
        ),
      ),
    );
  }
}

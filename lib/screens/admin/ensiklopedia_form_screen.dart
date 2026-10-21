import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../models/ensiklopedia_entry_model.dart';
import '../../services/ensiklopedia_service.dart';
import '../../utils/app_exception.dart';
import '../../widgets/admin/admin_markdown_editor.dart';
import '../../widgets/admin/admin_widgets.dart';
import '../../widgets/gastropedia/gastropedia_header.dart';

class EnsiklopediaFormScreen extends StatefulWidget {
  final EnsiklopediaEntry? initialEntry; // null = mode tambah
  final String adminName;
  final String adminId;

  const EnsiklopediaFormScreen({
    super.key,
    this.initialEntry,
    required this.adminName,
    required this.adminId,
  });

  @override
  State<EnsiklopediaFormScreen> createState() => _EnsiklopediaFormScreenState();
}

class _EnsiklopediaFormScreenState extends State<EnsiklopediaFormScreen> {
  final _service = EnsiklopediaService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaMakananCtrl;
  late final TextEditingController _caloriesCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _deskripsiCtrl;
  late final TextEditingController _manfaatCtrl;
  late final TextEditingController _kandunganCtrl;

  String _kategori = 'Makanan';
  final List<String> _kategoriOptions = ['Makanan', 'Buah', 'Sayuran'];

  bool _isRecommended = false;

  File? _imageFile;
  String? _existingImageUrl;

  String? _namaMakananError;
  String? _kategoriError;
  String? _imageError;
  String? _deskripsiError;
  String? _caloriesError;
  String? _proteinError;
  String? _carbsError;
  String? _fatError;

  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool get _isEditMode => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initialEntry;

    _namaMakananCtrl = TextEditingController(text: e?.istilah ?? '');

    // Kategori: jika ada data lama yang bukan Makanan/Buah/Sayuran, kosongkan chip agar admin pilih ulang
    if (e != null) {
      if (_kategoriOptions.contains(e.kategori)) {
        _kategori = e.kategori;
      } else {
        _kategori = '';
      }
    } else {
      _kategori = 'Makanan';
    }

    _existingImageUrl = (e?.imageAsset != null && e!.imageAsset!.isNotEmpty) ? e.imageAsset : null;
    _isRecommended = e?.isRecommended ?? false;

    _caloriesCtrl = TextEditingController(text: (e?.calories != null && e!.calories > 0) ? '${e.calories}' : '');
    _proteinCtrl = TextEditingController(text: (e?.protein != null && e!.protein > 0) ? '${e.protein}' : '');
    _carbsCtrl = TextEditingController(text: (e?.carbs != null && e!.carbs > 0) ? '${e.carbs}' : '');
    _fatCtrl = TextEditingController(text: (e?.fat != null && e!.fat > 0) ? '${e.fat}' : '');

    final initialDesc = (e?.definisiSingkat != null && e!.definisiSingkat.isNotEmpty)
        ? e.definisiSingkat
        : (e?.penjelasanLengkap ?? '');
    _deskripsiCtrl = TextEditingController(text: initialDesc);

    _manfaatCtrl = TextEditingController(text: e?.manfaat.join('\n') ?? '');
    _kandunganCtrl = TextEditingController(text: e?.kandungan.join('\n') ?? '');
  }

  @override
  void dispose() {
    _namaMakananCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _deskripsiCtrl.dispose();
    _manfaatCtrl.dispose();
    _kandunganCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final ext = picked.path.split('.').last.toLowerCase();
      if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
        _showError('Format gambar harus JPG atau PNG.');
        return;
      }

      final file = File(picked.path);
      final sizeBytes = await file.length();
      if (sizeBytes > 2 * 1024 * 1024) {
        _showError('Ukuran gambar melebihi 2MB. Silakan pilih gambar yang lebih kecil.');
        return;
      }

      setState(() {
        _imageFile = file;
        _imageError = null;
      });
    } catch (e) {
      _showError('Gagal memilih gambar: $e');
    }
  }

  Future<String> _uploadImageToStorage(File file, String docId) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final filename = '${DateTime.now().millisecondsSinceEpoch}_$docId.$ext';
      final ref = FirebaseStorage.instance.ref().child('gastropedia_images/$filename');
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$ext'),
      );
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('[EnsiklopediaForm] Firebase Storage error: ${e.code} - ${e.message}');
      throw AppException(
        'Gagal mengunggah gambar ke Firebase Storage (${e.code}): ${e.message ?? 'Layanan belum aktif'}.\n\n'
        'Langkah perbaikan di Firebase Console:\n'
        '1. Buka Firebase Console > Build > Storage > klik "Get Started".\n'
        '2. Pada tab "Rules", pastikan aturan mengizinkan admin untuk menulis, contoh:\n'
        'rules_version = \'2\';\n'
        'service firebase.storage {\n'
        '  match /b/{bucket}/o {\n'
        '    match /{allPaths=**} {\n'
        '      allow read: if request.auth != null;\n'
        '      allow write: if request.auth != null;\n'
        '    }\n'
        '  }\n'
        '}'
      );
    } catch (e) {
      debugPrint('[EnsiklopediaForm] Upload image error: $e');
      throw AppException('Gagal mengunggah gambar: $e');
    }
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _namaMakananError = null;
      _kategoriError = null;
      _imageError = null;
      _deskripsiError = null;
      _caloriesError = null;
      _proteinError = null;
      _carbsError = null;
      _fatError = null;
    });

    final nama = _namaMakananCtrl.text.trim();
    if (nama.isEmpty) {
      _namaMakananError = 'Nama makanan wajib diisi.';
      ok = false;
    }

    if (_kategori.isEmpty) {
      _kategoriError = 'Kategori wajib dipilih.';
      ok = false;
    }

    final hasImage = _imageFile != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);
    if (!hasImage) {
      _imageError = 'Gambar wajib diunggah.';
      ok = false;
    }

    final deskripsi = _deskripsiCtrl.text.trim();
    if (deskripsi.isEmpty) {
      _deskripsiError = 'Deskripsi wajib diisi.';
      ok = false;
    }

    final calText = _caloriesCtrl.text.trim();
    if (calText.isNotEmpty) {
      final val = num.tryParse(calText);
      if (val == null || val < 0) {
        _caloriesError = 'Kalori harus berupa angka tidak negatif.';
        ok = false;
      }
    }

    final protText = _proteinCtrl.text.trim();
    if (protText.isNotEmpty) {
      final val = num.tryParse(protText);
      if (val == null || val < 0) {
        _proteinError = 'Protein harus berupa angka tidak negatif.';
        ok = false;
      }
    }

    final carbsText = _carbsCtrl.text.trim();
    if (carbsText.isNotEmpty) {
      final val = num.tryParse(carbsText);
      if (val == null || val < 0) {
        _carbsError = 'Karbohidrat harus berupa angka tidak negatif.';
        ok = false;
      }
    }

    final fatText = _fatCtrl.text.trim();
    if (fatText.isNotEmpty) {
      final val = num.tryParse(fatText);
      if (val == null || val < 0) {
        _fatError = 'Lemak harus berupa angka tidak negatif.';
        ok = false;
      }
    }

    return ok;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    if (widget.adminId.isEmpty) {
      _showError('Gagal mendapatkan data admin. Silakan login ulang.');
      return;
    }

    setState(() => _isSaving = true);

    final istilah = _namaMakananCtrl.text.trim();
    final istilahLower = istilah.toLowerCase();
    final now = DateTime.now();

    String docId = widget.initialEntry?.id ?? '';
    if (docId.isEmpty) {
      docId = istilahLower
          .replaceAll(RegExp(r'[^a-z0-9\-_]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
    }

    try {
      String imageUrl = _existingImageUrl ?? '';
      if (_imageFile != null) {
        setState(() => _isUploadingImage = true);
        try {
          imageUrl = await _uploadImageToStorage(_imageFile!, docId);
        } finally {
          if (mounted) setState(() => _isUploadingImage = false);
        }
      }

      final manfaatList = _manfaatCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final kandunganList = _kandunganCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final calVal = num.tryParse(_caloriesCtrl.text.trim())?.round() ?? (widget.initialEntry?.calories ?? 150);
      final protVal = num.tryParse(_proteinCtrl.text.trim())?.round() ?? (widget.initialEntry?.protein ?? 6);
      final carbsVal = num.tryParse(_carbsCtrl.text.trim())?.round() ?? (widget.initialEntry?.carbs ?? 18);
      final fatVal = num.tryParse(_fatCtrl.text.trim())?.round() ?? (widget.initialEntry?.fat ?? 6);

      final deskripsiText = _deskripsiCtrl.text.trim();

      if (_isEditMode) {
        final updated = EnsiklopediaEntry(
          id: widget.initialEntry!.id,
          istilah: istilah,
          istilahLower: istilahLower,
          namaLain: widget.initialEntry?.namaLain,
          definisiSingkat: deskripsiText,
          penjelasanLengkap: deskripsiText,
          kategori: _kategori,
          referensi: widget.initialEntry?.referensi,
          createdBy: widget.initialEntry?.createdBy ?? '',
          createdById: widget.initialEntry?.createdById ?? '',
          createdByType: widget.initialEntry?.createdByType ?? 'admin',
          createdAt: widget.initialEntry?.createdAt ?? now,
          updatedBy: widget.adminName,
          updatedById: widget.adminId,
          updatedAt: now,
          status: widget.initialEntry?.status ?? 'terbit',
          imageAsset: imageUrl,
          manfaat: manfaatList,
          kandungan: kandunganList,
          isRecommended: _isRecommended,
          calories: calVal,
          protein: protVal,
          carbs: carbsVal,
          fat: fatVal,
        );

        final newId = await _service.updateEntry(
          widget.initialEntry!.id,
          updated,
          widget.adminName,
          widget.adminId,
        );

        // Pastikan field deskripsi & imageAsset tersimpan dengan aman
        await FirebaseFirestore.instance.collection('encyclopedia').doc(newId).set({
          'deskripsi': deskripsiText,
          'definisiSingkat': deskripsiText,
          'penjelasanLengkap': deskripsiText,
          'imageAsset': imageUrl,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(_successSnackbar('Data gastropedia berhasil diperbarui.'));
          Navigator.of(context).pop();
        }
      } else {
        final entry = EnsiklopediaEntry(
          id: docId,
          istilah: istilah,
          istilahLower: istilahLower,
          namaLain: null,
          definisiSingkat: deskripsiText,
          penjelasanLengkap: deskripsiText,
          kategori: _kategori,
          referensi: null,
          createdBy: widget.adminName,
          createdById: widget.adminId,
          createdByType: 'admin',
          createdAt: now,
          status: 'terbit', // Entri baru otomatis berstatus terbit
          imageAsset: imageUrl,
          manfaat: manfaatList,
          kandungan: kandunganList,
          isRecommended: _isRecommended,
          calories: calVal,
          protein: protVal,
          carbs: carbsVal,
          fat: fatVal,
        );

        await _service.createEntry(entry, widget.adminName, widget.adminId);

        // Pastikan field deskripsi & imageAsset tersimpan dengan aman
        await FirebaseFirestore.instance.collection('encyclopedia').doc(docId).set({
          'deskripsi': deskripsiText,
          'definisiSingkat': deskripsiText,
          'penjelasanLengkap': deskripsiText,
          'imageAsset': imageUrl,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(_successSnackbar('Data gastropedia berhasil ditambahkan.'));
          Navigator.of(context).pop();
        }
      }
    } on AppException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.adminRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  SnackBar _successSnackbar(String msg) => SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );

  Widget _buildImagePicker() {
    final hasImage = _imageFile != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    return GestureDetector(
      onTap: (_isSaving || _isUploadingImage) ? null : _pickImage,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _imageError != null ? AppColors.adminRed : AppColors.inputBorder,
            width: _imageError != null ? 1.6 : 1.4,
          ),
        ),
        child: _isUploadingImage
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(color: AppColors.adminBlue, strokeWidth: 2.5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Mengunggah gambar...',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.adminBlue),
                    ),
                  ],
                ),
              )
            : hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_imageFile != null)
                          Image.file(_imageFile!, fit: BoxFit.cover)
                        else if (_existingImageUrl!.startsWith('http'))
                          Image.network(
                            _existingImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildUploadPlaceholder(),
                          )
                        else
                          Image.asset(
                            _existingImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildUploadPlaceholder(),
                          ),
                        // Tombol hapus di pojok kanan atas
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: (_isSaving || _isUploadingImage)
                                ? null
                                : () {
                                    setState(() {
                                      _imageFile = null;
                                      _existingImageUrl = null;
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        // Tombol ganti gambar di bar bawah
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.black54,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Ganti Gambar',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildUploadPlaceholder(),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: AppColors.adminBlue.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Unggah Gambar',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.adminBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Format JPG/PNG, maks. 2MB',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.neutralGray,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      header: GastropediaHeader(
        title: _isEditMode ? 'Edit Gastropedia' : 'Tambah Gastropedia',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            40 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Nama Makanan
              AdminInputField(
                label: 'Nama Makanan',
                hint: 'Contoh : Oatmeal',
                controller: _namaMakananCtrl,
                errorText: _namaMakananError,
                onChanged: (_) => setState(() => _namaMakananError = null),
              ),
              const SizedBox(height: 16),

              // 2. Kategori (Wrap chips)
              Text(
                'Kategori',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kategoriOptions.map((k) {
                  final active = _kategori == k;
                  return AdminFilterChip(
                    label: k,
                    isActive: active,
                    onTap: () => setState(() {
                      _kategori = k;
                      _kategoriError = null;
                    }),
                  );
                }).toList(),
              ),
              if (_kategoriError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _kategoriError!,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.adminRed),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 3. Gambar
              Text(
                'Gambar',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              _buildImagePicker(),
              if (_imageError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _imageError!,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.adminRed),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 4. Rekomendasi Makanan (Switch)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.inputBorder, width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rekomendasi Makanan',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Tampilkan di bagian rekomendasi pada halaman Gastropedia pengguna',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.neutralGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isRecommended,
                      activeThumbColor: AppColors.adminBlue,
                      onChanged: (_isSaving || _isUploadingImage)
                          ? null
                          : (val) => setState(() => _isRecommended = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Informasi Nutrisi (2 Kolom)
              Text(
                'Informasi Nutrisi',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AdminInputField(
                      label: 'Kalori',
                      hint: '150',
                      suffixText: 'kkal',
                      controller: _caloriesCtrl,
                      keyboardType: TextInputType.number,
                      errorText: _caloriesError,
                      onChanged: (_) => setState(() => _caloriesError = null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminInputField(
                      label: 'Protein',
                      hint: '5.0',
                      suffixText: 'g',
                      controller: _proteinCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      errorText: _proteinError,
                      onChanged: (_) => setState(() => _proteinError = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AdminInputField(
                      label: 'Karbohidrat',
                      hint: '27.0',
                      suffixText: 'g',
                      controller: _carbsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      errorText: _carbsError,
                      onChanged: (_) => setState(() => _carbsError = null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminInputField(
                      label: 'Lemak',
                      hint: '2.5',
                      suffixText: 'g',
                      controller: _fatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      errorText: _fatError,
                      onChanged: (_) => setState(() => _fatError = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Deskripsi (Toolbar B / I / list)
              AdminMarkdownEditorField(
                label: 'Deskripsi',
                hint: 'Tulis deskripsi makanan',
                controller: _deskripsiCtrl,
                errorText: _deskripsiError,
                minLines: 4,
                maxLines: 6,
                onChanged: (_) => setState(() => _deskripsiError = null),
              ),
              const SizedBox(height: 16),

              // 7. Manfaat (Toolbar B / I / list)
              AdminMarkdownEditorField(
                label: 'Manfaat',
                hint: 'Tulis satu manfaat per baris',
                controller: _manfaatCtrl,
                minLines: 4,
                maxLines: 6,
              ),
              const SizedBox(height: 16),

              // 8. Kandungan (Toolbar B / I / list)
              AdminMarkdownEditorField(
                label: 'Kandungan',
                hint: 'Tulis satu kandungan per baris',
                controller: _kandunganCtrl,
                minLines: 4,
                maxLines: 6,
              ),
              const SizedBox(height: 32),

              // 9. Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSaving || _isUploadingImage) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.adminBlue.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: (_isSaving || _isUploadingImage)
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _isEditMode ? 'Simpan Perubahan' : 'Simpan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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

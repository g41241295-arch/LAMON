import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../models/berita_article_model.dart';
import '../../services/berita/berita_service.dart';
import '../../utils/app_exception.dart';
import '../../widgets/admin/admin_widgets.dart';
import '../../widgets/app_header_pill.dart';
import '../../widgets/berita/berita_image.dart';

const List<String> _kKategori = [
  'Pencernaan',
  'Gizi',
  'Gaya Hidup',
  'Kesehatan Umum',
];

class BeritaFormScreen extends StatefulWidget {
  /// Null = mode tambah baru
  final BeritaArticle? initialArtikel;
  final String adminName;
  final String adminId;

  const BeritaFormScreen({
    super.key,
    this.initialArtikel,
    this.adminName = 'Admin',
    this.adminId = '',
  });

  @override
  State<BeritaFormScreen> createState() => _BeritaFormScreenState();
}

class _BeritaFormScreenState extends State<BeritaFormScreen> {
  final _service = BeritaService();
  final _judulCtrl = TextEditingController();
  final _ringkasanCtrl = TextEditingController();
  final _penjelasanCtrl = TextEditingController();
  final _sumberNamaCtrl = TextEditingController();
  final _sumberUrlCtrl = TextEditingController();

  String _kategori = _kKategori.first;
  DateTime? _tanggal;
  List<String> _bacaJuga = [];

  File? _imageFile;
  String? _existingImageUrl; // URL atau asset gambar yang sudah ada (mode edit)

  bool _isSaving = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool get _isEditMode => widget.initialArtikel != null;

  // Error texts
  String? _judulError;
  String? _kategoriError;
  String? _tanggalError;
  String? _ringkasanError;
  String? _penjelasanError;

  @override
  void initState() {
    super.initState();
    final a = widget.initialArtikel;
    if (a != null) {
      _judulCtrl.text = a.judul;
      _ringkasanCtrl.text = a.ringkasanSingkat;
      _penjelasanCtrl.text = a.kontenMarkdown ?? '';
      _sumberNamaCtrl.text = a.sumberNama;
      _sumberUrlCtrl.text = a.sumberUrl;
      _kategori = _kKategori.contains(a.kategori) ? a.kategori : _kKategori.first;
      _tanggal = a.tanggal;
      _bacaJuga = List<String>.from(a.bacaJuga);
      _existingImageUrl = a.gambarUrl.isNotEmpty
          ? a.gambarUrl
          : (a.gambarAsset.isNotEmpty ? a.gambarAsset : null);
    } else {
      // Default tanggal hari ini untuk artikel baru
      _tanggal = DateTime.now();
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _ringkasanCtrl.dispose();
    _penjelasanCtrl.dispose();
    _sumberNamaCtrl.dispose();
    _sumberUrlCtrl.dispose();
    super.dispose();
  }

  // ── Format tanggal Indonesia ───────────────────────────────────────────────

  String _formatDateIndo(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF134563),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tanggal = picked;
        _tanggalError = null;
      });
    }
  }

  // ── Validasi ──────────────────────────────────────────────────────────────

  bool _validate({required bool forPublish}) {
    bool ok = true;
    setState(() {
      _judulError = null;
      _kategoriError = null;
      _tanggalError = null;
      _ringkasanError = null;
      _penjelasanError = null;
    });

    if (_judulCtrl.text.trim().isEmpty) {
      _judulError = 'Judul artikel wajib diisi.';
      ok = false;
    }

    if (forPublish) {
      if (_tanggal == null) {
        _tanggalError = 'Tanggal terbit wajib diisi untuk menerbitkan.';
        ok = false;
      }
      if (_ringkasanCtrl.text.trim().isEmpty) {
        _ringkasanError = 'Ringkasan singkat wajib diisi untuk menerbitkan.';
        ok = false;
      }
      if (_penjelasanCtrl.text.trim().isEmpty) {
        _penjelasanError = 'Penjelasan lengkap wajib diisi untuk menerbitkan.';
        ok = false;
      }
    }

    setState(() {});
    return ok;
  }

  // ── Upload gambar ─────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 75,
      );
      if (picked == null || !mounted) return;

      final file = File(picked.path);
      if (!await file.exists()) {
        _showError('Berkas gambar tidak ditemukan di penyimpanan perangkat.');
        return;
      }

      final ext = file.path.split('.').last.toLowerCase();
      const allowed = ['jpg', 'jpeg', 'png', 'webp'];
      if (!allowed.contains(ext)) {
        _showError('Format berkas .$ext tidak didukung. Harap pilih gambar dengan format JPG atau PNG.');
        return;
      }

      final sizeBytes = await file.length();
      if (sizeBytes > 2 * 1024 * 1024) {
        final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
        _showError('Ukuran gambar ($sizeMb MB) melebihi batas 2 MB. Silakan pilih gambar yang lebih kecil.');
        return;
      }

      setState(() {
        _imageFile = file;
      });
      debugPrint('[BeritaForm] Gambar lokal dipilih: ${file.path} ($sizeBytes bytes)');
    } catch (e) {
      _showError('Gagal memilih gambar: $e');
    }
  }

  // ── Simpan / Terbitkan ────────────────────────────────────────────────────

  Future<void> _save({required bool forPublish}) async {
    if (!_validate(forPublish: forPublish)) return;

    setState(() {
      _isSaving = true;
      _uploadProgress = 0.0;
    });

    try {
      final targetId = widget.initialArtikel?.id ??
          FirebaseFirestore.instance.collection('berita_articles').doc().id;

      String finalGambarUrl = '';
      String finalGambarAsset = '';

      if (_imageFile != null) {
        setState(() => _isUploading = true);
        try {
          final uploadedUrl = await _service.uploadBeritaCover(
            _imageFile!,
            targetId,
            onProgress: (p) => setState(() => _uploadProgress = p),
          );
          finalGambarUrl = uploadedUrl;
          debugPrint('[BeritaForm] Berhasil upload gambar cover: $finalGambarUrl');

          // Hapus gambar lama di Storage jika mode edit dan URL lama diganti
          if (_isEditMode && widget.initialArtikel?.gambarUrl.isNotEmpty == true) {
            final oldUrl = widget.initialArtikel!.gambarUrl;
            if (oldUrl != finalGambarUrl) {
              await _service.deleteStorageFile(oldUrl);
            }
          }
        } catch (uploadErr) {
          setState(() {
            _isUploading = false;
            _isSaving = false;
          });
          String errDetail = '$uploadErr';
          if (uploadErr is FirebaseException) {
            debugPrint('[BeritaForm] FirebaseException saat upload: code=${uploadErr.code}, message=${uploadErr.message}, plugin=${uploadErr.plugin}');
            errDetail = '[${uploadErr.code}] ${uploadErr.message ?? 'Gagal upload'}';
          } else if (uploadErr is AppException) {
            debugPrint('[BeritaForm] AppException saat upload: ${uploadErr.message}');
            errDetail = uploadErr.message;
          }
          if (mounted) {
            _showError('Gagal mengunggah gambar ke Storage: $errDetail. Berita tidak disimpan.');
          }
          return;
        } finally {
          if (mounted) setState(() => _isUploading = false);
        }
      } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
        // Pertahankan gambar lama (jangan tertimpa kosong)
        if (_existingImageUrl!.startsWith('http://') ||
            _existingImageUrl!.startsWith('https://') ||
            _existingImageUrl!.startsWith('data:image')) {
          finalGambarUrl = _existingImageUrl!;
        } else {
          finalGambarAsset = _existingImageUrl!;
        }
        debugPrint('[BeritaForm] Mempertahankan gambar lama: $_existingImageUrl');
      }

      final publish = forPublish;
      final now = DateTime.now();

      final artikel = BeritaArticle(
        id: targetId,
        judul: _judulCtrl.text.trim(),
        kategori: _kategori,
        tanggal: _tanggal ?? (publish ? now : null),
        gambarUrl: finalGambarUrl,
        gambarAsset: finalGambarAsset,
        konten: BeritaArticle.parseMarkdown(_penjelasanCtrl.text.trim()),
        sumberNama: _sumberNamaCtrl.text.trim(),
        sumberUrl: _sumberUrlCtrl.text.trim(),
        ringkasanSingkat: _ringkasanCtrl.text.trim(),
        status: publish ? 'terbit' : 'draft',
        bacaJuga: _bacaJuga,
        kontenMarkdown: _penjelasanCtrl.text.trim().isNotEmpty
            ? _penjelasanCtrl.text.trim()
            : null,
      );

      debugPrint('[BeritaForm] Menyimpan artikel (ID: $targetId, status: ${artikel.status}, gambarUrl: $finalGambarUrl, gambarAsset: $finalGambarAsset)');

      if (_isEditMode) {
        final wasPublished = widget.initialArtikel!.status == 'terbit';
        await _service.updateArtikel(
          artikelId: targetId,
          artikel: artikel,
          adminName: widget.adminName,
          adminId: widget.adminId,
          wasPublished: wasPublished,
        );
        if (mounted) {
          _showSuccess(publish
              ? (wasPublished ? 'Perubahan berhasil disimpan.' : 'Artikel berhasil diterbitkan.')
              : 'Draft berhasil disimpan.');
          Navigator.of(context).pop(true);
        }
      } else {
        await _service.createArtikel(
          artikel: artikel,
          adminName: widget.adminName,
          adminId: widget.adminId,
        );
        if (mounted) {
          _showSuccess(publish
              ? 'Artikel berhasil diterbitkan.'
              : 'Draft berhasil disimpan.');
          Navigator.of(context).pop(true);
        }
      }
    } on AppException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: AppColors.adminRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: AppColors.successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Toolbar editor markdown ───────────────────────────────────────────────

  void _insertMarkdown(String syntax) {
    final ctrl = _penjelasanCtrl;
    final sel = ctrl.selection;
    final text = ctrl.text;
    if (!sel.isValid) {
      ctrl.text = text + syntax;
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
      return;
    }
    final selected = sel.textInside(text);
    String replacement;
    int cursorOffset;

    if (syntax == '**') {
      replacement = '**$selected**';
      cursorOffset = sel.start + replacement.length - 2;
    } else if (syntax == '_') {
      replacement = '_${selected}_';
      cursorOffset = sel.start + replacement.length - 1;
    } else {
      // bullet: tambah baris baru dengan "- " di awal
      final before = text.substring(0, sel.start);
      final after = text.substring(sel.end);
      final newLine = before.endsWith('\n') || before.isEmpty ? '' : '\n';
      replacement = '$before$newLine- $selected$after';
      ctrl.text = replacement;
      ctrl.selection = TextSelection.collapsed(
          offset: sel.start + newLine.length + 2 + selected.length);
      setState(() {});
      return;
    }

    ctrl.text = text.substring(0, sel.start) + replacement + text.substring(sel.end);
    ctrl.selection = TextSelection.collapsed(offset: cursorOffset);
    setState(() {});
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isAlreadyPublished = _isEditMode && widget.initialArtikel?.status == 'terbit';
    final String publishButtonText = isAlreadyPublished ? 'Simpan Perubahan' : 'Terbitkan';

    return AdminScaffold(
      header: AppHeaderPill(
        title: _isEditMode ? 'Edit Artikel Berita' : 'Tambah Artikel Berita',
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            32 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Upload gambar sampul ─────────────────────────────────────
              _buildImagePicker(),
              const SizedBox(height: 20),

              // ── 2. Judul Artikel ────────────────────────────────────────────
              AdminInputField(
                label: 'Judul Artikel',
                hint: 'Tulis judul artikel...',
                controller: _judulCtrl,
                errorText: _judulError,
                onChanged: (_) => setState(() => _judulError = null),
              ),
              const SizedBox(height: 18),

              // ── 3. Kategori ─────────────────────────────────────────────────
              _buildLabel('Kategori'),
              const SizedBox(height: 8),
              _buildKategoriChips(),
              if (_kategoriError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(_kategoriError!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.adminRed)),
                ),
              ],
              const SizedBox(height: 18),

              // ── 4. Tanggal Terbit ───────────────────────────────────────────
              _buildLabel('Tanggal Terbit'),
              const SizedBox(height: 8),
              _buildDatePicker(),
              if (_tanggalError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(_tanggalError!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.adminRed)),
                ),
              ],
              const SizedBox(height: 18),

              // ── 5. Ringkasan Singkat ────────────────────────────────────────
              AdminInputField(
                label: 'Ringkasan Singkat',
                hint: '1-2 kalimat ringkasan untuk preview...',
                controller: _ringkasanCtrl,
                maxLines: 3,
                errorText: _ringkasanError,
                onChanged: (_) => setState(() => _ringkasanError = null),
              ),
              const SizedBox(height: 18),

              // ── 6. Penjelasan Lengkap (editor markdown) ────────────────────
              _buildLabel('Penjelasan Lengkap'),
              const SizedBox(height: 8),
              _buildMarkdownEditor(),
              if (_penjelasanError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(_penjelasanError!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.adminRed)),
                ),
              ],
              const SizedBox(height: 18),

              // ── 7. Sumber (opsional) ────────────────────────────────────────
              AdminInputField(
                label: 'Sumber (opsional)',
                hint: 'Nama media/sumber artikel',
                controller: _sumberNamaCtrl,
              ),
              const SizedBox(height: 12),

              // ── 8. Link Sumber (opsional) ───────────────────────────────────
              AdminInputField(
                label: 'Link Sumber (opsional)',
                hint: 'https://...',
                controller: _sumberUrlCtrl,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),

              // ── 9. Tombol aksi (Simpan Draft & Terbitkan/Simpan Perubahan) ─
              _buildActionButtons(publishButtonText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      ),
    );
  }

  // ── Upload gambar sampul ──────────────────────────────────────────────────

  Widget _buildImagePicker() {
    final bool hasImage = _imageFile != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder, width: 1.4),
      ),
      child: Column(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: _isUploading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            value: _uploadProgress > 0 ? _uploadProgress : null,
                            strokeWidth: 3,
                            color: const Color(0xFF134563),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Mengunggah gambar... ${(_uploadProgress * 100).toInt()}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF134563),
                          ),
                        ),
                      ],
                    ),
                  )
                : _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      )
                    : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: BeritaImage(
                              gambarUrl: (_existingImageUrl!.startsWith('http') || _existingImageUrl!.startsWith('data:image'))
                                  ? _existingImageUrl
                                  : null,
                              gambarAsset: _existingImageUrl!.startsWith('assets/') ? _existingImageUrl : null,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: _isSaving || _isUploading ? null : _pickImage,
                            child: _buildUploadPlaceholder(),
                          ),
          ),
          if (hasImage && !_isUploading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _isSaving ? null : _pickImage,
                    icon: const Icon(Icons.photo_library_outlined, size: 16, color: Color(0xFF134563)),
                    label: Text(
                      'Ganti Gambar',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF134563)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() {
                              _imageFile = null;
                              _existingImageUrl = null;
                            });
                          },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.adminRed),
                    label: Text(
                      'Hapus Gambar',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.adminRed),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.adminBlue.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(
            'Unggah Gambar Sampul',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.adminBlue),
          ),
          const SizedBox(height: 2),
          Text(
            'Format JPG/PNG, maks. 2MB',
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.neutralGray),
          ),
        ],
      ),
    );
  }

  // ── Kategori chips ────────────────────────────────────────────────────────

  Widget _buildKategoriChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kKategori.map((kat) {
        final selected = _kategori == kat;
        return GestureDetector(
          onTap: () => setState(() {
            _kategori = kat;
            _kategoriError = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF134563) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? const Color(0xFF134563) : AppColors.inputBorder,
                width: 1.4,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: const Color(0xFF134563).withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Text(
              kat,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.primaryText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Date Picker Field ─────────────────────────────────────────────────────

  Widget _buildDatePicker() {
    final dateText = _tanggal != null
        ? _formatDateIndo(_tanggal!)
        : 'Pilih tanggal terbit';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _isSaving ? null : _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _tanggalError != null ? AppColors.adminRed : AppColors.inputBorder,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: Color(0xFF134563), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dateText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _tanggal != null ? AppColors.primaryText : AppColors.neutralGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.neutralGray, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Editor markdown + toolbar ─────────────────────────────────────────────

  Widget _buildMarkdownEditor() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _penjelasanError != null ? AppColors.adminRed : AppColors.inputBorder,
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          // Toolbar format teks
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _buildToolbarButton(
                  icon: Icons.format_bold_rounded,
                  tooltip: 'Tebal (**teks**)',
                  onTap: () => _insertMarkdown('**'),
                ),
                const SizedBox(width: 4),
                _buildToolbarButton(
                  icon: Icons.format_italic_rounded,
                  tooltip: 'Miring (_teks_)',
                  onTap: () => _insertMarkdown('_'),
                ),
                const SizedBox(width: 4),
                _buildToolbarButton(
                  icon: Icons.format_list_bulleted_rounded,
                  tooltip: 'Daftar butir (- butir)',
                  onTap: () => _insertMarkdown('- '),
                ),
                const Spacer(),
                Text(
                  'Markdown didukung',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.neutralGray),
                ),
              ],
            ),
          ),
          // Area input teks
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: TextField(
              controller: _penjelasanCtrl,
              maxLines: 12,
              minLines: 8,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.6, color: AppColors.primaryText),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Tulis isi lengkap artikel di sini...\n\nGunakan toolbar di atas untuk format teks tebal, miring, atau daftar butir (- butir).',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.neutralGray, height: 1.6),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() => _penjelasanError = null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4FB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF134563)),
        ),
      ),
    );
  }

  // ── Tombol Aksi ───────────────────────────────────────────────────────────

  Widget _buildActionButtons(String publishLabel) {
    final bool isBusy = _isSaving || _isUploading;

    return Row(
      children: [
        // Tombol Simpan Draft
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: isBusy ? null : () => _save(forPublish: false),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF9DB),
                side: const BorderSide(color: Color(0xFF134563), width: 1.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Simpan Draft',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF134563),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Tombol Terbitkan / Simpan Perubahan
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: isBusy ? null : () => _save(forPublish: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF134563),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      publishLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

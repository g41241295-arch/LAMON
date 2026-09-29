import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/ensiklopedia_entry_model.dart';
import '../../services/ensiklopedia_service.dart';
import '../../utils/app_exception.dart';
import '../../widgets/admin/admin_widgets.dart';

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

  late final TextEditingController _istilahCtrl;
  late final TextEditingController _namaLainCtrl;
  late final TextEditingController _definisiCtrl;
  late final TextEditingController _penjelasanCtrl;
  late final TextEditingController _referensiCtrl;

  String _kategori = 'Pencernaan';
  final List<String> _kategoriOptions = ['Pencernaan', 'Gizi', 'Gaya Hidup'];

  String? _istilahError;
  String? _definisiError;
  String? _penjelasanError;
  String? _referensiError;

  bool _isSaving = false;
  bool get _isEditMode => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initialEntry;
    _istilahCtrl = TextEditingController(text: e?.istilah ?? '');
    _namaLainCtrl = TextEditingController(text: e?.namaLain ?? '');
    _definisiCtrl = TextEditingController(text: e?.definisiSingkat ?? '');
    _penjelasanCtrl = TextEditingController(text: e?.penjelasanLengkap ?? '');
    _referensiCtrl = TextEditingController(text: e?.referensi ?? '');
    _kategori = e?.kategori ?? 'Pencernaan';
  }

  @override
  void dispose() {
    _istilahCtrl.dispose();
    _namaLainCtrl.dispose();
    _definisiCtrl.dispose();
    _penjelasanCtrl.dispose();
    _referensiCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _istilahError = null;
      _definisiError = null;
      _penjelasanError = null;
      _referensiError = null;
    });

    final istilah = _istilahCtrl.text.trim();
    final definisi = _definisiCtrl.text.trim();
    final penjelasan = _penjelasanCtrl.text.trim();
    final referensi = _referensiCtrl.text.trim();

    if (istilah.isEmpty) {
      _istilahError = 'Istilah medis tidak boleh kosong.';
      ok = false;
    }
    if (definisi.isEmpty) {
      _definisiError = 'Definisi singkat tidak boleh kosong.';
      ok = false;
    }
    if (penjelasan.isEmpty) {
      _penjelasanError = 'Penjelasan lengkap tidak boleh kosong.';
      ok = false;
    }
    if (referensi.isNotEmpty) {
      final uri = Uri.tryParse(referensi);
      if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        _referensiError = 'Referensi harus berupa URL valid (contoh: https://...).';
        ok = false;
      }
    }

    setState(() {});
    return ok;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    if (widget.adminId.isEmpty) {
      _showError('Gagal mendapatkan data admin. Silakan login ulang.');
      return;
    }

    setState(() => _isSaving = true);

    final istilah = _istilahCtrl.text.trim();
    final now = DateTime.now();

    try {
      if (_isEditMode) {
        final updated = EnsiklopediaEntry(
          id: '', // akan di-generate oleh service
          istilah: istilah,
          istilahLower: istilah.toLowerCase(),
          namaLain: _namaLainCtrl.text.trim().isNotEmpty ? _namaLainCtrl.text.trim() : null,
          definisiSingkat: _definisiCtrl.text.trim(),
          penjelasanLengkap: _penjelasanCtrl.text.trim(),
          kategori: _kategori,
          referensi: _referensiCtrl.text.trim().isNotEmpty ? _referensiCtrl.text.trim() : null,
          // Data dibawah akan diisi oleh service dari oldData:
          createdBy: '',
          createdById: '',
          createdByType: '',
          createdAt: now,
          updatedBy: widget.adminName,
          updatedById: widget.adminId,
          updatedAt: now,
        );

        // updateEntry mengembalikan newId (bisa berubah jika istilah diganti)
        await _service.updateEntry(
          widget.initialEntry!.id,
          updated,
          widget.adminName,
          widget.adminId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(_successSnackbar('Entri berhasil diperbarui.'));
          // Pop kembali ke list; jika ID berubah, list sudah update via stream sehingga tidak ada "tidak ditemukan"
          Navigator.of(context).pop();
        }
      } else {
        final entry = EnsiklopediaEntry(
          id: '',
          istilah: istilah,
          istilahLower: istilah.toLowerCase(),
          namaLain: _namaLainCtrl.text.trim().isNotEmpty ? _namaLainCtrl.text.trim() : null,
          definisiSingkat: _definisiCtrl.text.trim(),
          penjelasanLengkap: _penjelasanCtrl.text.trim(),
          kategori: _kategori,
          referensi: _referensiCtrl.text.trim().isNotEmpty ? _referensiCtrl.text.trim() : null,
          createdBy: widget.adminName,
          createdById: widget.adminId,
          createdByType: 'admin',
          createdAt: now,
        );

        await _service.createEntry(entry, widget.adminName, widget.adminId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(_successSnackbar('Entri berhasil ditambahkan.'));
          Navigator.of(context).pop();
        }
      }
    } on AppException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: AppColors.adminRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AdminAppBar(
        title: _isEditMode ? 'Edit Entri Ensiklopedia' : 'Tambah Entri Ensiklopedia',
      ),
      body: AdminGradientBackground(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminInputField(
                  label: 'Istilah Medis',
                  hint: 'Contoh : Dyspepsia',
                  controller: _istilahCtrl,
                  errorText: _istilahError,
                  onChanged: (_) => setState(() => _istilahError = null),
                ),
                const SizedBox(height: 16),
                AdminInputField(
                  label: 'Nama Lain/Singkatan',
                  hint: 'Contoh : Maag',
                  controller: _namaLainCtrl,
                ),
                const SizedBox(height: 16),
                AdminInputField(
                  label: 'Definisi Singkat',
                  hint: '1-2 kalimat untuk ringkasan card',
                  controller: _definisiCtrl,
                  maxLines: 3,
                  errorText: _definisiError,
                  onChanged: (_) => setState(() => _definisiError = null),
                ),
                const SizedBox(height: 16),
                AdminInputField(
                  label: 'Penjelasan Lengkap',
                  hint: 'Penjelasan detail istilah medis ini...',
                  controller: _penjelasanCtrl,
                  maxLines: 6,
                  errorText: _penjelasanError,
                  onChanged: (_) => setState(() => _penjelasanError = null),
                ),
                const SizedBox(height: 16),

                // Kategori single-select chips
                Text(
                  'Kategori Terkait',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _kategoriOptions.map((k) {
                    final active = _kategori == k;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: AdminFilterChip(
                        label: k,
                        isActive: active,
                        onTap: () => setState(() => _kategori = k),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                AdminInputField(
                  label: 'Referensi/Sumber (opsional)',
                  hint: 'Link jurnal/sumber medis',
                  controller: _referensiCtrl,
                  keyboardType: TextInputType.url,
                  errorText: _referensiError,
                  onChanged: (_) => setState(() => _referensiError = null),
                ),
                const SizedBox(height: 32),

                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.adminBlue.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Simpan',
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
      ),
    );
  }
}

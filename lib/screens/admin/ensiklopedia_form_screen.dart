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
  late final TextEditingController _imageAssetCtrl;
  late final TextEditingController _manfaatCtrl;
  late final TextEditingController _kandunganCtrl;
  late final TextEditingController _caloriesCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;

  String _kategori = 'Makanan';
  final List<String> _kategoriOptions = [
    'Makanan',
    'Buah',
    'Sayuran',
    'Pencernaan',
    'Gizi',
    'Gaya Hidup',
  ];

  String _status = 'terbit';
  final List<String> _statusOptions = ['terbit', 'draft'];
  bool _isRecommended = false;

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
    _imageAssetCtrl = TextEditingController(text: e?.imageAsset ?? '');
    _manfaatCtrl = TextEditingController(text: e?.manfaat.join('\n') ?? '');
    _kandunganCtrl = TextEditingController(text: e?.kandungan.join('\n') ?? '');
    _caloriesCtrl = TextEditingController(text: e?.calories != null ? '${e!.calories}' : '');
    _proteinCtrl = TextEditingController(text: e?.protein != null ? '${e!.protein}' : '');
    _carbsCtrl = TextEditingController(text: e?.carbs != null ? '${e!.carbs}' : '');
    _fatCtrl = TextEditingController(text: e?.fat != null ? '${e!.fat}' : '');

    _kategori = e?.kategori ?? 'Makanan';
    _status = e?.status ?? 'terbit';
    _isRecommended = e?.isRecommended ?? false;
  }

  @override
  void dispose() {
    _istilahCtrl.dispose();
    _namaLainCtrl.dispose();
    _definisiCtrl.dispose();
    _penjelasanCtrl.dispose();
    _referensiCtrl.dispose();
    _imageAssetCtrl.dispose();
    _manfaatCtrl.dispose();
    _kandunganCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
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
    final imageAsset = _imageAssetCtrl.text.trim().isNotEmpty ? _imageAssetCtrl.text.trim() : null;
    final manfaatList = _manfaatCtrl.text.trim().isNotEmpty
        ? _manfaatCtrl.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];
    final kandunganList = _kandunganCtrl.text.trim().isNotEmpty
        ? _kandunganCtrl.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];
    final cal = int.tryParse(_caloriesCtrl.text.trim()) ?? 150;
    final prot = int.tryParse(_proteinCtrl.text.trim()) ?? 6;
    final car = int.tryParse(_carbsCtrl.text.trim()) ?? 18;
    final f = int.tryParse(_fatCtrl.text.trim()) ?? 6;

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
          status: _status,
          imageAsset: imageAsset,
          manfaat: manfaatList,
          kandungan: kandunganList,
          isRecommended: _isRecommended,
          calories: cal,
          protein: prot,
          carbs: car,
          fat: f,
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
          ScaffoldMessenger.of(context).showSnackBar(_successSnackbar('Data gastropedia berhasil diperbarui.'));
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
          status: _status,
          imageAsset: imageAsset,
          manfaat: manfaatList,
          kandungan: kandunganList,
          isRecommended: _isRecommended,
          calories: cal,
          protein: prot,
          carbs: car,
          fat: f,
          createdBy: widget.adminName,
          createdById: widget.adminId,
          createdByType: 'admin',
          createdAt: now,
        );

        await _service.createEntry(entry, widget.adminName, widget.adminId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(_successSnackbar('Data gastropedia berhasil ditambahkan.'));
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
    return AdminScaffold(
      header: AdminAppBar(
        title: _isEditMode ? 'Edit Gastropedia' : 'Tambah Gastropedia',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Publikasi
              Text(
                'Status Publikasi',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _statusOptions.map((s) {
                  final active = _status == s;
                  final label = s == 'terbit' ? 'Terbitkan' : 'Draft';
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: AdminFilterChip(
                      label: label,
                      isActive: active,
                      onTap: () => setState(() => _status = s),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              AdminInputField(
                label: 'Nama Makanan / Istilah',
                hint: 'Contoh : Oatmeal / Pisang',
                controller: _istilahCtrl,
                errorText: _istilahError,
                onChanged: (_) => setState(() => _istilahError = null),
              ),
              const SizedBox(height: 16),
              AdminInputField(
                label: 'Nama Lain / Singkatan (opsional)',
                hint: 'Contoh : Havermut',
                controller: _namaLainCtrl,
              ),
              const SizedBox(height: 16),
              AdminInputField(
                label: 'Deskripsi Singkat',
                hint: '1-2 kalimat untuk ringkasan kartu...',
                controller: _definisiCtrl,
                maxLines: 3,
                errorText: _definisiError,
                onChanged: (_) => setState(() => _definisiError = null),
              ),
              const SizedBox(height: 16),
              AdminInputField(
                label: 'Penjelasan Lengkap',
                hint: 'Penjelasan lengkap untuk halaman detail...',
                controller: _penjelasanCtrl,
                maxLines: 5,
                errorText: _penjelasanError,
                onChanged: (_) => setState(() => _penjelasanError = null),
              ),
              const SizedBox(height: 16),

              // Kategori single-select chips
              Text(
                'Kategori',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _kategoriOptions.map((k) {
                    final active = _kategori == k;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AdminFilterChip(
                        label: k,
                        isActive: active,
                        onTap: () => setState(() => _kategori = k),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              AdminInputField(
                label: 'Gambar (Asset Path / URL Web)',
                hint: 'Contoh : assets/images/gastropedia/oatmeal.jpg atau https://...',
                controller: _imageAssetCtrl,
              ),
              const SizedBox(height: 16),

              // Switch Ramah Lambung (Rekomendasi)
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
                            'Rekomendasi Ramah Lambung',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Tampilkan di bagian Rekomendasi Teratas untuk penderita maag/GERD',
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
                      onChanged: (val) => setState(() => _isRecommended = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              AdminInputField(
                label: 'Manfaat (1 baris per poin)',
                hint: 'Meredakan iritasi lambung\nMembantu menetralkan asam lambung',
                controller: _manfaatCtrl,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              AdminInputField(
                label: 'Kandungan Gizi / Senyawa (1 baris per poin)',
                hint: 'Serat Beta-Glukan\nKalium dan Vitamin B',
                controller: _kandunganCtrl,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Baris Info Nutrisi Opsional
              Text(
                'Informasi Nutrisi Opsional (per porsi)',
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
                      label: 'Kalori (kkal)',
                      hint: '150',
                      controller: _caloriesCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminInputField(
                      label: 'Protein (g)',
                      hint: '5.0',
                      controller: _proteinCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AdminInputField(
                      label: 'Karbo (g)',
                      hint: '27.0',
                      controller: _carbsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminInputField(
                      label: 'Lemak (g)',
                      hint: '2.5',
                      controller: _fatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AdminInputField(
                label: 'Referensi / Sumber (opsional)',
                hint: 'Link jurnal medis / https://...',
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
    );
  }
}

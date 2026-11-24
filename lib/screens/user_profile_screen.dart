import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../services/profile_photo_service.dart';
import '../services/satusehat_service.dart';
import '../widgets/app_scaffold.dart';
import '../routes/app_routes.dart';
import '../services/fcm_service.dart';
import '../auth/biometric_service.dart';
import '../pengingat_jam_makan/services/meal_reminder_service.dart';

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

  // Field Integrasi SatuSehat Kemenkes
  String? _nik;
  String? _ihsNumber;
  bool _satusehatLinked = false;
  String? _satusehatVerifiedName;

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
    String? nik;
    String? ihsNumber;
    bool satusehatLinked = false;
    String? satusehatVerifiedName;

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

        // Data SatuSehat FHIR
        nik = data['nik']?.toString();
        ihsNumber = data['ihsNumber']?.toString();
        satusehatLinked = data['satusehatLinked'] == true;
        satusehatVerifiedName = data['satusehatVerifiedName']?.toString();
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
        _nik = nik;
        _ihsNumber = ihsNumber;
        _satusehatLinked = satusehatLinked;
        _satusehatVerifiedName = satusehatVerifiedName;
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

  String? get _calculatedAgeString {
    if (_rawBirthDate == null) return null;
    DateTime? dt;
    if (_rawBirthDate is Timestamp) {
      dt = (_rawBirthDate as Timestamp).toDate();
    } else if (_rawBirthDate is DateTime) {
      dt = _rawBirthDate as DateTime;
    } else if (_rawBirthDate is String) {
      dt = DateTime.tryParse(_rawBirthDate as String);
    }
    if (dt != null) {
      final now = DateTime.now();
      int age = now.year - dt.year;
      if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) {
        age--;
      }
      if (age > 0 && age < 120) {
        return '$age thn';
      }
    }
    return null;
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

  Widget _buildGenderChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isFemale,
  }) {
    final selectedColor = isFemale ? const Color(0xFFD63384) : const Color(0xFF276F8F);
    final selectedBgColor = isFemale
        ? const Color(0xFFFCE4EF)
        : const Color(0xFF276F8F).withValues(alpha: 0.10);

    return AnimatedContainer(
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
            icon,
            size: 18,
            color: isSelected ? selectedColor : const Color(0xFF7A8B99),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? selectedColor : const Color(0xFF5A7184),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryWidget() {
    String historyText = 'Tidak ada riwayat penyakit lambung';
    String historySubtext = 'Kondisi lambung prima berdasarkan catatan skrining awal';
    IconData historyIcon = Icons.check_circle_rounded;
    Color iconColor = const Color(0xFF53A66B);
    Color bgColor = const Color(0xFFF1F8F3);
    Color borderColor = const Color(0xFFC8E6C9);

    bool hasHistory = false;
    bool isKnown = true;

    if (_rawHistory == null) {
      isKnown = false;
      historyText = 'Belum diisi';
      historySubtext = 'Lakukan skrining untuk melengkapi riwayat klinis';
      historyIcon = Icons.help_outline_rounded;
      iconColor = const Color(0xFF7A8B99);
      bgColor = const Color(0xFFF8F9FA);
      borderColor = const Color(0xFFEBE3D0);
    } else if (_rawHistory is bool) {
      hasHistory = _rawHistory == true;
    } else if (_rawHistory is List) {
      final list = (_rawHistory as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      hasHistory = list.isNotEmpty && !list.contains('tidak ada') && !list.contains('tidak');
      if (hasHistory) {
        historyText = list.join(', ');
      }
    } else {
      final str = _rawHistory.toString().trim();
      final lower = str.toLowerCase();
      if (str.isEmpty || lower == '-' || lower == 'belum diisi') {
        isKnown = false;
        historyText = 'Belum diisi';
        historySubtext = 'Lakukan skrining untuk melengkapi riwayat klinis';
        historyIcon = Icons.help_outline_rounded;
        iconColor = const Color(0xFF7A8B99);
        bgColor = const Color(0xFFF8F9FA);
        borderColor = const Color(0xFFEBE3D0);
      } else {
        hasHistory = lower.contains('iya') || lower.contains('ya') || lower.contains('true') ||
            (!lower.contains('tidak') && !lower.contains('false'));
        if (hasHistory && !lower.contains('ada riwayat') && lower != 'ya' && lower != 'iya') {
          historyText = str;
        }
      }
    }

    if (isKnown) {
      if (hasHistory) {
        historyText = 'Ada riwayat penyakit lambung';
        historySubtext = 'Perhatikan jadwal makan dan kurangi pemicu iritasi lambung';
        historyIcon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFD95030);
        bgColor = const Color(0xFFFFF9EE);
        borderColor = const Color(0xFFFFE0B2);
      } else {
        historyText = 'Tidak ada riwayat penyakit lambung';
        historySubtext = 'Kondisi lambung prima berdasarkan catatan skrining awal';
        historyIcon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF53A66B);
        bgColor = const Color(0xFFF1F8F3);
        borderColor = const Color(0xFFC8E6C9);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(historyIcon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  historyText,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C4E68),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  historySubtext,
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
    );
  }

  void _showSatuSehatVerificationDialog() {
    final controller = TextEditingController(text: _nik ?? '');
    String? errorMessage;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0288D1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF0288D1),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Verifikasi SatuSehat',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C4E68),
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masukkan 16 digit Nomor Induk Kependudukan (NIK) KTP Anda untuk menyinkronkan data pasien dengan platform SatuSehat Kemenkes (HL7 FHIR).',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: const Color(0xFF5A7184),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      maxLength: 16,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: const Color(0xFF1C4E68),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nomor Induk Kependudukan (NIK)',
                        labelStyle: GoogleFonts.poppins(fontSize: 12),
                        hintText: '3171012345670001',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        counterText: '',
                        errorText: errorMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0288D1),
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8FB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD3E7F3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Color(0xFF0288D1),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Data NIK hanya digunakan untuk query resource Patient Kemenkes dan tidak dibagikan ke pihak ketiga lainnya.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF335C6D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogCtx),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final nikInput = controller.text.trim();
                          if (nikInput.length != 16) {
                            setDialogState(() {
                              errorMessage = 'NIK harus terdiri dari 16 digit';
                            });
                            return;
                          }

                          setDialogState(() {
                            errorMessage = null;
                            isSubmitting = true;
                          });

                          try {
                            final result = await SatuSehatService.instance.verifyPatient(nikInput);
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Berhasil terhubung ke SatuSehat! IHS Pasien: ${result.ihsNumber ?? '-'}',
                                ),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );

                            await _loadUserData();
                          } catch (e) {
                            if (!dCtx.mounted) return;
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = e.toString().replaceAll('Exception: ', '').trim();
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verifikasi',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmUnlinkSatuSehat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Lepas Tautan SatuSehat?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Dengan melepas tautan, data konsultasi Anda sementara tidak disinkronkan ke rekam medis nasional SatuSehat.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
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
            child: const Text('Lepas'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SatuSehatService.instance.unlinkPatient();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan SatuSehat berhasil dilepas'),
          backgroundColor: AppColors.primaryText,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal melepas tautan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSatuSehatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.verified_user_outlined, 'Integrasi SatuSehat Kemenkes'),
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
              // Header Status Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _satusehatLinked
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _satusehatLinked
                          ? Icons.health_and_safety_rounded
                          : Icons.healing_rounded,
                      color: _satusehatLinked
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform SatuSehat FHIR',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C4E68),
                          ),
                        ),
                        Text(
                          'Kemenkes RI Interoperabilitas',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5A7184),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _satusehatLinked
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _satusehatLinked
                            ? const Color(0xFFA5D6A7)
                            : const Color(0xFFFFCC80),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _satusehatLinked
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          size: 13,
                          color: _satusehatLinked
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _satusehatLinked ? 'Terhubung' : 'Belum Terhubung',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _satusehatLinked
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Color(0xFFF0EBE1), thickness: 1),
              ),

              if (_satusehatLinked) ...[
                // IHS Number Card
                Text(
                  'Indonesia Health Services (IHS) Pasien',
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
                    color: const Color(0xFFF1F8FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC7E2F1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fingerprint_rounded,
                        size: 20,
                        color: Color(0xFF0288D1),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _ihsNumber ?? '-',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: const Color(0xFF1C4E68),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_ihsNumber != null)
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _ihsNumber!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nomor IHS berhasil disalin'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: Color(0xFF0288D1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // NIK Terdaftar
                Text(
                  'NIK Terdaftar (Dukcapil)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A7184),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card_rounded, size: 18, color: Color(0xFF5A7184)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _nik ?? '-',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C4E68),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_satusehatVerifiedName != null && _satusehatVerifiedName!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Nama Resmi di SatuSehat',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A7184),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF5A7184)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _satusehatVerifiedName!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C4E68),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: Color(0xFF0288D1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _showSatuSehatVerificationDialog,
                        icon: const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF0288D1)),
                        label: Text(
                          'Sinkron Ulang',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0288D1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      onPressed: _confirmUnlinkSatuSehat,
                      child: Text(
                        'Lepas Tautan',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Unlinked state
                Text(
                  'Tautkan NIK KTP Anda untuk menyinkronkan profil pasien dan riwayat konsultasi lambung ke sistem Rekam Medis Elektronik (RME) SatuSehat Kementerian Kesehatan RI.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF5A7184),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _showSatuSehatVerificationDialog,
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: Text(
                      'Hubungkan dengan NIK KTP',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
          await BiometricService.instance.clearBiometricForUser(uid);
        }
        await MealReminderService.instance.cancelAlarmsForLogout();
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
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFCFBF7),
          Color(0xFFF7F4EB),
          Color(0xFFF2EEDB),
        ],
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7D6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE8D7A5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Profil Pengguna',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C4E68),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD6E2E8),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF1C4E68),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Hero Profile Section (Avatar, Name, Email, Identity Chips) ──
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

                  // Nama Pengguna
                  Text(
                    _displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C4E68),
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Badge Pengguna (Centered, Clean & Aesthetic)
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
                          Icons.verified_user_rounded,
                          size: 14,
                          color: Color(0xFF53A66B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Pengguna',
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBFBFD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.badge_outlined,
                                size: 18,
                                color: Color(0xFF276F8F),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _displayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1C4E68),
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                                  _userEmail.isNotEmpty ? _userEmail : '-',
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION: INTEGRASI SATUSEHAT KEMENKES (FHIR PATIENT) ──
                  _buildSatuSehatSection(),
                  const SizedBox(height: 20),

                  // ── SECTION 2: DATA KESEHATAN & SKRINING ──
                  _buildSectionHeader(Icons.health_and_safety_outlined, 'Data Kesehatan & Skrining'),
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
                            Expanded(
                              child: _buildGenderChip(
                                label: 'Laki-laki',
                                icon: Icons.male_rounded,
                                isSelected: _isMale,
                                isFemale: false,
                              ),
                            ),
                            const SizedBox(width: 10),
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1, color: Color(0xFFF0EBE1), thickness: 1),
                        ),

                        // Tanggal Lahir
                        Text(
                          'Tanggal Lahir',
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
                                Icons.cake_outlined,
                                size: 18,
                                color: Color(0xFF276F8F),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _formatIndonesianDate(_rawBirthDate),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1C4E68),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_calculatedAgeString != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7D6),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE8D7A5)),
                                  ),
                                  child: Text(
                                    _calculatedAgeString!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1C4E68),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1, color: Color(0xFFF0EBE1), thickness: 1),
                        ),

                        // Riwayat Penyakit Lambung
                        Text(
                          'Riwayat Penyakit Lambung',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5A7184),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildHistoryWidget(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Tombol Keluar dari Akun ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _confirmLogout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFD32F2F),
                        size: 18,
                      ),
                      label: Text(
                        'Keluar dari Akun',
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
            ),
    );
  }
}

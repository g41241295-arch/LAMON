import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/consultation_theme.dart';
import '../../../models/doctor_model.dart';

/// Widget avatar / foto dokter terpusat untuk seluruh area konsultasi dokter.
///
/// Memuat foto dokter dari assets lokal secara aman, dengan fallback inisial
/// berlatar gradient lembut jika foto tidak ditemukan atau tidak tersedia.
/// Mendukung bentuk kotak rounded maupun lingkaran penuh, serta lencana verifikasi.
class DoctorAvatar extends StatelessWidget {
  final DoctorModel? doctor;
  final String? photoUrl;
  final String? doctorId;
  final String? doctorName;
  final double size;
  final double? borderRadius;
  final bool isCircle;
  final bool showVerificationBadge;
  final bool isVerified;
  final double? badgeSize;

  const DoctorAvatar({
    super.key,
    this.doctor,
    this.photoUrl,
    this.doctorId,
    this.doctorName,
    this.size = 72,
    this.borderRadius,
    this.isCircle = false,
    this.showVerificationBadge = false,
    this.isVerified = false,
    this.badgeSize,
  });

  /// Pemetaan doctorId atau nama dokter ke file asset lokal yang ada
  static String? getDoctorAssetPath(String? doctorId, [String? doctorName]) {
    final id = (doctorId ?? '').toLowerCase().trim();
    final name = (doctorName ?? '').toLowerCase().trim();

    if (id.contains('ketut') || name.contains('ketut')) {
      return 'assets/images/doctors/Ketut Maulana.jpg';
    }
    if (id.contains('oggy') || name.contains('oggy')) {
      return 'assets/images/doctors/Oggy Agustin.jpg';
    }
    if (id.contains('dandi') || name.contains('dandi')) {
      return 'assets/images/doctors/Dandi Wijaya.jpg';
    }
    return null;
  }

  /// Ekstraksi inisial nama dokter (mengabaikan gelar seperti Dr./dr./Sp.)
  static String getDoctorInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'D';
    final clean = name
        .replaceAll(RegExp(r'\b(Dr\.|dr\.|drg\.|Sp\.[A-Za-z]+|M\.Biomed|S\.Ked)\b', caseSensitive: false), '')
        .trim();
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'D';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = isCircle ? (size / 2) : (borderRadius ?? 18.0);
    final clipRadius = BorderRadius.circular(effectiveRadius);

    // Resolusi path foto lokal
    String cleanPath = (photoUrl ?? doctor?.effectivePhotoUrl ?? '').trim();
    final effId = doctorId ?? doctor?.id;
    final effName = doctorName ?? doctor?.name;

    if (cleanPath.isEmpty || (!cleanPath.startsWith('assets/') && !cleanPath.startsWith('http'))) {
      final mapped = getDoctorAssetPath(effId, effName);
      if (mapped != null) {
        cleanPath = mapped;
      }
    }

    // Resolusi cacheWidth & cacheHeight untuk performa
    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    final cacheDim = (size * pixelRatio).round().clamp(60, 400);

    Widget imageContent;
    if (cleanPath.isEmpty) {
      imageContent = _buildFallback(effName);
    } else if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      // Fallback untuk backward compatibility jika ada network URL
      imageContent = Image.network(
        cleanPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        errorBuilder: (context, error, stackTrace) => _buildFallback(effName),
      );
    } else {
      // Asset lokal
      imageContent = Image.asset(
        cleanPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        errorBuilder: (context, error, stackTrace) => _buildFallback(effName),
      );
    }

    final avatarBox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ConsultationTheme.lightBlue,
        borderRadius: clipRadius,
        border: Border.all(
          color: ConsultationTheme.cardBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: clipRadius,
        child: imageContent,
      ),
    );

    // Lencana verifikasi: lingkaran kecil biru tua, centang putih, border putih 2px di kanan bawah
    // Tampil HANYA jika datanya mendukung (isVerified == true) dan opsinya dinyalakan (showVerificationBadge == true)
    if (showVerificationBadge && isVerified) {
      final bSize = badgeSize ?? (size * 0.30).clamp(16.0, 24.0);
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatarBox,
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: bSize,
                height: bSize,
                decoration: BoxDecoration(
                  color: ConsultationTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: bSize * 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return avatarBox;
  }

  /// Fallback berupa kotak gradient lembut (#DCEBF3 ke #BFD9E6)
  /// berisi inisial nama dokter (biru tua #1F5C7A, bold)
  Widget _buildFallback(String? name) {
    final initials = getDoctorInitials(name);
    final fontSize = (size * 0.36).clamp(11.0, 32.0);

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFDCEBF3),
            Color(0xFFBFD9E6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: ConsultationTheme.primary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

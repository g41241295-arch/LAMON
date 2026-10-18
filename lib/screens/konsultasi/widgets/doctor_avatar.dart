import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Widget foto/avatar dokter universal berbentuk persegi rounded.
/// Mendukung URL network maupun asset lokal, serta fallback jika gambar gagal dimuat.
class DoctorAvatar extends StatelessWidget {
  final String photoUrl;
  final String? doctorId;
  final String? doctorName;
  final double size;
  final double borderRadius;

  const DoctorAvatar({
    super.key,
    required this.photoUrl,
    this.doctorId,
    this.doctorName,
    this.size = 76,
    this.borderRadius = 16,
  });

  /// Pemetaan doctorId atau nama dokter ke file asset lokal
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE2ECF2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    String cleanPath = photoUrl.trim();

    if (cleanPath.isEmpty) {
      final assetPath = getDoctorAssetPath(doctorId, doctorName);
      if (assetPath != null) {
        cleanPath = assetPath;
      }
    }

    if (cleanPath.isEmpty) {
      return _buildPlaceholder();
    }

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        cleanPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(isLoading: true);
        },
      );
    }

    // Asset image
    return Image.asset(
      cleanPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFE8EFF5),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: size * 0.35,
                height: size * 0.35,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: size * 0.58,
                color: AppColors.neutralGray.withValues(alpha: 0.6),
              ),
      ),
    );
  }
}

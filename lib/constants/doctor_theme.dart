import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System terpusat untuk seluruh area akses DOKTER aplikasi LAMON.
///
/// Konsisten dengan desain area PASIEN (Warm Off-White + Deep Teal LAMON).
/// Menghilangkan warna kuning berlebih dan dekorasi yang mencolok,
/// menggantikannya dengan tampilan yang formal, bersih, dan profesional.
class DoctorTheme {
  DoctorTheme._();

  // ── Warna Latar Belakang (Formal Warm Off-White) ─────────────────────────
  static const Color scaffoldBg = Color(0xFFFAF6F0);
  static const Color bgGradientStart = Color(0xFFFCFBF7);
  static const Color bgGradientEnd = Color(0xFFF7F4EB);
  static const Color bgGradientBottom = Color(0xFFF2EEDB);

  // ── Warna Utama (Deep Teal / Primary LAMON) ──────────────────────────────
  static const Color primary = Color(0xFF276F8F);
  static const Color primaryDark = Color(0xFF1B556E);
  static const Color primaryLight = Color(0xFF3885A8);
  static const Color primaryText = Color(0xFF1C4E68);
  static const Color secondaryText = Color(0xFF527F97);
  static const Color neutralGray = Color(0xFF7C8E97);
  static const Color lightGray = Color(0xFFE2EDF3);

  // ── Warna Kartu & Border ────────────────────────────────────────────────
  static const Color cardBg = Colors.white;
  static const Color cardBgSubtle = Color(0xFFFCFBF7);
  static const Color cardBorder = Color(0xFFEBE3D0);
  static const Color cardBorderSubtle = Color(0xFFE8EFF5);

  // ── Warna Aksen (Hanya sebagai aksen kecil, bukan background dominan) ───
  static const Color accentOrange = Color(0xFFE5983A);
  static const Color accentBrown = Color(0xFF9E652B);
  static const Color alertRed = Color(0xFFD32F2F);
  static const Color alertRedBg = Color(0xFFFFEBEE);
  static const Color alertRedBorder = Color(0xFFFFCDD2);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color successGreenBg = Color(0xFFE8F5E9);

  // ── Gradasi Kartu Hero (Gaya Kartu Jadwal Makan di Beranda Pasien) ───────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B556E), // Deep Teal
      Color(0xFF276F8F), // Primary Teal
      Color(0xFF3885A8), // Light Teal
    ],
  );

  // ── Dekorasi Kartu Standar ──────────────────────────────────────────────
  static BoxDecoration cardDecoration({
    Color? color,
    Color? borderColor,
    double borderRadius = 20,
    double borderWidth = 1.2,
    List<BoxShadow>? customShadow,
  }) {
    return BoxDecoration(
      color: color ?? cardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? cardBorder,
        width: borderWidth,
      ),
      boxShadow: customShadow ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
    );
  }

  // ── Tipografi (GoogleFonts.poppins) ──────────────────────────────────────
  static TextStyle headingLarge({Color color = primaryText}) =>
      GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle headingMedium({Color color = primaryText}) =>
      GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle headingSmall({Color color = primaryText}) =>
      GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle body({Color color = primaryText, FontWeight fontWeight = FontWeight.w500}) =>
      GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle subtext({Color color = secondaryText}) =>
      GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle caption({Color color = neutralGray}) =>
      GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // ── Input Decoration ─────────────────────────────────────────────────────
  static InputDecoration inputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color fillColor = const Color(0xFFF8FAFC),
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: neutralGray,
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: fillColor,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: cardBorder, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: cardBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: alertRed, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: alertRed, width: 1.6),
      ),
    );
  }

  // ── Tombol Utama (Primary Button) ───────────────────────────────────────
  static ButtonStyle primaryButtonStyle({
    double borderRadius = 16,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding,
      textStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ── Tombol Sekunder (Outlined Button) ───────────────────────────────────
  static ButtonStyle secondaryButtonStyle({
    double borderRadius = 16,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
  }) {
    return OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: primaryText,
      side: const BorderSide(color: cardBorder, width: 1.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding,
      textStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Pembungkus Latar Belakang Area Dokter.
/// Menggunakan gradasi krem/off-white lembut (sama dengan halaman pasien, #FCFBF7 - #F7F4EB).
class DoctorBackground extends StatelessWidget {
  final Widget child;

  const DoctorBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: DoctorTheme.scaffoldBg,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DoctorTheme.bgGradientStart,
            DoctorTheme.bgGradientEnd,
          ],
        ),
      ),
      child: child,
    );
  }
}

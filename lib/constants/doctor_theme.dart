import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System terpusat untuk seluruh area akses DOKTER aplikasi LAMON.
///
/// Konsisten dengan desain area PASIEN (Warm Off-White #FAF6F0 + Deep Teal #1F5C7A).
/// Menghilangkan warna kuning berlebih dan dekorasi yang mencolok,
/// menggantikannya dengan tampilan yang formal, bersih, dan profesional.
class DoctorTheme {
  DoctorTheme._();

  // ── Warna Latar Belakang (Formal Warm Off-White) ─────────────────────────
  static const Color scaffoldBg = Color(0xFFFAF6F0);
  static const Color bgGradientStart = Color(0xFFFAF6F0);
  static const Color bgGradientEnd = Color(0xFFFAF6F0);
  static const Color bgGradientBottom = Color(0xFFF5EFE6);

  // ── Warna Utama (Deep Teal / Primary LAMON) ──────────────────────────────
  static const Color primary = Color(0xFF1F5C7A);
  static const Color primaryDark = Color(0xFF17475E);
  static const Color primaryLight = Color(0xFF2E85A8);
  static const Color primaryText = Color(0xFF1F5C7A);
  static const Color secondaryText = Color(0xFF6B8190);
  static const Color neutralGray = Color(0xFF8B9EAA);
  static const Color lightGray = Color(0xFFE2EDF3);

  // ── Warna Kartu & Border ────────────────────────────────────────────────
  static const Color cardBg = Colors.white;
  static const Color cardBgSubtle = Color(0xFFFCFBF7);
  static const Color cardBorder = Color(0xFFEFE3D0);
  static const Color cardBorderSubtle = Color(0xFFE8EFF5);

  // ── Warna Kartu Unread & Chat ───────────────────────────────────────────
  static const Color unreadCardBg = Color(0xFFF4FAFD);
  static const Color unreadCardBorder = Color(0xFFBFD9E6);
  static const Color patientBubbleText = Color(0xFF24435A);
  static const Color doctorBubbleTime = Color(0xFFCFE3EE);
  static const Color dateChipBg = Color(0xFFE9E2D3);
  static const Color envelopeIconBg = Color(0xFFDCEBF3);
  static const Color keluhanBg = Color(0xFFFFF8EA);
  static const Color keluhanBorder = Color(0xFFF2D9B0);

  // ── Warna Aksen (Hanya sebagai aksen kecil, bukan background dominan) ───
  static const Color accentGold = Color(0xFFF2B544);
  static const Color accentOrange = Color(0xFFE5983A);
  static const Color accentBrown = Color(0xFFB5651D);
  static const Color notifOrange = Color(0xFFE0913A);
  static const Color alertRed = Color(0xFFD93A3A);
  static const Color alertRedBg = Color(0xFFFFEBEE);
  static const Color alertRedBorder = Color(0xFFFFCDD2);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color successGreenBg = Color(0xFFE8F5E9);

  // ── Warna Status & Kategori Notifikasi / Badge ───────────────────────────
  static const Color selesaiPurple = Color(0xFF5B3F8C);
  static const Color selesaiPurpleBg = Color(0xFFEDE7F6);
  static const Color patientAvatarBeige = Color(0xFFFBE9D2);
  static const Color patientAvatarBrown = Color(0xFFB5651D);
  static const Color jadwalGreen = Color(0xFF2F7A57);
  static const Color jadwalGreenBg = Color(0xFFE4F3EC);
  static const Color jadwalChipBg = Color(0xFFD8EFE4);
  static const Color konsultasiChipBg = Color(0xFFFFF0D2);
  static const Color konsultasiBoxBg = Color(0xFFFFF3DC);

  // ── Gradasi Kartu Hero (Gaya Kartu Jadwal Makan di Beranda Pasien) ───────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment(-0.8, -0.8),
    end: Alignment(0.8, 0.8),
    colors: [
      Color(0xFF1F5C7A), // Deep Teal
      Color(0xFF2E85A8), // Light Teal
    ],
  );

  // ── Variasi Warna Avatar Inisial Pasien (Biru muda, Peach, Hijau muda, Lavender) ──
  static const List<DoctorAvatarColors> avatarColorPalette = [
    DoctorAvatarColors(
      bg: Color(0xFFE1F0F8), // Biru muda
      text: Color(0xFF1F5C7A),
    ),
    DoctorAvatarColors(
      bg: Color(0xFFFDE8E1), // Peach
      text: Color(0xFFB5651D),
    ),
    DoctorAvatarColors(
      bg: Color(0xFFE2F5E9), // Hijau muda
      text: Color(0xFF2E7D32),
    ),
    DoctorAvatarColors(
      bg: Color(0xFFEDE7F6), // Lavender
      text: Color(0xFF5E35B1),
    ),
  ];

  static DoctorAvatarColors getAvatarColors(String key) {
    if (key.isEmpty) return avatarColorPalette.first;
    final code = key.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return avatarColorPalette[code % avatarColorPalette.length];
  }

  // ── Dekorasi Kartu Standar ──────────────────────────────────────────────
  static BoxDecoration cardDecoration({
    Color? color,
    Color? borderColor,
    double borderRadius = 22,
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
    Color? fillColor,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: neutralGray,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: fillColor ?? Colors.white,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cardBorder, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cardBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    );
  }

  // ── Gaya Tombol ──────────────────────────────────────────────────────────
  static ButtonStyle primaryButtonStyle({
    double borderRadius = 16,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
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

  static ButtonStyle secondaryButtonStyle({
    double borderRadius = 16,
    double borderWidth = 1.2,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: primary,
      side: BorderSide(color: primary, width: borderWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding,
      textStyle: GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Model warna avatar inisial (background dan teks)
class DoctorAvatarColors {
  final Color bg;
  final Color text;

  const DoctorAvatarColors({
    required this.bg,
    required this.text,
  });

  Color get background => bg;
}

/// Pembungkus Latar Belakang Area Dokter.
/// Menggunakan warna solid krem / off-white lembut (#FAF6F0).
class DoctorBackground extends StatelessWidget {
  final Widget child;

  const DoctorBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: DoctorTheme.scaffoldBg,
      child: child,
    );
  }
}

/// Komponen header seksi formal untuk area dokter.
/// Menampilkan kotak ikon rounded 40x40 (radius 13, background putih, border #EFE3D0)
/// di sebelah kiri judul (17sp bold #1F5C7A), dengan aksi opsional di sebelah kanan.
class DoctorSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const DoctorSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: DoctorTheme.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: DoctorTheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: DoctorTheme.primaryText,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

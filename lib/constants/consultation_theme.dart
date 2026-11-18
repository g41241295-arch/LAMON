import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Design tokens dan komponen terpusat untuk seluruh fitur Konsultasi Dokter
/// di sisi PASIEN aplikasi LAMON.
/// Konsisten dengan tema Beranda Pasien dan Gastropedia (formal, profesional, modern).
class ConsultationTheme {
  ConsultationTheme._();

  // ── Warna Utama & Background ─────────────────────────────────────────────
  /// Background solid krem LAMON — menggantikan background kuning / pola lama
  static const Color scaffoldBg = Color(0xFFFAF6F0);
  /// Biru tua LAMON untuk heading, tombol utama, teks penting
  static const Color primary = Color(0xFF1F5C7A);
  static const Color primaryDark = Color(0xFF17475E);
  /// Teal aksen untuk tautan, penekanan angka invoice
  static const Color teal = Color(0xFF2E85A8);
  /// Border krem standar untuk semua kartu dan kontrol
  static const Color cardBorder = Color(0xFFEFE3D0);
  /// Teks sekunder abu-abu kebiruan
  static const Color secondaryText = Color(0xFF5E7585);
  /// Latar lembut krem netral untuk kotak info sekunder
  static const Color softBg = Color(0xFFF7F3EB);
  /// Garis pemisah halus
  static const Color divider = Color(0xFFF1E8DA);

  // ── Gradasi Latar & Header Kuning (Identik dengan Catat Makanan) ─────────
  static const LinearGradient pageGradient = AppColors.pageGradient;
  static const Color titlePillYellowBg = AppColors.titlePillYellowBg;
  static const Color titlePillYellowBorder = AppColors.titlePillYellowBorder;
  static const Color titlePillYellowText = AppColors.titlePillYellowText;

  // ── Warna Aksen & State ──────────────────────────────────────────────────
  static const Color lightBlue = Color(0xFFDCEBF3);
  static const Color lightBlueBg = Color(0xFFEAF3F8);
  static const Color lightBlueBorder = Color(0xFFBFD9E6);
  static const Color gold = Color(0xFFF2B544);
  static const Color goldBg = Color(0xFFFFF3DC);
  static const Color goldBorder = Color(0xFFF2D9B0);
  static const Color goldText = Color(0xFFB5651D);
  static const Color orange = Color(0xFFE0913A);
  static const Color green = Color(0xFF2F7A57);
  static const Color greenDot = Color(0xFF3DAA5C);
  static const Color greenBg = Color(0xFFE4F3EC);
  static const Color red = Color(0xFFD93A3A);
  static const Color darkRed = Color(0xFFB42318);
  static const Color amberBg = Color(0xFFFFF8EA);
  static const Color amberBorder = Color(0xFFF2D9B0);
  static const Color amberText = Color(0xFF8A5A1E);
  static const Color disabledButton = Color(0xFFA9C4D2);

  // ── Bayangan Kartu Halus ────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x0D1F5C7A), // rgba(31, 92, 122, 0.05)
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x0D1F5C7A), // rgba(31, 92, 122, 0.05)
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ];

  // ── Tipografi ───────────────────────────────────────────────────────────
  static TextStyle poppins({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = primary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Teks judul besar
  static TextStyle titleLarge({Color color = primary}) => poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Teks judul sedang
  static TextStyle titleMedium({Color color = primary}) => poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Teks judul kecil / nama dokter
  static TextStyle titleSmall({Color color = primary}) => poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Teks body standar
  static TextStyle body({Color color = primary}) => poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// Teks keterangan / subtext
  static TextStyle subtext({Color color = secondaryText}) => poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// Label mikro huruf besar (UPPERCASE)
  static TextStyle microLabel({Color color = secondaryText}) => poppins(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.8,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// KOMPONEN REUSABLE
// ─────────────────────────────────────────────────────────────────────────────

/// Header halaman standar formal:
/// Tombol kembali bulat 44 (putih, border krem), judul di pill bergaris krem,
/// dan aksi kanan bulat 44 opsional.
///
/// Jika [isYellowPill] bernilai true, warna dan gaya pill dibuat identik dengan
/// header Catat Makanan (kuning krem #FFF7D6, border #E8D7A5, font 14 bold #1C4E68).
class ConsultationHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? rightAction;
  final VoidCallback? onBack;
  final bool isYellowPill;

  const ConsultationHeader({
    super.key,
    required this.title,
    this.rightAction,
    this.onBack,
    this.isYellowPill = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final effectiveBack = onBack ?? () => Navigator.of(context).maybePop();

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Tombol kembali bulat 44
            InkWell(
              onTap: effectiveBack,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ConsultationTheme.cardBorder,
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
                  color: ConsultationTheme.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Judul di pill (kuning jika isYellowPill, putih jika default) di tengah
            Expanded(
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: isYellowPill ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: isYellowPill
                        ? ConsultationTheme.titlePillYellowBg
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isYellowPill
                          ? ConsultationTheme.titlePillYellowBorder
                          : ConsultationTheme.cardBorder,
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
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: isYellowPill ? 14 : 16,
                      fontWeight:
                          isYellowPill ? FontWeight.w700 : FontWeight.w600,
                      color: isYellowPill
                          ? ConsultationTheme.titlePillYellowText
                          : ConsultationTheme.primary,
                      letterSpacing: isYellowPill ? 0.2 : 0.1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Sisi kanan: aksi kustom (misal tombol bulat 44) atau penyeimbang invisible
            SizedBox(
              width: 44,
              height: 44,
              child: rightAction ?? const SizedBox(width: 44, height: 44),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol ikon bulat 44x44 untuk ditaruh di slot kanan ConsultationHeader
class RoundHeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color iconColor;

  const RoundHeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.iconColor = ConsultationTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: ConsultationTheme.cardBorder,
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
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

/// Kartu putih standar: putih, border 1px #EFE3D0, radius 20, bayangan sangat tipis, padding 16
class InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor = Colors.white,
    this.borderColor = ConsultationTheme.cardBorder,
    this.borderRadius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: ConsultationTheme.cardShadow,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}

/// Label mikro: font 10.5, semi-bold, UPPERCASE, letterSpacing ~0.08em, warna #5E7585
class MicroLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;

  const MicroLabel(this.text, {super.key, this.color, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: textAlign,
      style: ConsultationTheme.microLabel(
        color: color ?? ConsultationTheme.secondaryText,
      ),
    );
  }
}

/// Status: titik warna 7px + teks semi-bold 11.5 (hijau untuk selesai/praktik, oranye untuk menunggu)
class StatusDot extends StatelessWidget {
  final String text;
  final Color dotColor;
  final Color? textColor;

  const StatusDot({
    super.key,
    required this.text,
    required this.dotColor,
    this.textColor,
  });

  factory StatusDot.active({String text = 'Praktik hari ini'}) => StatusDot(
        text: text,
        dotColor: ConsultationTheme.greenDot,
        textColor: ConsultationTheme.green,
      );

  factory StatusDot.completed({String text = 'Selesai'}) => StatusDot(
        text: text,
        dotColor: ConsultationTheme.greenDot,
        textColor: ConsultationTheme.green,
      );

  factory StatusDot.waiting({String text = 'Menunggu Konfirmasi'}) => StatusDot(
        text: text,
        dotColor: ConsultationTheme.orange,
        textColor: const Color(0xFFB5651D),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: textColor ?? dotColor,
          ),
        ),
      ],
    );
  }
}

/// Tombol utama formal: biru tua #1F5C7A, teks putih semi-bold 14, radius 14, padding vertikal 13.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double borderRadius;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: Colors.white),
              ],
            ],
          );

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ConsultationTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ConsultationTheme.disabledButton,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Tombol sekunder: outline biru tua 1.5px, latar putih, radius 14
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double borderRadius;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: ConsultationTheme.primary,
          side: const BorderSide(
            color: ConsultationTheme.primary,
            width: 1.5,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: ConsultationTheme.primary),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: ConsultationTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kotak peringatan amber: latar #FFF8EA, border #F2D9B0, radius 16, padding 12x14,
/// ikon info oranye, teks #8A5A1E 13
class InfoNotice extends StatelessWidget {
  final String text;
  final IconData icon;

  const InfoNotice({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ConsultationTheme.amberBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ConsultationTheme.amberBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: ConsultationTheme.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ConsultationTheme.amberText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Garis pemisah halus #F1E8DA
class SectionDivider extends StatelessWidget {
  final double verticalPadding;
  const SectionDivider({super.key, this.verticalPadding = 12});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: const Divider(
        height: 1,
        thickness: 1,
        color: ConsultationTheme.divider,
      ),
    );
  }
}

/// Helper untuk menampilkan floating snackbar formal LAMON:
/// margin 20, radius 14, latar biru tua #1F5C7A (atau hijau #2F7A57 untuk sukses),
/// teks putih 13, ikon centang di kiri.
void showConsultationSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
  bool isSuccess = false,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  Color bgColor = ConsultationTheme.primary;
  IconData icon = Icons.info_outline_rounded;
  if (isSuccess) {
    bgColor = ConsultationTheme.green;
    icon = Icons.check_circle_rounded;
  } else if (isError) {
    bgColor = ConsultationTheme.red;
    icon = Icons.error_outline_rounded;
  }

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      duration: duration,
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 4,
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      action: action,
    ),
  );
}

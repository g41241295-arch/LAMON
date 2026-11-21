import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_assets.dart';
import 'biometric_service.dart';

/// Pembungkus PopScope untuk layar utama pasien (Beranda) agar tombol back
/// sistem menampilkan dialog konfirmasi keluar aplikasi tanpa mengubah beranda_screen.dart.
class ExitConfirmScope extends StatelessWidget {
  final Widget child;

  const ExitConfirmScope({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (didPop) return;
        showExitAppConfirmDialog(context);
      },
      child: child,
    );
  }
}

/// Dialog konfirmasi keluar dari aplikasi pada layar Beranda pasien.
/// "Ya, keluar" menjalankan SystemNavigator.pop() TANPA logout.
Future<void> showExitAppConfirmDialog(BuildContext context) async {
  final shouldExit = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: Text(
        'Apakah Anda yakin keluar dari aplikasi?',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1C4E68),
        ),
      ),
      content: Text(
        'Anda dapat membuka kembali aplikasi kapan saja tanpa perlu masuk ulang.',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFF5A7184),
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Batal',
            style: GoogleFonts.poppins(
              color: const Color(0xFF7A8B99),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF276F8F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Ya, keluar',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  if (shouldExit == true) {
    SystemNavigator.pop();
  }
}

/// Dialog tawaran mengaktifkan masuk dengan sidik jari setelah login pasien berhasil.
Future<bool?> showEnableBiometricDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF276F8F).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: Color(0xFF276F8F),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aktifkan masuk dengan sidik jari?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C4E68),
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'Masuk lebih cepat dan praktis setiap membuka aplikasi LAMON cukup dengan sidik jari Anda tanpa perlu mengetik ulang akun.',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFF5A7184),
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Nanti',
            style: GoogleFonts.poppins(
              color: const Color(0xFF7A8B99),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF276F8F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: Text(
            'Aktifkan',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

/// Layar kunci sederhana saat autentikasi sidik jari gagal atau dibatalkan pada cold start.
class BiometricLockScreen extends StatefulWidget {
  final String uid;
  final String userName;
  final String email;
  final bool hasCompletedScreening;
  final String? initialMessage;

  const BiometricLockScreen({
    super.key,
    required this.uid,
    required this.userName,
    required this.email,
    required this.hasCompletedScreening,
    this.initialMessage,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _isAuthenticating = false;
  bool _isLoggingOut = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _statusMessage = widget.initialMessage ??
        'Verifikasi sidik jari diperlukan untuk membuka akun Anda.';
  }

  Future<void> _retryBiometric() async {
    if (_isAuthenticating || _isLoggingOut) return;
    setState(() {
      _isAuthenticating = true;
    });

    final result = await BiometricService.instance.authenticateUser();
    if (!mounted) return;

    if (result.success) {
      BiometricService.instance.completePatientLoginAndNavigate(
        context,
        uid: widget.uid,
        userName: widget.userName,
        email: widget.email,
        hasCompletedScreening: widget.hasCompletedScreening,
      );
      return;
    }

    if (result.noDeviceSecurity) {
      await BiometricService.instance.performExplicitLogoutAndGoToLogin(
        context,
        uid: widget.uid,
      );
      return;
    }

    setState(() {
      _isAuthenticating = false;
      _statusMessage = result.errorMessage ??
          'Verifikasi belum berhasil. Silakan coba lagi atau masuk dengan akun lain.';
    });
  }

  Future<void> _switchAccount() async {
    if (_isAuthenticating || _isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
    });
    await BiometricService.instance.performExplicitLogoutAndGoToLogin(
      context,
      uid: widget.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (didPop) return;
        showExitAppConfirmDialog(context);
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFCFBF7),
                Color(0xFFF7F4EB),
                Color(0xFFF2EEDB),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFEBE3D0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1C4E68).withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF276F8F).withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          AppAssets.logo,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.fingerprint_rounded,
                            size: 44,
                            color: Color(0xFF276F8F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Halo, ${widget.userName}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1C4E68),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage ??
                            'Gunakan sidik jari atau kunci layar perangkat untuk melanjutkan.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF5A7184),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: (_isAuthenticating || _isLoggingOut)
                              ? null
                              : _retryBiometric,
                          icon: _isAuthenticating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.fingerprint_rounded, size: 22),
                          label: Text(
                            'Coba lagi',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF276F8F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: (_isAuthenticating || _isLoggingOut)
                              ? null
                              : _switchAccount,
                          icon: _isLoggingOut
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1C4E68),
                                  ),
                                )
                              : const Icon(Icons.switch_account_outlined, size: 20),
                          label: Text(
                            'Masuk dengan akun lain',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C4E68),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

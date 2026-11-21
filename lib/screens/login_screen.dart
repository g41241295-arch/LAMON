import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../providers/app_state.dart';
import '../services/consultation_retention_service.dart';
import '../auth/biometric_service.dart';

enum AuthView { welcome, login, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthView _currentView = AuthView.welcome;

  // Controllers Login
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _isLoginLoading = false;
  bool _obscureLoginPassword = true;
  bool _rememberMe = true;

  // Controllers Register
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  String? _regNameError;
  String? _regEmailError;
  String? _regPasswordError;
  bool _isRegisterLoading = false;
  bool _obscureRegPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  // ── VALIDASI LOGIN ──────────────────────────────────────────────────────────
  bool _validateLogin() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    bool isValid = true;

    if (email.isEmpty) {
      _emailError = 'Email tidak boleh kosong';
      isValid = false;
    } else if (!emailRegex.hasMatch(email)) {
      _emailError = 'Format email tidak valid (contoh: user@gmail.com)';
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Kata sandi tidak boleh kosong';
      isValid = false;
    } else if (password.length < 8) {
      _passwordError = 'Kata sandi minimal harus 8 karakter';
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  // ── EKSEKUSI LOGIN ──────────────────────────────────────────────────────────
  void _handleLogin() async {
    if (!_validateLogin()) return;

    setState(() => _isLoginLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        try {
          await FirebaseFirestore.instance.collection('login_history').add({
            'user_id': uid,
            'email': email,
            'waktu_login': Timestamp.now(),
          });
        } catch (e) {
          debugPrint('Gagal menambahkan riwayat login: $e');
        }

        bool hasCompletedScreening = false;
        String userName = email.split('@')[0];
        if (userName.isNotEmpty) {
          userName = userName[0].toUpperCase() + userName.substring(1);
        }

        DocumentSnapshot<Map<String, dynamic>>? userDoc;
        try {
          userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get()
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint('Gagal membaca data user dari Firestore: $e');
        }

        if (!mounted) return;

        if (userDoc == null || !userDoc.exists) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          setState(() => _isLoginLoading = false);
          _showErrorSnackBar('Akun tidak ditemukan atau belum terdaftar dengan benar');
          return;
        }

        final data = userDoc.data() ?? {};
        final role = data['role'] as String?;
        final isDoctor = role == 'doctor' || role == 'dokter';

        if (role == 'admin') {
          final statusVerifikasi = data['status_verifikasi'] as String?;
          if (statusVerifikasi != 'approved') {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            setState(() => _isLoginLoading = false);
            _showErrorSnackBar('Akun Anda belum diverifikasi, silakan hubungi admin');
            return;
          }
        } else if (!isDoctor && role != null && role != 'pengguna' && role != 'patient') {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          setState(() => _isLoginLoading = false);
          _showErrorSnackBar('Role akun tidak dikenali');
          return;
        }

        hasCompletedScreening = data['hasCompletedScreening'] == true;
        if (data['nama'] != null && data['nama'].toString().trim().isNotEmpty) {
          userName = data['nama'];
        } else if (data['name'] != null && data['name'].toString().trim().isNotEmpty) {
          userName = data['name'];
        }

        setState(() => _isLoginLoading = false);

        final appState = AppState.of(context);
        appState.loginWithGoogle(userName, email);

        ConsultationRetentionService.instance.resetSession();
        ConsultationRetentionService.instance.runRetentionCleanup(
          uid: uid,
          isDoctor: isDoctor,
          doctorId: (data['doctorId'] ?? data['doctor_id'])?.toString(),
        );

        if (isDoctor) {
          Navigator.pushNamedAndRemoveUntil(context, '/dokter', (route) => false);
        } else if (role == 'admin') {
          Navigator.pushNamedAndRemoveUntil(context, '/admin-dashboard', (route) => false);
        } else {
          await BiometricService.instance.maybeOfferBiometricAfterLogin(context, uid: uid);
          if (!mounted) return;
          if (!hasCompletedScreening) {
            Navigator.pushNamedAndRemoveUntil(context, '/screening/gender', (route) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/beranda', (route) => false);
          }
        }
      } else {
        if (!mounted) return;
        setState(() => _isLoginLoading = false);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoginLoading = false);
      String errorMessage = 'Terjadi kesalahan saat masuk.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'invalid-email') {
        errorMessage = 'Akun tidak ditemukan. Silakan buat akun terlebih dahulu.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Kata sandi salah. Silakan periksa kembali.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoginLoading = false);
      _showErrorSnackBar('Terjadi kesalahan saat masuk.');
    }
  }

  // ── VALIDASI REGISTER ───────────────────────────────────────────────────────
  bool _validateRegister() {
    setState(() {
      _regNameError = null;
      _regEmailError = null;
      _regPasswordError = null;
    });

    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    bool isValid = true;

    if (name.isEmpty) {
      _regNameError = 'Nama lengkap tidak boleh kosong';
      isValid = false;
    }

    if (email.isEmpty) {
      _regEmailError = 'Email tidak boleh kosong';
      isValid = false;
    } else if (!emailRegex.hasMatch(email)) {
      _regEmailError = 'Format email tidak valid (contoh: user@gmail.com)';
      isValid = false;
    }

    if (password.isEmpty) {
      _regPasswordError = 'Kata sandi tidak boleh kosong';
      isValid = false;
    } else if (password.length < 8) {
      _regPasswordError = 'Kata sandi minimal harus 8 karakter';
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  // ── EKSEKUSI REGISTER ───────────────────────────────────────────────────────
  void _handleRegister() async {
    if (!_validateRegister()) return;

    setState(() => _isRegisterLoading = true);

    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'nama': name,
          'email': email,
          'role': 'pengguna',
          'tanggal_daftar': Timestamp.now(),
          'hasCompletedScreening': false,
        });

        if (!mounted) return;
        setState(() => _isRegisterLoading = false);

        final appState = AppState.of(context);
        appState.loginWithGoogle(name, email);

        Navigator.pushNamedAndRemoveUntil(context, '/screening/gender', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isRegisterLoading = false);
      String errorMessage = 'Gagal membuat akun.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah terdaftar. Silakan langsung masuk ke akun Anda.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Kata sandi terlalu lemah. Gunakan kombinasi yang lebih kuat.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRegisterLoading = false);
      _showErrorSnackBar('Terjadi kesalahan saat pendaftaran.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailCtrl = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF276F8F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF276F8F), size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Lupa Kata Sandi?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C4E68),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan alamat email Anda yang terdaftar untuk menerima tautan pemulihan kata sandi.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF5A7184),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF1C4E68)),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18, color: Color(0xFF276F8F)),
                hintText: 'nama@email.com',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF276F8F), width: 1.4),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                color: const Color(0xFF7A8B99),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF276F8F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () async {
              final email = resetEmailCtrl.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                _showErrorSnackBar('Masukkan email yang valid');
                return;
              }
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tautan pemulihan kata sandi telah dikirim ke $email'),
                      backgroundColor: const Color(0xFF38B249),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) _showErrorSnackBar('Gagal mengirim email reset: $e');
              }
            },
            child: Text('Kirim', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (didPop) return;
        if (_currentView != AuthView.welcome) {
          setState(() => _currentView = AuthView.welcome);
        } else {
          SystemNavigator.pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
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
              bottom: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: child,
                  );
                },
                child: _buildCurrentView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case AuthView.welcome:
        return _buildWelcomeView();
      case AuthView.login:
        return _buildLoginView();
      case AuthView.register:
        return _buildRegisterView();
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // VIEW 1: SELAMAT DATANG & LOGO (Screen Tengah Referensi)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildWelcomeView() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      key: const ValueKey('welcome_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(28, 24, 28, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Judul Bahasa Indonesia
                  Text(
                    'Selamat Datang!',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C4E68),
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle Narasi Ramah Bahasa Indonesia
                  Text(
                    'Halo!\nKami hadir untuk membantu memantau dan menjaga kesehatan lambung Anda setiap hari.\nSilakan pilih: Masuk atau Buat Akun Baru.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5A7184),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Maskot Logo LAMON di Tengah (Ukuran Proporsional & Presisi)
                  Container(
                    width: 170,
                    height: 170,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF276F8F).withValues(alpha: 0.18),
                        width: 3.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1C4E68).withValues(alpha: 0.10),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      AppAssets.logo,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Brand Label Pill Presisi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7D6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE8D7A5),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      'LAMON • Lambung Awareness & Monitoring',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C4E68),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Dua Tombol Pilihan
                  // Tombol 1: Buat Akun Baru (Solid Button)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _currentView = AuthView.register);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1C4E68),
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Color(0xFFEBE3D0),
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Buat Akun Baru',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1C4E68),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Tombol 2: Masuk ke Akun (Outlined Pill Button)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _currentView = AuthView.login);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF276F8F).withValues(alpha: 0.08),
                        foregroundColor: const Color(0xFF276F8F),
                        side: BorderSide(
                          color: const Color(0xFF276F8F).withValues(alpha: 0.35),
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Masuk ke Akun',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF276F8F),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // VIEW 2: MASUK KE AKUN (Screen Kiri Referensi: "Selamat Datang Kembali")
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildLoginView() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      key: const ValueKey('login_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Logo LAMON Lebih Besar & Proporsional (Tanpa tombol Back)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF276F8F).withValues(alpha: 0.20),
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1C4E68).withValues(alpha: 0.09),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'LAMON',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1C4E68),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Curved White Sheet Card — Memanjang Penuh Sampai Bawah
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
                        border: Border.all(color: const Color(0xFFEBE3D0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(26, 28, 26, 36 + bottomInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang Kembali',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1C4E68),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Siap melanjutkan pemantauan kesehatan lambung Anda?\nSilakan masuk ke akun Anda.',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5A7184),
                              height: 1.45,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Field Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C4E68),
                            ),
                            onChanged: (_) {
                              if (_emailError != null) setState(() => _emailError = null);
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                size: 18,
                                color: Color(0xFF276F8F),
                              ),
                              hintText: 'Masukkan email Anda',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _emailError != null ? const Color(0xFFD32F2F) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _emailError != null ? const Color(0xFFD32F2F) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF276F8F), width: 1.4),
                              ),
                              errorText: _emailError,
                              errorStyle: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFD32F2F)),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Field Kata Sandi
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureLoginPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C4E68),
                            ),
                            onChanged: (_) {
                              if (_passwordError != null) setState(() => _passwordError = null);
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: Color(0xFF276F8F),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 19,
                                  color: const Color(0xFF7A8B99),
                                ),
                                onPressed: () {
                                  setState(() => _obscureLoginPassword = !_obscureLoginPassword);
                                },
                              ),
                              hintText: 'Masukkan kata sandi',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _passwordError != null ? const Color(0xFFD32F2F) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _passwordError != null ? const Color(0xFFD32F2F) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF276F8F), width: 1.4),
                              ),
                              errorText: _passwordError,
                              errorStyle: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFD32F2F)),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Row: Ingat saya & Lupa kata sandi?
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: const Color(0xFF276F8F),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.4),
                                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ingat saya',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF5A7184),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _showForgotPasswordDialog,
                                child: Text(
                                  'Lupa kata sandi?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF276F8F),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // Tombol Masuk
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoginLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF276F8F),
                                foregroundColor: Colors.white,
                                elevation: 1,
                                shadowColor: const Color(0xFF276F8F).withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoginLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Masuk',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Divider: atau masuk dengan
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: Color(0xFFE2E8F0), thickness: 1.0),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'atau masuk dengan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF7A8B99),
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Color(0xFFE2E8F0), thickness: 1.0),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Tombol Google Masuk (Hanya Google Sesuai Request User)
                          InkWell(
                            onTap: () => Navigator.pushNamed(context, '/google-auth'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CustomPaint(painter: GoogleLogoPainter()),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Masuk dengan Google',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1C4E68),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // VIEW 3: BUAT AKUN BARU (Screen Kanan Referensi: "Buat Akun Baru")
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildRegisterView() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      key: const ValueKey('register_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Logo LAMON Lebih Besar & Proporsional (Tanpa tombol Back)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF276F8F).withValues(alpha: 0.20),
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1C4E68).withValues(alpha: 0.09),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'LAMON',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1C4E68),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Curved White Sheet Card — Memanjang Penuh Sampai Bawah
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
                        border: Border.all(color: const Color(0xFFEBE3D0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(26, 28, 26, 36 + bottomInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buat Akun Baru',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1C4E68),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mulai langkah awal untuk pemantauan dan kesehatan lambung yang optimal bersama LAMON.',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5A7184),
                              height: 1.45,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Field 1: Nama Lengkap
                          TextFormField(
                            controller: _regNameController,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C4E68),
                            ),
                            onChanged: (_) {
                              if (_regNameError != null) setState(() => _regNameError = null);
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: Color(0xFF276F8F),
                              ),
                              hintText: 'Nama lengkap Anda',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _regNameError != null ? const Color(0xFFD32F2F) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _regNameError != null ? const Color(0xFFD32F2F) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF276F8F), width: 1.4),
                              ),
                              errorText: _regNameError,
                              errorStyle: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFD32F2F)),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Field 2: Email
                          TextFormField(
                            controller: _regEmailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C4E68),
                            ),
                            onChanged: (_) {
                              if (_regEmailError != null) setState(() => _regEmailError = null);
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                size: 18,
                                color: Color(0xFF276F8F),
                              ),
                              hintText: 'Masukkan email Anda',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _regEmailError != null ? const Color(0xFFD32F2F) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _regEmailError != null ? const Color(0xFFD32F2F) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF276F8F), width: 1.4),
                              ),
                              errorText: _regEmailError,
                              errorStyle: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFD32F2F)),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Field 3: Kata Sandi
                          TextFormField(
                            controller: _regPasswordController,
                            obscureText: _obscureRegPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleRegister(),
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C4E68),
                            ),
                            onChanged: (_) {
                              if (_regPasswordError != null) setState(() => _regPasswordError = null);
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: Color(0xFF276F8F),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 19,
                                  color: const Color(0xFF7A8B99),
                                ),
                                onPressed: () {
                                  setState(() => _obscureRegPassword = !_obscureRegPassword);
                                },
                              ),
                              hintText: 'Minimal 8 karakter',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _regPasswordError != null ? const Color(0xFFD32F2F) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _regPasswordError != null ? const Color(0xFFD32F2F) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF276F8F), width: 1.4),
                              ),
                              errorText: _regPasswordError,
                              errorStyle: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFD32F2F)),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Tombol Daftar Sekarang
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isRegisterLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF276F8F),
                                foregroundColor: Colors.white,
                                elevation: 1,
                                shadowColor: const Color(0xFF276F8F).withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isRegisterLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Daftar Sekarang',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Divider: atau daftar dengan
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: Color(0xFFE2E8F0), thickness: 1.0),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'atau daftar dengan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF7A8B99),
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Color(0xFFE2E8F0), thickness: 1.0),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Tombol Google Daftar (Hanya Google Sesuai Request User)
                          InkWell(
                            onTap: () => Navigator.pushNamed(context, '/google-auth'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CustomPaint(painter: GoogleLogoPainter()),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Daftar dengan Google',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1C4E68),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Google Multicolor G Logo Custom Painter
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.butt;

    // Blue arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2.5),
      -0.4,
      1.5,
      false,
      paint,
    );

    // Green arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2.5),
      1.1,
      1.5,
      false,
      paint,
    );

    // Yellow arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2.5),
      2.6,
      1.2,
      false,
      paint,
    );

    // Red arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2.5),
      3.8,
      1.4,
      false,
      paint,
    );

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w / 2 - 1, h / 2 - 2.1, w / 2 - 1, 4.2),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

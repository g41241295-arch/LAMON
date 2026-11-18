import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../providers/app_state.dart';

class GoogleAuthScreen extends StatefulWidget {
  const GoogleAuthScreen({super.key});

  @override
  State<GoogleAuthScreen> createState() => _GoogleAuthScreenState();
}

class _GoogleAuthScreenState extends State<GoogleAuthScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Inisialisasi GoogleSignIn dengan Web Client ID
      await GoogleSignIn.instance.initialize(
        serverClientId: '360000290906-hsn7ebeukuas0bq56a1avq2m00nduknr.apps.googleusercontent.com',
      );

      // Trigger the authentication flow
      final googleUser = await GoogleSignIn.instance.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create credential using idToken
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final email = userCredential.user!.email ?? googleUser.email;
        // Simpan riwayat login ke Firestore (dibalut try-catch agar kegagalan log tidak memblokir login)
        try {
          await FirebaseFirestore.instance.collection('login_history').add({
            'user_id': uid,
            'email': email,
            'waktu_login': Timestamp.now(),
          }).timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('Gagal mencatat login history: $e');
        }

        bool hasCompletedScreening = false;
        String userName = userCredential.user?.displayName ?? googleUser.displayName ?? email.split('@')[0];
        if (userName.isNotEmpty && userName == email.split('@')[0]) {
          userName = userName[0].toUpperCase() + userName.substring(1);
        }

        // Cek dan ambil dokumen user dari Firestore
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
        DocumentSnapshot<Map<String, dynamic>>? userDoc;
        try {
          userDoc = await userDocRef.get().timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint('Gagal membaca data user dari Firestore: $e');
        }

        // Jika dokumen belum ada (pengguna baru atau data belum tersimpan)
        if (userDoc == null || !userDoc.exists) {
          await userDocRef.set({
            'nama': userName,
            'email': email,
            'role': 'pengguna',
            'tanggal_daftar': Timestamp.now(),
            'hasCompletedScreening': false,
          }, SetOptions(merge: true));
        } else {
          final data = userDoc.data();
          if (data != null) {
            final rawRole = data['role'] as String?;
            if (rawRole == 'doctor' || rawRole == 'dokter') {
              if (!mounted) return;
              setState(() => _isLoading = false);
              Navigator.pushNamedAndRemoveUntil(context, '/dokter', (route) => false);
              return;
            }
            hasCompletedScreening = data['hasCompletedScreening'] == true;
            userName = data['nama'] ?? userName;
          }
        }

        if (!mounted) return;

        final appState = AppState.of(context);
        appState.loginWithGoogle(userName, email);

        setState(() {
          _isLoading = false;
        });

        if (!hasCompletedScreening) {
          Navigator.pushNamedAndRemoveUntil(context, '/screening/gender', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/beranda', (route) => false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Terjadi kendala saat login dengan Google. Silakan coba kembali.',
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Bagian Atas (50% Layar): Logo LAMON Diperbesar & Presisi di Tengah
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 170,
                                    height: 170,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF276F8F).withValues(alpha: 0.20),
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
                                    child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'LAMON',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1C4E68),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bagian Bawah (50% Layar): Card Putih Melengkung Selaras di Tengah Rata Atas-Bawah
                        Expanded(
                          flex: 5,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                              border: Border.all(color: const Color(0xFFEBE3D0), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, -6),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.fromLTRB(26, 28, 26, 24 + bottomInset),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'Login Google',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1C4E68),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Untuk Melanjutkan ke LAMON',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF276F8F),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),

                                // Tombol Solid Teal: Lanjutkan dengan Google
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signInWithGoogle,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF276F8F),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(0xFF276F8F).withValues(alpha: 0.5),
                                      elevation: 1.5,
                                      shadowColor: const Color(0xFF276F8F).withValues(alpha: 0.35),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Lanjutkan dengan Google',
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                  ),
                                ),

                                // Tulisan-tulisan Kebijakan Privasi di Bawah Tombol
                                Text(
                                  'Untuk melanjutkan, Google akan membagikan nama, alamat email, dan foto profil Anda ke LAMON. Sebelum menggunakan aplikasi ini, tinjau kebijakan privasi dan persyaratan layanan-nya',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    height: 1.5,
                                    color: const Color(0xFF5A7184),
                                    fontWeight: FontWeight.w400,
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
          ),
        ),
      ),
    );
  }
}

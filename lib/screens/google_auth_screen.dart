import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';

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
      
      // Request authorization to get access token (dibutuhkan Firebase)
      final clientAuth = await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final email = userCredential.user!.email ?? googleUser.email;
        
        // Simpan riwayat login ke Firestore
        await FirebaseFirestore.instance.collection('login_history').add({
          'user_id': uid,
          'email': email,
          'waktu_login': Timestamp.now(),
        });

        bool hasCompletedScreening = false;
        String userName = googleUser.displayName ?? 'User';

        // Cek jika pengguna baru
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'nama': userName,
            'email': email,
            'tanggal_daftar': Timestamp.now(),
            'hasCompletedScreening': false,
          });
        } else {
          // Ambil dari Firestore
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final data = userDoc.data();
            if (data != null) {
              hasCompletedScreening = data['hasCompletedScreening'] == true;
              userName = data['nama'] ?? userName;
            }
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
          content: Text('Terjadi kesalahan saat login dengan Google: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.primaryText,
                      size: 24,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Kembali',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: const Color(0xFFF0E6CA),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Mascot Logo
                  Image.asset(
                    AppAssets.logo,
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Login Google',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Untuk Melanjutkan ke LAMON',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Lanjutkan dengan Google Button
                  PrimaryButton(
                    text: 'Lanjutkan dengan Google',
                    isLoading: _isLoading,
                    onPressed: _signInWithGoogle,
                  ),

                  const SizedBox(height: 24),

                  // Privacy Policy Disclaimer
                  const Text(
                    'Untuk melanjutkan, Google akan membagikan nama, alamat email, dan foto profil Anda ke LAMON. Sebelum menggunakan aplikasi ini, tinjau kebijakan privasi dan persyaratan layanan-nya',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF4A5568),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

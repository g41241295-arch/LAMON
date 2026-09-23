import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/google_auth_screen.dart';
import '../screens/beranda_screen.dart';
import '../screens/placeholder_screen.dart';
import '../screens/screening/screening_gender_screen.dart';
import '../screens/screening/screening_birthdate_screen.dart';
import '../screens/screening/screening_history_screen.dart';
import '../screens/screening/screening_success_screen.dart';
import '../screens/prediction/disease_prediction_intro_screen.dart';
import '../screens/prediction/disease_prediction_screen.dart';
import '../screens/prediction/disease_prediction_result_screen.dart';
import '../screens/prediction/disease_prediction_history_screen.dart';
import '../screens/prediction/disease_prediction_history_detail_screen.dart';
import '../screens/food/catat_makanan_screen.dart';
import '../screens/food/ringkasan_makanan_screen.dart';
import '../screens/gastropedia/gastropedia_screen.dart';
import '../screens/gastropedia/gastropedia_category_screen.dart';
import '../screens/gastropedia/gastropedia_detail_screen.dart';
import '../screens/konsultasi/daftar_dokter_screen.dart';
import '../screens/konsultasi/detail_dokter_screen.dart';
import '../screens/konsultasi/ringkasan_pembayaran_screen.dart';
import '../screens/konsultasi/virtual_account_screen.dart';
import '../screens/konsultasi/payment_success_screen.dart';
import '../screens/konsultasi/chat_dokter_screen.dart';
import '../models/reflux_prediction_model.dart';
import '../models/gastropedia_item_model.dart';
import '../models/doctor_model.dart';

class AppRoutes {
  static const String initial = '/splash';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String googleAuth = '/google-auth';
  static const String beranda = '/beranda';
  static const String placeholder = '/placeholder';

  // Screening Flow Routes
  static const String screeningGender = '/screening/gender';
  static const String screeningBirthdate = '/screening/birthdate';
  static const String screeningHistory = '/screening/history';
  static const String screeningSuccess = '/screening/success';

  // Disease Prediction Routes
  static const String diseasePrediction = '/prediksi-penyakit';
  static const String diseasePredictionForm = '/prediksi-penyakit/form';
  static const String diseasePredictionResult = '/prediksi-penyakit/result';
  static const String diseasePredictionHistory = '/prediksi-penyakit/riwayat';
  static const String diseasePredictionHistoryLegacy = '/prediksi-penyakit/history';

  // Catat Makanan Route
  static const String catatMakanan = '/catat-makananmu';
  static const String ringkasanMakanan = '/ringkasan-makanan';

  // Gastropedia Routes
  static const String gastropedia = '/gastropedia';
  static const String gastropediaCategory = '/gastropedia/kategori';
  static const String gastropediaDetail = '/gastropedia/detail';

  // Konsultasi Dokter Routes
  static const String konsultasi = '/konsultasi';
  static const String konsulDokterAlias = '/konsul-dokter'; // alias dari menu beranda
  // Route dinamis konsultasi — path parameter di-parse di onGenerateRoute:
  // /konsultasi/dokter/:doctorId
  // /konsultasi/pembayaran/:doctorId
  // /konsultasi/virtual-account/:consultationId
  // /konsultasi/payment-success/:consultationId
  // /konsultasi/chat/:consultationId

  /// Helper untuk membuat transisi halaman yang halus (fade + subtle slide 450ms)
  static PageRouteBuilder<T> _createSmoothRoute<T>(
    Widget page, {
    RouteSettings? settings,
    bool isFadeOnly = false,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );

        if (isFadeOnly) {
          return FadeTransition(opacity: curved, child: child);
        }

        // Transisi slide halus ke atas/samping + fade
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final rawName = settings.name ?? '';
    final uri = Uri.parse(rawName);

    // ── Konsultasi: Dynamic Routes ─────────────────────────────────────────

    // /konsultasi/dokter/:doctorId → Detail Dokter
    if (uri.pathSegments.length == 3 &&
        uri.pathSegments[0] == 'konsultasi' &&
        uri.pathSegments[1] == 'dokter') {
      final doctorId = uri.pathSegments[2];
      final initialDoctor = settings.arguments is DoctorModel
          ? settings.arguments as DoctorModel
          : null;
      return _createSmoothRoute(
        DetailDokterScreen(doctorId: doctorId, initialDoctor: initialDoctor),
        settings: settings,
      );
    }

    // /konsultasi/pembayaran/:doctorId → Ringkasan Pembayaran
    if (uri.pathSegments.length == 3 &&
        uri.pathSegments[0] == 'konsultasi' &&
        uri.pathSegments[1] == 'pembayaran') {
      final doctor = settings.arguments is DoctorModel
          ? settings.arguments as DoctorModel
          : null;
      if (doctor != null) {
        return _createSmoothRoute(
          RingkasanPembayaranScreen(doctor: doctor),
          settings: settings,
        );
      }
      // Fallback jika tidak ada argumen dokter
      return _createSmoothRoute(
        const DaftarDokterScreen(),
        settings: settings,
      );
    }

    // /konsultasi/virtual-account/:consultationId → Virtual Account
    if (uri.pathSegments.length == 3 &&
        uri.pathSegments[0] == 'konsultasi' &&
        uri.pathSegments[1] == 'virtual-account') {
      final consultationId = uri.pathSegments[2];
      return _createSmoothRoute(
        VirtualAccountScreen(consultationId: consultationId),
        settings: settings,
      );
    }

    // /konsultasi/payment-success/:consultationId → Payment Success
    if (uri.pathSegments.length == 3 &&
        uri.pathSegments[0] == 'konsultasi' &&
        uri.pathSegments[1] == 'payment-success') {
      final consultationId = uri.pathSegments[2];
      return _createSmoothRoute(
        PaymentSuccessScreen(consultationId: consultationId),
        settings: settings,
        isFadeOnly: true,
      );
    }

    // /konsultasi/chat/:consultationId → Chat Dokter
    if (uri.pathSegments.length == 3 &&
        uri.pathSegments[0] == 'konsultasi' &&
        uri.pathSegments[1] == 'chat') {
      final consultationId = uri.pathSegments[2];
      return _createSmoothRoute(
        ChatDokterScreen(consultationId: consultationId),
        settings: settings,
      );
    }

    // ── Prediksi: Dynamic Routes ───────────────────────────────────────────

    // Dynamic Route untuk Detail Riwayat: /prediksi-penyakit/riwayat/:id atau /prediksi-penyakit/history/:id
    if (uri.pathSegments.length == 3 &&
        uri.pathSegments[0] == 'prediksi-penyakit' &&
        (uri.pathSegments[1] == 'riwayat' || uri.pathSegments[1] == 'history')) {
      final predictionId = uri.pathSegments[2];
      final initialResult = settings.arguments is RefluxPredictionResult
          ? settings.arguments as RefluxPredictionResult
          : null;

      return _createSmoothRoute(
        DiseasePredictionHistoryDetailScreen(
          predictionId: predictionId,
          initialResult: initialResult,
        ),
        settings: settings,
      );
    }

    // Dynamic Route untuk Daftar Riwayat
    if (uri.path == diseasePredictionHistory ||
        uri.path == diseasePredictionHistoryLegacy) {
      final args = settings.arguments is Map<String, dynamic>
          ? settings.arguments as Map<String, dynamic>
          : null;
      final newId = args?['newId'] as String?;
      return _createSmoothRoute(
        DiseasePredictionHistoryScreen(newId: newId),
        settings: settings,
      );
    }

    switch (settings.name) {
      case splash:
        return _createSmoothRoute(
          const SplashScreen(),
          settings: settings,
          isFadeOnly: true,
        );
      case login:
        return _createSmoothRoute(
          const LoginScreen(),
          settings: settings,
          isFadeOnly: true,
        );
      case register:
        return _createSmoothRoute(
          const RegisterScreen(),
          settings: settings,
        );
      case googleAuth:
        return _createSmoothRoute(
          const GoogleAuthScreen(),
          settings: settings,
        );
      case screeningGender:
        return _createSmoothRoute(
          const ScreeningGenderScreen(),
          settings: settings,
        );
      case screeningBirthdate:
        return _createSmoothRoute(
          const ScreeningBirthdateScreen(),
          settings: settings,
        );
      case screeningHistory:
        return _createSmoothRoute(
          const ScreeningHistoryScreen(),
          settings: settings,
        );
      case screeningSuccess:
        return _createSmoothRoute(
          const ScreeningSuccessScreen(),
          settings: settings,
          isFadeOnly: true,
        );
      case beranda:
        return _createSmoothRoute(
          const BerandaScreen(),
          settings: settings,
          isFadeOnly: true,
        );
      case catatMakanan:
        return _createSmoothRoute(
          const CatatMakananScreen(),
          settings: settings,
        );
      case ringkasanMakanan:
        return _createSmoothRoute(
          const RingkasanMakananScreen(),
          settings: settings,
        );
      case diseasePrediction:
        return _createSmoothRoute(
          const DiseasePredictionIntroScreen(),
          settings: settings,
        );
      case diseasePredictionForm:
        return _createSmoothRoute(
          const DiseasePredictionScreen(),
          settings: settings,
        );
      case diseasePredictionHistory:
      case diseasePredictionHistoryLegacy:
        final histArgs = settings.arguments is Map<String, dynamic>
            ? settings.arguments as Map<String, dynamic>
            : null;
        final newId = histArgs?['newId'] as String?;
        return _createSmoothRoute(
          DiseasePredictionHistoryScreen(newId: newId),
          settings: settings,
        );
      case diseasePredictionResult:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final result = args['result'] as RefluxPredictionResult?;
        final dietInput = args['dietInput'] as UserDietInput?;
        if (result != null) {
          return _createSmoothRoute(
            DiseasePredictionResultScreen(
              result: result,
              dietInput: dietInput,
            ),
            settings: settings,
          );
        }
        return _createSmoothRoute(
          const DiseasePredictionScreen(),
          settings: settings,
        );
      case placeholder:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _createSmoothRoute(
          PlaceholderScreen(
            title: args['title'] as String? ?? 'Halaman Menu',
            description: args['description'] as String?,
          ),
          settings: settings,
        );
      case gastropedia:
        return _createSmoothRoute(
          const GastropediaScreen(),
          settings: settings,
        );
      case gastropediaCategory:
        final category = settings.arguments is GastropediaCategory
            ? settings.arguments as GastropediaCategory
            : GastropediaCategory.makanan;
        return _createSmoothRoute(
          GastropediaCategoryScreen(category: category),
          settings: settings,
        );
      case gastropediaDetail:
        final item = settings.arguments is GastropediaItem
            ? settings.arguments as GastropediaItem
            : GastropediaData.items.first;
        return _createSmoothRoute(
          GastropediaDetailScreen(item: item),
          settings: settings,
        );
      // ── Konsultasi Dokter Routes ──────────────────────────────────────────
      case konsultasi:
      case konsulDokterAlias: // alias dari menu beranda (/konsul-dokter)
        return _createSmoothRoute(
          const DaftarDokterScreen(),
          settings: settings,
        );
      default:
        return _createSmoothRoute(
          const LoginScreen(),
          settings: settings,
        );
    }
  }
}


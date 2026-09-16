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
import '../models/reflux_prediction_model.dart';

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
  static const String diseasePredictionHistory = '/prediksi-penyakit/history';

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
        return _createSmoothRoute(
          const PlaceholderScreen(
            title: 'Riwayat Pemeriksaan',
            description: 'Halaman riwayat hasil prediksi penyakit asam lambung sedang dikembangkan.',
          ),
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
      default:
        return _createSmoothRoute(
          const LoginScreen(),
          settings: settings,
        );
    }
  }
}


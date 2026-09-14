import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/google_auth_screen.dart';
import '../screens/beranda_screen.dart';
import '../screens/placeholder_screen.dart';

class AppRoutes {
  static const String initial = '/login';
  static const String login = '/login';
  static const String register = '/register';
  static const String googleAuth = '/google-auth';
  static const String beranda = '/beranda';
  static const String placeholder = '/placeholder';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case googleAuth:
        return MaterialPageRoute(builder: (_) => const GoogleAuthScreen());
      case beranda:
        return MaterialPageRoute(builder: (_) => const BerandaScreen());
      case placeholder:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => PlaceholderScreen(
            title: args['title'] as String? ?? 'Halaman Menu',
            description: args['description'] as String?,
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}

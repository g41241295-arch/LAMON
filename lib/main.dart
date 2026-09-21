import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'constants/app_colors.dart';
import 'providers/app_state.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LamonApp());
}

class LamonApp extends StatefulWidget {
  const LamonApp({super.key});

  @override
  State<LamonApp> createState() => _LamonAppState();
}

class _LamonAppState extends State<LamonApp> {
  final AppState _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _appState,
      child: MaterialApp(
        title: 'LAMON - Pemantauan Kesehatan Lambung',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
          ),
          scaffoldBackgroundColor: AppColors.bgGradientMiddle,
          fontFamily: 'Segoe UI',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.primaryText),
            titleTextStyle: TextStyle(
              color: AppColors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        initialRoute: AppRoutes.initial,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamon/screens/login_screen.dart';
import 'package:lamon/screens/splash_screen.dart';
import 'package:lamon/providers/app_state.dart';
import 'package:lamon/widgets/primary_button.dart';

void main() {
  testWidgets('LamonApp smoke test - verifies Login screen displays with correct order', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      AppStateScope(
        notifier: appState,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that LAMON header and Welcome card exist
    expect(find.text('LAMON'), findsOneWidget);
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);

    // Verify order: Masuk button is rendered higher (smaller dy) than Google button
    final masukPos = tester.getCenter(find.widgetWithText(PrimaryButton, 'Masuk'));
    final googlePos = tester.getCenter(find.text('Masuk dengan Google'));
    expect(masukPos.dy < googlePos.dy, isTrue, reason: 'Masuk button must be above Google button');
  });

  testWidgets('Login validation blocks unregistered email and shows error message', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      AppStateScope(
        notifier: appState,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Enter unregistered email and valid length password
    await tester.enterText(find.byType(TextField).at(0), 'unregistered@gmail.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');

    // Scroll to and tap Masuk
    final masukFinder = find.widgetWithText(PrimaryButton, 'Masuk');
    await tester.ensureVisible(masukFinder);
    await tester.tap(masukFinder);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify error message is shown
    expect(find.text('Akun tidak ditemukan. Silakan daftar terlebih dahulu.'), findsWidgets);
  });

  testWidgets('SplashScreen renders without error and has skip tap to navigate', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login Screen Mock')),
        },
        home: const SplashScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Tap to skip
    await tester.tap(find.byType(SplashScreen));
    await tester.pumpAndSettle();

    expect(find.text('Login Screen Mock'), findsOneWidget);
  });
}

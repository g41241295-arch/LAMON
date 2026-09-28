import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamon/screens/beranda_screen.dart';
import 'package:lamon/providers/app_state.dart';
import 'package:lamon/widgets/bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Skenario 1: Jam 09.00 (tombol makan siang nonaktif, jam diam, snackbar muncul)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final appState = AppState();
    final berandaKey = GlobalKey<BerandaScreenState>();

    await tester.pumpWidget(
      AppStateScope(
        notifier: appState,
        child: MaterialApp(
          home: BerandaScreen(key: berandaKey),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Set waktu ke pukul 09.00
    berandaKey.currentState?.setDebugTime(DateTime(2026, 9, 28, 9, 0));
    await tester.pump(const Duration(milliseconds: 300));

    // Pastikan jadwal yang ditampilkan adalah Makan siang
    expect(find.text('Jam makan siang'), findsOneWidget);
    expect(find.text('12.00 – 13.00 WIB'), findsOneWidget);

    // Alarm harus diam (tidak berbunyi)
    expect(berandaKey.currentState?.mealService.isAlarmRinging, isFalse);

    // Tekan tombol "Tandai selesai" (yang nonaktif)
    final buttonFinder = find.text('Tandai selesai');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pump();

    // Verifikasi muncul SnackBar peringatan belum waktunya
    expect(find.text('Belum waktunya makan. Tersedia pukul 12.00'), findsOneWidget);

    // Status makan siang di ringkasan masih belum tercentang
    expect(find.text('Makan siang'), findsOneWidget);
  });

  testWidgets('Skenario 2: Jam 12.05 (alarm bunyi, jam bergetar, tombol aktif, tandai selesai)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final appState = AppState();
    final berandaKey = GlobalKey<BerandaScreenState>();

    await tester.pumpWidget(
      AppStateScope(
        notifier: appState,
        child: MaterialApp(
          home: BerandaScreen(key: berandaKey),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Set waktu ke pukul 12.05 (dalam rentang 12.00 - 13.00)
    berandaKey.currentState?.setDebugTime(DateTime(2026, 9, 28, 12, 5));
    await tester.pump(const Duration(milliseconds: 300));

    // Pastikan alarm berbunyi
    expect(berandaKey.currentState?.mealService.isAlarmRinging, isTrue);

    // Tekan tombol "Tandai selesai" yang sedang aktif
    final buttonFinder = find.text('Tandai selesai');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pump();

    // Tombol berubah menjadi "Selesai ✓" dan alarm mati
    expect(find.text('Selesai ✓'), findsOneWidget);
    expect(berandaKey.currentState?.mealService.isAlarmRinging, isFalse);

    // Verifikasi jam aktual tercatat pada ringkasan
    expect(find.text('12.05'), findsOneWidget);

    // Tunggu transisi otomatis (1.4 detik)
    await tester.pump(const Duration(milliseconds: 1500));

    // Kartu otomatis berpindah ke jam makan berikutnya (Makan malam)
    expect(find.text('Jam makan malam'), findsOneWidget);
    expect(find.text('18.00 – 19.00 WIB'), findsOneWidget);
  });

  testWidgets('Skenario 3: Jam 13.30 tanpa ditandai (makan siang terlewat, pindah ke makan malam)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final appState = AppState();
    final berandaKey = GlobalKey<BerandaScreenState>();

    await tester.pumpWidget(
      AppStateScope(
        notifier: appState,
        child: MaterialApp(
          home: BerandaScreen(key: berandaKey),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Set waktu ke pukul 13.30 (makan siang sudah lewat tanpa ditandai)
    berandaKey.currentState?.setDebugTime(DateTime(2026, 9, 28, 13, 30));
    await tester.pump(const Duration(milliseconds: 300));

    // Kartu harus otomatis menampilkan jadwal berikutnya (Makan malam)
    expect(find.text('Jam makan malam'), findsOneWidget);
    expect(find.text('18.00 – 19.00 WIB'), findsOneWidget);

    // Alarm harus diam karena belum masuk jam 18.00
    expect(berandaKey.currentState?.mealService.isAlarmRinging, isFalse);

    // Di ringkasan, Makan siang tidak ada jam selesai (tetap tidak tercentang)
    expect(find.text('12.00'), findsNothing);
    expect(find.text('12.30'), findsNothing);
  });

  testWidgets('Skenario 4: UI Beranda (tidak ada bottom nav, menu full-bleed, seputar informasi)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final appState = AppState();

    await tester.pumpWidget(
      AppStateScope(
        notifier: appState,
        child: const MaterialApp(
          home: BerandaScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verifikasi BottomNavBar TIDAK ADA di halaman Beranda
    expect(find.byType(BottomNavBar), findsNothing);

    // 2. Verifikasi Header & Maskot
    expect(find.textContaining('Halo,'), findsOneWidget);
    expect(find.textContaining('Sehatkan Lambung'), findsOneWidget);

    // 3. Verifikasi Ringkasan hari ini
    expect(find.text('Ringkasan hari ini'), findsOneWidget);
    expect(find.text('Sarapan'), findsOneWidget);
    expect(find.text('Makan siang'), findsOneWidget);
    expect(find.text('Makan malam'), findsOneWidget);

    // 4. Verifikasi Menu Utama
    expect(find.text('Menu Utama'), findsOneWidget);
    expect(find.textContaining('Pengingat'), findsOneWidget);
    expect(find.textContaining('Catat'), findsOneWidget);
    expect(find.text('Ringkasan\nmakanan'), findsOneWidget);

    // Scroll horizontal Menu Utama
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.drag(find.byType(ListView), const Offset(-240, 0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Prediksi'), findsOneWidget);
    expect(find.textContaining('Konsul'), findsOneWidget);

    // 5. Verifikasi Seputar Informasi
    expect(find.text('Seputar Informasi'), findsOneWidget);
    expect(find.text('Gastropedia'), findsOneWidget);
    expect(find.text('Berita Kesehatan'), findsOneWidget);

    // Bebas RenderFlex overflow
    expect(tester.takeException(), isNull);
  });
}

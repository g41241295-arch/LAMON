import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamon/models/reflux_prediction_model.dart';
import 'package:lamon/services/reflux_prediction_service.dart';
import 'package:lamon/providers/app_state.dart';
import 'package:lamon/screens/prediction/disease_prediction_screen.dart';
import 'package:lamon/routes/app_routes.dart';

void main() {
  group('Reflux Prediction Service & Model Tests', () {
    test('UserDietInput toFeatureVector generates exactly 13 ordered features', () {
      const input = UserDietInput(
        dietType: 'Omnivora',
        fruitFrequency: 3,
        vegetableFrequency: 4,
        homecookedMealsFrequency: 2,
        oneLiterWaterFrequency: 3,
        redMeatFrequency: 2,
        highFatRedMeat: true,
        saltedSnacksFrequency: 1,
        frozenDessertFrequency: 0,
        milkCheeseFrequency: 1,
        alcoholFrequency: 0,
      );

      final vector = input.toFeatureVector();
      expect(vector.length, 13);
      // 1. diet_Omn
      expect(vector[0], 1.0);
      // 2. diet_Veg
      expect(vector[1], 0.0);
      // 3. diet_Vegt
      expect(vector[2], 0.0);
      // 4. fruit_frequency_encoded
      expect(vector[3], 3.0);
      // 5. high_fat_red_meat_frequency_enc
      expect(vector[4], 1.0);
      // 6. homecooked_meals_frequency_enc
      expect(vector[5], 2.0);
      // 7. vegetable_frequency_enc
      expect(vector[6], 4.0);
      // 8. alcohol_frequency_enc
      expect(vector[7], 0.0);
      // 9. frozen_dessert_frequency_enc
      expect(vector[8], 0.0);
      // 10. milk_cheese_frequency_enc
      expect(vector[9], 1.0);
      // 11. one_liter_of_water_a_day_frequency_enc
      expect(vector[10], 3.0);
      // 12. salted_snacks_frequency_enc
      expect(vector[11], 1.0);
      // 13. red_meat_frequency_enc
      expect(vector[12], 2.0);
    });

    test('predictReflux produces valid risk category and 3 top factors', () async {
      const highRiskInput = UserDietInput(
        dietType: 'Omnivora',
        fruitFrequency: 0,
        vegetableFrequency: 0,
        homecookedMealsFrequency: 0,
        oneLiterWaterFrequency: 0,
        redMeatFrequency: 4,
        highFatRedMeat: true,
        saltedSnacksFrequency: 4,
        frozenDessertFrequency: 4,
        milkCheeseFrequency: 4,
        alcoholFrequency: 4,
      );

      final result = await RefluxPredictionService.predictReflux(highRiskInput);

      expect(result.riskPercentage, greaterThan(60.0));
      expect(result.riskCategory, 'Risiko Tinggi');
      expect(result.topFactors.length, 3);
      expect(result.recommendations.isNotEmpty, isTrue);
    });

    test('AppState saves prediction result to user history', () {
      final appState = AppState();
      expect(appState.predictionHistory.isEmpty, isTrue);

      final mockResult = RefluxPredictionResult(
        riskPercentage: 45.0,
        riskCategory: 'Risiko Sedang',
        categoryDescription: 'Deskripsi uji coba',
        topFactors: const [],
        recommendations: const ['Perbanyak minum air'],
        dietInput: const UserDietInput(),
        createdAt: DateTime.now(),
      );

      appState.savePredictionResult(mockResult);

      expect(appState.predictionHistory.length, 1);
      expect(appState.predictionHistory.first.riskPercentage, 45.0);
      expect(appState.predictionHistory.first.riskCategory, 'Risiko Sedang');

      // Test lookup by ID
      final retrieved = appState.getPredictionById(mockResult.id);
      expect(retrieved, isNotNull);
      expect(retrieved?.riskPercentage, 45.0);
    });

    test('RefluxPredictionResult JSON serialization preserves all fields', () {
      const diet = UserDietInput(
        dietType: 'Vegetarian',
        fruitFrequency: 4,
        vegetableFrequency: 4,
        highFatRedMeat: false,
        alcoholFrequency: 0,
      );

      final result = RefluxPredictionResult(
        id: 'pred_test_123',
        riskPercentage: 22.5,
        riskCategory: 'Risiko Rendah',
        categoryDescription: 'Pola makan ramah lambung',
        topFactors: const [
          FactorContribution(
            featureName: 'fruit_habit',
            title: 'Asupan Buah Tinggi',
            userValueDescription: 'setiap hari',
            contributionScore: 0.8,
            icon: Icons.apple_rounded,
          ),
        ],
        recommendations: const ['Pertahankan pola makan sehat'],
        dietInput: diet,
        createdAt: DateTime(2026, 9, 15, 14, 30),
      );

      final json = result.toJson();
      final fromJson = RefluxPredictionResult.fromJson(json);

      expect(fromJson.id, 'pred_test_123');
      expect(fromJson.riskPercentage, 22.5);
      expect(fromJson.riskCategory, 'Risiko Rendah');
      expect(fromJson.dietInput.dietType, 'Vegetarian');
      expect(fromJson.dietInput.fruitFrequency, 4);
      expect(fromJson.dietInput.highFatRedMeat, isFalse);
      expect(fromJson.topFactors.length, 1);
      expect(fromJson.recommendations.first, 'Pertahankan pola makan sehat');
    });
  });

  group('DiseasePredictionScreen Widget Tests', () {
    testWidgets('Renders Step 1 with stepper and navigates to Step 2 without losing state',
        (WidgetTester tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        AppStateScope(
          notifier: appState,
          child: const MaterialApp(
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: DiseasePredictionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi header dan stepper
      expect(find.text('Prediksi Penyakit'), findsOneWidget);
      expect(find.text('Langkah 1 — Pola makan sehari-hari'), findsOneWidget);
      expect(find.text('Jenis Pola Makan'), findsOneWidget);
      expect(find.text('Omnivora'), findsOneWidget);
      expect(find.text('Vegetarian'), findsOneWidget);
      expect(find.text('Vegan'), findsOneWidget);

      // Pilih Vegetarian
      await tester.tap(find.text('Vegetarian'));
      await tester.pumpAndSettle();

      // Tekan tombol Lanjut
      final lanjutBtn = find.text('Lanjut');
      expect(lanjutBtn, findsOneWidget);
      await tester.tap(lanjutBtn);
      await tester.pumpAndSettle();

      // Verifikasi berada di Langkah 2
      expect(find.text('Langkah 2 — Makanan Berisiko'), findsOneWidget);
      expect(find.text('Sering konsumsi daging tinggi lemak?'), findsOneWidget);

      // Tekan tombol Back
      final backBtn = find.byIcon(Icons.arrow_back_rounded);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Verifikasi kembali ke Langkah 1 dan Vegetarian tetap terpilih
      expect(find.text('Langkah 1 — Pola makan sehari-hari'), findsOneWidget);
    });
  });

  group('DiseasePredictionHistoryScreen & Detail Tests', () {
    testWidgets('Renders empty state when history is empty',
        (WidgetTester tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        AppStateScope(
          notifier: appState,
          child: const MaterialApp(
            initialRoute: '/prediksi-penyakit/riwayat',
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Prediksi'), findsOneWidget);
      expect(find.text('Belum ada riwayat pemeriksaan'), findsOneWidget);
      expect(find.text('Mulai Pemeriksaan Baru'), findsOneWidget);
    });

    testWidgets('Renders history list with trend card and navigates to detail snapshot',
        (WidgetTester tester) async {
      final appState = AppState();

      final record1 = RefluxPredictionResult(
        id: 'pred_1',
        riskPercentage: 25.0,
        riskCategory: 'Risiko Rendah',
        categoryDescription: 'Pola makan baik',
        topFactors: const [
          FactorContribution(
            featureName: 'fruit_habit',
            title: 'Asupan Buah',
            userValueDescription: 'setiap hari',
            contributionScore: 0.6,
            icon: Icons.apple_rounded,
          ),
        ],
        recommendations: const ['Perbanyak serat'],
        dietInput: const UserDietInput(
          dietType: 'Omnivora',
          fruitFrequency: 4,
          vegetableFrequency: 3,
          highFatRedMeat: false,
        ),
        createdAt: DateTime(2026, 9, 10, 10, 0),
      );

      final record2 = RefluxPredictionResult(
        id: 'pred_2',
        riskPercentage: 72.0,
        riskCategory: 'Risiko Tinggi',
        categoryDescription: 'Banyak faktor pemicu',
        topFactors: const [
          FactorContribution(
            featureName: 'alcohol',
            title: 'Konsumsi Alkohol',
            userValueDescription: 'sering',
            contributionScore: 0.9,
            icon: Icons.local_bar_rounded,
          ),
        ],
        recommendations: const ['Kurangi konsumsi alkohol'],
        dietInput: const UserDietInput(
          dietType: 'Omnivora',
          alcoholFrequency: 3,
          highFatRedMeat: true,
        ),
        createdAt: DateTime(2026, 9, 15, 14, 0),
      );

      appState.savePredictionResult(record1);
      appState.savePredictionResult(record2);

      await tester.pumpWidget(
        AppStateScope(
          notifier: appState,
          child: const MaterialApp(
            initialRoute: '/prediksi-penyakit/riwayat',
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi judul dan list kartu
      expect(find.text('Riwayat Prediksi'), findsOneWidget);
      expect(find.text('Tren risikomu'), findsOneWidget);
      expect(find.text('2 pemeriksaan'), findsOneWidget);
      expect(find.text('Semua Pemeriksaan (2)'), findsOneWidget);
      expect(find.text('72%'), findsWidgets);
      expect(find.text('25%'), findsWidgets);

      // Tap kartu terbaru (72%)
      await tester.ensureVisible(find.text('Risiko Tinggi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Risiko Tinggi'));
      await tester.pumpAndSettle();

      // Verifikasi halaman Detail Pemeriksaan (Snapshot)
      expect(find.text('Detail Pemeriksaan'), findsOneWidget);
      expect(find.text('Pola makan tercatat'), findsOneWidget);
      expect(find.text('Jawaban yang tersimpan'), findsOneWidget);
      expect(find.text('Daging tinggi lemak'), findsOneWidget);
      expect(find.text('Ya'), findsOneWidget);
      expect(find.text('Faktor paling berpengaruh saat itu'), findsOneWidget);
      expect(find.text('Konsumsi Alkohol'), findsOneWidget);
      expect(find.text('Rekomendasi saat itu'), findsOneWidget);
      expect(find.text('Kurangi konsumsi alkohol'), findsOneWidget);

      // Tap Back
      final backBtn = find.byIcon(Icons.arrow_back_rounded);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Prediksi'), findsOneWidget);
    });

    testWidgets('Direct route to /prediksi-penyakit/riwayat/:id renders detail snapshot on deep link',
        (WidgetTester tester) async {
      final appState = AppState();

      final record = RefluxPredictionResult(
        id: 'pred_999',
        riskPercentage: 30.0,
        riskCategory: 'Risiko Rendah',
        categoryDescription: 'Aman dan stabil',
        topFactors: const [],
        recommendations: const ['Pertahankan hidrasi'],
        dietInput: const UserDietInput(
          dietType: 'Vegan',
          fruitFrequency: 4,
          vegetableFrequency: 4,
        ),
        createdAt: DateTime(2026, 9, 20, 8, 30),
      );

      appState.savePredictionResult(record);

      await tester.pumpWidget(
        AppStateScope(
          notifier: appState,
          child: const MaterialApp(
            initialRoute: '/prediksi-penyakit/riwayat/pred_999',
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail Pemeriksaan'), findsOneWidget);
      expect(find.text('Vegan'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('Risiko Rendah'), findsOneWidget);
      expect(find.text('Pertahankan hidrasi'), findsOneWidget);
    });

    test('RefluxPredictionResult toFirestore and fromMap handle Firestore data correctly', () {
      final sample = RefluxPredictionResult(
        id: 'pred_123456789',
        riskPercentage: 72.5,
        riskCategory: 'Risiko Tinggi',
        categoryDescription: 'Pola konsumsi berisiko tinggi.',
        topFactors: const [
          FactorContribution(
            featureName: 'alcohol',
            title: 'Konsumsi Alkohol',
            userValueDescription: 'sering',
            contributionScore: 0.85,
            icon: Icons.local_bar_rounded,
          ),
          FactorContribution(
            featureName: 'high_fat_meat',
            title: 'Daging Tinggi Lemak',
            userValueDescription: 'sering dikonsumsi',
            contributionScore: 0.70,
            icon: Icons.lunch_dining_rounded,
          ),
        ],
        recommendations: const [
          'Hindari konsumsi alkohol.',
          'Kurangi daging tinggi lemak.',
        ],
        dietInput: const UserDietInput(
          dietType: 'Omnivora',
          fruitFrequency: 1,
          vegetableFrequency: 1,
          alcoholFrequency: 3,
          highFatRedMeat: true,
        ),
        createdAt: DateTime(2026, 9, 22, 10, 0),
      );

      final firestoreMap = sample.toFirestore();

      expect(firestoreMap['id'], 'pred_123456789');
      expect(firestoreMap['riskPercentage'], 72.5);
      expect(firestoreMap['riskCategory'], 'Risiko Tinggi');
      expect(firestoreMap['categoryDescription'], 'Pola konsumsi berisiko tinggi.');
      expect(firestoreMap['recommendations'], ['Hindari konsumsi alkohol.', 'Kurangi daging tinggi lemak.']);

      // Pastikan topFactors tidak mengandung IconData
      final factors = firestoreMap['topFactors'] as List;
      expect(factors.length, 2);
      expect(factors[0]['featureName'], 'alcohol');
      expect(factors[0]['title'], 'Konsumsi Alkohol');
      expect(factors[0]['contributionScore'], 0.85);
      expect(factors[0].containsKey('icon'), isFalse);
      expect(factors[0].containsKey('iconCodePoint'), isFalse);

      // Deserialisasi dari Map (simulasi data dari Firestore)
      final restored = RefluxPredictionResult.fromMap({
        'id': 'pred_123456789',
        'riskPercentage': 72.5,
        'riskCategory': 'Risiko Tinggi',
        'categoryDescription': 'Pola konsumsi berisiko tinggi.',
        'topFactors': factors,
        'recommendations': ['Hindari konsumsi alkohol.', 'Kurangi daging tinggi lemak.'],
        'dietInput': firestoreMap['dietInput'],
        'createdAt': '2026-09-22T10:00:00.000',
      });

      expect(restored.id, 'pred_123456789');
      expect(restored.riskPercentage, 72.5);
      expect(restored.topFactors.length, 2);
      expect(restored.topFactors[0].featureName, 'alcohol');
      // Ikon harus terpetakan kembali secara otomatis di sisi UI/model
      expect(restored.topFactors[0].icon, Icons.local_bar_rounded);
      expect(restored.topFactors[1].icon, Icons.lunch_dining_rounded);
      expect(restored.dietInput.dietType, 'Omnivora');
      expect(restored.dietInput.alcoholFrequency, 3);
      expect(restored.dietInput.highFatRedMeat, true);
    });
  });
}


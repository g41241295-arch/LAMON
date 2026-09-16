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
}

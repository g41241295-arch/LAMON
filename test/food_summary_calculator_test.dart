import 'package:flutter_test/flutter_test.dart';
import 'package:lamon/models/food_entry_model.dart';
import 'package:lamon/utils/food_summary_calculator.dart';

void main() {
  group('FoodSummaryCalculator Tests', () {
    test('Empty entries return default safe values without crash', () {
      final calc = FoodSummaryCalculator(entries: []);
      final risk = calc.calculateLambungRiskScore();
      final nut = calc.calculateDailyNutrition();

      expect(risk.level, LambungRiskLevel.aman);
      expect(risk.score, 0.0);
      expect(nut.calories, 0);
      expect(nut.protein, 0.0);
      expect(nut.carbs, 0.0);
      expect(nut.fat, 0.0);
      expect(nut.caloriesPercentage, 0);
    });

    test('Scenario: Aman untuk Lambung (Pola makan sehat & homemade)', () {
      final entries = [
        FoodEntry(
          id: 'test_sarapan',
          userId: 'user1',
          tanggal: '2026-11-15',
          waktuPengisian: DateTime(2026, 11, 15, 7, 0),
          sesi: MealSession.sarapan,
          jenisMakanan: ['Homemade'],
          sumberKarbohidrat: ['Roti'],
          protein: ['Telur'],
          sayuran: ['Bayam'],
          levelPedas: 0,
          levelAsin: 1,
          levelAsam: 0,
          levelManis: 1,
          levelBerlemak: 1,
          berbaringSetelahMakan: false,
          konsumsiSoda: false,
          konsumsiKopi: false,
        ),
        FoodEntry(
          id: 'test_siang',
          userId: 'user1',
          tanggal: '2026-11-15',
          waktuPengisian: DateTime(2026, 11, 15, 12, 30),
          sesi: MealSession.makanSiang,
          jenisMakanan: ['Homemade'],
          sumberKarbohidrat: ['Nasi putih'],
          protein: ['Ikan'],
          sayuran: ['Brokoli'],
          levelPedas: 0,
          levelAsin: 1,
          levelAsam: 0,
          levelManis: 1,
          levelBerlemak: 1,
          berbaringSetelahMakan: false,
          konsumsiSoda: false,
          konsumsiKopi: false,
        ),
        FoodEntry(
          id: 'test_malam',
          userId: 'user1',
          tanggal: '2026-11-15',
          waktuPengisian: DateTime(2026, 11, 15, 19, 0),
          sesi: MealSession.makanMalam,
          jenisMakanan: ['Homemade'],
          sumberKarbohidrat: ['Nasi putih'],
          protein: ['Tahu/Tempe'],
          sayuran: ['Sawi'],
          levelPedas: 0,
          levelAsin: 1,
          levelAsam: 0,
          levelManis: 0,
          levelBerlemak: 1,
          berbaringSetelahMakan: false,
          konsumsiSoda: false,
          konsumsiKopi: false,
          bebanPikiran: 1, // rata-rata 2.0/5
          bebanAktivitas: 1,
        ),
      ];

      final calc = FoodSummaryCalculator(entries: entries);
      final risk = calc.calculateLambungRiskScore();
      final nut = calc.calculateDailyNutrition();

      expect(risk.level, LambungRiskLevel.aman);
      expect(risk.label, 'Aman untuk Lambung');
      expect(nut.calories, greaterThan(800));
      expect(nut.protein, greaterThan(40));
    });

    test('Scenario User Screenshot: Perlu Diperhatikan (Asin & Berlemak dominan)', () {
      final entries = [
        FoodEntry(
          id: 'test_1',
          userId: 'user1',
          tanggal: '2026-11-12',
          waktuPengisian: DateTime(2026, 11, 12, 7, 30),
          sesi: MealSession.sarapan,
          jenisMakanan: ['Homemade'],
          sumberKarbohidrat: ['Nasi putih'],
          protein: ['Daging Ayam'],
          sayuran: ['Bayam'],
          levelPedas: 0,
          levelAsin: 3,
          levelAsam: 0,
          levelManis: 0,
          levelBerlemak: 3,
          berbaringSetelahMakan: false,
          konsumsiSoda: false,
          konsumsiKopi: false,
        ),
        FoodEntry(
          id: 'test_2',
          userId: 'user1',
          tanggal: '2026-11-12',
          waktuPengisian: DateTime(2026, 11, 12, 12, 30),
          sesi: MealSession.makanSiang,
          jenisMakanan: ['Homemade'],
          sumberKarbohidrat: ['Nasi putih'],
          protein: ['Telur'],
          sayuran: ['Kangkung'],
          levelPedas: 0,
          levelAsin: 3,
          levelAsam: 0,
          levelManis: 0,
          levelBerlemak: 3,
          berbaringSetelahMakan: false,
          konsumsiSoda: false,
          konsumsiKopi: false,
        ),
        FoodEntry(
          id: 'test_3',
          userId: 'user1',
          tanggal: '2026-11-12',
          waktuPengisian: DateTime(2026, 11, 12, 19, 0),
          sesi: MealSession.makanMalam,
          jenisMakanan: ['Homemade'],
          sumberKarbohidrat: ['Nasi putih'],
          protein: [],
          sayuran: [],
          levelPedas: 0,
          levelAsin: 0,
          levelAsam: 0,
          levelManis: 0,
          levelBerlemak: 0,
          berbaringSetelahMakan: false,
          konsumsiSoda: false,
          konsumsiKopi: false,
          bebanPikiran: 2, // 2 + 1 = 3/5
          bebanAktivitas: 1, // 1 + 1 = 2/5
        ),
      ];

      final calc = FoodSummaryCalculator(entries: entries);
      final risk = calc.calculateLambungRiskScore();

      expect(risk.level, LambungRiskLevel.perluDiperhatikan);
      expect(risk.label, 'Perlu Diperhatikan');
      expect(risk.explanation, contains('berlemak'));
    });

    test('Scenario: Berisiko bagi Lambung (Junk Food, Pedas tinggi, Soda, Berbaring)', () {
      final entries = [
        FoodEntry(
          id: 'test_risk_1',
          userId: 'user1',
          tanggal: '2026-11-15',
          waktuPengisian: DateTime(2026, 11, 15, 12, 0),
          sesi: MealSession.makanSiang,
          jenisMakanan: ['Junk Food'],
          sumberKarbohidrat: ['Mie'],
          protein: ['Daging Sapi'],
          sayuran: [],
          levelPedas: 4,
          levelAsin: 3,
          levelAsam: 1,
          levelManis: 1,
          levelBerlemak: 4,
          berbaringSetelahMakan: true,
          konsumsiSoda: true,
          konsumsiKopi: false,
        ),
      ];

      final calc = FoodSummaryCalculator(entries: entries);
      final risk = calc.calculateLambungRiskScore();

      expect(risk.level, LambungRiskLevel.berisiko);
      expect(risk.label, 'Berisiko bagi Lambung');
      expect(risk.score, greaterThanOrEqualTo(7.0));
      expect(risk.explanation, contains('pemicu'));
    });

    test('Scenario: Akumulasi Nutrisi Harian vs Target', () {
      final entries = [
        FoodEntry(
          id: 'test_nut_1',
          userId: 'user1',
          tanggal: '2026-11-15',
          waktuPengisian: DateTime(2026, 11, 15, 7, 30),
          sesi: MealSession.sarapan,
          jenisMakanan: ['Homemade'],
          sumberKarbohidrat: ['Roti'], // 160 kcal, 5.5p, 30c, 2f
          protein: ['Telur'], // 78 kcal, 6.5p, 0.6c, 5.3f
          sayuran: ['Bayam'], // 23 kcal, 2.9p, 3.6c, 0.4f
          levelPedas: 0,
          levelAsin: 1,
          levelAsam: 0,
          levelManis: 1,
          levelBerlemak: 1, // +18 kcal, +2f
          berbaringSetelahMakan: false,
          konsumsiSoda: false,
          konsumsiKopi: true, // +25 kcal, 0.5p, 4c, 0.5f
        ),
      ];

      final calc = FoodSummaryCalculator(entries: entries);
      final nut = calc.calculateDailyNutrition();

      // Total expected approx: 160 + 78 + 23 + 18 + 25 = 304 kcal
      expect(nut.calories, equals(304));
      expect(nut.target.calories, equals(2000));
      expect(nut.caloriesPercentage, equals(15)); // (304 / 2000) * 100 = 15.2% -> 15%
    });
  });
}


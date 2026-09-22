import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// DTO yang menampung seluruh input kuesioner pengguna (Langkah 1–3)
class UserDietInput {
  final String dietType; // 'Omnivora', 'Vegetarian', 'Vegan'
  final int fruitFrequency; // 0-4
  final int vegetableFrequency; // 0-4
  final int homecookedMealsFrequency; // 0-4
  final int oneLiterWaterFrequency; // 0-4
  final int redMeatFrequency; // 0-4
  final bool highFatRedMeat; // false (Tidak), true (Ya)
  final int saltedSnacksFrequency; // 0-4
  final int frozenDessertFrequency; // 0-4
  final int milkCheeseFrequency; // 0-4
  final int alcoholFrequency; // 0-4

  const UserDietInput({
    this.dietType = 'Omnivora',
    this.fruitFrequency = 0,
    this.vegetableFrequency = 0,
    this.homecookedMealsFrequency = 0,
    this.oneLiterWaterFrequency = 0,
    this.redMeatFrequency = 0,
    this.highFatRedMeat = false,
    this.saltedSnacksFrequency = 0,
    this.frozenDessertFrequency = 0,
    this.milkCheeseFrequency = 0,
    this.alcoholFrequency = 0,
  });

  /// Mengonversi jawaban ke 13 fitur terurut identik dengan urutan dataset training Random Forest
  /// 1. diet_Omn
  /// 2. diet_Veg (Vegan)
  /// 3. diet_Vegt (Vegetarian)
  /// 4. fruit_frequency_encoded (0-4)
  /// 5. high_fat_red_meat_frequency_enc (0/1)
  /// 6. homecooked_meals_frequency_enc (0-4)
  /// 7. vegetable_frequency_enc (0-4)
  /// 8. alcohol_frequency_enc (0-4)
  /// 9. frozen_dessert_frequency_enc (0-4)
  /// 10. milk_cheese_frequency_enc (0-4)
  /// 11. one_liter_of_water_a_day_frequency_enc (0-4)
  /// 12. salted_snacks_frequency_enc (0-4)
  /// 13. red_meat_frequency_enc (0-4)
  List<double> toFeatureVector() {
    final isOmn = dietType.toLowerCase() == 'omnivora' ? 1.0 : 0.0;
    // Catatan: diet_Veg diasumsikan Vegan, diet_Vegt diasumsikan Vegetarian
    final isVeg = dietType.toLowerCase() == 'vegan' ? 1.0 : 0.0;
    final isVegt = dietType.toLowerCase() == 'vegetarian' ? 1.0 : 0.0;

    return [
      isOmn,
      isVeg,
      isVegt,
      fruitFrequency.toDouble(),
      highFatRedMeat ? 1.0 : 0.0,
      homecookedMealsFrequency.toDouble(),
      vegetableFrequency.toDouble(),
      alcoholFrequency.toDouble(),
      frozenDessertFrequency.toDouble(),
      milkCheeseFrequency.toDouble(),
      oneLiterWaterFrequency.toDouble(),
      saltedSnacksFrequency.toDouble(),
      redMeatFrequency.toDouble(),
    ];
  }

  UserDietInput copyWith({
    String? dietType,
    int? fruitFrequency,
    int? vegetableFrequency,
    int? homecookedMealsFrequency,
    int? oneLiterWaterFrequency,
    int? redMeatFrequency,
    bool? highFatRedMeat,
    int? saltedSnacksFrequency,
    int? frozenDessertFrequency,
    int? milkCheeseFrequency,
    int? alcoholFrequency,
  }) {
    return UserDietInput(
      dietType: dietType ?? this.dietType,
      fruitFrequency: fruitFrequency ?? this.fruitFrequency,
      vegetableFrequency: vegetableFrequency ?? this.vegetableFrequency,
      homecookedMealsFrequency:
          homecookedMealsFrequency ?? this.homecookedMealsFrequency,
      oneLiterWaterFrequency:
          oneLiterWaterFrequency ?? this.oneLiterWaterFrequency,
      redMeatFrequency: redMeatFrequency ?? this.redMeatFrequency,
      highFatRedMeat: highFatRedMeat ?? this.highFatRedMeat,
      saltedSnacksFrequency:
          saltedSnacksFrequency ?? this.saltedSnacksFrequency,
      frozenDessertFrequency:
          frozenDessertFrequency ?? this.frozenDessertFrequency,
      milkCheeseFrequency: milkCheeseFrequency ?? this.milkCheeseFrequency,
      alcoholFrequency: alcoholFrequency ?? this.alcoholFrequency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dietType': dietType,
      'fruitFrequency': fruitFrequency,
      'vegetableFrequency': vegetableFrequency,
      'homecookedMealsFrequency': homecookedMealsFrequency,
      'oneLiterWaterFrequency': oneLiterWaterFrequency,
      'redMeatFrequency': redMeatFrequency,
      'highFatRedMeat': highFatRedMeat,
      'saltedSnacksFrequency': saltedSnacksFrequency,
      'frozenDessertFrequency': frozenDessertFrequency,
      'milkCheeseFrequency': milkCheeseFrequency,
      'alcoholFrequency': alcoholFrequency,
    };
  }

  factory UserDietInput.fromJson(Map<String, dynamic> json) {
    return UserDietInput(
      dietType: json['dietType'] as String? ?? 'Omnivora',
      fruitFrequency: (json['fruitFrequency'] as num?)?.toInt() ?? 0,
      vegetableFrequency: (json['vegetableFrequency'] as num?)?.toInt() ?? 0,
      homecookedMealsFrequency:
          (json['homecookedMealsFrequency'] as num?)?.toInt() ?? 0,
      oneLiterWaterFrequency:
          (json['oneLiterWaterFrequency'] as num?)?.toInt() ?? 0,
      redMeatFrequency: (json['redMeatFrequency'] as num?)?.toInt() ?? 0,
      highFatRedMeat: json['highFatRedMeat'] as bool? ?? false,
      saltedSnacksFrequency:
          (json['saltedSnacksFrequency'] as num?)?.toInt() ?? 0,
      frozenDessertFrequency:
          (json['frozenDessertFrequency'] as num?)?.toInt() ?? 0,
      milkCheeseFrequency: (json['milkCheeseFrequency'] as num?)?.toInt() ?? 0,
      alcoholFrequency: (json['alcoholFrequency'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Model untuk faktor risiko yang paling berpengaruh
class FactorContribution {
  final String featureName;
  final String title;
  final String userValueDescription;
  final double contributionScore; // 0.0 - 1.0 untuk bar visualisasi
  final IconData icon;

  const FactorContribution({
    required this.featureName,
    required this.title,
    required this.userValueDescription,
    required this.contributionScore,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'featureName': featureName,
      'title': title,
      'userValueDescription': userValueDescription,
      'contributionScore': contributionScore,
      'iconCodePoint': icon.codePoint,
    };
  }

  /// Serialisasi khusus Firestore (tanpa IconData sesuai spesifikasi)
  Map<String, dynamic> toFirestore() {
    return {
      'featureName': featureName,
      'title': title,
      'userValueDescription': userValueDescription,
      'contributionScore': contributionScore,
    };
  }

  static IconData _iconForFeature(String featureName) {
    switch (featureName) {
      case 'alcohol':
        return Icons.local_bar_rounded;
      case 'high_fat_meat':
        return Icons.lunch_dining_rounded;
      case 'salted_snacks':
      case 'snack_habit':
        return Icons.cookie_outlined;
      case 'red_meat':
        return Icons.kebab_dining_rounded;
      case 'low_water':
      case 'water_habit':
        return Icons.water_drop_outlined;
      case 'frozen_dessert':
        return Icons.icecream_outlined;
      case 'milk_cheese':
        return Icons.local_drink_outlined;
      case 'low_veg':
      case 'fiber_habit':
        return Icons.eco_outlined;
      case 'low_fruit':
        return Icons.apple_outlined;
      case 'low_homecooked':
        return Icons.home_filled;
      default:
        return Icons.restaurant_rounded;
    }
  }

  factory FactorContribution.fromFirestore(Map<String, dynamic> data) {
    final featureName = data['featureName'] as String? ?? '';
    return FactorContribution(
      featureName: featureName,
      title: data['title'] as String? ?? '',
      userValueDescription: data['userValueDescription'] as String? ?? '',
      contributionScore:
          (data['contributionScore'] as num?)?.toDouble() ?? 0.0,
      icon: _iconForFeature(featureName),
    );
  }

  factory FactorContribution.fromJson(Map<String, dynamic> json) {
    final featureName = json['featureName'] as String? ?? '';
    return FactorContribution(
      featureName: featureName,
      title: json['title'] as String? ?? '',
      userValueDescription: json['userValueDescription'] as String? ?? '',
      contributionScore:
          (json['contributionScore'] as num?)?.toDouble() ?? 0.0,
      icon: _iconForFeature(featureName),
    );
  }
}

/// Model hasil prediksi risiko refluks asam lambung
class RefluxPredictionResult {
  final String id;
  final double riskPercentage; // 0 - 100
  final String riskCategory; // "Risiko Rendah", "Risiko Sedang", "Risiko Tinggi"
  final String categoryDescription;
  final List<FactorContribution> topFactors;
  final List<String> recommendations;
  final UserDietInput dietInput;
  final DateTime createdAt;

  const RefluxPredictionResult({
    this.id = '',
    required this.riskPercentage,
    required this.riskCategory,
    required this.categoryDescription,
    required this.topFactors,
    required this.recommendations,
    required this.dietInput,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id.isNotEmpty ? id : 'pred_${createdAt.millisecondsSinceEpoch}',
      'riskPercentage': riskPercentage,
      'riskCategory': riskCategory,
      'categoryDescription': categoryDescription,
      'topFactors': topFactors.map((f) => f.toJson()).toList(),
      'recommendations': recommendations,
      'dietInput': dietInput.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Serialisasi ke Cloud Firestore
  /// Menggunakan FieldValue.serverTimestamp() untuk createdAt
  Map<String, dynamic> toFirestore() {
    return {
      'id': id.isNotEmpty ? id : 'pred_${createdAt.millisecondsSinceEpoch}',
      'riskPercentage': riskPercentage,
      'riskCategory': riskCategory,
      'categoryDescription': categoryDescription,
      'topFactors': topFactors.map((f) => f.toFirestore()).toList(),
      'recommendations': recommendations,
      'dietInput': dietInput.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory RefluxPredictionResult.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return RefluxPredictionResult.fromMap(data, id: doc.id);
  }

  factory RefluxPredictionResult.fromMap(
    Map<String, dynamic> data, {
    String? id,
  }) {
    final createdAtRaw = data['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    final docId = id ??
        (data['id'] as String? ?? 'pred_${createdAt.millisecondsSinceEpoch}');

    return RefluxPredictionResult(
      id: docId.isNotEmpty ? docId : 'pred_${createdAt.millisecondsSinceEpoch}',
      riskPercentage: (data['riskPercentage'] as num?)?.toDouble() ?? 0.0,
      riskCategory: data['riskCategory'] as String? ?? 'Risiko Rendah',
      categoryDescription: data['categoryDescription'] as String? ?? '',
      topFactors: (data['topFactors'] as List<dynamic>?)
              ?.map((item) => FactorContribution.fromFirestore(
                  Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      recommendations: (data['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dietInput: data['dietInput'] != null
          ? UserDietInput.fromJson(
              Map<String, dynamic>.from(data['dietInput'] as Map))
          : const UserDietInput(),
      createdAt: createdAt,
    );
  }

  factory RefluxPredictionResult.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now();
    final id = json['id'] as String? ??
        'pred_${createdAt.millisecondsSinceEpoch}';

    return RefluxPredictionResult(
      id: id,
      riskPercentage: (json['riskPercentage'] as num?)?.toDouble() ?? 0.0,
      riskCategory: json['riskCategory'] as String? ?? 'Risiko Rendah',
      categoryDescription: json['categoryDescription'] as String? ?? '',
      topFactors: (json['topFactors'] as List<dynamic>?)
              ?.map((item) =>
                  FactorContribution.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dietInput: json['dietInput'] != null
          ? UserDietInput.fromJson(json['dietInput'] as Map<String, dynamic>)
          : const UserDietInput(),
      createdAt: createdAt,
    );
  }
}

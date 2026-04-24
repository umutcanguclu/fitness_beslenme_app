import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.amount,
    this.grams,
  });

  final String name;
  final String amount;
  final double? grams;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient(
        name: json['name'] as String,
        amount: json['amount'] as String,
        grams: (json['grams'] as num?)?.toDouble(),
      );
}

class RecipeNutrition {
  const RecipeNutrition({this.kcal, this.proteinG, this.carbsG, this.fatG});

  final int? kcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  factory RecipeNutrition.fromJson(Map<String, dynamic> json) => RecipeNutrition(
        kcal: (json['kcal'] as num?)?.round(),
        proteinG: (json['proteinG'] as num?)?.toDouble(),
        carbsG: (json['carbsG'] as num?)?.toDouble(),
        fatG: (json['fatG'] as num?)?.toDouble(),
      );
}

class Recipe {
  const Recipe({
    required this.id,
    required this.nameTr,
    required this.category,
    required this.servings,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    this.nameEn,
    this.tags = const [],
    this.nutrition,
    this.cuisine = 'turkish',
  });

  final String id;
  final String nameTr;
  final String? nameEn;
  final String category;
  final String cuisine;
  final int servings;
  final int prepMinutes;
  final int cookMinutes;
  final String difficulty;
  final List<String> tags;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final RecipeNutrition? nutrition;

  int get totalMinutes => prepMinutes + cookMinutes;

  String nameFor(String lang) =>
      (lang == 'tr' ? nameTr : (nameEn ?? nameTr));

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        nameTr: json['nameTr'] as String,
        nameEn: json['nameEn'] as String?,
        category: json['category'] as String,
        cuisine: (json['cuisine'] as String?) ?? 'turkish',
        servings: json['servings'] as int,
        prepMinutes: json['prepMinutes'] as int,
        cookMinutes: json['cookMinutes'] as int,
        difficulty: json['difficulty'] as String,
        tags: (json['tags'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        ingredients: (json['ingredients'] as List<dynamic>)
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        steps: (json['steps'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        nutrition: json['nutritionPerServing'] == null
            ? null
            : RecipeNutrition.fromJson(
                json['nutritionPerServing'] as Map<String, dynamic>),
      );
}

final recipeCatalogProvider = FutureProvider<List<Recipe>>((ref) async {
  final raw = await rootBundle.loadString('assets/recipes.json');
  final list = json.decode(raw) as List<dynamic>;
  return list
      .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
});

/// Known category keys with their localized display labels.
const Map<String, (String tr, String en)> recipeCategoryLabels = {
  'soup': ('Çorbalar', 'Soups'),
  'main_meat': ('Et Yemekleri', 'Meat Mains'),
  'main_veg': ('Sebze Yemekleri', 'Vegetable Mains'),
  'rice': ('Pilavlar', 'Rice & Bulgur'),
  'pasta': ('Makarnalar', 'Pasta'),
  'breakfast': ('Kahvaltı', 'Breakfast'),
  'pastry': ('Hamur İşi', 'Pastry'),
  'salad': ('Salatalar', 'Salads'),
  'dessert': ('Tatlılar', 'Desserts'),
  'drink': ('İçecekler', 'Drinks'),
  'meze': ('Mezeler', 'Meze'),
  'student': ('Öğrenci Pratik', 'Quick & Easy'),
};

String recipeCategoryLabel(String key, String lang) {
  final entry = recipeCategoryLabels[key];
  if (entry == null) return key;
  return lang == 'tr' ? entry.$1 : entry.$2;
}

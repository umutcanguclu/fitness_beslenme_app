class MealItem {
  const MealItem({
    required this.foodId,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String foodId;
  final int grams;
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
        foodId: json['foodId'] as String,
        grams: (json['grams'] as num).toInt(),
        kcal: (json['kcal'] as num).toInt(),
        proteinG: (json['proteinG'] as num).toDouble(),
        carbsG: (json['carbsG'] as num).toDouble(),
        fatG: (json['fatG'] as num).toDouble(),
      );
}

class Meal {
  const Meal({
    required this.key,
    required this.name,
    required this.targetKcal,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.items,
  });

  final String key;
  final String name;
  final int targetKcal;
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final List<MealItem> items;

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        key: json['key'] as String,
        name: json['name'] as String,
        targetKcal: (json['targetKcal'] as num).toInt(),
        kcal: (json['kcal'] as num).toInt(),
        proteinG: (json['proteinG'] as num).toDouble(),
        carbsG: (json['carbsG'] as num).toDouble(),
        fatG: (json['fatG'] as num).toDouble(),
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => MealItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class NutritionPlan {
  const NutritionPlan({
    required this.id,
    required this.name,
    required this.goal,
    required this.activityLevel,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.bmr,
    required this.tdee,
    required this.targetKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.meals,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String goal;
  final String activityLevel;
  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final int bmr;
  final int tdee;
  final int targetKcal;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final List<Meal> meals;
  final bool active;
  final DateTime createdAt;

  factory NutritionPlan.fromJson(Map<String, dynamic> json) => NutritionPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        goal: json['goal'] as String,
        activityLevel: json['activityLevel'] as String,
        gender: json['gender'] as String,
        age: (json['age'] as num).toInt(),
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        bmr: (json['bmr'] as num).toInt(),
        tdee: (json['tdee'] as num).toInt(),
        targetKcal: (json['targetKcal'] as num).toInt(),
        proteinG: (json['proteinG'] as num).toInt(),
        carbsG: (json['carbsG'] as num).toInt(),
        fatG: (json['fatG'] as num).toInt(),
        meals: (json['meals'] as List<dynamic>? ?? const [])
            .map((e) => Meal.fromJson(e as Map<String, dynamic>))
            .toList(),
        active: json['active'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class NutritionGenerateInput {
  const NutritionGenerateInput({
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
  });

  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String activityLevel;
  final String goal;

  Map<String, dynamic> toJson() => {
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel,
        'goal': goal,
      };
}

class FoodMeta {
  const FoodMeta({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.category,
  });

  final String id;
  final String nameTr;
  final String nameEn;
  final String category;

  factory FoodMeta.fromJson(Map<String, dynamic> json) => FoodMeta(
        id: json['id'] as String,
        nameTr: json['nameTr'] as String,
        nameEn: json['nameEn'] as String,
        category: json['category'] as String,
      );
}

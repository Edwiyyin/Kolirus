import 'dart:convert';

class Recipe {
  final String? id;
  final String name;
  final String? description;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final String? imageUrl;
  final bool isCommunityShared;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String category;

  // Nutritional info
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double saturatedFat;
  final double sodium;
  final double cholesterol;
  final double fiber;
  final double sugar;

  Recipe({
    this.id,
    required this.name,
    this.description,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
    this.isCommunityShared = false,
    this.prepTime = 0,
    this.cookTime = 0,
    this.servings = 1,
    this.category = 'Main',
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.saturatedFat = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.fiber = 0,
    this.sugar = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': jsonEncode(ingredients.map((e) => e.toMap()).toList()),
      'instructions': jsonEncode(instructions),
      'imageUrl': imageUrl,
      'isCommunityShared': isCommunityShared ? 1 : 0,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'saturatedFat': saturatedFat,
      'sodium': sodium,
      'cholesterol': cholesterol,
      'fiber': fiber,
      'sugar': sugar,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      ingredients: (jsonDecode(map['ingredients']) as List)
          .map((e) => RecipeIngredient.fromMap(e))
          .toList(),
      instructions: List<String>.from(jsonDecode(map['instructions'])),
      imageUrl: map['imageUrl'],
      isCommunityShared: map['isCommunityShared'] == 1,
      prepTime: map['prepTime'] ?? 0,
      cookTime: map['cookTime'] ?? 0,
      servings: map['servings'] ?? 1,
      category: map['category'] ?? 'Main',
      calories: map['calories']?.toDouble() ?? 0.0,
      protein: map['protein']?.toDouble() ?? 0.0,
      carbs: map['carbs']?.toDouble() ?? 0.0,
      fat: map['fat']?.toDouble() ?? 0.0,
      saturatedFat: map['saturatedFat']?.toDouble() ?? 0.0,
      sodium: map['sodium']?.toDouble() ?? 0.0,
      cholesterol: map['cholesterol']?.toDouble() ?? 0.0,
      fiber: map['fiber']?.toDouble() ?? 0.0,
      sugar: map['sugar']?.toDouble() ?? 0.0,
    );
  }
}

class RecipeIngredient {
  final String name;
  final String amount;
  final String unit;

  RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      name: map['name'],
      amount: map['amount'].toString(),
      unit: map['unit'],
    );
  }
}
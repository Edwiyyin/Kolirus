import 'dart:convert';
import 'food_item.dart';

class Recipe {
  final String? id;
  final String name;
  final String? description;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final String? imageUrl;
  final bool isCommunityShared;

  Recipe({
    this.id,
    required this.name,
    this.description,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
    this.isCommunityShared = false,
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
    );
  }
}

class RecipeIngredient {
  final String foodItemId;
  final String name;
  final double amount;
  final String unit;

  RecipeIngredient({
    required this.foodItemId,
    required this.name,
    required this.amount,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'foodItemId': foodItemId,
      'name': name,
      'amount': amount,
      'unit': unit,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      foodItemId: map['foodItemId'],
      name: map['name'],
      amount: map['amount'].toDouble(),
      unit: map['unit'],
    );
  }
}

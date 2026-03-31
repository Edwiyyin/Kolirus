import 'food_item.dart';

enum MealType { breakfast, lunch, dinner, snack }

class MealLog {
  final String? id;
  final String foodItemId;
  final String foodName;
  final double quantity; // in grams or units
  final DateTime consumedAt;
  final MealType type;
  
  // Macros at time of consumption (calculated based on quantity)
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double saturatedFat;
  final double sodium;
  final double cholesterol;
  final double fiber;
  final double sugar;

  MealLog({
    this.id,
    required this.foodItemId,
    required this.foodName,
    required this.quantity,
    required this.consumedAt,
    required this.type,
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
      'foodItemId': foodItemId,
      'foodName': foodName,
      'quantity': quantity,
      'consumedAt': consumedAt.toIso8601String(),
      'type': type.index,
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

  factory MealLog.fromMap(Map<String, dynamic> map) {
    return MealLog(
      id: map['id'],
      foodItemId: map['foodItemId'],
      foodName: map['foodName'],
      quantity: map['quantity']?.toDouble() ?? 0.0,
      consumedAt: DateTime.parse(map['consumedAt']),
      type: MealType.values[map['type'] ?? 0],
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

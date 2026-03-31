import 'dart:convert';

enum StorageLocation { fridge, shelf, freezer }

class FoodItem {
  final String? id;
  final String name;
  final String? barcode;
  final String? brand;
  final String? imageUrl;

  // Nutri-Score and Allergies
  final String? nutriScore;
  final List<String> allergens;

  // Storage and Expiry
  final StorageLocation location;
  final DateTime? expiryDate;
  final DateTime addedDate;

  // Nutritional Info (per 100g/unit)
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double saturatedFat;
  final double sodium;
  final double cholesterol;
  final double fiber;
  final double sugar;

  FoodItem({
    this.id,
    required this.name,
    this.barcode,
    this.brand,
    this.imageUrl,
    this.nutriScore,
    this.allergens = const [],
    this.location = StorageLocation.shelf,
    this.expiryDate,
    DateTime? addedDate,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.saturatedFat = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.fiber = 0,
    this.sugar = 0,
  }) : addedDate = addedDate ?? DateTime.now();

  // For Database/API conversions
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'brand': brand,
      'imageUrl': imageUrl,
      'nutriScore': nutriScore,
      'allergens': jsonEncode(allergens),
      'location': location.index,
      'expiryDate': expiryDate?.toIso8601String(),
      'addedDate': addedDate.toIso8601String(),
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

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      brand: map['brand'],
      imageUrl: map['imageUrl'],
      nutriScore: map['nutriScore'],
      allergens: List<String>.from(jsonDecode(map['allergens'] ?? '[]')),
      location: StorageLocation.values[map['location'] ?? 1],
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
      addedDate: DateTime.parse(map['addedDate']),
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

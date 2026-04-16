import 'dart:convert';

enum StorageLocation { fridge, shelf, freezer }

class FoodItem {
  final String? id;
  final String name;
  final String? barcode;
  final String? brand;
  final String? imageUrl;

  final String? nutriScore;
  final List<String> allergens;
  final String? ingredientsText;

  final StorageLocation location;
  final DateTime? expiryDate;
  final DateTime addedDate;

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double saturatedFat;
  final double sodium;
  final double cholesterol;
  final double fiber;
  final double sugar;
  
  // New nutrients
  final double potassium;
  final double magnesium;
  final double vitaminC;
  final double vitaminD;
  final double calcium;
  final double iron;
  
  // Price tracking
  final double? price;

  FoodItem({
    this.id,
    required this.name,
    this.barcode,
    this.brand,
    this.imageUrl,
    this.nutriScore,
    this.allergens = const [],
    this.ingredientsText,
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
    this.potassium = 0,
    this.magnesium = 0,
    this.vitaminC = 0,
    this.vitaminD = 0,
    this.calcium = 0,
    this.iron = 0,
    this.price,
  }) : addedDate = addedDate ?? DateTime.now();

  FoodItem copyWith({
    String? id,
    String? name,
    String? barcode,
    String? brand,
    String? imageUrl,
    String? nutriScore,
    List<String>? allergens,
    String? ingredientsText,
    StorageLocation? location,
    DateTime? expiryDate,
    DateTime? addedDate,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? saturatedFat,
    double? sodium,
    double? cholesterol,
    double? fiber,
    double? sugar,
    double? potassium,
    double? magnesium,
    double? vitaminC,
    double? vitaminD,
    double? calcium,
    double? iron,
    double? price,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      nutriScore: nutriScore ?? this.nutriScore,
      allergens: allergens ?? this.allergens,
      ingredientsText: ingredientsText ?? this.ingredientsText,
      location: location ?? this.location,
      expiryDate: expiryDate ?? this.expiryDate,
      addedDate: addedDate ?? this.addedDate,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      saturatedFat: saturatedFat ?? this.saturatedFat,
      sodium: sodium ?? this.sodium,
      cholesterol: cholesterol ?? this.cholesterol,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      potassium: potassium ?? this.potassium,
      magnesium: magnesium ?? this.magnesium,
      vitaminC: vitaminC ?? this.vitaminC,
      vitaminD: vitaminD ?? this.vitaminD,
      calcium: calcium ?? this.calcium,
      iron: iron ?? this.iron,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'brand': brand,
      'imageUrl': imageUrl,
      'nutriScore': nutriScore,
      'allergens': jsonEncode(allergens),
      'ingredientsText': ingredientsText,
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
      'potassium': potassium,
      'magnesium': magnesium,
      'vitaminC': vitaminC,
      'vitaminD': vitaminD,
      'calcium': calcium,
      'iron': iron,
      'price': price,
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
      ingredientsText: map['ingredientsText'],
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
      potassium: map['potassium']?.toDouble() ?? 0.0,
      magnesium: map['magnesium']?.toDouble() ?? 0.0,
      vitaminC: map['vitaminC']?.toDouble() ?? 0.0,
      vitaminD: map['vitaminD']?.toDouble() ?? 0.0,
      calcium: map['calcium']?.toDouble() ?? 0.0,
      iron: map['iron']?.toDouble() ?? 0.0,
      price: map['price']?.toDouble(),
    );
  }
}

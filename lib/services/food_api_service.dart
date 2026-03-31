import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class FoodApiService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product/';

  Future<FoodItem?> fetchProduct(String barcode) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$barcode.json'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          final nutriments = product['nutriments'] ?? {};

          return FoodItem(
            name: product['product_name'] ?? 'Unknown Product',
            barcode: barcode,
            brand: product['brands'],
            imageUrl: product['image_url'],
            nutriScore: product['nutriscore_grade']?.toString().toUpperCase(),
            allergens: _parseAllergens(product['allergens_tags']),
            calories: _toDouble(nutriments['energy-kcal_100g']),
            protein: _toDouble(nutriments['proteins_100g']),
            carbs: _toDouble(nutriments['carbohydrates_100g']),
            fat: _toDouble(nutriments['fat_100g']),
            saturatedFat: _toDouble(nutriments['saturated-fat_100g']),
            sodium: _toDouble(nutriments['sodium_100g']),
            cholesterol: _toDouble(nutriments['cholesterol_100g']),
            fiber: _toDouble(nutriments['fiber_100g']),
            sugar: _toDouble(nutriments['sugars_100g']),
          );
        }
      }
    } catch (e) {
      print('Error fetching product: $e');
    }
    return null;
  }

  List<String> _parseAllergens(dynamic tags) {
    if (tags == null || tags is! List) return [];
    return tags.map((e) => e.toString().replaceAll('en:', '')).toList();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

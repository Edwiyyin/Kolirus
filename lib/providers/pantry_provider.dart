import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

final pantryProvider = StateNotifierProvider<PantryNotifier, List<FoodItem>>((ref) {
  return PantryNotifier();
});

class PantryNotifier extends StateNotifier<List<FoodItem>> {
  PantryNotifier() : super([]) {
    loadItems();
  }

  final _db = DatabaseService.instance;
  final _notifications = NotificationService();

  Future<void> loadItems() async {
    state = await _db.getPantryItems();
  }

  Future<void> addItem(FoodItem item) async {
    await _db.insertFoodItem(item);
    if (item.expiryDate != null) {
      await _notifications.scheduleExpiryReminder(
        item.id ?? item.barcode ?? item.name,
        item.name,
        item.expiryDate!,
      );
    }
    await loadItems();
  }

  Future<void> removeItem(String id) async {
    await _db.deleteFoodItem(id);
    await loadItems();
  }
  
  List<FoodItem> getSuggestedForRecipe(List<String> ingredientNames) {
    return state.where((item) {
      return ingredientNames.any((name) => 
        item.name.toLowerCase().contains(name.toLowerCase()));
    }).toList();
  }
}

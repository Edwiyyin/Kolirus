import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

final pantryProvider =
StateNotifierProvider<PantryNotifier, List<FoodItem>>((ref) {
  return PantryNotifier();
});

class PantryNotifier extends StateNotifier<List<FoodItem>> {
  PantryNotifier() : super([]) {
    loadItems();
  }

  final _db            = DatabaseService.instance;
  final _notifications = NotificationService();

  Future<void> loadItems() async {
    state = await _db.getPantryItems();
  }

  Future<void> addItem(FoodItem item) async {
    await _db.insertFoodItem(item);

    if (item.expiryDate != null) {
      final notifId = item.id ?? item.barcode ?? item.name;
      await _notifications.scheduleExpiryReminder(
        notifId,
        item.name,
        item.expiryDate!,
      );
    }

    await loadItems();
  }

  Future<void> updateItem(FoodItem item) async {
    final notifId = item.id ?? item.barcode ?? item.name;
    await _notifications.cancelExpiryReminders(notifId);
    await _db.insertFoodItem(item);
    if (item.expiryDate != null) {
      await _notifications.scheduleExpiryReminder(
        notifId,
        item.name,
        item.expiryDate!,
      );
    }
    await loadItems();
  }

  Future<void> removeItem(String id) async {
    // Cancel notifications
    await _notifications.cancelExpiryReminders(id);

    // Try delete by primary id first
    await _db.deleteFoodItem(id);

    // If item still exists (id was actually name/barcode fallback),
    // try to find and delete by name
    final remaining = await _db.getPantryItems();
    final stillExists = remaining.any((i) => i.id == id || i.barcode == id || i.name == id);
    if (stillExists) {
      // Delete by name as last resort
      final toDelete = remaining.where((i) => i.id == id || i.barcode == id || i.name == id).toList();
      for (final item in toDelete) {
        if (item.id != null) {
          await _db.deleteFoodItem(item.id!);
        }
      }
    }

    await loadItems();
  }

  List<FoodItem> getSuggestedForRecipe(List<String> ingredientNames) {
    return state.where((item) {
      return ingredientNames.any((name) =>
          item.name.toLowerCase().contains(name.toLowerCase()));
    }).toList();
  }

  /// Filter pantry items by dietary and religious preferences
  List<FoodItem> getFilteredItems(List<String> dietaryPrefs, List<String> religiousPrefs) {
    if (dietaryPrefs.isEmpty && religiousPrefs.isEmpty) return state;
    return state.where((item) => _itemMatchesPrefs(item, dietaryPrefs, religiousPrefs)).toList();
  }

  bool _itemMatchesPrefs(FoodItem item, List<String> dietary, List<String> religious) {
    final searchText = [
      item.name,
      item.brand ?? '',
      item.ingredientsText ?? '',
      ...item.allergens,
    ].join(' ').toLowerCase();

    // Check dietary restrictions
    for (final pref in dietary) {
      if (pref == 'vegan' || pref == 'vegetarian') {
        final meatKeywords = ['meat', 'beef', 'pork', 'chicken', 'fish', 'seafood'];
        if (meatKeywords.any((k) => searchText.contains(k))) return false;
      }
      if (pref == 'vegan') {
        final animalKeywords = ['milk', 'egg', 'dairy', 'cheese', 'butter', 'honey'];
        if (animalKeywords.any((k) => searchText.contains(k))) return false;
      }
    }

    // Check religious restrictions
    for (final pref in religious) {
      if (pref == 'halal') {
        final haramKeywords = ['pork', 'alcohol', 'wine', 'beer', 'lard'];
        if (haramKeywords.any((k) => searchText.contains(k))) return false;
      }
      if (pref == 'kosher') {
        final nonKosherKeywords = ['pork', 'shellfish', 'shrimp', 'lobster'];
        if (nonKosherKeywords.any((k) => searchText.contains(k))) return false;
      }
    }

    return true;
  }
}
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

    // Schedule both the 5-day and 1-day expiry reminders (if expiry set).
    if (item.expiryDate != null) {
      await _notifications.scheduleExpiryReminder(
        item.id ?? item.barcode ?? item.name,
        item.name,
        item.expiryDate!,
      );
    }

    await loadItems();
  }

  Future<void> updateItem(FoodItem item) async {
    final notifId = item.id ?? item.barcode ?? item.name;

    // Cancel old reminders before (re-)scheduling so we never double-fire.
    await _notifications.cancelExpiryReminders(notifId);

    await _db.insertFoodItem(item); // ConflictAlgorithm.replace

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
    // Cancel any pending reminders for this item.
    await _notifications.cancelExpiryReminders(id);
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
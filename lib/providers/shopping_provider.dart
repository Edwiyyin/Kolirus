import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

final shoppingProvider = StateNotifierProvider<ShoppingNotifier, List<Map<String, dynamic>>>((ref) {
  return ShoppingNotifier();
});

class ShoppingNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  ShoppingNotifier() : super([]) {
    loadItems();
  }

  final _db = DatabaseService.instance;

  Future<void> loadItems() async {
    final items = await _db.getShoppingList();
    state = items;
  }

  Future<void> addItem(String name, {String category = 'General'}) async {
    final item = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'isCompleted': 0,
      'category': category,
    };
    await _db.insertShoppingItem(item);
    await loadItems();
  }

  Future<void> toggleItem(String id, bool isCompleted) async {
    final item = state.firstWhere((element) => element['id'] == id);
    final updated = Map<String, dynamic>.from(item);
    updated['isCompleted'] = isCompleted ? 1 : 0;
    await _db.insertShoppingItem(updated);
    await loadItems();
  }

  Future<void> removeItem(String id) async {
    await _db.deleteShoppingItem(id);
    await loadItems();
  }
}

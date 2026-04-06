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
    final res = await _db.query('shopping_list');
    state = res;
  }

  Future<void> addItem(String name, {required String listId, String? category}) async {
    final item = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'isCompleted': 0,
      'category': category ?? 'General',
      'quantity': 1.0,
      'listId': listId,
    };
    await _db.insert('shopping_list', item);
    await loadItems();
  }

  Future<void> updateItem(Map<String, dynamic> item) async {
    await _db.insert('shopping_list', item);
    await loadItems();
  }

  Future<void> toggleItem(String id, bool isCompleted) async {
    final item = state.firstWhere((element) => element['id'] == id);
    final updated = Map<String, dynamic>.from(item);
    updated['isCompleted'] = isCompleted ? 1 : 0;
    await _db.insert('shopping_list', updated);
    await loadItems();
  }

  Future<void> removeItem(String id) async {
    await _db.delete('shopping_list', where: 'id = ?', whereArgs: [id]);
    await loadItems();
  }

  Future<void> removeItemsByGroup(String listId) async {
    await _db.delete('shopping_list', where: 'listId = ?', whereArgs: [listId]);
    await loadItems();
  }
}

final shoppingGroupsProvider = StateNotifierProvider<ShoppingGroupsNotifier, List<Map<String, dynamic>>>((ref) {
  return ShoppingGroupsNotifier(ref);
});

class ShoppingGroupsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref _ref;
  ShoppingGroupsNotifier(this._ref) : super([]) {
    loadGroups();
  }
  final _db = DatabaseService.instance;

  Future<void> loadGroups() async {
    final res = await _db.query('shopping_groups');
    if (res.isEmpty) {
      await addGroup('Default List');
    } else {
      state = res;
    }
  }

  Future<void> addGroup(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _db.insert('shopping_groups', {'id': id, 'name': name});
    await loadGroups();
  }

  Future<void> updateGroup(String id, String name) async {
    await _db.insert('shopping_groups', {'id': id, 'name': name}); // replace
    await loadGroups();
  }

  Future<void> removeGroup(String id) async {
    await _db.delete('shopping_groups', where: 'id = ?', whereArgs: [id]);
    await _ref.read(shoppingProvider.notifier).removeItemsByGroup(id);
    await loadGroups();
  }
}

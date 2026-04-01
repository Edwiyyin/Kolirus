import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';

final scanHistoryProvider = StateNotifierProvider<ScanHistoryNotifier, List<FoodItem>>((ref) {
  return ScanHistoryNotifier();
});

class ScanHistoryNotifier extends StateNotifier<List<FoodItem>> {
  ScanHistoryNotifier() : super([]) {
    loadHistory();
  }

  final _db = DatabaseService.instance;

  Future<void> loadHistory() async {
    final history = await _db.getScanHistory();
    state = history;
  }

  Future<void> addToHistory(FoodItem item) async {
    await _db.insertScanHistory(item);
    await loadHistory();
  }
}

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  SettingsNotifier() : super({'allergies': <String>[]}) {
    _loadSettings();
  }

  final _db = DatabaseService.instance;

  Future<void> _loadSettings() async {
    final allergiesStr = await _db.getSetting('allergies');
    if (allergiesStr != null) {
      state = {...state, 'allergies': List<String>.from(jsonDecode(allergiesStr))};
    }
  }

  Future<void> updateAllergies(List<String> allergies) async {
    state = {...state, 'allergies': allergies};
    await _db.saveSetting('allergies', jsonEncode(allergies));
  }
}

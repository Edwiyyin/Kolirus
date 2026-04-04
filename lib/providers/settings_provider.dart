import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  SettingsNotifier() : super({
    'allergies': <String>[],
    'name': 'User',
    'dietary_prefs': <String>[],
    'religious_prefs': <String>[],
  }) {
    _loadSettings();
  }

  final _db = DatabaseService.instance;

  Future<void> _loadSettings() async {
    final allergiesStr = await _db.getSetting('allergies');
    final name = await _db.getSetting('name');
    final dietaryStr = await _db.getSetting('dietary_prefs');
    final religiousStr = await _db.getSetting('religious_prefs');

    Map<String, dynamic> newState = {...state};
    if (allergiesStr != null) newState['allergies'] = List<String>.from(jsonDecode(allergiesStr));
    if (name != null) newState['name'] = name;
    if (dietaryStr != null) newState['dietary_prefs'] = List<String>.from(jsonDecode(dietaryStr));
    if (religiousStr != null) newState['religious_prefs'] = List<String>.from(jsonDecode(religiousStr));
    
    state = newState;
  }

  Future<void> updateAllergies(List<String> allergies) async {
    state = {...state, 'allergies': allergies};
    await _db.saveSetting('allergies', jsonEncode(allergies));
  }

  Future<void> updateName(String name) async {
    state = {...state, 'name': name};
    await _db.saveSetting('name', name);
  }

  Future<void> updateDietaryPrefs(List<String> prefs) async {
    state = {...state, 'dietary_prefs': prefs};
    await _db.saveSetting('dietary_prefs', jsonEncode(prefs));
  }

  Future<void> updateReligiousPrefs(List<String> prefs) async {
    state = {...state, 'religious_prefs': prefs};
    await _db.saveSetting('religious_prefs', jsonEncode(prefs));
  }
}

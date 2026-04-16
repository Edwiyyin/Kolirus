import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

final settingsProvider =
StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  SettingsNotifier()
      : super({
    'allergies': <String>[],
    'name': 'User',
    'dietary_prefs': <String>[],
    'religious_prefs': <String>[],
    'quality_filters': <String>[],
    'calorie_goal': 2000.0,
    'protein_goal': 150.0,
    'carbs_goal': 250.0,
    'fat_goal': 70.0,
    'fiber_goal': 30.0,
    'water_goal': 2000.0,
    'profile_pic': null,
  }) {
    _loadSettings();
  }

  final _db = DatabaseService.instance;

  Future<void> _loadSettings() async {
    final allergiesStr    = await _db.getSetting('allergies');
    final name            = await _db.getSetting('name');
    final dietaryStr      = await _db.getSetting('dietary_prefs');
    final religiousStr    = await _db.getSetting('religious_prefs');
    final qualityStr      = await _db.getSetting('quality_filters');
    final goalStr         = await _db.getSetting('calorie_goal');
    final proteinGoalStr  = await _db.getSetting('protein_goal');
    final carbsGoalStr    = await _db.getSetting('carbs_goal');
    final fatGoalStr      = await _db.getSetting('fat_goal');
    final fiberGoalStr    = await _db.getSetting('fiber_goal');
    final waterGoalStr    = await _db.getSetting('water_goal');
    final profilePic      = await _db.getSetting('profile_pic');

    Map<String, dynamic> newState = {...state};
    if (allergiesStr != null)
      newState['allergies'] = List<String>.from(jsonDecode(allergiesStr));
    if (name != null) newState['name'] = name;
    if (dietaryStr != null)
      newState['dietary_prefs'] = List<String>.from(jsonDecode(dietaryStr));
    if (religiousStr != null)
      newState['religious_prefs'] = List<String>.from(jsonDecode(religiousStr));
    if (qualityStr != null)
      newState['quality_filters'] = List<String>.from(jsonDecode(qualityStr));
    if (goalStr != null)
      newState['calorie_goal'] = double.tryParse(goalStr) ?? 2000.0;
    if (proteinGoalStr != null)
      newState['protein_goal'] = double.tryParse(proteinGoalStr) ?? 150.0;
    if (carbsGoalStr != null)
      newState['carbs_goal'] = double.tryParse(carbsGoalStr) ?? 250.0;
    if (fatGoalStr != null)
      newState['fat_goal'] = double.tryParse(fatGoalStr) ?? 70.0;
    if (fiberGoalStr != null)
      newState['fiber_goal'] = double.tryParse(fiberGoalStr) ?? 30.0;
    if (waterGoalStr != null)
      newState['water_goal'] = double.tryParse(waterGoalStr) ?? 2000.0;
    if (profilePic != null) newState['profile_pic'] = profilePic;

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

  Future<void> updateQualityFilters(List<String> filters) async {
    state = {...state, 'quality_filters': filters};
    await _db.saveSetting('quality_filters', jsonEncode(filters));
  }

  Future<void> updateCalorieGoal(double goal) async {
    state = {...state, 'calorie_goal': goal};
    await _db.saveSetting('calorie_goal', goal.toString());
  }

  Future<void> updateNutrientGoal(String key, double goal) async {
    state = {...state, key: goal};
    await _db.saveSetting(key, goal.toString());
  }

  Future<void> updateProfilePic(String path) async {
    state = {...state, 'profile_pic': path};
    await _db.saveSetting('profile_pic', path);
  }
}
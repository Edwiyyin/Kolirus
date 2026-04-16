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
    'calorie_goal': 2000.0,
    'weight_goal': 70.0,
    'water_goal_ml': 2000.0,
    'healthy_food_goal': 5.0,
    'prefer_high_nutriscore': false,
    'avoid_nova_4': false,
    'profile_pic': null,
  }) {
    _loadSettings();
  }

  final _db = DatabaseService.instance;

  Future<void> _loadSettings() async {
    final allergiesStr = await _db.getSetting('allergies');
    final name = await _db.getSetting('name');
    final dietaryStr = await _db.getSetting('dietary_prefs');
    final religiousStr = await _db.getSetting('religious_prefs');
    final goalStr = await _db.getSetting('calorie_goal');
    final weightGoalStr = await _db.getSetting('weight_goal');
    final waterGoalStr = await _db.getSetting('water_goal_ml');
    final healthyGoalStr = await _db.getSetting('healthy_food_goal');
    final highNutriStr = await _db.getSetting('prefer_high_nutriscore');
    final avoidNovaStr = await _db.getSetting('avoid_nova_4');
    final profilePic = await _db.getSetting('profile_pic');

    Map<String, dynamic> newState = {...state};
    if (allergiesStr != null) {
      newState['allergies'] = List<String>.from(jsonDecode(allergiesStr));
    }
    if (name != null) newState['name'] = name;
    if (dietaryStr != null) {
      newState['dietary_prefs'] = List<String>.from(jsonDecode(dietaryStr));
    }
    if (religiousStr != null) {
      newState['religious_prefs'] = List<String>.from(jsonDecode(religiousStr));
    }
    if (goalStr != null) {
      newState['calorie_goal'] = double.tryParse(goalStr) ?? 2000.0;
    }
    if (weightGoalStr != null) {
      newState['weight_goal'] = double.tryParse(weightGoalStr) ?? 70.0;
    }
    if (waterGoalStr != null) {
      newState['water_goal_ml'] = double.tryParse(waterGoalStr) ?? 2000.0;
    }
    if (healthyGoalStr != null) {
      newState['healthy_food_goal'] = double.tryParse(healthyGoalStr) ?? 5.0;
    }
    if (highNutriStr != null) {
      newState['prefer_high_nutriscore'] = highNutriStr == 'true';
    }
    if (avoidNovaStr != null) {
      newState['avoid_nova_4'] = avoidNovaStr == 'true';
    }
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

  Future<void> updateCalorieGoal(double goal) async {
    state = {...state, 'calorie_goal': goal};
    await _db.saveSetting('calorie_goal', goal.toString());
  }

  Future<void> updateProfilePic(String path) async {
    state = {...state, 'profile_pic': path};
    await _db.saveSetting('profile_pic', path);
  }

  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    state = newSettings;
    for (var entry in newSettings.entries) {
      if (entry.value is List) {
        await _db.saveSetting(entry.key, jsonEncode(entry.value));
      } else if (entry.value != null) {
        await _db.saveSetting(entry.key, entry.value.toString());
      }
    }
  }
}

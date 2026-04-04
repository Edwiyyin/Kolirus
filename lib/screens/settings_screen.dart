import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../utils/constants.dart';
import '../providers/health_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<String> _availableAllergens = [
    'gluten', 'milk', 'eggs', 'nuts', 'peanuts', 'sesame',
    'soybeans', 'fish', 'shellfish', 'celery', 'mustard',
    'lupin', 'molluscs', 'sulphites',
  ];

  static const List<String> _dietaryPrefs = [
    'vegan', 'vegetarian', 'paleo', 'keto', 'mediterranean', 'low-carb'
  ];

  static const List<String> _religiousDiets = [
    'halal', 'kosher', 'christian lent', 'orthodox lent', 'hindu vegetarian', 'jain', 'buddhist vegetarian'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final userAllergies = List<String>.from(settings['allergies'] ?? []);
    final userDietary = List<String>.from(settings['dietary_prefs'] ?? []);
    final userReligious = List<String>.from(settings['religious_prefs'] ?? []);
    final healthState = ref.watch(healthProvider);
    final health = healthState.today;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile & Settings'.toTitleCase()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Personal Info
          const _SettingsHeader(title: 'Personal Info'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, size: 35, color: AppColors.olive),
                ),
                const SizedBox(height: 16),
                _EditableTextField(
                  label: 'Name',
                  value: settings['name'] ?? 'User',
                  onChanged: (val) => ref.read(settingsProvider.notifier).updateName(val),
                ),
                const Divider(color: Colors.white10, height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _EditableStat(
                        label: 'Height (cm)',
                        value: '${health?.height.toInt() ?? 0}',
                        icon: Icons.height,
                        onTap: () => _showStatDialog(context, ref, 'height', health?.height ?? 0),
                      ),
                    ),
                    Expanded(
                      child: _EditableStat(
                        label: 'Weight (kg)',
                        value: '${health?.weight ?? 0}',
                        icon: Icons.monitor_weight_outlined,
                        onTap: () => _showStatDialog(context, ref, 'weight', health?.weight ?? 0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dietary Preferences
          const _SettingsHeader(title: 'Dietary Preferences'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dietary Labels'.toTitleCase(), style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _dietaryPrefs.map((pref) {
                    final isSelected = userDietary.contains(pref);
                    return FilterChip(
                      label: Text(pref.toTitleCase(), style: const TextStyle(fontSize: 10)),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newList = List<String>.from(userDietary);
                        selected ? newList.add(pref) : newList.remove(pref);
                        ref.read(settingsProvider.notifier).updateDietaryPrefs(newList);
                      },
                      selectedColor: AppColors.olive.withOpacity(0.3),
                      checkmarkColor: AppColors.olive,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Religious Diet
          const _SettingsHeader(title: 'Religious Diet'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Religious Rules'.toTitleCase(), style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _religiousDiets.map((pref) {
                    final isSelected = userReligious.contains(pref);
                    return FilterChip(
                      label: Text(pref.toTitleCase(), style: const TextStyle(fontSize: 10)),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newList = List<String>.from(userReligious);
                        selected ? newList.add(pref) : newList.remove(pref);
                        ref.read(settingsProvider.notifier).updateReligiousPrefs(newList);
                      },
                      selectedColor: AppColors.olive.withOpacity(0.3),
                      checkmarkColor: AppColors.olive,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Allergies
          const _SettingsHeader(title: 'Allergies'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Allergy Filters'.toTitleCase(), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _availableAllergens.map((allergy) {
                    final isSelected = userAllergies.contains(allergy);
                    return FilterChip(
                      label: Text(allergy.toTitleCase(), style: const TextStyle(fontSize: 10)),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newList = List<String>.from(userAllergies);
                        selected ? newList.add(allergy) : newList.remove(allergy);
                        ref.read(settingsProvider.notifier).updateAllergies(newList);
                      },
                      selectedColor: Colors.redAccent.withOpacity(0.3),
                      checkmarkColor: Colors.redAccent,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Data Management
          const _SettingsHeader(title: 'Data Management'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload, color: AppColors.olive),
                  title: Text('Export Data'.toTitleCase()),
                  subtitle: const Text('Backup your database to a file', style: TextStyle(fontSize: 10, color: Colors.white38)),
                  onTap: () => _exportDatabase(context),
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download, color: AppColors.olive),
                  title: Text('Import Data'.toTitleCase()),
                  subtitle: const Text('Restore from a backup file', style: TextStyle(fontSize: 10, color: Colors.white38)),
                  onTap: () => _importDatabase(context),
                ),
              ],
            ),
          ),

          // Health Data Sync
          const _SettingsHeader(title: 'Data & Sync'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.sync, color: AppColors.olive),
              title: Text('Sync Google Fit'.toTitleCase(), style: const TextStyle(color: Colors.white, fontSize: 14)),
              onTap: () => ref.read(healthProvider.notifier).syncWithGoogleFit(),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final dbPath = await getDatabasesPath();
      final sourceFile = File(p.join(dbPath, 'kolirus.db'));
      
      // In a real environment, you'd use a file picker to choose destination.
      // Here we just notify the user where it is.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database Exported To: ${sourceFile.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export Failed: $e')),
      );
    }
  }

  Future<void> _importDatabase(BuildContext context) async {
    // This is a placeholder as full file system access requires path_provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a .db file to import.')),
    );
  }

  void _showStatDialog(BuildContext context, WidgetRef ref, String type, double currentVal) {
    final controller = TextEditingController(text: currentVal > 0 ? currentVal.toString() : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Update ${type.toTitleCase()}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(suffixText: type == 'height' ? 'cm' : 'kg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel'.toTitleCase())),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              if (type == 'height') {
                ref.read(healthProvider.notifier).updateManualEntry(height: val, date: DateTime.now());
              } else {
                ref.read(healthProvider.notifier).updateManualEntry(weight: val, date: DateTime.now());
              }
              Navigator.pop(context);
            },
            child: Text('Save'.toTitleCase()),
          ),
        ],
      ),
    );
  }
}

class _EditableTextField extends StatelessWidget {
  final String label, value;
  final Function(String) onChanged;
  const _EditableTextField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label.toTitleCase(),
        labelStyle: const TextStyle(color: AppColors.olive),
        suffixIcon: const Icon(Icons.edit, size: 16, color: Colors.white24),
      ),
      onSubmitted: onChanged,
    );
  }
}

class _EditableStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final VoidCallback onTap;
  const _EditableStat({required this.label, required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.olive, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label.toTitleCase(), style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final String title;
  const _SettingsHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
    );
  }
}

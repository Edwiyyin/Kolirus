import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../utils/diet_constants.dart';
import '../providers/health_provider.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final userAllergies = List<String>.from(settings['allergies'] ?? []);
    final userDietary = List<String>.from(settings['dietary_prefs'] ?? []);
    final userReligious = List<String>.from(settings['religious_prefs'] ?? []);
    final healthState = ref.watch(healthProvider);
    final health = healthState.today;
    final profilePicPath = settings['profile_pic'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SettingsHeader(title: 'Account'),
          const AccountCard(),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _ProfileAvatar(imagePath: profilePicPath, onTap: () => _pickProfilePic(context, ref)),
                const SizedBox(height: 16),
                _EditableTextField(
                  label: 'Name',
                  value: settings['name'] ?? 'User',
                  onChanged: (val) => ref.read(settingsProvider.notifier).updateName(val),
                ),
              ],
            ),
          ),

          const _SettingsHeader(title: 'Quality Preferences (OFF Style)'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _qualitySwitch(ref, settings, 'palm_oil_free', 'Palm Oil Free', 'Warn if products contain palm oil'),
                _qualitySwitch(ref, settings, 'sugar_free', 'Sugar Free', 'Warn if products have added sugar'),
                _qualitySwitch(ref, settings, 'avoid_highly_processed', 'Avoid Ultra-Processed', 'Flag NOVA 4 processed items'),
                _qualitySwitch(ref, settings, 'low_salt', 'Low Salt', 'Warn about high sodium content'),
              ],
            ),
          ),

          const _SettingsHeader(title: 'Dietary Preferences'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: allDietaryPrefs.map((pref) {
                    final sel = userDietary.contains(pref);
                    return FilterChip(
                      label: Text(pref.toTitleCase(), style: TextStyle(fontSize: 12, color: sel ? Colors.black : Colors.white70)),
                      selected: sel,
                      onSelected: (v) {
                        final list = List<String>.from(userDietary);
                        v ? list.add(pref) : list.remove(pref);
                        ref.read(settingsProvider.notifier).updateDietaryPrefs(list);
                      },
                      selectedColor: AppColors.olive,
                      backgroundColor: AppColors.background,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const _SettingsHeader(title: 'Religious Diet'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Wrap(
              spacing: 6, runSpacing: 6,
              children: allReligiousDiets.map((pref) {
                final sel = userReligious.contains(pref);
                return FilterChip(
                  label: Text(pref.toTitleCase(), style: TextStyle(fontSize: 12, color: sel ? Colors.black : Colors.white70)),
                  selected: sel,
                  onSelected: (v) {
                    final list = List<String>.from(userReligious);
                    v ? list.add(pref) : list.remove(pref);
                    ref.read(settingsProvider.notifier).updateReligiousPrefs(list);
                  },
                  selectedColor: AppColors.olive,
                  backgroundColor: AppColors.background,
                );
              }).toList(),
            ),
          ),

          const _SettingsHeader(title: 'Allergies'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Wrap(
              spacing: 6, runSpacing: 6,
              children: allAllergens.map((a) {
                final sel = userAllergies.contains(a);
                return FilterChip(
                  label: Text(a.toTitleCase(), style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.white70)),
                  selected: sel,
                  onSelected: (v) {
                    final list = List<String>.from(userAllergies);
                    v ? list.add(a) : list.remove(a);
                    ref.read(settingsProvider.notifier).updateAllergies(list);
                  },
                  selectedColor: Colors.redAccent.withOpacity(0.7),
                  backgroundColor: AppColors.background,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _qualitySwitch(WidgetRef ref, Map<String, dynamic> settings, String key, String label, String sub) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.white38)),
      value: settings[key] ?? false,
      onChanged: (val) {
        final newSettings = Map<String, dynamic>.from(settings);
        newSettings[key] = val;
        ref.read(settingsProvider.notifier).updateSettings(newSettings);
      },
      activeColor: AppColors.olive,
    );
  }

  Future<void> _pickProfilePic(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) ref.read(settingsProvider.notifier).updateProfilePic(img.path);
  }

  void _showStatDialog(BuildContext context, WidgetRef ref, String type, double currentVal) {
    final ctrl = TextEditingController(text: currentVal > 0 ? currentVal.toString() : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Update ${type.toTitleCase()}'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text) ?? 0;
              if (type == 'height') {
                ref.read(healthProvider.notifier).updateManualEntry(height: val);
              } else {
                ref.read(healthProvider.notifier).updateManualEntry(weight: val);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final String title;
  const _SettingsHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
    child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
  );
}

class _ProfileAvatar extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  const _ProfileAvatar({this.imagePath, required this.onTap});
  @override
  Widget build(BuildContext context) {
    ImageProvider? img;
    if (imagePath != null) img = FileImage(File(imagePath!));
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 45,
        backgroundColor: AppColors.primary,
        backgroundImage: img,
        child: img == null ? const Icon(Icons.person, size: 45, color: AppColors.olive) : null,
      ),
    );
  }
}

class _EditableTextField extends StatelessWidget {
  final String label, value;
  final Function(String) onChanged;
  const _EditableTextField({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => TextField(
    controller: TextEditingController(text: value),
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: AppColors.olive)),
    onSubmitted: onChanged,
  );
}

class _EditableStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final VoidCallback onTap;
  const _EditableStat({required this.label, required this.value, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Column(
      children: [
        Icon(icon, color: AppColors.olive, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
      ],
    ),
  );
}

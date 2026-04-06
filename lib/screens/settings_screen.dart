import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
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
    'halal', 'kosher', 'christian lent', 'orthodox lent',
    'hindu vegetarian', 'jain', 'buddhist vegetarian'
  ];

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
          // ── Personal Info ─────────────────────────────────────────────────
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
                // Profile picture
                _ProfileAvatar(
                  imagePath: profilePicPath,
                  onTap: () => _pickProfilePic(context, ref),
                ),
                const SizedBox(height: 16),
                _EditableTextField(
                  label: 'Name',
                  value: settings['name'] ?? 'User',
                  onChanged: (val) =>
                      ref.read(settingsProvider.notifier).updateName(val),
                ),
                const Divider(color: Colors.white10, height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _EditableStat(
                        label: 'Height (cm)',
                        value: '${health?.height.toInt() ?? 0}',
                        icon: Icons.height,
                        onTap: () => _showStatDialog(
                            context, ref, 'height', health?.height ?? 0),
                      ),
                    ),
                    Expanded(
                      child: _EditableStat(
                        label: 'Weight (kg)',
                        value: '${health?.weight ?? 0}',
                        icon: Icons.monitor_weight_outlined,
                        onTap: () => _showStatDialog(
                            context, ref, 'weight', health?.weight ?? 0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Dietary Preferences ───────────────────────────────────────────
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
                Row(
                  children: [
                    const Icon(Icons.eco, color: AppColors.olive, size: 16),
                    const SizedBox(width: 8),
                    const Text('Dietary Labels',
                        style: TextStyle(
                            color: AppColors.olive,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const Spacer(),
                    if (userDietary.isNotEmpty)
                      Text('${userDietary.length} active',
                          style: const TextStyle(
                              color: AppColors.olive, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Active labels will warn you when scanning incompatible products.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 12),
                // Warning banner when prefs are active
                if (userDietary.isNotEmpty)
                  _ActiveDietBanner(
                    labels: userDietary,
                    color: AppColors.olive,
                    icon: Icons.eco,
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _dietaryPrefs.map((pref) {
                    final isSelected = userDietary.contains(pref);
                    return FilterChip(
                      label: Text(pref.toTitleCase(),
                          style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.black
                                  : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newList = List<String>.from(userDietary);
                        selected ? newList.add(pref) : newList.remove(pref);
                        ref
                            .read(settingsProvider.notifier)
                            .updateDietaryPrefs(newList);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(selected
                              ? '${pref.toTitleCase()} diet enabled — scanner will warn you'
                              : '${pref.toTitleCase()} diet removed'),
                          duration: const Duration(seconds: 2),
                          backgroundColor:
                          selected ? AppColors.olive : Colors.white24,
                        ));
                      },
                      selectedColor: AppColors.olive,
                      checkmarkColor: Colors.black,
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                        color: isSelected ? AppColors.olive : Colors.white24,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Religious Diet ────────────────────────────────────────────────
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
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.olive, size: 16),
                    const SizedBox(width: 8),
                    const Text('Religious Rules',
                        style: TextStyle(
                            color: AppColors.olive,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const Spacer(),
                    if (userReligious.isNotEmpty)
                      Text('${userReligious.length} active',
                          style: const TextStyle(
                              color: AppColors.olive, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Active rules will flag incompatible food during scanning.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 12),
                if (userReligious.isNotEmpty)
                  _ActiveDietBanner(
                    labels: userReligious,
                    color: Colors.deepPurpleAccent,
                    icon: Icons.star,
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _religiousDiets.map((pref) {
                    final isSelected = userReligious.contains(pref);
                    return FilterChip(
                      label: Text(pref.toTitleCase(),
                          style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.black
                                  : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newList = List<String>.from(userReligious);
                        selected ? newList.add(pref) : newList.remove(pref);
                        ref
                            .read(settingsProvider.notifier)
                            .updateReligiousPrefs(newList);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(selected
                              ? '${pref.toTitleCase()} rules enabled — scanner will warn you'
                              : '${pref.toTitleCase()} rules removed'),
                          duration: const Duration(seconds: 2),
                          backgroundColor:
                          selected ? AppColors.olive : Colors.white24,
                        ));
                      },
                      selectedColor: AppColors.olive,
                      checkmarkColor: Colors.black,
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                        color:
                        isSelected ? AppColors.olive : Colors.white24,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Allergies ─────────────────────────────────────────────────────
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
                Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    const Text('Allergy Filters',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const Spacer(),
                    if (userAllergies.isNotEmpty)
                      Text('${userAllergies.length} active',
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'You will be warned when scanning products containing these.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 12),
                if (userAllergies.isNotEmpty)
                  _ActiveDietBanner(
                    labels: userAllergies,
                    color: Colors.redAccent,
                    icon: Icons.warning_amber,
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _availableAllergens.map((allergy) {
                    final isSelected = userAllergies.contains(allergy);
                    return FilterChip(
                      label: Text(allergy.toTitleCase(),
                          style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newList = List<String>.from(userAllergies);
                        selected
                            ? newList.add(allergy)
                            : newList.remove(allergy);
                        ref
                            .read(settingsProvider.notifier)
                            .updateAllergies(newList);
                      },
                      selectedColor: Colors.redAccent.withOpacity(0.7),
                      checkmarkColor: Colors.white,
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                        color: isSelected
                            ? Colors.redAccent
                            : Colors.white24,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Data Management ───────────────────────────────────────────────
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
                  leading:
                  const Icon(Icons.file_upload, color: AppColors.olive),
                  title: const Text('Export Data'),
                  subtitle: const Text('Backup your database to a file',
                      style: TextStyle(fontSize: 10, color: Colors.white38)),
                  onTap: () => _exportDatabase(context),
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download,
                      color: AppColors.olive),
                  title: const Text('Import Data'),
                  subtitle: const Text('Restore from a backup file',
                      style: TextStyle(fontSize: 10, color: Colors.white38)),
                  onTap: () => _importDatabase(context),
                ),
              ],
            ),
          ),

          // ── Health Sync ───────────────────────────────────────────────────
          const _SettingsHeader(title: 'Data & Sync'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.sync, color: AppColors.olive),
              title: const Text('Sync Google Fit',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              onTap: () =>
                  ref.read(healthProvider.notifier).syncWithGoogleFit(),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Future<void> _pickProfilePic(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.olive),
            title: const Text('Take Photo',
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              final img =
              await picker.pickImage(source: ImageSource.camera);
              if (img != null) {
                ref
                    .read(settingsProvider.notifier)
                    .updateProfilePic(img.path);
              }
            },
          ),
          ListTile(
            leading:
            const Icon(Icons.photo_library, color: AppColors.olive),
            title: const Text('Choose from Gallery',
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              final img =
              await picker.pickImage(source: ImageSource.gallery);
              if (img != null) {
                ref
                    .read(settingsProvider.notifier)
                    .updateProfilePic(img.path);
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final dbPath = await getDatabasesPath();
      final sourceFile = File(p.join(dbPath, 'kolirus.db'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database at: ${sourceFile.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export Failed: $e')),
      );
    }
  }

  Future<void> _importDatabase(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Please select a .db file to import.')),
    );
  }

  void _showStatDialog(BuildContext context, WidgetRef ref, String type,
      double currentVal) {
    final controller = TextEditingController(
        text: currentVal > 0 ? currentVal.toString() : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Update ${type.toTitleCase()}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
              suffixText: type == 'height' ? 'cm' : 'kg'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              if (type == 'height') {
                ref.read(healthProvider.notifier).updateManualEntry(
                    height: val, date: DateTime.now());
              } else {
                ref.read(healthProvider.notifier).updateManualEntry(
                    weight: val, date: DateTime.now());
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

// ── Profile Avatar ─────────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  const _ProfileAvatar({this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.primary,
            backgroundImage: imagePath != null
                ? (imagePath!.startsWith('http')
                ? NetworkImage(imagePath!)
                : FileImage(File(imagePath!)))
            as ImageProvider
                : null,
            child: imagePath == null
                ? const Icon(Icons.person, size: 45, color: AppColors.olive)
                : null,
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.olive,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

// ── Active Diet Banner ─────────────────────────────────────────────────────────

class _ActiveDietBanner extends StatelessWidget {
  final List<String> labels;
  final Color color;
  final IconData icon;
  const _ActiveDietBanner(
      {required this.labels, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Active: ${labels.map((l) => l.toTitleCase()).join(', ')}. Scanner will warn you about incompatible products.',
              style: TextStyle(color: color, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _EditableTextField extends StatelessWidget {
  final String label, value;
  final Function(String) onChanged;
  const _EditableTextField(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      style:
      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
  const _EditableStat(
      {required this.label,
        required this.value,
        required this.icon,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.olive, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label.toTitleCase(),
              style:
              const TextStyle(fontSize: 10, color: Colors.white38)),
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
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              color: AppColors.olive,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1)),
    );
  }
}
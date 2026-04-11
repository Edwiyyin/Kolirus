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

          const _SettingsHeader(title: 'Body Stats'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Row(
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
          ),

          // ── Dietary Preferences ──────────────────────────────────────────
          const _SettingsHeader(title: 'Dietary Preferences'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.eco, color: AppColors.olive, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Dietary Labels', style: TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold, fontSize: 13))),
                  if (userDietary.isNotEmpty) Text('${userDietary.length} active', style: const TextStyle(color: AppColors.olive, fontSize: 11)),
                ]),
                const SizedBox(height: 6),
                const Text(
                  'Products containing forbidden ingredients for your selected diet will be flagged during scanning.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 12),
                if (userDietary.isNotEmpty) _ActiveDietBanner(labels: userDietary, color: AppColors.olive, icon: Icons.eco),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: allDietaryPrefs.map((pref) {
                    final sel = userDietary.contains(pref);
                    return FilterChip(
                      label: Text(pref.toTitleCase(), style: TextStyle(fontSize: 12, color: sel ? Colors.black : Colors.white70, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                      selected: sel,
                      onSelected: (v) {
                        final list = List<String>.from(userDietary);
                        v ? list.add(pref) : list.remove(pref);
                        ref.read(settingsProvider.notifier).updateDietaryPrefs(list);
                      },
                      selectedColor: AppColors.olive,
                      checkmarkColor: Colors.black,
                      backgroundColor: AppColors.background,
                      side: BorderSide(color: sel ? AppColors.olive : Colors.white24),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Custom Diet ──────────────────────────────────────────────────
          const _SettingsHeader(title: 'Custom Diet Filter'),
          const _CustomDietSection(),

          // ── Religious Diet ───────────────────────────────────────────────
          const _SettingsHeader(title: 'Religious Diet'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.star, color: AppColors.olive, size: 16),
                  SizedBox(width: 8),
                  Text('Religious Rules', style: TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
                const SizedBox(height: 6),
                const Text(
                  'Includes gelatin, alcohol, non-halal slaughter, shellfish, pork, and more.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: allReligiousDiets.map((pref) {
                    final sel = userReligious.contains(pref);
                    return FilterChip(
                      label: Text(pref.toTitleCase(), style: TextStyle(fontSize: 12, color: sel ? Colors.black : Colors.white70, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                      selected: sel,
                      onSelected: (v) {
                        final list = List<String>.from(userReligious);
                        v ? list.add(pref) : list.remove(pref);
                        ref.read(settingsProvider.notifier).updateReligiousPrefs(list);
                      },
                      selectedColor: AppColors.olive,
                      checkmarkColor: Colors.black,
                      backgroundColor: AppColors.background,
                      side: BorderSide(color: sel ? AppColors.olive : Colors.white24),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Allergies ────────────────────────────────────────────────────
          const _SettingsHeader(title: 'Allergies'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.warning_amber, color: Colors.redAccent, size: 16),
                  SizedBox(width: 8),
                  Text('Allergy Filters', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
                const SizedBox(height: 6),
                const Text(
                  'All EU-14 major allergens covered with comprehensive ingredient matching.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: allAllergens.map((a) {
                    final sel = userAllergies.contains(a);
                    return FilterChip(
                      label: Text(a.toTitleCase(), style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.white70, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                      selected: sel,
                      onSelected: (v) {
                        final list = List<String>.from(userAllergies);
                        v ? list.add(a) : list.remove(a);
                        ref.read(settingsProvider.notifier).updateAllergies(list);
                      },
                      selectedColor: Colors.redAccent.withOpacity(0.7),
                      checkmarkColor: Colors.white,
                      backgroundColor: AppColors.background,
                      side: BorderSide(color: sel ? Colors.redAccent : Colors.white24),
                    );
                  }).toList(),
                ),
              ],
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.olive),
            title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              final img = await picker.pickImage(source: ImageSource.camera);
              if (img != null) ref.read(settingsProvider.notifier).updateProfilePic(img.path);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.olive),
            title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              final img = await picker.pickImage(source: ImageSource.gallery);
              if (img != null) ref.read(settingsProvider.notifier).updateProfilePic(img.path);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showStatDialog(BuildContext context, WidgetRef ref, String type, double currentVal) {
    final ctrl = TextEditingController(text: currentVal > 0 ? currentVal.toString() : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Update ${type.toTitleCase()}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(suffixText: type == 'height' ? 'cm' : 'kg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text) ?? 0;
              if (type == 'height') {
                ref.read(healthProvider.notifier).updateManualEntry(height: val, date: DateTime.now());
              } else {
                ref.read(healthProvider.notifier).updateManualEntry(weight: val, date: DateTime.now());
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

// ─────────────────────────────────────────────────────────────────────────────

class _CustomDietSection extends StatefulWidget {
  const _CustomDietSection();
  @override
  State<_CustomDietSection> createState() => _CustomDietSectionState();
}

class _CustomDietSectionState extends State<_CustomDietSection> {
  List<Map<String, dynamic>> _diets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DatabaseService.instance.getCustomDiets();
    if (mounted) setState(() => _diets = list);
  }

  void _showEditor({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final kwCtrl = TextEditingController(
      text: existing != null
          ? (jsonDecode(existing['violationKeywords'] as String) as List).join(', ')
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing != null ? 'Edit Custom Diet' : 'New Custom Diet', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Diet name *', labelStyle: TextStyle(color: AppColors.olive))),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Description (optional)', labelStyle: TextStyle(color: AppColors.olive))),
              const SizedBox(height: 8),
              TextField(
                controller: kwCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Forbidden ingredients (comma-separated) *',
                  labelStyle: TextStyle(color: AppColors.olive),
                  hintText: 'e.g. pork, alcohol, shellfish',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
              const SizedBox(height: 4),
              const Text('These keywords are matched against scanned product ingredients.', style: TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (existing != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                        onPressed: () async {
                          await DatabaseService.instance.deleteCustomDiet(existing['id']);
                          await _load();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Delete'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty || kwCtrl.text.isEmpty) return;
                        final keywords = kwCtrl.text.split(',').map((k) => k.trim().toLowerCase()).where((k) => k.isNotEmpty).toList();
                        await DatabaseService.instance.saveCustomDiet({
                          'id': existing?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          'name': nameCtrl.text,
                          'description': descCtrl.text,
                          'violationKeywords': jsonEncode(keywords),
                        });
                        await _load();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(existing != null ? 'Update' : 'Save', style: const TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.olive, size: 16),
              const SizedBox(width: 8),
              const Expanded(child: Text('Custom Diets', style: TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold, fontSize: 13))),
              IconButton(icon: const Icon(Icons.add_circle, color: AppColors.olive, size: 22), onPressed: () => _showEditor()),
            ],
          ),
          const Text('Create your own rule by listing forbidden keywords. These are checked when you scan products.', style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 12),
          if (_diets.isEmpty)
            const Text('No custom diets yet.', style: TextStyle(color: Colors.white24, fontSize: 12))
          else
            ..._diets.map((diet) {
              final kw = (jsonDecode(diet['violationKeywords'] as String) as List).cast<String>();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.olive.withOpacity(0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt, color: AppColors.olive, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(diet['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          if ((diet['description'] as String?)?.isNotEmpty == true)
                            Text(diet['description'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          Text('Blocks: ${kw.take(5).join(", ")}${kw.length > 5 ? "..." : ""}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.edit, color: AppColors.olive, size: 18), onPressed: () => _showEditor(existing: diet)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  const _ProfileAvatar({this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    ImageProvider? img;
    if (imagePath != null) {
      img = imagePath!.startsWith('http') ? NetworkImage(imagePath!) as ImageProvider : FileImage(File(imagePath!));
    }
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.primary,
            backgroundImage: img,
            child: img == null ? const Icon(Icons.person, size: 45, color: AppColors.olive) : null,
          ),
          Container(
            decoration: const BoxDecoration(color: AppColors.olive, shape: BoxShape.circle),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class _ActiveDietBanner extends StatelessWidget {
  final List<String> labels;
  final Color color;
  final IconData icon;
  const _ActiveDietBanner({required this.labels, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.4))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text('Active: ${labels.map((l) => l.toTitleCase()).join(', ')}.', style: TextStyle(color: color, fontSize: 11))),
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
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/constants.dart';
import '../providers/health_provider.dart';
import '../providers/settings_provider.dart';
import '../services/health_service.dart';
import '../services/database_service.dart';

// ── Google Sign-In singleton ──────────────────────────────────────────────────
final _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
);

final googleAccountProvider =
StateProvider<GoogleSignInAccount?>((ref) => null);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<String> _availableAllergens = [
    'gluten', 'milk', 'eggs', 'nuts', 'peanuts', 'sesame',
    'soybeans', 'fish', 'shellfish', 'celery', 'mustard',
    'lupin', 'molluscs', 'sulphites',
  ];

  static const List<String> _dietaryPrefs = [
    'vegan', 'vegetarian', 'paleo', 'keto', 'mediterranean', 'low-carb',
  ];

  static const List<String> _religiousDiets = [
    'halal', 'kosher', 'christian lent', 'orthodox lent',
    'hindu vegetarian', 'jain', 'buddhist vegetarian',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final userAllergies = List<String>.from(settings['allergies'] ?? []);
    final userDietary =
    List<String>.from(settings['dietary_prefs'] ?? []);
    final userReligious =
    List<String>.from(settings['religious_prefs'] ?? []);
    final healthState = ref.watch(healthProvider);
    final health = healthState.today;
    final profilePicPath = settings['profile_pic'] as String?;
    final googleAccount = ref.watch(googleAccountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Account ──────────────────────────────────────────────────────
          const _SettingsHeader(title: 'Account'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _ProfileAvatar(
                  imagePath: profilePicPath ??
                      googleAccount?.photoUrl,
                  onTap: () => _pickProfilePic(context, ref),
                ),
                const SizedBox(height: 16),
                _EditableTextField(
                  label: 'Name',
                  value: settings['name'] ?? 'User',
                  onChanged: (val) =>
                      ref.read(settingsProvider.notifier).updateName(val),
                ),
                const SizedBox(height: 16),
                // Google Sign-In / Sign-Out button
                _GoogleSignInButton(
                  account: googleAccount,
                  onSignIn: () async {
                    await _handleGoogleSignIn(context, ref);
                  },
                  onSignOut: () async {
                    await _googleSignIn.signOut();
                    ref.read(googleAccountProvider.notifier).state = null;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out')),
                      );
                    }
                  },
                ),
                if (googleAccount != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Note: Data is stored locally. '
                          'Firebase Firestore integration needed for cloud sync.',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          // ── Body Stats ────────────────────────────────────────────────────
          const _SettingsHeader(title: 'Body Stats'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
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
                Row(children: [
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
                ]),
                const SizedBox(height: 12),
                if (userDietary.isNotEmpty)
                  _ActiveDietBanner(
                      labels: userDietary,
                      color: AppColors.olive,
                      icon: Icons.eco),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _dietaryPrefs.map((pref) {
                    final sel = userDietary.contains(pref);
                    return FilterChip(
                      label: Text(pref.toTitleCase(),
                          style: TextStyle(
                              fontSize: 12,
                              color: sel ? Colors.black : Colors.white70,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      selected: sel,
                      onSelected: (v) {
                        final list = List<String>.from(userDietary);
                        v ? list.add(pref) : list.remove(pref);
                        ref
                            .read(settingsProvider.notifier)
                            .updateDietaryPrefs(list);
                      },
                      selectedColor: AppColors.olive,
                      checkmarkColor: Colors.black,
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                          color: sel ? AppColors.olive : Colors.white24),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Custom Diet ────────────────────────────────────────────────────
          const _SettingsHeader(title: 'Custom Diet Filter'),
          _CustomDietSection(),

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
                const Row(children: [
                  Icon(Icons.star, color: AppColors.olive, size: 16),
                  SizedBox(width: 8),
                  Text('Religious Rules',
                      style: TextStyle(
                          color: AppColors.olive,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _religiousDiets.map((pref) {
                    final sel = userReligious.contains(pref);
                    return FilterChip(
                      label: Text(pref.toTitleCase(),
                          style: TextStyle(
                              fontSize: 12,
                              color: sel ? Colors.black : Colors.white70,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      selected: sel,
                      onSelected: (v) {
                        final list = List<String>.from(userReligious);
                        v ? list.add(pref) : list.remove(pref);
                        ref
                            .read(settingsProvider.notifier)
                            .updateReligiousPrefs(list);
                      },
                      selectedColor: AppColors.olive,
                      checkmarkColor: Colors.black,
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                          color: sel ? AppColors.olive : Colors.white24),
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
                const Row(children: [
                  Icon(Icons.warning_amber,
                      color: Colors.redAccent, size: 16),
                  SizedBox(width: 8),
                  Text('Allergy Filters',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _availableAllergens.map((a) {
                    final sel = userAllergies.contains(a);
                    return FilterChip(
                      label: Text(a.toTitleCase(),
                          style: TextStyle(
                              fontSize: 12,
                              color: sel ? Colors.white : Colors.white70,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      selected: sel,
                      onSelected: (v) {
                        final list = List<String>.from(userAllergies);
                        v ? list.add(a) : list.remove(a);
                        ref
                            .read(settingsProvider.notifier)
                            .updateAllergies(list);
                      },
                      selectedColor: Colors.redAccent.withOpacity(0.7),
                      checkmarkColor: Colors.white,
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                          color:
                          sel ? Colors.redAccent : Colors.white24),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Health Sync ───────────────────────────────────────────────────
          const _SettingsHeader(title: 'Data & Sync'),
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
                  const Icon(Icons.sync, color: AppColors.olive),
                  title: const Text('Sync Google Fit / Health Connect',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text(
                      'Requires Health Connect on Android 14+',
                      style:
                      TextStyle(color: Colors.white38, fontSize: 11)),
                  onTap: () async {
                    final service = HealthService();
                    final ok = await service.requestPermissions();
                    if (ok) {
                      await ref
                          .read(healthProvider.notifier)
                          .syncWithGoogleFit();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Health sync successful')),
                        );
                      }
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Permission denied. Install Health Connect from the Play Store.'),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.file_upload,
                      color: AppColors.olive),
                  title: const Text('Show DB Path'),
                  onTap: () => _exportDatabase(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Google Sign-In logic ──────────────────────────────────────────────────

  Future<void> _handleGoogleSignIn(
      BuildContext context, WidgetRef ref) async {
    try {
      // Attempt silent sign-in first (restores previous session)
      GoogleSignInAccount? account =
      await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        // User cancelled the picker
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign-in cancelled')),
          );
        }
        return;
      }

      ref.read(googleAccountProvider.notifier).state = account;
      ref.read(settingsProvider.notifier).updateName(
        account.displayName ?? account.email,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('Signed in as ${account.email}'),
            backgroundColor: AppColors.olive,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        String msg = e.toString();
        if (msg.contains('sign_in_failed') ||
            msg.contains('ApiException: 10')) {
          msg = 'Sign-in failed: SHA-1 fingerprint not configured.\n'
              'Run: keytool -list -v -keystore ~/.android/debug.keystore\n'
              'Then add the SHA-1 to your Firebase project.';
        } else if (msg.contains('network_error')) {
          msg = 'Network error. Check your internet connection.';
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Google Sign-In Failed'),
            content: Text(msg,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  Future<void> _pickProfilePic(
      BuildContext context, WidgetRef ref) async {
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
            leading:
            const Icon(Icons.camera_alt, color: AppColors.olive),
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
            leading: const Icon(Icons.photo_library,
                color: AppColors.olive),
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
      final path = p.join(dbPath, 'kolirus.db');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DB: $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showStatDialog(BuildContext context, WidgetRef ref,
      String type, double currentVal) {
    final ctrl = TextEditingController(
        text: currentVal > 0 ? currentVal.toString() : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Update ${type.toTitleCase()}'),
        content: TextField(
          controller: ctrl,
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
              final val = double.tryParse(ctrl.text) ?? 0;
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

// ── Google Sign-In Button ─────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final GoogleSignInAccount? account;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const _GoogleSignInButton({
    required this.account,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    if (account == null) {
      return OutlinedButton(
        onPressed: onSignIn,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google 'G' logo placeholder using colored text
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Center(
                child: Text('G',
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Sign in with Google',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    // Signed in — show account info + sign out
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.olive.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.olive.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Avatar from Google account
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            backgroundImage: account!.photoUrl != null
                ? NetworkImage(account!.photoUrl!)
                : null,
            child: account!.photoUrl == null
                ? Text(
              (account!.displayName ?? account!.email)
                  .substring(0, 1)
                  .toUpperCase(),
              style: const TextStyle(
                  color: AppColors.olive,
                  fontWeight: FontWeight.bold),
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (account!.displayName != null)
                  Text(account!.displayName!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                Text(account!.email,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          TextButton(
            onPressed: onSignOut,
            child: const Text('Sign out',
                style: TextStyle(
                    color: Colors.redAccent, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Custom Diet Section ───────────────────────────────────────────────────────

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
    final nameCtrl =
    TextEditingController(text: existing?['name'] ?? '');
    final descCtrl =
    TextEditingController(text: existing?['description'] ?? '');
    final kwCtrl = TextEditingController(
      text: existing != null
          ? (jsonDecode(existing['violationKeywords'] as String) as List)
          .join(', ')
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  existing != null
                      ? 'Edit Custom Diet'
                      : 'New Custom Diet',
                  style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Diet name *',
                  labelStyle: TextStyle(color: AppColors.olive),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: AppColors.olive),
                ),
              ),
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
              const Text(
                'These keywords are matched against scanned product ingredients.',
                style:
                TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (existing != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side:
                          const BorderSide(color: Colors.redAccent),
                        ),
                        onPressed: () async {
                          await DatabaseService.instance
                              .deleteCustomDiet(existing['id']);
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
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.olive),
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty ||
                            kwCtrl.text.isEmpty) return;
                        final keywords = kwCtrl.text
                            .split(',')
                            .map((k) => k.trim().toLowerCase())
                            .where((k) => k.isNotEmpty)
                            .toList();
                        await DatabaseService.instance.saveCustomDiet({
                          'id': existing?['id'] ??
                              DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                          'name': nameCtrl.text,
                          'description': descCtrl.text,
                          'violationKeywords': jsonEncode(keywords),
                        });
                        await _load();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(
                          existing != null ? 'Update' : 'Save',
                          style: const TextStyle(color: Colors.black)),
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
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune,
                  color: AppColors.olive, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Custom Diets',
                    style: TextStyle(
                        color: AppColors.olive,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle,
                    color: AppColors.olive, size: 22),
                onPressed: () => _showEditor(),
              ),
            ],
          ),
          const Text(
            'Create your own rule by listing forbidden keywords. '
                'These are checked when you scan products.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 12),
          if (_diets.isEmpty)
            const Text('No custom diets yet.',
                style:
                TextStyle(color: Colors.white24, fontSize: 12))
          else
            ..._diets.map((diet) {
              final kw = (jsonDecode(
                  diet['violationKeywords'] as String) as List)
                  .cast<String>();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.olive.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt,
                        color: AppColors.olive, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(diet['name'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          if ((diet['description'] as String?)
                              ?.isNotEmpty ==
                              true)
                            Text(diet['description'],
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11)),
                          Text(
                            'Blocks: ${kw.take(5).join(", ")}${kw.length > 5 ? "..." : ""}',
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: AppColors.olive, size: 18),
                      onPressed: () => _showEditor(existing: diet),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  const _ProfileAvatar({this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    ImageProvider? img;
    if (imagePath != null) {
      img = imagePath!.startsWith('http')
          ? NetworkImage(imagePath!) as ImageProvider
          : FileImage(File(imagePath!));
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
            child: img == null
                ? const Icon(Icons.person,
                size: 45, color: AppColors.olive)
                : null,
          ),
          Container(
            decoration: const BoxDecoration(
                color: AppColors.olive, shape: BoxShape.circle),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.camera_alt,
                size: 14, color: Colors.black),
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
  const _ActiveDietBanner(
      {required this.labels,
        required this.color,
        required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              'Active: ${labels.map((l) => l.toTitleCase()).join(', ')}.',
              style: TextStyle(color: color, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableTextField extends StatelessWidget {
  final String label, value;
  final Function(String) onChanged;
  const _EditableTextField(
      {required this.label,
        required this.value,
        required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label.toTitleCase(),
        labelStyle: const TextStyle(color: AppColors.olive),
        suffixIcon:
        const Icon(Icons.edit, size: 16, color: Colors.white24),
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
              style: const TextStyle(
                  fontSize: 10, color: Colors.white38)),
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
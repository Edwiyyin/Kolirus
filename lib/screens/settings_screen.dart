import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final userAllergies = List<String>.from(settings['allergies'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          const _SettingsHeader(title: 'Profile'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 40, color: AppColors.olive),
                  ),
                ),
                const SizedBox(height: 16),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.email_outlined, color: AppColors.olive),
                  title: Text('Email', style: TextStyle(color: Colors.white)),
                  subtitle: Text('user@example.com', style: AppTextStyles.caption),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.cake_outlined, color: AppColors.olive),
                  title: Text('Birthday', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Jan 01, 1990', style: AppTextStyles.caption),
                ),
              ],
            ),
          ),

          // Allergen / dietary filters
          const _SettingsHeader(title: 'Dietary Filters & Allergies'),
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
                const Text(
                  'Select ingredients you are allergic to. We will warn you when scanning products that may contain these.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 16),
                if (userAllergies.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Active filters: ${userAllergies.map((a) => a.toUpperCase()).join(", ")}',
                            style: const TextStyle(color: AppColors.danger, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _availableAllergens.map((allergy) {
                    final isSelected = userAllergies.contains(allergy.toLowerCase());
                    return FilterChip(
                      label: Text(allergy.toUpperCase(),
                          style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newList = List<String>.from(userAllergies);
                        if (selected) {
                          newList.add(allergy.toLowerCase());
                        } else {
                          newList.remove(allergy.toLowerCase());
                        }
                        ref.read(settingsProvider.notifier).updateAllergies(newList);
                      },
                      selectedColor: AppColors.danger.withOpacity(0.7),
                      checkmarkColor: Colors.white,
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Health & Data
          const _SettingsHeader(title: 'Health & Data'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.sync, color: AppColors.olive),
              title: const Text('Sync with Google Fit',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Fetch latest steps and weight data',
                  style: AppTextStyles.caption),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () async {
                await ref.read(healthProvider.notifier).syncWithGoogleFit();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Synced with Google Fit')),
                  );
                }
              },
            ),
          ),

          // About
          const _SettingsHeader(title: 'About'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const ListTile(
              title: Text('App Version', style: TextStyle(color: Colors.white)),
              trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
            ),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.olive,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
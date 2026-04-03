import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../providers/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  final List<String> _availableAllergens = const [
    'Gluten', 'Milk', 'Eggs', 'Nuts', 'Peanuts', 'Sesame', 'Soybeans', 'Fish', 'Shellfish', 'Celery', 'Mustard', 'Lupin', 'Molluscs', 'Sulphites'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final userAllergies = List<String>.from(settings['allergies'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 50, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Dietary Filters & Allergies', style: AppTextStyles.heading2),
          const SizedBox(height: 12),
          const Text(
            'Select ingredients you are allergic to. We will warn you when scanning products containing these.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _availableAllergens.map((allergy) {
              final isSelected = userAllergies.contains(allergy.toLowerCase());
              return FilterChip(
                label: Text(allergy),
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
                selectedColor: AppColors.accent,
                checkmarkColor: Colors.black,
                labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Text('Profile Info', style: AppTextStyles.heading2),
          const ListTile(
            leading: Icon(Icons.email_outlined, color: AppColors.accent),
            title: Text('Email', style: TextStyle(color: Colors.white)),
            subtitle: Text('user@example.com', style: AppTextStyles.caption),
          ),
          const ListTile(
            leading: Icon(Icons.cake_outlined, color: AppColors.accent),
            title: Text('Birthday', style: TextStyle(color: Colors.white)),
            subtitle: Text('Jan 01, 1990', style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }
}

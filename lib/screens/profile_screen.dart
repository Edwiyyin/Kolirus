import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          _sectionHeader('Daily Nutrition'),
          const SizedBox(height: 8),
          _goalTile(
            context,
            ref,
            icon: Icons.local_fire_department_outlined,
            label: 'Calorie Goal',
            value: '${(settings['calorie_goal'] ?? 2000).toInt()} kcal',
            onTap: () => _showGoalDialog(context, ref, 'calorie_goal', 'Calorie Goal (kcal)', 2000),
          ),
          _goalTile(
            context,
            ref,
            icon: Icons.egg_alt_outlined,
            label: 'Protein Goal',
            value: '${(settings['protein_goal'] ?? 150).toInt()} g',
            onTap: () => _showGoalDialog(context, ref, 'protein_goal', 'Protein Goal (g)', 150),
          ),
          _goalTile(
            context,
            ref,
            icon: Icons.grain_outlined,
            label: 'Carbs Goal',
            value: '${(settings['carbs_goal'] ?? 250).toInt()} g',
            onTap: () => _showGoalDialog(context, ref, 'carbs_goal', 'Carbs Goal (g)', 250),
          ),
          _goalTile(
            context,
            ref,
            icon: Icons.opacity_outlined,
            label: 'Fat Goal',
            value: '${(settings['fat_goal'] ?? 70).toInt()} g',
            onTap: () => _showGoalDialog(context, ref, 'fat_goal', 'Fat Goal (g)', 70),
          ),
          _goalTile(
            context,
            ref,
            icon: Icons.grass_outlined,
            label: 'Fiber Goal',
            value: '${(settings['fiber_goal'] ?? 30).toInt()} g',
            onTap: () => _showGoalDialog(context, ref, 'fiber_goal', 'Fiber Goal (g)', 30),
          ),
          const SizedBox(height: 20),
          _sectionHeader('Hydration & Health'),
          const SizedBox(height: 8),
          _goalTile(
            context,
            ref,
            icon: Icons.water_drop_outlined,
            label: 'Water Goal',
            value: '${(settings['water_goal'] ?? 2000).toInt()} ml',
            onTap: () => _showGoalDialog(context, ref, 'water_goal', 'Water Goal (ml)', 2000),
          ),
          _goalTile(
            context,
            ref,
            icon: Icons.monitor_weight_outlined,
            label: 'Weight Goal',
            value: '${(settings['weight_goal'] ?? 70).toInt()} kg',
            onTap: () => _showGoalDialog(context, ref, 'weight_goal', 'Weight Goal (kg)', 70),
          ),
          _goalTile(
            context,
            ref,
            icon: Icons.restaurant_outlined,
            label: 'Healthy Food Goal',
            value: '${(settings['healthy_food_goal'] ?? 5).toInt()} items/day',
            onTap: () => _showGoalDialog(context, ref, 'healthy_food_goal', 'Healthy Food Items per Day', 5),
          ),
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'Goals help Koly track your progress!',
              style: TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            color: AppColors.olive,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.0),
      ),
    );
  }

  Widget _goalTile(
      BuildContext context,
      WidgetRef ref, {
        required IconData icon,
        required String label,
        required String value,
        required VoidCallback onTap,
      }) {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 10),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.olive.withOpacity(0.1),
              shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.olive, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    color: AppColors.olive,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                color: Colors.white24, size: 18),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref, String key,
      String title, double defaultValue) {
    final settings = ref.read(settingsProvider);
    final ctrl = TextEditingController(
        text: (settings[key] ?? defaultValue).toInt().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title,
            style: const TextStyle(fontSize: 16, color: AppColors.beige)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.olive)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.olive),
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null) {
                ref.read(settingsProvider.notifier).updateNutrientGoal(key, val);
                Navigator.pop(context);
              }
            },
            child: const Text('Save',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
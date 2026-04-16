import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';

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
          const AccountCard(),
          const SizedBox(height: 24),
          
          _goalTile(
            context,
            ref,
            icon: Icons.monitor_weight_outlined,
            label: 'Weight Goal',
            value: '${settings['weight_goal'] ?? 70} kg',
            onTap: () => _showGoalDialog(context, ref, 'weight_goal', 'Weight Goal (kg)'),
          ),
          _goalTile(
            context,
            ref,
            icon: Icons.local_fire_department_outlined,
            label: 'Calorie Goal',
            value: '${settings['calorie_goal'] ?? 2000} kcal',
            onTap: () => _showGoalDialog(context, ref, 'calorie_goal', 'Calorie Goal (kcal)'),
          ),
          _goalTile(
            context,
            ref,
            icon: Icons.water_drop_outlined,
            label: 'Water Goal',
            value: '${settings['water_goal_ml'] ?? 2000} ml',
            onTap: () => _showGoalDialog(context, ref, 'water_goal_ml', 'Water Goal (ml)'),
          ),
          _goalTile(
            context,
            ref,
            icon: Icons.restaurant_outlined,
            label: 'Healthy Food Goal',
            value: '${settings['healthy_food_goal'] ?? 5} items',
            onTap: () => _showGoalDialog(context, ref, 'healthy_food_goal', 'Healthy Food Goal (items/day)'),
          ),
          
          const SizedBox(height: 40),
          const Center(
            child: Text('Goals help Koly track your progress!', 
              style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Widget _goalTile(BuildContext context, WidgetRef ref, {required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.olive.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.olive, size: 20),
        ),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: Text(value, style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold, fontSize: 16)),
        onTap: onTap,
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref, String key, String title) {
    final settings = ref.read(settingsProvider);
    final ctrl = TextEditingController(text: settings[key]?.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.olive)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null) {
                final newSettings = Map<String, dynamic>.from(settings);
                newSettings[key] = val;
                ref.read(settingsProvider.notifier).updateSettings(newSettings);
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: AppColors.olive)),
          ),
        ],
      ),
    );
  }
}

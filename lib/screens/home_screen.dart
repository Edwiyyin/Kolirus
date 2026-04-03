import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../providers/food_log_provider.dart';
import '../models/meal_log.dart';
import '../models/food_item.dart';
import '../providers/pantry_provider.dart';
import '../models/meal_type.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(foodLogProvider.notifier).getDailyTotals();
    final logs = ref.watch(foodLogProvider);
    final calories = totals['calories'] ?? 0;
    const double goal = 2000;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('hello,', style: TextStyle(color: AppColors.textLight, fontSize: 16)),
                  Text('ready to fuel?', style: AppTextStyles.heading1),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showLogMealDialog(context, ref),
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Log Meal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.olive,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Main Calorie Ring
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: (calories / goal).clamp(0, 1),
                    strokeWidth: 12,
                    backgroundColor: AppColors.card,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.olive),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${calories.toInt()}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.beige)),
                    const Text('kcal', style: TextStyle(color: AppColors.olive, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('of ${goal.toInt()}', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          const Text('quick macros', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          
          Row(
            children: [
              _MacroMiniCard(label: 'protein', value: '${totals['protein']?.toInt() ?? 0}g', color: AppColors.olive),
              const SizedBox(width: 12),
              _MacroMiniCard(label: 'carbs', value: '${totals['carbs']?.toInt() ?? 0}g', color: AppColors.olive.withOpacity(0.6)),
              const SizedBox(width: 12),
              _MacroMiniCard(label: 'fat', value: '${totals['fat']?.toInt() ?? 0}g', color: AppColors.olive.withOpacity(0.3)),
            ],
          ),
          
          const SizedBox(height: 32),
          const Text('today\'s logs', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No meals logged today', style: TextStyle(color: Colors.white24))))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _MealLogTile(log: log);
              },
            ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showLogMealDialog(BuildContext context, WidgetRef ref) {
    final pantry = ref.watch(pantryProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Log a Meal', style: AppTextStyles.heading1),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showManualLogDialog(context, ref);
                    },
                    icon: const Icon(Icons.edit, color: AppColors.olive),
                    label: const Text('Manual Entry', style: TextStyle(color: AppColors.olive)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: pantry.isEmpty 
                ? const Center(child: Text('Kitchen is empty. Scan items first!'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: pantry.length,
                    itemBuilder: (context, index) {
                      final item = pantry[index];
                      return ListTile(
                        leading: item.imageUrl != null 
                          ? (item.imageUrl!.startsWith('http') 
                              ? Image.network(item.imageUrl!, width: 40, height: 40, fit: BoxFit.cover)
                              : Image.file(File(item.imageUrl!), width: 40, height: 40, fit: BoxFit.cover))
                          : const Icon(Icons.fastfood, color: AppColors.olive),
                        title: Text(item.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${item.calories.toInt()} kcal', style: AppTextStyles.caption),
                        onTap: () {
                          final log = MealLog(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            foodItemId: item.id!,
                            foodName: item.name,
                            quantity: 1.0,
                            consumedAt: DateTime.now(),
                            type: MealType.Lunch,
                            calories: item.calories,
                            protein: item.protein,
                            carbs: item.carbs,
                            fat: item.fat,
                            sugar: item.sugar,
                            fiber: item.fiber,
                            sodium: item.sodium,
                            cholesterol: item.cholesterol,
                            saturatedFat: item.saturatedFat,
                          );
                          ref.read(foodLogProvider.notifier).addLog(log);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualLogDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Manual Meal Log', style: TextStyle(color: AppColors.beige)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Meal Name', labelStyle: TextStyle(color: AppColors.olive)),
              ),
              TextField(
                controller: calController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Calories', labelStyle: TextStyle(color: AppColors.olive)),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: proteinController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Protein (g)', labelStyle: TextStyle(color: AppColors.olive)),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: carbsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Carbs (g)', labelStyle: TextStyle(color: AppColors.olive)),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: fatController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Fat (g)', labelStyle: TextStyle(color: AppColors.olive)),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final log = MealLog(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  foodItemId: 'manual',
                  foodName: nameController.text,
                  quantity: 1.0,
                  consumedAt: DateTime.now(),
                  type: MealType.Lunch,
                  calories: double.tryParse(calController.text) ?? 0,
                  protein: double.tryParse(proteinController.text) ?? 0,
                  carbs: double.tryParse(carbsController.text) ?? 0,
                  fat: double.tryParse(fatController.text) ?? 0,
                );
                ref.read(foodLogProvider.notifier).addLog(log);
                Navigator.pop(context);
              }
            },
            child: const Text('Log', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _MealLogTile extends ConsumerWidget {
  final MealLog log;
  const _MealLogTile({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(log.id!),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(foodLogProvider.notifier).removeLog(log.id!);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.olive.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.restaurant, color: AppColors.olive, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.foodName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(DateFormat('hh:mm a').format(log.consumedAt), style: AppTextStyles.caption),
                ],
              ),
            ),
            Text('${log.calories.toInt()} kcal', style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _MacroMiniCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MacroMiniCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border(bottom: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.beige)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

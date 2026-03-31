import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_log_provider.dart';
import '../providers/pantry_provider.dart';
import '../models/meal_log.dart';
import '../models/food_item.dart';
import '../utils/constants.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(foodLogProvider);
    final totals = ref.read(foodLogProvider.notifier).getDailyTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                ref.read(foodLogProvider.notifier).loadLogs(date);
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          _SummaryCard(totals: totals),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  title: Text(log.foodName),
                  subtitle: Text('${log.type.name.toUpperCase()} • ${log.quantity}g'),
                  trailing: Text('${log.calories.toStringAsFixed(0)} kcal'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        onPressed: () => _showAddMealDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddMealDialog(BuildContext context) {
    final pantry = ref.read(pantryProvider);
    FoodItem? selectedItem;
    MealType selectedType = MealType.breakfast;
    final quantityController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Log a Meal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<FoodItem>(
                hint: const Text('Select food from pantry'),
                value: selectedItem,
                isExpanded: true,
                items: pantry.map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item.name),
                )).toList(),
                onChanged: (val) => setDialogState(() => selectedItem = val),
              ),
              DropdownButton<MealType>(
                value: selectedType,
                isExpanded: true,
                items: MealType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                )).toList(),
                onChanged: (val) => setDialogState(() => selectedType = val!),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity (grams/units)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (selectedItem != null) {
                  ref.read(foodLogProvider.notifier).addMeal(
                    selectedItem!,
                    double.tryParse(quantityController.text) ?? 100,
                    selectedType,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, double> totals;
  const _SummaryCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '${totals['calories']?.toStringAsFixed(0)} kcal',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Text('Total Calories Today', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NutrientMini('Protein', '${totals['protein']?.toStringAsFixed(1)}g'),
              _NutrientMini('Carbs', '${totals['carbs']?.toStringAsFixed(1)}g'),
              _NutrientMini('Fat', '${totals['fat']?.toStringAsFixed(1)}g'),
            ],
          )
        ],
      ),
    );
  }

  Widget _NutrientMini(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

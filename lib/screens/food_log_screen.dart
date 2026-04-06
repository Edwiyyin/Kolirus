import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_log_provider.dart';
import '../providers/pantry_provider.dart';
import '../models/meal_log.dart'; // Ensure MealType is defined here
import '../models/food_item.dart';
import '../utils/constants.dart';

// If MealType is not defined in meal_log.dart, uncomment the line below:
 enum MealType { breakfast, lunch, dinner, snack }

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
    final totals = ref.watch(foodLogProvider.notifier).getDailyTotals();

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
            child: logs.isEmpty
                ? const Center(child: Text('No meals logged for this day', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  color: AppColors.card,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      log.type == MealType.breakfast ? Icons.wb_sunny_outlined :
                      log.type == MealType.lunch ? Icons.wb_cloudy_outlined :
                      log.type == MealType.dinner ? Icons.nights_stay_outlined : Icons.apple,
                      color: AppColors.olive,
                    ),
                    title: Text(log.foodName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${log.type.name.toUpperCase()} • ${log.quantity}g'),
                    trailing: Text('${log.calories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.olive,
        onPressed: () => _showAddMealDialog(context),
        child: const Icon(Icons.add, color: Colors.black),
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
          backgroundColor: AppColors.card,
          title: const Text('Log a Meal', style: TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FoodItem>(
                  decoration: const InputDecoration(labelText: 'Food from Pantry'),
                  dropdownColor: AppColors.card,
                  value: selectedItem,
                  isExpanded: true,
                  items: pantry.map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item.name, style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedItem = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MealType>(
                  decoration: const InputDecoration(labelText: 'Meal Type'),
                  dropdownColor: AppColors.card,
                  value: selectedType,
                  isExpanded: true,
                  items: MealType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase(), style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Quantity (grams/units)',
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.olive)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
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
              child: const Text('Add', style: TextStyle(color: Colors.black)),
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
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.olive,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
      ),
      child: Column(
        children: [
          Text(
            '${totals['calories']?.toStringAsFixed(0)} kcal',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const Text('TOTAL CALORIES TODAY',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NutrientMini('PROTEIN', '${totals['protein']?.toStringAsFixed(1)}g'),
              _NutrientMini('CARBS', '${totals['carbs']?.toStringAsFixed(1)}g'),
              _NutrientMini('FAT', '${totals['fat']?.toStringAsFixed(1)}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _NutrientMini(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
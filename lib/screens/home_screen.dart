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
                  Text('hello,',
                      style: TextStyle(color: AppColors.textLight, fontSize: 16)),
                  Text('ready to fuel?', style: AppTextStyles.heading1),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showLogMealBottomSheet(context, ref),
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Log Meal',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.olive,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.olive),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${calories.toInt()}',
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.beige)),
                    const Text('kcal',
                        style: TextStyle(
                            color: AppColors.olive,
                            fontWeight: FontWeight.w600)),
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
              _MacroMiniCard(
                  label: 'protein',
                  value: '${totals['protein']?.toInt() ?? 0}g',
                  color: AppColors.olive),
              const SizedBox(width: 12),
              _MacroMiniCard(
                  label: 'carbs',
                  value: '${totals['carbs']?.toInt() ?? 0}g',
                  color: AppColors.olive.withOpacity(0.6)),
              const SizedBox(width: 12),
              _MacroMiniCard(
                  label: 'fat',
                  value: '${totals['fat']?.toInt() ?? 0}g',
                  color: AppColors.olive.withOpacity(0.3)),
            ],
          ),

          const SizedBox(height: 32),
          const Text("today's logs", style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No meals logged today',
                        style: TextStyle(color: Colors.white24))))
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

  void _showLogMealBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _LogMealSheet(),
    );
  }
}

class _LogMealSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends ConsumerState<_LogMealSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pantry = ref.watch(pantryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Text('Log a Meal', style: AppTextStyles.heading1),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.olive,
            labelColor: AppColors.olive,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: 'From Kitchen'),
              Tab(text: 'Manual Entry'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: From Kitchen
                pantry.isEmpty
                    ? const Center(
                    child: Text('Kitchen is empty. Scan items first!',
                        style: TextStyle(color: Colors.white38)))
                    : _KitchenMealPicker(pantry: pantry),

                // Tab 2: Manual Entry
                const _ManualMealEntry(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KitchenMealPicker extends ConsumerStatefulWidget {
  final List<FoodItem> pantry;
  const _KitchenMealPicker({required this.pantry});

  @override
  ConsumerState<_KitchenMealPicker> createState() => _KitchenMealPickerState();
}

class _KitchenMealPickerState extends ConsumerState<_KitchenMealPicker> {
  FoodItem? _selected;
  MealType _mealType = MealType.Lunch;
  final _quantityController = TextEditingController(text: '100');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<FoodItem>(
            value: _selected,
            hint: const Text('Select food from kitchen',
                style: TextStyle(color: Colors.white38)),
            dropdownColor: AppColors.card,
            decoration: const InputDecoration(
                labelText: 'Food item',
                labelStyle: TextStyle(color: AppColors.olive)),
            items: widget.pantry
                .map((item) => DropdownMenuItem(
              value: item,
              child: Text(item.name,
                  style: const TextStyle(color: Colors.white)),
            ))
                .toList(),
            onChanged: (val) => setState(() => _selected = val),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MealType>(
            value: _mealType,
            dropdownColor: AppColors.card,
            decoration: const InputDecoration(
                labelText: 'Meal type',
                labelStyle: TextStyle(color: AppColors.olive)),
            items: MealType.values
                .map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.name,
                    style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (val) => setState(() => _mealType = val!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: 'Quantity (grams)',
                labelStyle: TextStyle(color: AppColors.olive)),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.olive,
                minimumSize: const Size(double.infinity, 50)),
            onPressed: () {
              if (_selected != null) {
                final qty =
                    double.tryParse(_quantityController.text) ?? 100;
                ref
                    .read(foodLogProvider.notifier)
                    .addMeal(_selected!, qty, _mealType);
                Navigator.pop(context);
              }
            },
            child: const Text('Log Meal',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ManualMealEntry extends ConsumerStatefulWidget {
  const _ManualMealEntry();

  @override
  ConsumerState<_ManualMealEntry> createState() => _ManualMealEntryState();
}

class _ManualMealEntryState extends ConsumerState<_ManualMealEntry> {
  final _nameController = TextEditingController();
  final _calController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _sodiumController = TextEditingController();
  MealType _mealType = MealType.Lunch;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: 'Meal name *',
                labelStyle: TextStyle(color: AppColors.olive)),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<MealType>(
            value: _mealType,
            dropdownColor: AppColors.card,
            decoration: const InputDecoration(
                labelText: 'Meal type',
                labelStyle: TextStyle(color: AppColors.olive)),
            items: MealType.values
                .map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.name,
                    style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (val) => setState(() => _mealType = val!),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _calController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: 'Calories (kcal)',
                labelStyle: TextStyle(color: AppColors.olive)),
            keyboardType: TextInputType.number,
          ),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _proteinController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Protein (g)',
                    labelStyle: TextStyle(color: AppColors.olive)),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _carbsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Carbs (g)',
                    labelStyle: TextStyle(color: AppColors.olive)),
                keyboardType: TextInputType.number,
              ),
            ),
          ]),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _fatController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Fat (g)',
                    labelStyle: TextStyle(color: AppColors.olive)),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _fiberController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Fiber (g)',
                    labelStyle: TextStyle(color: AppColors.olive)),
                keyboardType: TextInputType.number,
              ),
            ),
          ]),
          TextField(
            controller: _sodiumController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: 'Sodium (mg)',
                labelStyle: TextStyle(color: AppColors.olive)),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.olive,
                minimumSize: const Size(double.infinity, 50)),
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                final log = MealLog(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  foodItemId: 'manual',
                  foodName: _nameController.text,
                  quantity: 1.0,
                  consumedAt: DateTime.now(),
                  type: _mealType,
                  calories: double.tryParse(_calController.text) ?? 0,
                  protein: double.tryParse(_proteinController.text) ?? 0,
                  carbs: double.tryParse(_carbsController.text) ?? 0,
                  fat: double.tryParse(_fatController.text) ?? 0,
                  fiber: double.tryParse(_fiberController.text) ?? 0,
                  sodium: double.tryParse(_sodiumController.text) ?? 0,
                );
                ref.read(foodLogProvider.notifier).addLog(log);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a meal name')),
                );
              }
            },
            child: const Text('Log Meal',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
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
              decoration: BoxDecoration(
                  color: AppColors.olive.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.restaurant,
                  color: AppColors.olive, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.foodName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(
                    '${log.type.name} • ${DateFormat('hh:mm a').format(log.consumedAt)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Text('${log.calories.toInt()} kcal',
                style: const TextStyle(
                    color: AppColors.olive, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _MacroMiniCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MacroMiniCard(
      {required this.label, required this.value, required this.color});

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
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.beige)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
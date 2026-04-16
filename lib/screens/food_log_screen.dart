import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/food_log_provider.dart';
import '../providers/pantry_provider.dart';
import '../models/meal_log.dart';
import '../models/food_item.dart';
import '../models/meal_type.dart';
import '../utils/constants.dart';
import '../services/database_service.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  DateTime _selectedDate = DateTime.now();
  List<MealLog> _logsForDate = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLogsForDate(_selectedDate);
  }

  Future<void> _loadLogsForDate(DateTime date) async {
    setState(() => _isLoading = true);
    final start =
    DateTime(date.year, date.month, date.day).toIso8601String();
    final end =
    DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final res = await DatabaseService.instance.query(
      'meal_logs',
      where: 'consumedAt BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'consumedAt ASC',
    );
    if (mounted) {
      setState(() {
        _logsForDate = res.map((j) => MealLog.fromMap(j)).toList();
        _selectedDate = date;
        _isLoading = false;
      });
    }
  }

  Map<String, double> _getTotals() {
    double cal = 0, protein = 0, carbs = 0, fat = 0, fiber = 0, sugar = 0,
        sodium = 0;
    for (final l in _logsForDate) {
      cal += l.calories;
      protein += l.protein;
      carbs += l.carbs;
      fat += l.fat;
      fiber += l.fiber;
      sugar += l.sugar;
      sodium += l.sodium;
    }
    return {
      'calories': cal,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
    };
  }

  @override
  Widget build(BuildContext context) {
    final totals = _getTotals();
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal History'),
        actions: [
          if (!isToday)
            IconButton(
              icon: const Icon(Icons.today, color: AppColors.olive),
              tooltip: 'Go to today',
              onPressed: () => _loadLogsForDate(DateTime.now()),
            ),
        ],
      ),
      body: Column(
        children: [
          // Date navigation
          Container(
            color: AppColors.primary,
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: AppColors.olive),
                  onPressed: () => _loadLogsForDate(
                      _selectedDate.subtract(const Duration(days: 1))),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Column(
                      children: [
                        Text(
                          isToday
                              ? 'Today'
                              : DateFormat('EEEE').format(_selectedDate),
                          style: const TextStyle(
                              color: AppColors.olive,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          DateFormat('d MMMM yyyy').format(_selectedDate),
                          style: const TextStyle(
                              color: AppColors.beige, fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: isToday ? Colors.white24 : AppColors.olive,
                  ),
                  onPressed: isToday
                      ? null
                      : () => _loadLogsForDate(
                      _selectedDate.add(const Duration(days: 1))),
                ),
              ],
            ),
          ),

          // Summary card
          if (_logsForDate.isNotEmpty) _SummaryCard(totals: totals),

          // Logs list
          Expanded(
            child: _isLoading
                ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.olive))
                : _logsForDate.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu,
                      size: 52, color: Colors.white12),
                  const SizedBox(height: 16),
                  Text(
                    isToday
                        ? 'No meals logged today yet'
                        : 'No meals on ${DateFormat('d MMM').format(_selectedDate)}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _logsForDate.length,
              itemBuilder: (context, index) {
                final log = _logsForDate[index];
                return Dismissible(
                  key: Key(log.id ?? index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete,
                        color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    if (log.id != null) {
                      await DatabaseService.instance
                          .deleteMealLog(log.id!);
                      // Also refresh the provider if viewing today
                      if (isToday) {
                        ref
                            .read(foodLogProvider.notifier)
                            .loadLogs(DateTime.now());
                      }
                      await _loadLogsForDate(_selectedDate);
                    }
                  },
                  child: _MealLogCard(log: log),
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

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.olive,
              onPrimary: Colors.black,
              surface: AppColors.card,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      _loadLogsForDate(date);
    }
  }

  void _showAddMealDialog(BuildContext context) {
    final pantry = ref.read(pantryProvider);
    FoodItem? selectedItem;
    MealType selectedType = MealType.Lunch;
    final quantityController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Log a Meal',
              style: TextStyle(
                  color: AppColors.olive, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FoodItem>(
                  decoration: const InputDecoration(labelText: 'Food from Kitchen'),
                  dropdownColor: AppColors.card,
                  value: selectedItem,
                  isExpanded: true,
                  items: pantry
                      .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedItem = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MealType>(
                  decoration: const InputDecoration(labelText: 'Meal Type'),
                  dropdownColor: AppColors.card,
                  value: selectedType,
                  isExpanded: true,
                  items: MealType.values
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white)),
                  ))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedType = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Quantity (grams)',
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.olive)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
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
              onPressed: () async {
                if (selectedItem != null) {
                  await ref.read(foodLogProvider.notifier).addMeal(
                    selectedItem!,
                    double.tryParse(quantityController.text) ?? 100,
                    selectedType,
                  );
                  Navigator.pop(context);
                  await _loadLogsForDate(_selectedDate);
                }
              },
              child: const Text('Add',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final Map<String, double> totals;
  const _SummaryCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.olive,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            '${totals['calories']?.toStringAsFixed(0)} kcal',
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
          const Text('TOTAL CALORIES',
              style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NutrientMini('PROTEIN',
                  '${totals['protein']?.toStringAsFixed(1)}g'),
              _NutrientMini(
                  'CARBS', '${totals['carbs']?.toStringAsFixed(1)}g'),
              _NutrientMini(
                  'FAT', '${totals['fat']?.toStringAsFixed(1)}g'),
              _NutrientMini(
                  'FIBER', '${totals['fiber']?.toStringAsFixed(1)}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _NutrientMini(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        Text(label,
            style: const TextStyle(
                color: Colors.black54,
                fontSize: 9,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Meal Log Card ─────────────────────────────────────────────────────────────

class _MealLogCard extends StatelessWidget {
  final MealLog log;
  const _MealLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.olive.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(
              _mealIcon(log.type),
              color: AppColors.olive,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.foodName.toTitleCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${log.type.name.toTitleCase()} · ${log.quantity.toInt()}g · ${DateFormat('HH:mm').format(log.consumedAt)}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    _tag('P: ${log.protein.toInt()}g',
                        Colors.blue.shade300),
                    _tag('C: ${log.carbs.toInt()}g', Colors.amber),
                    _tag('F: ${log.fat.toInt()}g', Colors.redAccent),
                    if (log.fiber > 0)
                      _tag('Fb: ${log.fiber.toInt()}g',
                          Colors.green.shade400),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${log.calories.toStringAsFixed(0)} kcal',
              style: const TextStyle(
                  color: AppColors.olive, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 10)),
  );

  IconData _mealIcon(MealType type) {
    switch (type) {
      case MealType.Breakfast:
        return Icons.wb_sunny_outlined;
      case MealType.Lunch:
        return Icons.wb_cloudy_outlined;
      case MealType.Dinner:
        return Icons.nights_stay_outlined;
      case MealType.Snack:
        return Icons.apple;
    }
  }
}
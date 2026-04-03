import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../models/meal_routine.dart';
import '../providers/routine_provider.dart';
import '../models/recipe.dart';
import '../screens/recipe_screen.dart';
import '../models/meal_type.dart';

class RoutineScreen extends ConsumerStatefulWidget {
  const RoutineScreen({super.key});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  final ScrollController _hourScrollController = ScrollController();
  final ScrollController _dayScrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hourScrollController.jumpTo(8 * 60.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final routineEntries = ref.watch(routineProvider);

    return Column(
      children: [
        // Horizontal Date Selector
        Container(
          height: 90,
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: AppColors.primary,
          child: ListView.builder(
            controller: _dayScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: 60,
            itemBuilder: (context, index) {
              final date = DateTime.now()
                  .subtract(const Duration(days: 30))
                  .add(Duration(days: index));
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              final isToday = DateUtils.isSameDay(date, DateTime.now());

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                  ref.read(routineProvider.notifier).loadRoutine(date);
                },
                child: Container(
                  width: 65,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.olive : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: isToday ? AppColors.olive : Colors.white10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat('E').format(date),
                          style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white38,
                              fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(DateFormat('d').format(date),
                          style: TextStyle(
                              color: isSelected ? Colors.black : AppColors.beige,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Hourly Calendar
        Expanded(
          child: ListView.builder(
            controller: _hourScrollController,
            itemCount: 24,
            itemBuilder: (context, hour) {
              final timeStr = '${hour.toString().padLeft(2, '0')}:00';
              final entriesAtHour =
              routineEntries.where((e) => e.time == timeStr).toList();

              return Container(
                constraints: const BoxConstraints(minHeight: 80),
                decoration: BoxDecoration(
                  border: Border(
                      bottom:
                      BorderSide(color: AppColors.beige.withOpacity(0.05))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: Text(timeStr, style: AppTextStyles.caption),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          ...entriesAtHour.map((entry) =>
                              _RoutineItemTile(entry: entry, onEdit: () => _editEntry(entry))),
                          GestureDetector(
                            onTap: () => _addMealToTime(hour),
                            child: Container(
                              height: 40,
                              width: double.infinity,
                              color: Colors.transparent,
                              child: const Icon(Icons.add,
                                  color: Colors.white10, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _editEntry(MealRoutine entry) {
    if (entry.recipeId != null) {
      // Edit recipe entry - just show name change for now
      _showManualEntryDialog(entry.time ?? '00:00', editEntry: entry);
    } else {
      _showManualEntryDialog(entry.time ?? '00:00', editEntry: entry);
    }
  }

  void _addMealToTime(int hour) {
    final timeStr = '${hour.toString().padLeft(2, '0')}:00';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Plan meal at $timeStr', style: AppTextStyles.heading2),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.book, color: AppColors.olive),
              title: const Text('Add from recipes',
                  style: TextStyle(color: AppColors.beige)),
              onTap: () {
                Navigator.pop(context);
                _showRecipePicker(timeStr);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.olive),
              title: const Text('Manual entry',
                  style: TextStyle(color: AppColors.beige)),
              onTap: () {
                Navigator.pop(context);
                _showManualEntryDialog(timeStr);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showRecipePicker(String time) {
    final recipes = ref.read(recipeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        children: [
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Recipe', style: AppTextStyles.heading2)),
          Expanded(
            child: recipes.isEmpty
                ? const Center(child: Text('No recipes found'))
                : ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final r = recipes[index];
                return ListTile(
                  title: Text(r.name,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: r.calories > 0
                      ? Text('${r.calories.toInt()} kcal',
                      style: AppTextStyles.caption)
                      : null,
                  onTap: () {
                    final entry = MealRoutine(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      date: _selectedDate,
                      mealType: MealType.Lunch,
                      recipeId: r.id,
                      manualEntry: r.name,
                      time: time,
                      calories: r.calories,
                      protein: r.protein,
                      carbs: r.carbs,
                      fat: r.fat,
                    );
                    ref.read(routineProvider.notifier).addEntry(entry);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog(String time, {MealRoutine? editEntry}) {
    final isEditing = editEntry != null;
    final controller =
    TextEditingController(text: editEntry?.manualEntry ?? '');
    final calController = TextEditingController(
        text: editEntry?.calories?.toStringAsFixed(0) ?? '');
    final proteinController = TextEditingController(
        text: editEntry?.protein?.toStringAsFixed(0) ?? '');
    final carbsController = TextEditingController(
        text: editEntry?.carbs?.toStringAsFixed(0) ?? '');
    final fatController =
    TextEditingController(text: editEntry?.fat?.toStringAsFixed(0) ?? '');
    MealType selectedType = editEntry?.mealType ?? MealType.Lunch;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(isEditing ? 'Edit Meal' : 'Meal at $time',
              style: const TextStyle(color: AppColors.beige)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Meal name',
                    labelStyle: TextStyle(color: AppColors.olive),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<MealType>(
                  value: selectedType,
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
                  onChanged: (v) =>
                      setDialogState(() => selectedType = v ?? MealType.Lunch),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: calController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Calories (optional)',
                    labelStyle: TextStyle(color: AppColors.olive),
                  ),
                  keyboardType: TextInputType.number,
                ),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: proteinController,
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
                      controller: carbsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Carbs (g)',
                          labelStyle: TextStyle(color: AppColors.olive)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Fat (g)',
                          labelStyle: TextStyle(color: AppColors.olive)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final entry = MealRoutine(
                    id: isEditing
                        ? editEntry.id
                        : DateTime.now().millisecondsSinceEpoch.toString(),
                    date: isEditing ? editEntry.date : _selectedDate,
                    mealType: selectedType,
                    manualEntry: controller.text,
                    time: time,
                    isEaten: isEditing ? editEntry.isEaten : false,
                    calories: double.tryParse(calController.text),
                    protein: double.tryParse(proteinController.text),
                    carbs: double.tryParse(carbsController.text),
                    fat: double.tryParse(fatController.text),
                  );
                  if (isEditing) {
                    ref.read(routineProvider.notifier).updateEntry(entry);
                  } else {
                    ref.read(routineProvider.notifier).addEntry(entry);
                  }
                }
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Update' : 'Save',
                  style: const TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineItemTile extends ConsumerWidget {
  final MealRoutine entry;
  final VoidCallback onEdit;
  const _RoutineItemTile({required this.entry, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: onEdit,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: entry.isEaten
              ? AppColors.olive.withOpacity(0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: entry.isEaten ? AppColors.olive : Colors.white10),
        ),
        child: Row(
          children: [
            Checkbox(
              value: entry.isEaten,
              activeColor: AppColors.olive,
              onChanged: (_) =>
                  ref.read(routineProvider.notifier).toggleEaten(entry),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.manualEntry ?? 'Meal',
                    style: TextStyle(
                      color: entry.isEaten ? AppColors.olive : Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration:
                      entry.isEaten ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (entry.calories != null && entry.calories! > 0)
                    Text('${entry.calories!.toInt()} kcal',
                        style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.drag_handle, color: Colors.white24, size: 16),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.white24),
              onPressed: () =>
                  ref.read(routineProvider.notifier).removeEntry(entry),
            ),
          ],
        ),
      ),
    );
  }
}
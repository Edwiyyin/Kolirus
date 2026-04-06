import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../models/meal_routine.dart';
import '../providers/routine_provider.dart';
import '../models/recipe.dart';
import '../screens/recipe_screen.dart';
import '../screens/planner_screen.dart';
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
      // Scroll to 8 AM
      if (_hourScrollController.hasClients) {
        _hourScrollController.jumpTo(8 * 60.0);
      }
      // Scroll day strip to today (index 30 of 60)
      if (_dayScrollController.hasClients) {
        _dayScrollController.jumpTo(30 * 77.0);
      }
    });
  }

  @override
  void dispose() {
    _hourScrollController.dispose();
    _dayScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routineEntries = ref.watch(routineProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: _showFullCalendar,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: AppColors.olive, size: 20),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.auto_awesome, color: AppColors.olive, size: 18),
            label: const Text(
              'Auto Plan',
              style: TextStyle(
                color: AppColors.olive,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlannerScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal Date Strip
          _buildDayStrip(),

          // Hourly Calendar — always shown
          Expanded(
            child: _buildHourlyView(routineEntries),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStrip() {
    return Container(
      height: 90,
      color: AppColors.primary,
      child: Column(
        children: [
          Expanded(
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
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.olive
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isToday && !isSelected
                            ? AppColors.olive
                            : Colors.white10,
                        width: isToday && !isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date).toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            color: isSelected ? Colors.black : AppColors.beige,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          GestureDetector(
            onTap: _showFullCalendar,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'View Full Calendar',
                style: TextStyle(
                  color: AppColors.olive.withOpacity(0.7),
                  fontSize: 10,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyView(List<MealRoutine> routineEntries) {
    return ListView.builder(
      controller: _hourScrollController,
      itemCount: 24,
      itemBuilder: (context, hour) {
        final timeStr = '${hour.toString().padLeft(2, '0')}:00';
        final entriesAtHour =
        routineEntries.where((e) => e.time == timeStr).toList();

        return InkWell(
          onTap: () => _addMealToTime(hour),
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.beige.withOpacity(0.05)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hour label
                SizedBox(
                  width: 60,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      timeStr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                // Entries + tap target
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...entriesAtHour.map(
                            (entry) => _RoutineItemTile(
                          entry: entry,
                          onEdit: () => _editEntry(entry),
                        ),
                      ),
                      if (entriesAtHour.isEmpty)
                        Container(height: 60, color: Colors.transparent),
                      if (entriesAtHour.isNotEmpty)
                        Container(
                          height: 28,
                          color: Colors.transparent,
                          child: const Center(
                            child: Icon(Icons.add, color: Colors.white10, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullCalendar() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
      ref.read(routineProvider.notifier).loadRoutine(date);
    }
  }

  void _editEntry(MealRoutine entry) {
    _showManualEntryDialog(entry.time ?? '00:00', editEntry: entry);
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
            Text(
              'Plan Meal At $timeStr'.toTitleCase(),
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.book, color: AppColors.olive),
              title: const Text('Add From Recipes',
                  style: TextStyle(color: AppColors.beige)),
              onTap: () {
                Navigator.pop(context);
                _showRecipePicker(timeStr);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.olive),
              title: const Text('Manual Entry',
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Select Recipe'.toTitleCase(), style: AppTextStyles.heading2),
          ),
          Expanded(
            child: recipes.isEmpty
                ? const Center(
                child: Text('No Recipes Found',
                    style: TextStyle(color: Colors.white38)))
                : ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final r = recipes[index];
                return ListTile(
                  title: Text(r.name.toTitleCase(),
                      style: const TextStyle(color: Colors.white)),
                  subtitle: r.calories > 0
                      ? Text('${r.calories.toInt()} Kcal',
                      style: AppTextStyles.caption)
                      : null,
                  onTap: () {
                    final entry = MealRoutine(
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
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
          title: Text(
            isEditing ? 'Edit Meal' : 'Meal At $time'.toTitleCase(),
            style: const TextStyle(color: AppColors.beige),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Meal Name',
                    labelStyle: TextStyle(color: AppColors.olive),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<MealType>(
                  value: selectedType,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    labelStyle: TextStyle(color: AppColors.olive),
                  ),
                  items: MealType.values
                      .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.name.toTitleCase(),
                          style: const TextStyle(color: Colors.white))))
                      .toList(),
                  onChanged: (v) => setDialogState(
                          () => selectedType = v ?? MealType.Lunch),
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
            if (isEditing)
              TextButton(
                onPressed: () {
                  ref.read(routineProvider.notifier).removeEntry(editEntry);
                  Navigator.pop(context);
                },
                child: const Text('Delete',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
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
              child: Text(
                isEditing ? 'Update' : 'Save',
                style: const TextStyle(color: Colors.black),
              ),
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
        margin: const EdgeInsets.fromLTRB(4, 4, 8, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: entry.isEaten
              ? AppColors.olive.withOpacity(0.12)
              : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: entry.isEaten ? AppColors.olive : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: entry.isEaten,
                activeColor: AppColors.olive,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (_) =>
                    ref.read(routineProvider.notifier).toggleEaten(entry),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (entry.manualEntry ?? 'Meal').toTitleCase(),
                    style: TextStyle(
                      color: entry.isEaten ? AppColors.olive : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      decoration: entry.isEaten
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (entry.calories != null && entry.calories! > 0)
                    Text('${entry.calories!.toInt()} Kcal',
                        style: AppTextStyles.caption),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: Colors.white24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () =>
                  ref.read(routineProvider.notifier).removeEntry(entry),
            ),
          ],
        ),
      ),
    );
  }
}
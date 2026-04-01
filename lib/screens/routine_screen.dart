import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../models/meal_routine.dart';
import '../providers/pantry_provider.dart';

class RoutineScreen extends ConsumerStatefulWidget {
  const RoutineScreen({super.key});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  final ScrollController _hourScrollController = ScrollController();
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  int _selectedDayIndex = DateTime.now().weekday - 1;
  bool _isNextWeek = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hourScrollController.jumpTo(8 * 60.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Week Selector
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('This Week'),
                selected: !_isNextWeek,
                onSelected: (val) => setState(() => _isNextWeek = false),
                selectedColor: AppColors.olive,
                labelStyle: TextStyle(color: !_isNextWeek ? Colors.black : Colors.white),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('Next Week'),
                selected: _isNextWeek,
                onSelected: (val) => setState(() => _isNextWeek = true),
                selectedColor: AppColors.olive,
                labelStyle: TextStyle(color: _isNextWeek ? Colors.black : Colors.white),
              ),
            ],
          ),
        ),
        // Day Selector
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: AppColors.primary,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (context, index) {
              bool isSelected = _selectedDayIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = index),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.olive : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.olive),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_days[index], 
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppColors.beige,
                          fontWeight: FontWeight.bold
                        )
                      ),
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
              return Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.beige.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _addMealToTime(hour),
                        child: Container(
                          color: Colors.transparent,
                          child: const Center(
                            child: Icon(Icons.add, color: Colors.white10, size: 16),
                          ),
                        ),
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

  void _addMealToTime(int hour) {
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
            Text('add meal at ${hour.toString().padLeft(2, '0')}:00', style: AppTextStyles.heading2),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.book, color: AppColors.olive),
              title: const Text('add from recipes', style: TextStyle(color: AppColors.beige)),
              onTap: () {
                Navigator.pop(context);
                _showRecipePicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.olive),
              title: const Text('manual entry', style: TextStyle(color: AppColors.beige)),
              onTap: () {
                Navigator.pop(context);
                _showManualEntryDialog(hour);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showRecipePicker() {
    // Implement recipe selection
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe picker coming soon!')));
  }

  void _showManualEntryDialog(int hour) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Meal at ${hour.toString().padLeft(2, '0')}:00'),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'What are you eating?',
            labelStyle: TextStyle(color: AppColors.olive),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
            onPressed: () {
              // Save to routine provider (need to create one or use DB)
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

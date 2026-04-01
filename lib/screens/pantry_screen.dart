import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pantry_provider.dart';
import '../models/food_item.dart';
import '../utils/constants.dart';

class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantry = ref.watch(pantryProvider);

    final shelfItems = pantry.where((item) => item.location == StorageLocation.shelf).toList();
    final fridgeItems = pantry.where((item) => item.location == StorageLocation.fridge).toList();
    final freezerItems = pantry.where((item) => item.location == StorageLocation.freezer).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _StorageSection(
                  title: 'FREEZER',
                  icon: Icons.ac_unit,
                  items: freezerItems,
                  color: Colors.blueAccent,
                  location: StorageLocation.freezer,
                ),
                _StorageSection(
                  title: 'FRIDGE',
                  icon: Icons.kitchen,
                  items: fridgeItems,
                  color: AppColors.olive,
                  location: StorageLocation.fridge,
                ),
                _StorageSection(
                  title: 'SHELF',
                  icon: Icons.shelves,
                  items: shelfItems,
                  color: AppColors.olive,
                  location: StorageLocation.shelf,
                ),
                const SizedBox(height: 100), // Space for FAB padding
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StorageSection extends ConsumerWidget {
  final String title;
  final IconData icon;
  final List<FoodItem> items;
  final Color color;
  final StorageLocation location;

  const _StorageSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
    required this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.heading2.copyWith(color: color)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add_circle, color: color),
                  onPressed: () => _showAddDialog(context, ref, location),
                ),
                Text('${items.length}', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: items.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(10), child: Text('Empty')))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _PantryItemTile(item: items[index], accentColor: color),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, StorageLocation loc) {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('add to ${loc.name}', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'food name', labelStyle: TextStyle(color: AppColors.olive)),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: calController,
              decoration: const InputDecoration(labelText: 'calories', labelStyle: TextStyle(color: AppColors.olive)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final item = FoodItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    calories: double.tryParse(calController.text) ?? 0,
                    location: loc,
                  );
                  ref.read(pantryProvider.notifier).addItem(item);
                  Navigator.pop(context);
                }
              },
              child: const Text('save', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PantryItemTile extends ConsumerWidget {
  final FoodItem item;
  final Color accentColor;
  const _PantryItemTile({required this.item, required this.accentColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.name, 
                  style: const TextStyle(color: AppColors.beige, fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text('${item.calories.toInt()} kcal', style: AppTextStyles.caption),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                  onPressed: () => ref.read(pantryProvider.notifier).removeItem(item.id!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

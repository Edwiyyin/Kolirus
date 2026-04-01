import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
    return DragTarget<FoodItem>(
      onWillAccept: (data) => data?.location != location,
      onAccept: (item) {
        final updatedItem = FoodItem(
          id: item.id,
          name: item.name,
          barcode: item.barcode,
          brand: item.brand,
          imageUrl: item.imageUrl,
          nutriScore: item.nutriScore,
          allergens: item.allergens,
          location: location,
          expiryDate: item.expiryDate,
          addedDate: item.addedDate,
          calories: item.calories,
          protein: item.protein,
          carbs: item.carbs,
          fat: item.fat,
          saturatedFat: item.saturatedFat,
          sodium: item.sodium,
          cholesterol: item.cholesterol,
          fiber: item.fiber,
          sugar: item.sugar,
        );
        ref.read(pantryProvider.notifier).updateItem(updatedItem);
      },
      builder: (context, candidateData, rejectedData) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: candidateData.isNotEmpty ? color.withOpacity(0.1) : AppColors.primary,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: candidateData.isNotEmpty ? color : color.withOpacity(0.3), 
            width: candidateData.isNotEmpty ? 3 : 2
          ),
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
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Empty', style: TextStyle(color: Colors.white24))))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) => LongPressDraggable<FoodItem>(
                        data: items[index],
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 150,
                            child: _PantryItemTile(item: items[index], accentColor: color, isFeedback: true),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _PantryItemTile(item: items[index], accentColor: color),
                        ),
                        child: _PantryItemTile(item: items[index], accentColor: color),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, StorageLocation loc) {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    String? localImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setModalState(() => localImagePath = image.path);
                  }
                },
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.olive),
                  ),
                  child: localImagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.file(File(localImagePath!), fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: AppColors.olive),
                            Text('Photo', style: TextStyle(color: AppColors.olive, fontSize: 10)),
                          ],
                        ),
                ),
              ),
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
                      imageUrl: localImagePath,
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
      ),
    );
  }
}

class _PantryItemTile extends ConsumerWidget {
  final FoodItem item;
  final Color accentColor;
  final bool isFeedback;

  const _PantryItemTile({
    required this.item, 
    required this.accentColor, 
    this.isFeedback = false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.2)),
        boxShadow: isFeedback ? [const BoxShadow(color: Colors.black54, blurRadius: 10)] : null,
      ),
      child: Stack(
        children: [
          Row(
            children: [
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                  child: _buildImage(item.imageUrl!),
                ),
              Expanded(
                child: Padding(
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
              ),
            ],
          ),
          if (!isFeedback)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                onPressed: () => ref.read(pantryProvider.notifier).removeItem(item.id!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, width: 50, height: double.infinity, fit: BoxFit.cover);
    } else {
      return Image.file(File(path), width: 50, height: double.infinity, fit: BoxFit.cover);
    }
  }
}

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

    final shelfItems =
    pantry.where((item) => item.location == StorageLocation.shelf).toList();
    final fridgeItems =
    pantry.where((item) => item.location == StorageLocation.fridge).toList();
    final freezerItems =
    pantry.where((item) => item.location == StorageLocation.freezer).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _StorageSection(
                  title: 'SHELF',
                  icon: Icons.shelves,
                  items: shelfItems,
                  color: AppColors.beige,
                  location: StorageLocation.shelf,
                ),
                _StorageSection(
                  title: 'FRIDGE',
                  icon: Icons.kitchen,
                  items: fridgeItems,
                  color: AppColors.olive,
                  location: StorageLocation.fridge,
                ),
                _StorageSection(
                  title: 'FREEZER',
                  icon: Icons.ac_unit,
                  items: freezerItems,
                  color: Colors.blueAccent,
                  location: StorageLocation.freezer,
                ),
                const SizedBox(height: 100),
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
          ingredientsText: item.ingredientsText,
          location: location, // Move to new location
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
          potassium: item.potassium,
          magnesium: item.magnesium,
          vitaminC: item.vitaminC,
          vitaminD: item.vitaminD,
          calcium: item.calcium,
          iron: item.iron,
          price: item.price,
        );
        ref.read(pantryProvider.notifier).updateItem(updatedItem);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} moved to ${location.name}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: candidateData.isNotEmpty
              ? color.withOpacity(0.12)
              : AppColors.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: candidateData.isNotEmpty
                ? color
                : color.withOpacity(0.3),
            width: candidateData.isNotEmpty ? 3 : 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Text(title,
                      style: AppTextStyles.heading2.copyWith(color: color)),
                  if (candidateData.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text('Drop here',
                        style: TextStyle(color: color, fontSize: 12)),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: color),
                    onPressed: () =>
                        _showAddDialog(context, ref, location),
                  ),
                  Text('${items.length}',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: items.isEmpty
                  ? const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Empty',
                          style: TextStyle(color: Colors.white24))))
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return LongPressDraggable<FoodItem>(
                    data: item,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: 150,
                        child: _PantryItemTile(
                            item: item,
                            accentColor: color,
                            isFeedback: true),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _PantryItemTile(
                          item: item, accentColor: color),
                    ),
                    child: GestureDetector(
                      onLongPress: () =>
                          _showAddDialog(context, ref, item.location,
                              editItem: item),
                      child: _PantryItemTile(
                          item: item, accentColor: color),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref,
      StorageLocation initialLoc, {FoodItem? editItem}) {
    final isEditing = editItem != null;
    final nameController =
    TextEditingController(text: editItem?.name ?? '');
    final calController =
    TextEditingController(text: editItem?.calories.toString() ?? '');
    final proteinController =
    TextEditingController(text: editItem?.protein.toString() ?? '');
    final carbsController =
    TextEditingController(text: editItem?.carbs.toString() ?? '');
    final fatController =
    TextEditingController(text: editItem?.fat.toString() ?? '');
    final fiberController =
    TextEditingController(text: editItem?.fiber.toString() ?? '');
    final sodiumController =
    TextEditingController(text: editItem?.sodium.toString() ?? '');
    final priceController =
    TextEditingController(text: editItem?.price?.toString() ?? '');
    
    // Additional nutrients
    final potassiumController = TextEditingController(text: editItem?.potassium.toString() ?? '');
    final magnesiumController = TextEditingController(text: editItem?.magnesium.toString() ?? '');
    final vitCController = TextEditingController(text: editItem?.vitaminC.toString() ?? '');
    final vitDController = TextEditingController(text: editItem?.vitaminD.toString() ?? '');
    final calciumController = TextEditingController(text: editItem?.calcium.toString() ?? '');
    final ironController = TextEditingController(text: editItem?.iron.toString() ?? '');

    StorageLocation selectedLoc = initialLoc;
    String? localImagePath = editItem?.imageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEditing ? 'Edit Item' : 'Add Item',
                    style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final XFile? image =
                    await picker.pickImage(source: ImageSource.camera);
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
                      child: localImagePath!.startsWith('http')
                          ? Image.network(localImagePath!,
                          fit: BoxFit.cover)
                          : Image.file(File(localImagePath!),
                          fit: BoxFit.cover),
                    )
                        : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: AppColors.olive),
                        Text('Photo',
                            style: TextStyle(
                                color: AppColors.olive, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<StorageLocation>(
                  value: selectedLoc,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(
                    labelText: 'Storage Location',
                    labelStyle: TextStyle(color: AppColors.olive),
                  ),
                  items: StorageLocation.values.map((loc) {
                    return DropdownMenuItem(
                      value: loc,
                      child: Text(loc.name.toUpperCase(), style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) => setModalState(() => selectedLoc = val!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'food name',
                      labelStyle: TextStyle(color: AppColors.olive)),
                ),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                          controller: calController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              labelText: 'calories',
                              labelStyle: TextStyle(color: AppColors.olive)),
                          keyboardType: TextInputType.number,
                        )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: TextField(
                          controller: proteinController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              labelText: 'protein',
                              labelStyle: TextStyle(color: AppColors.olive)),
                          keyboardType: TextInputType.number,
                        )),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                          controller: carbsController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              labelText: 'carbs',
                              labelStyle: TextStyle(color: AppColors.olive)),
                          keyboardType: TextInputType.number,
                        )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: TextField(
                          controller: fatController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              labelText: 'fat',
                              labelStyle: TextStyle(color: AppColors.olive)),
                          keyboardType: TextInputType.number,
                        )),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                          controller: fiberController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              labelText: 'fiber',
                              labelStyle: TextStyle(color: AppColors.olive)),
                          keyboardType: TextInputType.number,
                        )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: TextField(
                          controller: sodiumController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              labelText: 'sodium',
                              labelStyle: TextStyle(color: AppColors.olive)),
                          keyboardType: TextInputType.number,
                        )),
                  ],
                ),
                TextField(
                  controller: priceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'price',
                      labelStyle: TextStyle(color: AppColors.olive),
                      prefixText: '\$ ',
                      prefixStyle: TextStyle(color: Colors.white)),
                  keyboardType: TextInputType.number,
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white10),
                ),
                const Text('Additional Nutrients', style: TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold)),
                
                Row(
                  children: [
                    Expanded(child: _nutrientField(potassiumController, 'Potassium')),
                    const SizedBox(width: 10),
                    Expanded(child: _nutrientField(magnesiumController, 'Magnesium')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _nutrientField(vitCController, 'Vit C')),
                    const SizedBox(width: 10),
                    Expanded(child: _nutrientField(vitDController, 'Vit D')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _nutrientField(calciumController, 'Calcium')),
                    const SizedBox(width: 10),
                    Expanded(child: _nutrientField(ironController, 'Iron')),
                  ],
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.olive,
                      minimumSize: const Size(double.infinity, 50)),
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      final item = FoodItem(
                        id: isEditing
                            ? editItem.id
                            : DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        name: nameController.text,
                        calories:
                        double.tryParse(calController.text) ?? 0,
                        protein:
                        double.tryParse(proteinController.text) ?? 0,
                        carbs:
                        double.tryParse(carbsController.text) ?? 0,
                        fat: double.tryParse(fatController.text) ?? 0,
                        fiber:
                        double.tryParse(fiberController.text) ??
                            editItem?.fiber ?? 0,
                        sodium:
                        double.tryParse(sodiumController.text) ??
                            editItem?.sodium ?? 0,
                        location: selectedLoc,
                        imageUrl: localImagePath,
                        barcode: editItem?.barcode,
                        brand: editItem?.brand,
                        nutriScore: editItem?.nutriScore,
                        allergens: editItem?.allergens ?? [],
                        ingredientsText: editItem?.ingredientsText,
                        expiryDate: editItem?.expiryDate,
                        addedDate: editItem?.addedDate,
                        saturatedFat: editItem?.saturatedFat ?? 0,
                        cholesterol: editItem?.cholesterol ?? 0,
                        sugar: editItem?.sugar ?? 0,
                        potassium: double.tryParse(potassiumController.text) ?? editItem?.potassium ?? 0,
                        magnesium: double.tryParse(magnesiumController.text) ?? editItem?.magnesium ?? 0,
                        vitaminC: double.tryParse(vitCController.text) ?? editItem?.vitaminC ?? 0,
                        vitaminD: double.tryParse(vitDController.text) ?? editItem?.vitaminD ?? 0,
                        calcium: double.tryParse(calciumController.text) ?? editItem?.calcium ?? 0,
                        iron: double.tryParse(ironController.text) ?? editItem?.iron ?? 0,
                        price: double.tryParse(priceController.text),
                      );
                      if (isEditing) {
                        ref
                            .read(pantryProvider.notifier)
                            .updateItem(item);
                      } else {
                        ref.read(pantryProvider.notifier).addItem(item);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Save',
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nutrientField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 10)),
      keyboardType: TextInputType.number,
    );
  }
}

class _PantryItemTile extends ConsumerWidget {
  final FoodItem item;
  final Color accentColor;
  final bool isFeedback;

  const _PantryItemTile(
      {required this.item,
        required this.accentColor,
        this.isFeedback = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isExpired = item.expiryDate != null && item.expiryDate!.isBefore(DateTime.now());
    final int daysLeft = item.expiryDate != null ? item.expiryDate!.difference(DateTime.now()).inDays : -1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isExpired ? Colors.redAccent : accentColor.withOpacity(0.2)),
        boxShadow: isFeedback
            ? [
          const BoxShadow(
              color: Colors.black54, blurRadius: 10)
        ]
            : null,
      ),
      child: Stack(
        children: [
          Row(
            children: [
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(9)),
                  child: _buildImage(item.imageUrl!),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name.toTitleCase(),
                        style: const TextStyle(
                            color: AppColors.beige,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('${item.calories.toInt()} kcal',
                          style: AppTextStyles.caption),
                      if (item.expiryDate != null)
                        Text(
                          isExpired ? 'Expired' : '$daysLeft days left',
                          style: TextStyle(
                            color: isExpired ? Colors.redAccent : AppColors.olive,
                            fontSize: 10,
                            fontWeight: FontWeight.bold
                          ),
                        ),
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
                icon: const Icon(Icons.close,
                    size: 16, color: Colors.redAccent),
                onPressed: () =>
                    ref.read(pantryProvider.notifier).removeItem(item.id!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, width: 50, height: 60, fit: BoxFit.cover);
    } else {
      return Image.file(File(path), width: 50, height: 60, fit: BoxFit.cover);
    }
  }
}

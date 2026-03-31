import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pantry_provider.dart';
import '../models/food_item.dart';
import '../utils/constants.dart';

class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantryItems = ref.watch(pantryProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Pantry'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.kitchen), text: 'Fridge'),
              Tab(icon: Icon(Icons.shelves), text: 'Shelf'),
              Tab(icon: Icon(Icons.ac_unit), text: 'Freezer'),
            ],
            indicatorColor: AppColors.accent,
            labelColor: AppColors.card,
            unselectedLabelColor: AppColors.accent,
          ),
        ),
        body: TabBarView(
          children: [
            _PantryList(items: pantryItems.where((i) => i.location == StorageLocation.fridge).toList()),
            _PantryList(items: pantryItems.where((i) => i.location == StorageLocation.shelf).toList()),
            _PantryList(items: pantryItems.where((i) => i.location == StorageLocation.freezer).toList()),
          ],
        ),
      ),
    );
  }
}

class _PantryList extends ConsumerWidget {
  final List<FoodItem> items;
  const _PantryList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(child: Text('No items here', style: AppTextStyles.body));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isExpired = item.expiryDate != null && item.expiryDate!.isBefore(DateTime.now());
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: item.imageUrl != null 
              ? Image.network(item.imageUrl!, width: 50, errorBuilder: (_, __, ___) => const Icon(Icons.fastfood))
              : const Icon(Icons.fastfood, size: 40, color: AppColors.secondary),
            title: Text(item.name, style: AppTextStyles.heading2),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.brand != null) Text(item.brand!, style: AppTextStyles.caption),
                if (item.expiryDate != null)
                  Text(
                    'Expires: ${item.expiryDate!.toLocal().toString().split(' ')[0]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? AppColors.danger : AppColors.textLight,
                      fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () => ref.read(pantryProvider.notifier).removeItem(item.id!),
            ),
            onTap: () => _showItemDetails(context, item),
          ),
        );
      },
    );
  }

  void _showItemDetails(BuildContext context, FoodItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: AppTextStyles.heading1),
            const SizedBox(height: 10),
            _NutrientRow('Calories', '${item.calories.toStringAsFixed(1)} kcal'),
            _NutrientRow('Protein', '${item.protein.toStringAsFixed(1)}g'),
            _NutrientRow('Carbs', '${item.carbs.toStringAsFixed(1)}g'),
            _NutrientRow('Fat', '${item.fat.toStringAsFixed(1)}g'),
            _NutrientRow('Sugar', '${item.sugar.toStringAsFixed(1)}g'),
            const SizedBox(height: 20),
            if (item.nutriScore != null)
              Row(
                children: [
                  const Text('Nutri-Score: ', style: AppTextStyles.heading2),
                  Chip(label: Text(item.nutriScore!), backgroundColor: Colors.orange.shade200),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _NutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

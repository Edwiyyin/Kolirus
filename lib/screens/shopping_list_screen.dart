import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shopping_provider.dart';
import '../utils/constants.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingList = ref.watch(shoppingProvider);
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: () {
              // Clear completed items logic could go here
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add item...',
                hintStyle: const TextStyle(color: Colors.white38),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.olive),
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      ref.read(shoppingProvider.notifier).addItem(controller.text);
                      controller.clear();
                    }
                  },
                ),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.olive)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.beige)),
              ),
              onSubmitted: (val) {
                if (val.isNotEmpty) {
                  ref.read(shoppingProvider.notifier).addItem(val);
                  controller.clear();
                }
              },
            ),
          ),
          Expanded(
            child: shoppingList.isEmpty
                ? const Center(child: Text('Your list is empty', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: shoppingList.length,
                    itemBuilder: (context, index) {
                      final item = shoppingList[index];
                      final bool isCompleted = item['isCompleted'] == 1;
                      return ListTile(
                        leading: Checkbox(
                          value: isCompleted,
                          activeColor: AppColors.olive,
                          onChanged: (val) {
                            ref.read(shoppingProvider.notifier).toggleItem(item['id'], val ?? false);
                          },
                        ),
                        title: Text(
                          item['name'],
                          style: TextStyle(
                            color: isCompleted ? Colors.white38 : Colors.white,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white24, size: 20),
                          onPressed: () => ref.read(shoppingProvider.notifier).removeItem(item['id']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

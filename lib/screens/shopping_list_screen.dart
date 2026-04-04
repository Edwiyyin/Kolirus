import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shopping_provider.dart';
import '../utils/constants.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  String _selectedGroupId = 'default';

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(shoppingProvider);
    final groups = ref.watch(shoppingGroupsProvider);
    final groupItems = allItems.where((i) => i['listId'] == _selectedGroupId).toList();
    final controller = TextEditingController();

    return Scaffold(
      body: Column(
        children: [
          // Custom Header for Groups
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: groups.map((g) {
                        final isSelected = g['id'] == _selectedGroupId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(g['name'], style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (s) => setState(() => _selectedGroupId = g['id']),
                            selectedColor: AppColors.olive.withOpacity(0.3),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined, size: 20, color: AppColors.olive),
                  onPressed: () => _showAddGroupDialog(),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Add to this list...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.olive),
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      ref.read(shoppingProvider.notifier).addItem(controller.text, listId: _selectedGroupId);
                      controller.clear();
                    }
                  },
                ),
              ),
              onSubmitted: (val) {
                if (val.isNotEmpty) {
                  ref.read(shoppingProvider.notifier).addItem(val, listId: _selectedGroupId);
                  controller.clear();
                }
              },
            ),
          ),
          
          Expanded(
            child: groupItems.isEmpty
                ? const Center(child: Text('Empty list', style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    itemCount: groupItems.length,
                    itemBuilder: (context, index) {
                      final item = groupItems[index];
                      final isComp = item['isCompleted'] == 1;
                      return ListTile(
                        leading: Checkbox(
                          value: isComp,
                          onChanged: (v) => ref.read(shoppingProvider.notifier).toggleItem(item['id'], v ?? false),
                        ),
                        title: Text(item['name'], style: TextStyle(
                          decoration: isComp ? TextDecoration.lineThrough : null,
                          color: isComp ? Colors.white24 : Colors.white,
                        )),
                        subtitle: item['notes'] != null ? Text(item['notes'], style: const TextStyle(fontSize: 10)) : null,
                        trailing: Text('${item['quantity']?.toString().replaceAll('.0', '') ?? 1}x', style: const TextStyle(color: AppColors.olive)),
                        onLongPress: () => _showEditItemDialog(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialog() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('New Shopping List'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'e.g. Weekly Groceries')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (c.text.isNotEmpty) {
              ref.read(shoppingGroupsProvider.notifier).addGroup(c.text);
              Navigator.pop(context);
            }
          }, child: const Text('Create')),
        ],
      ),
    );
  }

  void _showEditItemDialog(Map<String, dynamic> item) {
    final nameC = TextEditingController(text: item['name']);
    final qtyC = TextEditingController(text: item['quantity']?.toString() ?? '1');
    final noteC = TextEditingController(text: item['notes'] ?? '');
    final aisleC = TextEditingController(text: item['category'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit Item', style: AppTextStyles.heading2),
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name')),
            Row(
              children: [
                Expanded(child: TextField(controller: qtyC, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: aisleC, decoration: const InputDecoration(labelText: 'Aisle/Category'))),
              ],
            ),
            TextField(controller: noteC, decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () {
                  ref.read(shoppingProvider.notifier).removeItem(item['id']);
                  Navigator.pop(context);
                }, child: const Text('Delete', style: TextStyle(color: Colors.redAccent)))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () {
                  final updated = Map<String, dynamic>.from(item);
                  updated['name'] = nameC.text;
                  updated['quantity'] = double.tryParse(qtyC.text) ?? 1.0;
                  updated['notes'] = noteC.text;
                  updated['category'] = aisleC.text;
                  ref.read(shoppingProvider.notifier).updateItem(updated);
                  Navigator.pop(context);
                }, child: const Text('Save'))),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

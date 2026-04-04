import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/pantry_provider.dart';
import '../models/food_item.dart';
import '../utils/constants.dart';

// ─── helpers ──────────────────────────────────────────────────────────────────

({String label, Color color, IconData icon}) _expiryStatus(DateTime? expiry) {
  if (expiry == null) {
    return (label: 'No expiry set', color: Colors.white24, icon: Icons.event_outlined);
  }
  final days = expiry.difference(DateTime.now()).inDays;
  if (days < 0)  return (label: 'Expired!',                                      color: Colors.red,          icon: Icons.dangerous_outlined);
  if (days == 0) return (label: 'Expires today!',                                 color: Colors.redAccent,    icon: Icons.warning_amber_rounded);
  if (days <= 2) return (label: '$days day${days == 1 ? '' : 's'} left!',        color: Colors.orangeAccent, icon: Icons.warning_amber_rounded);
  if (days <= 5) return (label: '$days days left — notif set',                   color: Colors.amber,        icon: Icons.notifications_active_outlined);
  return         (label: '$days days left',                                        color: AppColors.olive,     icon: Icons.event_available_outlined);
}

String _fmtDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

// ─── screen ───────────────────────────────────────────────────────────────────

class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantry = ref.watch(pantryProvider);

    final shelfItems   = pantry.where((i) => i.location == StorageLocation.shelf).toList();
    final fridgeItems  = pantry.where((i) => i.location == StorageLocation.fridge).toList();
    final freezerItems = pantry.where((i) => i.location == StorageLocation.freezer).toList();

    final expiringItems = pantry.where((i) {
      if (i.expiryDate == null) return false;
      final days = i.expiryDate!.difference(DateTime.now()).inDays;
      return days >= 0 && days <= 5;
    }).toList()
      ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

    return Column(
      children: [
        // ── expiry warning banner ──────────────────────────────────────────
        if (expiringItems.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.notifications_active, color: Colors.orangeAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${expiringItems.length} item${expiringItems.length == 1 ? '' : 's'} expiring soon',
                    style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ]),
                const SizedBox(height: 6),
                ...expiringItems.map((item) {
                  final s = _expiryStatus(item.expiryDate);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      Icon(s.icon, color: s.color, size: 13),
                      const SizedBox(width: 6),
                      Expanded(child: Text(item.name.toTitleCase(),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis)),
                      Text(s.label, style: TextStyle(color: s.color, fontSize: 11, fontWeight: FontWeight.bold)),
                    ]),
                  );
                }),
              ],
            ),
          ),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _StorageSection(title: 'SHELF',   icon: Icons.shelves,  items: shelfItems,   color: AppColors.beige,   location: StorageLocation.shelf),
                _StorageSection(title: 'FRIDGE',  icon: Icons.kitchen,  items: fridgeItems,  color: AppColors.olive,   location: StorageLocation.fridge),
                _StorageSection(title: 'FREEZER', icon: Icons.ac_unit,  items: freezerItems, color: AppColors.freezer, location: StorageLocation.freezer),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── storage section ──────────────────────────────────────────────────────────

class _StorageSection extends ConsumerWidget {
  final String title;
  final IconData icon;
  final List<FoodItem> items;
  final Color color;
  final StorageLocation location;
  const _StorageSection({required this.title, required this.icon, required this.items, required this.color, required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<FoodItem>(
      onWillAccept: (data) => data?.location != location,
      onAccept: (item) {
        final updated = FoodItem(
          id: item.id, name: item.name, barcode: item.barcode, brand: item.brand,
          imageUrl: item.imageUrl, nutriScore: item.nutriScore,
          allergens: item.allergens, ingredientsText: item.ingredientsText,
          location: location, expiryDate: item.expiryDate, addedDate: item.addedDate,
          calories: item.calories, protein: item.protein, carbs: item.carbs,
          fat: item.fat, saturatedFat: item.saturatedFat, sodium: item.sodium,
          cholesterol: item.cholesterol, fiber: item.fiber, sugar: item.sugar,
          potassium: item.potassium, magnesium: item.magnesium,
          vitaminC: item.vitaminC, vitaminD: item.vitaminD,
          calcium: item.calcium, iron: item.iron, price: item.price,
        );
        ref.read(pantryProvider.notifier).updateItem(updated);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${item.name} moved to ${location.name}'),
          duration: const Duration(seconds: 1),
        ));
      },
      builder: (context, candidateData, _) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: candidateData.isNotEmpty ? color.withOpacity(0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: candidateData.isNotEmpty ? color : color.withOpacity(0.3),
            width: candidateData.isNotEmpty ? 3 : 2,
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
              child: Row(children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.heading2.copyWith(color: color)),
                if (candidateData.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('Drop here', style: TextStyle(color: color, fontSize: 12)),
                ],
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add_circle, color: color),
                  onPressed: () => _showAddDialog(context, ref, location),
                ),
                Text('${items.length}', style: const TextStyle(color: Colors.white)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: items.isEmpty
                  ? const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Empty', style: TextStyle(color: Colors.white24))))
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 1.8,
                  crossAxisSpacing: 10, mainAxisSpacing: 10,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return LongPressDraggable<FoodItem>(
                    data: item,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(width: 150,
                          child: _PantryItemTile(item: item, accentColor: color, isFeedback: true)),
                    ),
                    childWhenDragging: Opacity(opacity: 0.3,
                        child: _PantryItemTile(item: item, accentColor: color)),
                    child: GestureDetector(
                      onLongPress: () => _showAddDialog(context, ref, item.location, editItem: item),
                      child: _PantryItemTile(item: item, accentColor: color),
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

  // ── add / edit bottom sheet ────────────────────────────────────────────────

  void _showAddDialog(BuildContext context, WidgetRef ref,
      StorageLocation initialLoc, {FoodItem? editItem}) {
    final isEditing = editItem != null;

    final nameCtrl      = TextEditingController(text: editItem?.name ?? '');
    final calCtrl       = TextEditingController(text: editItem != null && editItem.calories   != 0 ? editItem.calories.toString()   : '');
    final proteinCtrl   = TextEditingController(text: editItem != null && editItem.protein    != 0 ? editItem.protein.toString()    : '');
    final carbsCtrl     = TextEditingController(text: editItem != null && editItem.carbs      != 0 ? editItem.carbs.toString()      : '');
    final fatCtrl       = TextEditingController(text: editItem != null && editItem.fat        != 0 ? editItem.fat.toString()        : '');
    final fiberCtrl     = TextEditingController(text: editItem != null && editItem.fiber      != 0 ? editItem.fiber.toString()      : '');
    final sodiumCtrl    = TextEditingController(text: editItem != null && editItem.sodium     != 0 ? editItem.sodium.toString()     : '');
    final priceCtrl     = TextEditingController(text: editItem?.price?.toString() ?? '');
    final potassiumCtrl = TextEditingController(text: editItem != null && editItem.potassium  != 0 ? editItem.potassium.toString()  : '');
    final magnesiumCtrl = TextEditingController(text: editItem != null && editItem.magnesium  != 0 ? editItem.magnesium.toString()  : '');
    final vitCCtrl      = TextEditingController(text: editItem != null && editItem.vitaminC   != 0 ? editItem.vitaminC.toString()   : '');
    final vitDCtrl      = TextEditingController(text: editItem != null && editItem.vitaminD   != 0 ? editItem.vitaminD.toString()   : '');
    final calciumCtrl   = TextEditingController(text: editItem != null && editItem.calcium    != 0 ? editItem.calcium.toString()    : '');
    final ironCtrl      = TextEditingController(text: editItem != null && editItem.iron       != 0 ? editItem.iron.toString()       : '');

    StorageLocation selectedLoc = initialLoc;
    String? localImagePath = editItem?.imageUrl;
    DateTime? expiryDate = editItem?.expiryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 16,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                Text(isEditing ? 'Edit Item' : 'Add Item', style: AppTextStyles.heading2),
                const SizedBox(height: 16),

                // photo
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final XFile? img = await picker.pickImage(source: ImageSource.camera);
                    if (img != null) setModal(() => localImagePath = img.path);
                  },
                  child: Container(
                    height: 88, width: 88,
                    decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.olive)),
                    child: localImagePath != null
                        ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: localImagePath!.startsWith('http')
                            ? Image.network(localImagePath!, fit: BoxFit.cover)
                            : Image.file(File(localImagePath!), fit: BoxFit.cover))
                        : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: AppColors.olive),
                          Text('Photo', style: TextStyle(color: AppColors.olive, fontSize: 10)),
                        ]),
                  ),
                ),
                const SizedBox(height: 16),

                // storage location
                DropdownButtonFormField<StorageLocation>(
                  value: selectedLoc,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(
                    labelText: 'Storage Location',
                    labelStyle: TextStyle(color: AppColors.olive),
                  ),
                  items: StorageLocation.values
                      .map((loc) => DropdownMenuItem(
                      value: loc,
                      child: Text(loc.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white))))
                      .toList(),
                  onChanged: (val) => setModal(() => selectedLoc = val!),
                ),
                const SizedBox(height: 14),

                // ── EXPIRY DATE CARD ───────────────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.olive,
                            onPrimary: Colors.black,
                            surface: AppColors.card,
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setModal(() => expiryDate = picked);
                  },
                  child: _ExpiryDateCard(
                    expiryDate: expiryDate,
                    onClear: expiryDate != null ? () => setModal(() => expiryDate = null) : null,
                  ),
                ),
                const SizedBox(height: 14),

                // food name
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Food Name *',
                    labelStyle: TextStyle(color: AppColors.olive),
                  ),
                ),
                const SizedBox(height: 4),

                // macros
                _row2(_numField(calCtrl,    'Calories (kcal)'), _numField(proteinCtrl, 'Protein (g)')),
                _row2(_numField(carbsCtrl,  'Carbs (g)'),       _numField(fatCtrl,     'Fat (g)')),
                _row2(_numField(fiberCtrl,  'Fiber (g)'),       _numField(sodiumCtrl,  'Sodium (mg)')),
                _numField(priceCtrl, 'Price (€)'),

                // extra nutrients divider
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(children: [
                    Expanded(child: Divider(color: Colors.white10)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Extra Nutrients',
                          style: TextStyle(color: AppColors.olive, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider(color: Colors.white10)),
                  ]),
                ),
                _row2(_miniField(potassiumCtrl, 'Potassium'), _miniField(magnesiumCtrl, 'Magnesium')),
                _row2(_miniField(vitCCtrl, 'Vit C (mg)'),     _miniField(vitDCtrl,      'Vit D (µg)')),
                _row2(_miniField(calciumCtrl, 'Calcium'),      _miniField(ironCtrl,     'Iron')),
                const SizedBox(height: 20),

                // save
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.olive,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.isEmpty) return;
                    final item = FoodItem(
                      id: isEditing ? editItem.id : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text,
                      calories:   _d(calCtrl)     ?? editItem?.calories     ?? 0,
                      protein:    _d(proteinCtrl) ?? editItem?.protein      ?? 0,
                      carbs:      _d(carbsCtrl)   ?? editItem?.carbs        ?? 0,
                      fat:        _d(fatCtrl)     ?? editItem?.fat          ?? 0,
                      fiber:      _d(fiberCtrl)   ?? editItem?.fiber        ?? 0,
                      sodium:     _d(sodiumCtrl)  ?? editItem?.sodium       ?? 0,
                      potassium:  _d(potassiumCtrl) ?? editItem?.potassium  ?? 0,
                      magnesium:  _d(magnesiumCtrl) ?? editItem?.magnesium  ?? 0,
                      vitaminC:   _d(vitCCtrl)    ?? editItem?.vitaminC     ?? 0,
                      vitaminD:   _d(vitDCtrl)    ?? editItem?.vitaminD     ?? 0,
                      calcium:    _d(calciumCtrl) ?? editItem?.calcium      ?? 0,
                      iron:       _d(ironCtrl)    ?? editItem?.iron         ?? 0,
                      price:      _d(priceCtrl),
                      location:   selectedLoc,
                      imageUrl:   localImagePath,
                      expiryDate: expiryDate,
                      barcode:          editItem?.barcode,
                      brand:            editItem?.brand,
                      nutriScore:       editItem?.nutriScore,
                      allergens:        editItem?.allergens ?? [],
                      ingredientsText:  editItem?.ingredientsText,
                      addedDate:        editItem?.addedDate,
                      saturatedFat:     editItem?.saturatedFat ?? 0,
                      cholesterol:      editItem?.cholesterol  ?? 0,
                      sugar:            editItem?.sugar        ?? 0,
                    );
                    if (isEditing) {
                      ref.read(pantryProvider.notifier).updateItem(item);
                    } else {
                      ref.read(pantryProvider.notifier).addItem(item);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(isEditing ? 'Update Item' : 'Save Item',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // helpers
  double? _d(TextEditingController c) => c.text.isEmpty ? null : double.tryParse(c.text);

  Widget _row2(Widget a, Widget b) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)]),
  );

  Widget _numField(TextEditingController c, String label) => TextField(
    controller: c,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: AppColors.olive)),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
  );

  Widget _miniField(TextEditingController c, String label) => TextField(
    controller: c,
    style: const TextStyle(color: Colors.white, fontSize: 12),
    decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 10)),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
  );
}

// ─── expiry date card ─────────────────────────────────────────────────────────

class _ExpiryDateCard extends StatelessWidget {
  final DateTime? expiryDate;
  final VoidCallback? onClear;
  const _ExpiryDateCard({this.expiryDate, this.onClear});

  @override
  Widget build(BuildContext context) {
    final s   = _expiryStatus(expiryDate);
    final set = expiryDate != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:  set ? s.color.withOpacity(0.08) : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: set ? s.color.withOpacity(0.55) : Colors.white12,
          width: set ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // circle icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (set ? s.color : Colors.white24).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            set ? s.icon : Icons.event_outlined,
            color: set ? s.color : Colors.white38,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        // text column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expiry Date',
                style: TextStyle(
                  color: set ? s.color : Colors.white38,
                  fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                set ? _fmtDate(expiryDate!) : 'Tap to set expiry date',
                style: TextStyle(
                  color: set ? Colors.white : Colors.white38,
                  fontSize: 15,
                  fontWeight: set ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (set)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(children: [
                    Container(
                      width: 6, height: 6,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                    ),
                    Text(s.label,
                        style: TextStyle(color: s.color, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
            ],
          ),
        ),
        // clear / chevron
        if (set && onClear != null)
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.white38),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onClear,
          )
        else
          const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      ]),
    );
  }
}

// ─── pantry item tile ─────────────────────────────────────────────────────────

class _PantryItemTile extends ConsumerWidget {
  final FoodItem item;
  final Color accentColor;
  final bool isFeedback;
  const _PantryItemTile({required this.item, required this.accentColor, this.isFeedback = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s        = _expiryStatus(item.expiryDate);
    final hasExpiry = item.expiryDate != null;
    final isExpired = hasExpiry && item.expiryDate!.isBefore(DateTime.now());
    final warnColor = isExpired
        ? Colors.redAccent
        : hasExpiry && item.expiryDate!.difference(DateTime.now()).inDays <= 5
        ? s.color
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: warnColor != null
              ? warnColor.withOpacity(0.6)
              : accentColor.withOpacity(0.2),
          width: warnColor != null ? 1.4 : 1,
        ),
        boxShadow: isFeedback
            ? [const BoxShadow(color: Colors.black54, blurRadius: 10)]
            : null,
      ),
      child: Stack(
        children: [
          Row(
            children: [
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                  child: _img(item.imageUrl!),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name.toTitleCase(),
                        style: const TextStyle(
                            color: AppColors.beige, fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('${item.calories.toInt()} kcal', style: AppTextStyles.caption),
                      if (hasExpiry)
                        Row(children: [
                          Icon(s.icon, size: 10, color: s.color),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              s.label,
                              style: TextStyle(color: s.color, fontSize: 10, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!isFeedback)
            Positioned(
              top: 0, right: 0,
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

  Widget _img(String path) {
    if (path.startsWith('http')) return Image.network(path, width: 50, height: 60, fit: BoxFit.cover);
    return Image.file(File(path), width: 50, height: 60, fit: BoxFit.cover);
  }
}
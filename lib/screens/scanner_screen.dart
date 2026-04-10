import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/food_api_service.dart';
import '../services/database_service.dart';
import '../models/food_item.dart';
import '../providers/pantry_provider.dart';
import '../providers/scan_history_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import 'dart:convert';

// Allergen keyword mapping
const Map<String, List<String>> _allergenKeywords = {
  'gluten': ['gluten', 'wheat', 'barley', 'rye', 'oat', 'spelt', 'kamut', 'farro', 'semolina', 'farina', 'einkorn', 'durum'],
  'milk': ['milk', 'dairy', 'lactose', 'cheese', 'butter', 'cream', 'whey', 'casein', 'fromage'],
  'eggs': ['egg', 'ovum', 'albumin', 'lysozyme', 'mayonnaise'],
  'nuts': ['nuts', 'almond', 'cashew', 'walnut', 'pecan', 'pistachio', 'macadamia', 'hazelnut', 'brazil nut'],
  'peanuts': ['peanut', 'groundnut', 'arachide'],
  'sesame': ['sesame', 'tahini', 'sesamum'],
  'soybeans': ['soy', 'soya', 'tofu', 'tempeh', 'miso', 'edamame'],
  'fish': ['fish', 'cod', 'salmon', 'tuna', 'halibut', 'anchovy', 'sardine', 'herring', 'trout', 'bass'],
  'shellfish': ['shellfish', 'shrimp', 'crab', 'lobster', 'prawn', 'crayfish', 'scallop', 'oyster', 'mussel', 'clam'],
  'celery': ['celery', 'celeriac'],
  'mustard': ['mustard'],
  'lupin': ['lupin', 'lupine'],
  'molluscs': ['mollusc', 'mollusk', 'squid', 'octopus', 'snail', 'scallop'],
  'sulphites': ['sulphite', 'sulfite', 'sulphur dioxide', 'so2'],
};

// Dietary restriction keywords
const Map<String, List<String>> _dietaryViolationKeywords = {
  'vegan': ['meat', 'beef', 'pork', 'chicken', 'turkey', 'fish', 'seafood', 'milk', 'dairy', 'egg', 'cheese', 'butter', 'cream', 'honey', 'gelatin', 'lard'],
  'vegetarian': ['meat', 'beef', 'pork', 'chicken', 'turkey', 'fish', 'seafood', 'gelatin', 'lard', 'rennet'],
  'paleo': ['grain', 'wheat', 'rice', 'corn', 'oat', 'legume', 'bean', 'lentil', 'soy', 'dairy', 'sugar', 'processed'],
  'keto': ['sugar', 'glucose', 'fructose', 'corn syrup', 'maltose', 'wheat', 'rice', 'corn', 'potato', 'bread'],
  'mediterranean': ['trans fat', 'hydrogenated', 'artificial', 'processed meat', 'red meat'],
  'low-carb': ['sugar', 'glucose', 'fructose', 'corn syrup', 'wheat', 'rice', 'starch', 'bread', 'pasta'],
};

const Map<String, List<String>> _religiousViolationKeywords = {
  'halal': ['pork', 'pig', 'lard', 'bacon', 'ham', 'alcohol', 'wine', 'beer', 'spirits'],
  'kosher': ['pork', 'pig', 'lard', 'bacon', 'ham', 'shellfish', 'shrimp', 'crab', 'lobster', 'rabbit'],
  'christian lent': ['meat', 'beef', 'pork', 'chicken', 'turkey'],
  'orthodox lent': ['meat', 'dairy', 'egg', 'fish', 'oil', 'wine'],
  'hindu vegetarian': ['beef', 'veal', 'meat', 'pork', 'chicken', 'egg'],
  'jain': ['meat', 'fish', 'egg', 'onion', 'garlic', 'potato', 'carrot', 'beet'],
  'buddhist vegetarian': ['meat', 'fish', 'egg', 'onion', 'garlic', 'leek', 'chive'],
};

// ── The scan state lives here so _showProductDialog can use ref.watch ─────────

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final FoodApiService _apiService = FoodApiService();
  bool _isProcessing = false;
  bool _showHistory = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _showHistory) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() => _isProcessing = true);
        final product = await _apiService.fetchProduct(code);

        if (mounted) {
          if (product != null) {
            ref.read(scanHistoryProvider.notifier).addToHistory(product);
            _showProductDialog(product);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product not found')),
            );
            setState(() => _isProcessing = false);
          }
        }
      }
    }
  }

  // ── Detection helpers (static so _ProductDialog can also use them) ──────────

  static List<String> detectAllergens(FoodItem product, List<String> userAllergies) {
    final searchText = _buildSearchText(product);
    final detected = <String>[];
    for (final userAllergen in userAllergies) {
      final allergenKey = userAllergen.toLowerCase();
      final keywords = _allergenKeywords[allergenKey] ?? [allergenKey];
      if (keywords.any((keyword) => searchText.contains(keyword))) {
        detected.add(userAllergen);
      }
    }
    return detected;
  }

  static List<String> detectDietaryViolations(
      FoodItem product,
      List<String> dietaryPrefs,
      List<String> religiousPrefs,
      ) {
    final searchText = _buildSearchText(product);
    final violations = <String>[];

    for (final pref in dietaryPrefs) {
      final keywords = _dietaryViolationKeywords[pref.toLowerCase()] ?? [];
      if (keywords.any((k) => searchText.contains(k))) {
        violations.add('Not ${pref.toTitleCase()}');
      }
    }

    for (final pref in religiousPrefs) {
      final keywords = _religiousViolationKeywords[pref.toLowerCase()] ?? [];
      if (keywords.any((k) => searchText.contains(k))) {
        violations.add('Violates ${pref.toTitleCase()}');
      }
    }

    return violations;
  }

  static List<String> detectCustomDietViolations(
      FoodItem product,
      List<Map<String, dynamic>> customDiets,
      ) {
    final searchText = _buildSearchText(product);
    final violations = <String>[];

    for (final diet in customDiets) {
      final name = diet['name'] as String? ?? 'Custom Diet';
      final raw = diet['violationKeywords'];
      List<String> keywords = [];
      if (raw is String) {
        try {
          keywords = List<String>.from(jsonDecode(raw));
        } catch (_) {}
      }
      if (keywords.any((k) => searchText.contains(k.toLowerCase()))) {
        violations.add('Violates $name');
      }
    }

    return violations;
  }

  static String _buildSearchText(FoodItem product) {
    return [
      product.name,
      product.brand ?? '',
      product.ingredientsText ?? '',
      ...product.allergens,
    ].join(' ').toLowerCase();
  }

  // ── Product dialog ─────────────────────────────────────────────────────────

  void _showProductDialog(FoodItem product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProductDialog(product: product),
    ).whenComplete(() {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(scanHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Food'),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.camera_alt : Icons.history),
            onPressed: () => setState(() => _showHistory = !_showHistory),
          )
        ],
      ),
      body: Stack(
        children: [
          if (!_showHistory)
            MobileScanner(onDetect: _onDetect),
          if (!_showHistory)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.olive, width: 4),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          if (_showHistory)
            Container(
              color: AppColors.background,
              child: history.isEmpty
                  ? const Center(
                  child: Text('No scan history yet',
                      style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return Card(
                    color: AppColors.card,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: item.imageUrl != null
                          ? Image.network(item.imageUrl!,
                          width: 40, height: 40, fit: BoxFit.cover)
                          : const Icon(Icons.fastfood,
                          color: AppColors.olive),
                      title: Text(item.name,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(item.brand ?? '',
                          style: AppTextStyles.caption),
                      trailing: const Icon(Icons.chevron_right,
                          color: Colors.white24),
                      onTap: () => _showProductDialog(item),
                    ),
                  );
                },
              ),
            ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.olive),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Separate ConsumerWidget so it can use ref.watch for live settings ──────────

class _ProductDialog extends ConsumerStatefulWidget {
  final FoodItem product;
  const _ProductDialog({required this.product});

  @override
  ConsumerState<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<_ProductDialog> {
  StorageLocation _selectedLocation = StorageLocation.shelf;
  DateTime? _selectedExpiry;
  List<Map<String, dynamic>> _customDiets = [];
  bool _customDietsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCustomDiets();
  }

  Future<void> _loadCustomDiets() async {
    final diets = await DatabaseService.instance.getCustomDiets();
    if (mounted) {
      setState(() {
        _customDiets = diets;
        _customDietsLoaded = true;
      });
    }
  }

  Color _getNutriColor(String? score) {
    switch (score?.toLowerCase()) {
      case 'a': return Colors.green.shade700;
      case 'b': return Colors.green.shade400;
      case 'c': return Colors.yellow.shade700;
      case 'd': return Colors.orange.shade700;
      case 'e': return Colors.red.shade700;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ← ref.watch ensures we get the LATEST settings (not a stale snapshot)
    final userSettings = ref.watch(settingsProvider);
    final userAllergies = List<String>.from(userSettings['allergies'] ?? []);
    final userDietary = List<String>.from(userSettings['dietary_prefs'] ?? []);
    final userReligious = List<String>.from(userSettings['religious_prefs'] ?? []);

    final detectedAllergies =
    _ScannerScreenState.detectAllergens(widget.product, userAllergies);
    final dietaryViolations = _ScannerScreenState.detectDietaryViolations(
        widget.product, userDietary, userReligious);
    final customViolations = _customDietsLoaded
        ? _ScannerScreenState.detectCustomDietViolations(
        widget.product, _customDiets)
        : <String>[];

    final hasWarning = detectedAllergies.isNotEmpty ||
        dietaryViolations.isNotEmpty ||
        customViolations.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (widget.product.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(widget.product.imageUrl!,
                      height: 150, fit: BoxFit.cover),
                ),
              const SizedBox(height: 10),
              Text(widget.product.name,
                  style: AppTextStyles.heading1,
                  textAlign: TextAlign.center),
              Text(widget.product.brand ?? '', style: AppTextStyles.caption),

              // ── ALLERGY WARNING ──────────────────────────────────────────
              if (detectedAllergies.isNotEmpty) ...[
                const SizedBox(height: 15),
                _warningBanner(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  title: 'ALLERGY WARNING',
                  message:
                  'Contains: ${detectedAllergies.map((a) => a.toUpperCase()).join(", ")}',
                ),
              ],

              // ── DIETARY / RELIGIOUS WARNING ──────────────────────────────
              if (dietaryViolations.isNotEmpty) ...[
                const SizedBox(height: 10),
                _warningBanner(
                  icon: Icons.block,
                  color: Colors.orangeAccent,
                  title: 'DIET RESTRICTION',
                  message: dietaryViolations.join(' • '),
                ),
              ],

              // ── CUSTOM DIET WARNING ──────────────────────────────────────
              if (customViolations.isNotEmpty) ...[
                const SizedBox(height: 10),
                _warningBanner(
                  icon: Icons.tune,
                  color: Colors.deepOrangeAccent,
                  title: 'CUSTOM DIET',
                  message: customViolations.join(' • '),
                ),
              ],

              // ── ALL CLEAR ────────────────────────────────────────────────
              if (!hasWarning && _customDietsLoaded) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.olive.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.olive, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.olive, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ALL CLEAR',
                                style: TextStyle(
                                    color: AppColors.olive,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.5)),
                            Text(
                              userAllergies.isEmpty &&
                                  userDietary.isEmpty &&
                                  userReligious.isEmpty &&
                                  _customDiets.isEmpty
                                  ? 'No filters set — configure in Settings'
                                  : 'Passes all your active filters',
                              style: const TextStyle(
                                  color: AppColors.olive, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(color: Colors.white12, height: 30),

              // ── Nutri-Score ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nutri-Score',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Chip(
                    label: Text(widget.product.nutriScore ?? 'N/A',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    backgroundColor: _getNutriColor(widget.product.nutriScore),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Nutritional Information (per 100g)',
                    style: TextStyle(
                        color: AppColors.olive, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),

              // Main macros
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _macroHighlight(
                        'Calories', '${widget.product.calories.toInt()}', 'kcal'),
                    _macroHighlight('Protein',
                        '${widget.product.protein.toStringAsFixed(1)}', 'g'),
                    _macroHighlight(
                        'Carbs', '${widget.product.carbs.toStringAsFixed(1)}', 'g'),
                    _macroHighlight(
                        'Fat', '${widget.product.fat.toStringAsFixed(1)}', 'g'),
                  ],
                ),
              ),

              _buildNutrientRow(
                  'Sugars', '${widget.product.sugar.toStringAsFixed(1)} g'),
              _buildNutrientRow('Saturated Fat',
                  '${widget.product.saturatedFat.toStringAsFixed(1)} g'),
              _buildNutrientRow(
                  'Fiber', '${widget.product.fiber.toStringAsFixed(1)} g'),
              _buildNutrientRow(
                  'Sodium', '${widget.product.sodium.toStringAsFixed(3)} g'),
              _buildNutrientRow('Cholesterol',
                  '${widget.product.cholesterol.toStringAsFixed(1)} mg'),

              if (widget.product.allergens.isNotEmpty) ...[
                const Divider(color: Colors.white12, height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    children: [
                      const Text('Allergens: ',
                          style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                      ...widget.product.allergens.map((a) => Chip(
                        label: Text(a,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white)),
                        backgroundColor: AppColors.card,
                        padding: EdgeInsets.zero,
                      )),
                    ],
                  ),
                ),
              ],

              if (widget.product.ingredientsText != null &&
                  widget.product.ingredientsText!.isNotEmpty) ...[
                const Divider(color: Colors.white12, height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Ingredients',
                      style: TextStyle(
                          color: AppColors.olive, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                Text(widget.product.ingredientsText!,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12, height: 1.4)),
              ],

              const Divider(color: Colors.white12, height: 30),

              // ── Storage location ─────────────────────────────────────────
              DropdownButtonFormField<StorageLocation>(
                value: _selectedLocation,
                decoration: const InputDecoration(
                  labelText: 'Store in',
                  labelStyle: TextStyle(color: AppColors.olive),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white10)),
                ),
                dropdownColor: AppColors.card,
                items: StorageLocation.values.map((loc) {
                  return DropdownMenuItem(
                      value: loc,
                      child: Text(loc.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white)));
                }).toList(),
                onChanged: (val) =>
                    setState(() => _selectedLocation = val!),
              ),

              // ── Expiry date ──────────────────────────────────────────────
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedExpiry == null
                      ? 'Set Expiry Date'
                      : 'Expires: ${_selectedExpiry!.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing:
                const Icon(Icons.calendar_today, color: AppColors.olive),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate:
                    DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (date != null) setState(() => _selectedExpiry = date);
                },
              ),

              const SizedBox(height: 20),

              // ── Add to kitchen ───────────────────────────────────────────
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.olive,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  final finalProduct = FoodItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: widget.product.name,
                    barcode: widget.product.barcode,
                    brand: widget.product.brand,
                    imageUrl: widget.product.imageUrl,
                    nutriScore: widget.product.nutriScore,
                    allergens: widget.product.allergens,
                    ingredientsText: widget.product.ingredientsText,
                    location: _selectedLocation,
                    expiryDate: _selectedExpiry,
                    calories: widget.product.calories,
                    protein: widget.product.protein,
                    carbs: widget.product.carbs,
                    fat: widget.product.fat,
                    saturatedFat: widget.product.saturatedFat,
                    sodium: widget.product.sodium,
                    cholesterol: widget.product.cholesterol,
                    fiber: widget.product.fiber,
                    sugar: widget.product.sugar,
                    potassium: widget.product.potassium,
                    magnesium: widget.product.magnesium,
                    vitaminC: widget.product.vitaminC,
                    vitaminD: widget.product.vitaminD,
                    calcium: widget.product.calcium,
                    iron: widget.product.iron,
                  );
                  ref.read(pantryProvider.notifier).addItem(finalProduct);
                  Navigator.pop(context);
                },
                child: const Text('Add to Kitchen',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _warningBanner({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5)),
                Text(message, style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroHighlight(String label, String value, String unit) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.olive,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Text(label,
            style: const TextStyle(color: AppColors.beige, fontSize: 12)),
      ],
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
              const TextStyle(color: AppColors.beige, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
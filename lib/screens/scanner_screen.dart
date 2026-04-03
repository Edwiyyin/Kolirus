import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/food_api_service.dart';
import '../models/food_item.dart';
import '../providers/pantry_provider.dart';
import '../providers/scan_history_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

// Allergen keyword mapping: setting name -> keywords to search for
const Map<String, List<String>> _allergenKeywords = {
  'gluten': ['gluten', 'wheat', 'barley', 'rye', 'oat', 'spelt', 'kamut', 'farro', 'semolina', 'farina', 'einkorn', 'durum'],
  'milk': ['milk', 'dairy', 'lactose', 'cheese', 'butter', 'cream', 'whey', 'casein', 'lactose', 'fromage'],
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

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final FoodApiService _apiService = FoodApiService();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

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

  /// Detect allergens by searching across all product text fields
  List<String> _detectAllergens(FoodItem product, List<String> userAllergies) {
    // Build a big searchable text from all product fields
    final searchText = [
      product.name,
      product.brand ?? '',
      product.ingredientsText ?? '',
      ...product.allergens,
    ].join(' ').toLowerCase();

    final detected = <String>[];

    for (final userAllergen in userAllergies) {
      final allergenKey = userAllergen.toLowerCase();
      final keywords = _allergenKeywords[allergenKey] ?? [allergenKey];

      final found = keywords.any((keyword) => searchText.contains(keyword));
      if (found) {
        detected.add(userAllergen);
      }
    }

    return detected;
  }

  void _showProductDialog(FoodItem product) {
    StorageLocation selectedLocation = StorageLocation.shelf;
    DateTime? selectedExpiry;
    final userSettings = ref.read(settingsProvider);
    final userAllergies =
    List<String>.from(userSettings['allergies'] ?? []);

    final detectedAllergies = _detectAllergens(product, userAllergies);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
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
                  if (product.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(product.imageUrl!,
                          height: 150, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 10),
                  Text(product.name,
                      style: AppTextStyles.heading1,
                      textAlign: TextAlign.center),
                  Text(product.brand ?? '', style: AppTextStyles.caption),

                  // ALLERGY WARNING - shown prominently
                  if (detectedAllergies.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.danger, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ALLERGY WARNING',
                                    style: TextStyle(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.5)),
                                Text(
                                  'Contains: ${detectedAllergies.map((a) => a.toUpperCase()).join(", ")}',
                                  style: const TextStyle(
                                      color: AppColors.danger, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(color: Colors.white12, height: 30),

                  // Nutri-Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nutri-Score',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Chip(
                        label: Text(
                            product.nutriScore ?? 'N/A',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        backgroundColor: _getNutriColor(product.nutriScore),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Nutritional Information (per 100g)',
                        style: TextStyle(
                            color: AppColors.olive,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),

                  // Main macros highlighted
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
                        _macroHighlight('Calories', '${product.calories.toInt()}', 'kcal'),
                        _macroHighlight('Protein', '${product.protein.toStringAsFixed(1)}', 'g'),
                        _macroHighlight('Carbs', '${product.carbs.toStringAsFixed(1)}', 'g'),
                        _macroHighlight('Fat', '${product.fat.toStringAsFixed(1)}', 'g'),
                      ],
                    ),
                  ),

                  // Detailed nutrients
                  _buildNutrientRow('Sugars', '${product.sugar.toStringAsFixed(1)} g'),
                  _buildNutrientRow('Saturated Fat', '${product.saturatedFat.toStringAsFixed(1)} g'),
                  _buildNutrientRow('Fiber', '${product.fiber.toStringAsFixed(1)} g'),
                  _buildNutrientRow('Sodium', '${product.sodium.toStringAsFixed(3)} g'),
                  _buildNutrientRow('Cholesterol', '${product.cholesterol.toStringAsFixed(1)} mg'),

                  // Allergens list from product
                  if (product.allergens.isNotEmpty) ...[
                    const Divider(color: Colors.white12, height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        children: [
                          const Text('Allergens: ',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          ...product.allergens.map((a) => Chip(
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

                  if (product.ingredientsText != null &&
                      product.ingredientsText!.isNotEmpty) ...[
                    const Divider(color: Colors.white12, height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Ingredients',
                          style: TextStyle(
                              color: AppColors.olive,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    Text(product.ingredientsText!,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12, height: 1.4)),
                  ],

                  const Divider(color: Colors.white12, height: 30),

                  DropdownButtonFormField<StorageLocation>(
                    value: selectedLocation,
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
                        setModalState(() => selectedLocation = val!),
                  ),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      selectedExpiry == null
                          ? 'Set Expiry Date'
                          : 'Expires: ${selectedExpiry!.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.calendar_today,
                        color: AppColors.olive),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                        DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365 * 2)),
                      );
                      if (date != null)
                        setModalState(() => selectedExpiry = date);
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.olive,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    onPressed: () {
                      final finalProduct = FoodItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: product.name,
                        barcode: product.barcode,
                        brand: product.brand,
                        imageUrl: product.imageUrl,
                        nutriScore: product.nutriScore,
                        allergens: product.allergens,
                        ingredientsText: product.ingredientsText,
                        location: selectedLocation,
                        expiryDate: selectedExpiry,
                        calories: product.calories,
                        protein: product.protein,
                        carbs: product.carbs,
                        fat: product.fat,
                        saturatedFat: product.saturatedFat,
                        sodium: product.sodium,
                        cholesterol: product.cholesterol,
                        fiber: product.fiber,
                        sugar: product.sugar,
                      );
                      ref.read(pantryProvider.notifier).addItem(finalProduct);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Add to Kitchen',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() => setState(() => _isProcessing = false));
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
              style: const TextStyle(color: AppColors.beige, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getNutriColor(String? score) {
    switch (score?.toLowerCase()) {
      case 'a':
        return Colors.green.shade700;
      case 'b':
        return Colors.green.shade400;
      case 'c':
        return Colors.yellow.shade700;
      case 'd':
        return Colors.orange.shade700;
      case 'e':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Food'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
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
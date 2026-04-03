import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/food_api_service.dart';
import '../models/food_item.dart';
import '../providers/pantry_provider.dart';
import '../providers/scan_history_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

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

  void _showProductDialog(FoodItem product) {
    StorageLocation selectedLocation = StorageLocation.shelf;
    DateTime? selectedExpiry;
    final userSettings = ref.read(settingsProvider);
    final userAllergies = List<String>.from(userSettings['allergies'] ?? []);
    
    List<String> detectedAllergies = [];
    for (var allergy in userAllergies) {
      final allergenLower = allergy.toLowerCase();
      bool found = product.allergens.any((a) => a.toLowerCase().contains(allergenLower)) ||
                   product.name.toLowerCase().contains(allergenLower) ||
                   (product.brand?.toLowerCase().contains(allergenLower) ?? false) ||
                   (product.ingredientsText?.toLowerCase().contains(allergenLower) ?? false);
      if (found) {
        detectedAllergies.add(allergy);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
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
                      child: Image.network(product.imageUrl!, height: 150, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 10),
                  Text(product.name, style: AppTextStyles.heading1, textAlign: TextAlign.center),
                  Text(product.brand ?? '', style: AppTextStyles.caption),
                  
                  if (detectedAllergies.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ALLERGY WARNING: Contains ${detectedAllergies.join(", ")}',
                              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(color: Colors.white12, height: 30),
                  
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Nutritional Information (per 100g)', style: TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  _buildNutrientRow('Calories', '${product.calories} kcal'),
                  _buildNutrientRow('Protein', '${product.protein} g'),
                  _buildNutrientRow('Carbs', '${product.carbs} g'),
                  _buildNutrientRow('Sugars', '${product.sugar} g'),
                  _buildNutrientRow('Fat', '${product.fat} g'),
                  _buildNutrientRow('Saturated Fat', '${product.saturatedFat} g'),
                  _buildNutrientRow('Fiber', '${product.fiber} g'),
                  _buildNutrientRow('Sodium', '${product.sodium} g'),
                  _buildNutrientRow('Cholesterol', '${product.cholesterol} mg'),
                  
                  const Divider(color: Colors.white12, height: 30),
                  
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Nutri-Score', style: TextStyle(color: Colors.white)),
                    trailing: Chip(
                      label: Text(product.nutriScore ?? 'N/A'),
                      backgroundColor: _getNutriColor(product.nutriScore),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  DropdownButtonFormField<StorageLocation>(
                    value: selectedLocation,
                    decoration: const InputDecoration(
                      labelText: 'Store in', 
                      labelStyle: TextStyle(color: AppColors.olive),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                    ),
                    dropdownColor: AppColors.card,
                    items: StorageLocation.values.map((loc) {
                      return DropdownMenuItem(value: loc, child: Text(loc.name.toUpperCase(), style: const TextStyle(color: Colors.white)));
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedLocation = val!),
                  ),
                  
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(selectedExpiry == null 
                      ? 'Set Expiry Date' 
                      : 'Expires: ${selectedExpiry!.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.calendar_today, color: AppColors.olive),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (date != null) setModalState(() => selectedExpiry = date);
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.olive,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
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
                    child: const Text('Add to Kitchen', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() => setState(() => _isProcessing = false));
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.beige, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
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
        ],
      ),
    );
  }
}

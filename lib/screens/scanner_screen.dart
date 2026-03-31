import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/food_api_service.dart';
import '../models/food_item.dart';
import '../providers/pantry_provider.dart';
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20, left: 20, right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.imageUrl != null)
                Image.network(product.imageUrl!, height: 100),
              Text(product.name, style: AppTextStyles.heading1),
              Text(product.brand ?? '', style: AppTextStyles.caption),
              const Divider(color: AppColors.secondary),
              ListTile(
                title: const Text('Nutri-Score', style: TextStyle(color: Colors.white)),
                trailing: Chip(
                  label: Text(product.nutriScore ?? 'N/A'),
                  backgroundColor: _getNutriColor(product.nutriScore),
                ),
              ),
              DropdownButton<StorageLocation>(
                value: selectedLocation,
                isExpanded: true,
                dropdownColor: AppColors.card,
                items: StorageLocation.values.map((loc) {
                  return DropdownMenuItem(value: loc, child: Text(loc.name.toUpperCase(), style: const TextStyle(color: Colors.white)));
                }).toList(),
                onChanged: (val) => setModalState(() => selectedLocation = val!),
              ),
              ListTile(
                title: Text(selectedExpiry == null 
                  ? 'Set Expiry Date' 
                  : 'Expires: ${selectedExpiry!.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.calendar_today, color: AppColors.accent),
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      onPressed: () {
                        final finalProduct = FoodItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: product.name,
                          barcode: product.barcode,
                          brand: product.brand,
                          imageUrl: product.imageUrl,
                          nutriScore: product.nutriScore,
                          allergens: product.allergens,
                          location: selectedLocation,
                          expiryDate: selectedExpiry,
                          calories: product.calories,
                          protein: product.protein,
                          carbs: product.carbs,
                          fat: product.fat,
                          sugar: product.sugar,
                        );
                        ref.read(pantryProvider.notifier).addItem(finalProduct);
                        Navigator.pop(context); // Close bottom sheet
                        Navigator.pop(context); // Go back to pantry/home
                      },
                      child: const Text('Save to Pantry', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      appBar: AppBar(title: const Text('Scan Food')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          // Scanner Overlay (The square shape)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align barcode within the square',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, backgroundColor: Colors.black45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

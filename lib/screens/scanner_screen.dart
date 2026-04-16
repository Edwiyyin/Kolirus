import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/food_api_service.dart';
import '../services/database_service.dart';
import '../services/expiry_service.dart';
import '../models/food_item.dart';
import '../providers/pantry_provider.dart';
import '../providers/scan_history_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/dietary_rules.dart';
import 'dart:convert';

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
          if (_showHistory && history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.danger),
              onPressed: () => _confirmClearHistory(),
            ),
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
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white24),
                        onPressed: () => ref.read(scanHistoryProvider.notifier).removeFromHistory(item.id!),
                      ),
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

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete all scan history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(scanHistoryProvider.notifier).clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _ProductDialog extends ConsumerStatefulWidget {
  final FoodItem product;
  const _ProductDialog({required this.product});

  @override
  ConsumerState<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<_ProductDialog> {
  StorageLocation _selectedLocation = StorageLocation.shelf;
  DateTime? _selectedExpiry;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.product.location;
    _updateSuggestedExpiry();
  }

  void _updateSuggestedExpiry() {
    setState(() {
      _selectedExpiry = ExpiryService.suggestExpiry(widget.product.name, _selectedLocation);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userSettings = ref.watch(settingsProvider);
    final userAllergies = List<String>.from(userSettings['allergies'] ?? []);
    final userDietary = List<String>.from(userSettings['dietary_prefs'] ?? []);
    final userReligious = List<String>.from(userSettings['religious_prefs'] ?? []);

    final detectedAllergies = DietaryRules.detectAllergies(widget.product, userAllergies);
    final violations = DietaryRules.detectViolations(widget.product, userDietary, userReligious, userSettings);
    
    final qualityWarnings = <String>[];
    if (userSettings['prefer_high_nutriscore'] == true && 
        ['c', 'd', 'e'].contains(widget.product.nutriScore?.toLowerCase())) {
      qualityWarnings.add('Low Nutri-Score (${widget.product.nutriScore?.toUpperCase()})');
    }

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

              if (detectedAllergies.isNotEmpty) ...[
                const SizedBox(height: 15),
                _warningBanner(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  title: 'ALLERGY WARNING',
                  message: 'Contains: ${detectedAllergies.join(", ").toUpperCase()}',
                ),
              ],

              if (violations.isNotEmpty || qualityWarnings.isNotEmpty) ...[
                const SizedBox(height: 10),
                _warningBanner(
                  icon: Icons.no_food_outlined,
                  color: AppColors.warning,
                  title: 'DIETARY NOTICE',
                  message: [...violations, ...qualityWarnings].join(", "),
                ),
              ],

              const SizedBox(height: 20),
              _buildNutritionGrid(),
              const SizedBox(height: 20),
              
              const Text('Storage & Smart Expiry', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: StorageLocation.values.map((loc) => ChoiceChip(
                  label: Text(loc.name.toUpperCase()),
                  selected: _selectedLocation == loc,
                  onSelected: (val) {
                    setState(() => _selectedLocation = loc);
                    _updateSuggestedExpiry();
                  },
                  selectedColor: AppColors.olive,
                  labelStyle: TextStyle(color: _selectedLocation == loc ? Colors.black : Colors.white, fontSize: 11),
                )).toList(),
              ),
              if (_selectedExpiry != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Smart Suggestion: Good until ${_selectedExpiry!.day}/${_selectedExpiry!.month}/${_selectedExpiry!.year}',
                    style: const TextStyle(color: AppColors.olive, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.olive),
                      onPressed: () {
                        ref.read(pantryProvider.notifier).addItem(
                          widget.product.copyWith(
                            location: _selectedLocation,
                            expiryDate: _selectedExpiry,
                          )
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${widget.product.name} added to pantry')),
                        );
                      },
                      child: const Text('Add to Pantry',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _warningBanner({required IconData icon, required Color color, required String title, required String message}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(message, style: TextStyle(color: color.withOpacity(0.9), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _nutritionRow('Calories', '${widget.product.calories.round()} kcal'),
          const Divider(color: Colors.white10),
          _nutritionRow('Protein', '${widget.product.protein.toStringAsFixed(1)}g'),
          _nutritionRow('Carbs', '${widget.product.carbs.toStringAsFixed(1)}g'),
          _nutritionRow('Fat', '${widget.product.fat.toStringAsFixed(1)}g'),
          if (widget.product.nutriScore != null) ...[
             const Divider(color: Colors.white10),
             _nutritionRow('Nutri-Score', widget.product.nutriScore!.toUpperCase()),
          ]
        ],
      ),
    );
  }

  Widget _nutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

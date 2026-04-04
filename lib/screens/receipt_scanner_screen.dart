import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../models/receipt.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';
import '../providers/pantry_provider.dart';

class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  ConsumerState<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends ConsumerState<ReceiptScannerScreen> {
  File? _image;
  bool _isProcessing = false;
  List<ReceiptItem> _detectedItems = [];
  List<Receipt> _history = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final res = await DatabaseService.instance.query('receipts', orderBy: 'date DESC');
    setState(() => _history = res.map((j) => Receipt.fromMap(j)).toList());
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isProcessing = true;
      });

      // Simulation of improved OCR
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isProcessing = false;
        _detectedItems = [
          ReceiptItem(name: 'Greek Yogurt 500g', price: 4.99),
          ReceiptItem(name: 'Organic Spinach', price: 3.50),
          ReceiptItem(name: 'EVOO Extra Virgin 1L', price: 12.90),
          ReceiptItem(name: 'Salmon Fillet', price: 15.20),
        ];
      });
    }
  }

  void _saveReceipt() async {
    final receipt = Receipt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      imageUrl: _image?.path,
      totalAmount: _detectedItems.fold(0, (sum, item) => sum + item.price),
      items: _detectedItems,
    );
    await DatabaseService.instance.insert('receipts', receipt.toMap());
    _loadHistory();
    setState(() {
      _image = null;
      _detectedItems = [];
    });
  }

  void _editItem(int index) {
    final nameController = TextEditingController(text: _detectedItems[index].name);
    final priceController = TextEditingController(text: _detectedItems[index].price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            setState(() {
              _detectedItems[index].name = nameController.text;
              _detectedItems[index].price = double.tryParse(priceController.text) ?? 0.0;
            });
            Navigator.pop(context);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _linkToPantry(int index) {
    final pantry = ref.read(pantryProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) => ListView.builder(
        itemCount: pantry.length,
        itemBuilder: (context, i) => ListTile(
          title: Text(pantry[i].name),
          onTap: () async {
            setState(() {
              _detectedItems[index].linkedFoodItemId = pantry[i].id;
            });
            // Update pantry item price
            final updated = FoodItem(
              id: pantry[i].id,
              name: pantry[i].name,
              calories: pantry[i].calories,
              protein: pantry[i].protein,
              carbs: pantry[i].carbs,
              fat: pantry[i].fat,
              location: pantry[i].location,
              price: _detectedItems[index].price,
              barcode: pantry[i].barcode,
              brand: pantry[i].brand,
              imageUrl: pantry[i].imageUrl,
              nutriScore: pantry[i].nutriScore,
              allergens: pantry[i].allergens,
              ingredientsText: pantry[i].ingredientsText,
              expiryDate: pantry[i].expiryDate,
              addedDate: pantry[i].addedDate,
            );
            ref.read(pantryProvider.notifier).updateItem(updated);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.camera_alt : Icons.history),
            onPressed: () => setState(() => _showHistory = !_showHistory),
          )
        ],
      ),
      body: _showHistory ? _buildHistory() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        if (_image == null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 80, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('Scan a new receipt', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt, color: Colors.black),
                    label: const Text('Take Photo', style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _detectedItems.length,
              itemBuilder: (context, index) {
                final item = _detectedItems[index];
                return Card(
                  color: AppColors.card,
                  child: ListTile(
                    title: Text(item.name, style: const TextStyle(color: Colors.white)),
                    subtitle: item.linkedFoodItemId != null 
                        ? const Text('Linked to pantry', style: TextStyle(color: AppColors.olive, fontSize: 10))
                        : const Text('Not linked', style: TextStyle(fontSize: 10, color: Colors.white38)),
                    trailing: Text('\$${item.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold)),
                    onTap: () => _editItem(index),
                    onLongPress: () => _linkToPantry(index),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _image = null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveReceipt,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
                    child: const Text('Save Receipt', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistory() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final r = _history[index];
        return Card(
          color: AppColors.card,
          child: ListTile(
            title: Text('Receipt ${r.date.toString().split(' ')[0]}'),
            subtitle: Text('${r.items.length} items'),
            trailing: Text('\$${r.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.olive)),
            onTap: () {
              setState(() {
                _detectedItems = List.from(r.items);
                _image = r.imageUrl != null ? File(r.imageUrl!) : null;
                _showHistory = false;
              });
            },
          ),
        );
      },
    );
  }
}

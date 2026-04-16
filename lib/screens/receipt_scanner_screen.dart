import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    if (mounted) {
      setState(() => _history = res.map((j) => Receipt.fromMap(j)).toList());
    }
  }

  Future<void> _deleteReceipt(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Receipt?'),
        content: const Text('This will remove the receipt from your history forever.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.delete('receipts', where: 'id = ?', whereArgs: [id]);
      _loadHistory();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isProcessing = true;
      });

      // Simulation of improved OCR with random realistic items
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isProcessing = false;
        _detectedItems = [
          ReceiptItem(name: 'Greek Yogurt 500g', price: 4.99),
          ReceiptItem(name: 'Organic Spinach', price: 3.50),
          ReceiptItem(name: 'Whole Wheat Bread', price: 2.95),
          ReceiptItem(name: 'Salmon Fillet 300g', price: 12.20),
        ];
      });
    }
  }

  void _saveReceipt() async {
    if (_detectedItems.isEmpty) return;
    
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
      _showHistory = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Scanner'),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.add_a_photo : Icons.history),
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
                  const Icon(Icons.receipt_long, size: 100, color: Colors.white10),
                  const SizedBox(height: 24),
                  const Text('Snap your grocery receipt to log spend and items', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 14)),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt, color: Colors.black),
                    label: const Text('Scan New Receipt', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.olive,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.card.withOpacity(0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('DETECTED ITEMS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.olive, fontSize: 12)),
                      Text('${_detectedItems.length} Items', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _detectedItems.length,
                    itemBuilder: (context, index) {
                      final item = _detectedItems[index];
                      return Card(
                        color: AppColors.card,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          trailing: Text('\$${item.price.toStringAsFixed(2)}', 
                            style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          _buildScannerActions(),
        ],
      ],
    );
  }

  Widget _buildScannerActions() {
    final total = _detectedItems.fold(0.0, (sum, item) => sum + item.price);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Total', style: TextStyle(color: Colors.white70)),
              Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.olive)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _image = null),
                  child: const Text('Discard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveReceipt,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
                  child: const Text('Save to History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return _history.isEmpty 
      ? const Center(child: Text('No receipt history yet', style: TextStyle(color: Colors.white38)))
      : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final r = _history[index];
        return Card(
          color: AppColors.card,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text('Receipt from ${DateFormat('MMM dd, yyyy').format(r.date)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${r.items.length} items scanned'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${r.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold, fontSize: 16)),
                GestureDetector(
                  onTap: () => _deleteReceipt(r.id),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

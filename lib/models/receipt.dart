import 'dart:convert';

class ReceiptItem {
  String name;
  double price;
  String? linkedFoodItemId;

  ReceiptItem({required this.name, required this.price, this.linkedFoodItemId});

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'linkedFoodItemId': linkedFoodItemId};
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      linkedFoodItemId: map['linkedFoodItemId'],
    );
  }
}

class Receipt {
  final String id;
  final DateTime date;
  final String? imageUrl;
  final double totalAmount;
  final List<ReceiptItem> items;

  Receipt({
    required this.id,
    required this.date,
    this.imageUrl,
    required this.totalAmount,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'imageUrl': imageUrl,
      'totalAmount': totalAmount,
      'items': jsonEncode(items.map((i) => i.toMap()).toList()),
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    final List<dynamic> itemsJson = jsonDecode(map['items'] ?? '[]');
    return Receipt(
      id: map['id'],
      date: DateTime.parse(map['date']),
      imageUrl: map['imageUrl'],
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      items: itemsJson.map((i) => ReceiptItem.fromMap(i)).toList(),
    );
  }
}

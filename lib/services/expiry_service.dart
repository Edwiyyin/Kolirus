import '../models/food_item.dart';

class ExpiryService {
  static Duration getSuggestedShelfLife(String name, StorageLocation location) {
    final n = name.toLowerCase();
    
    // Categorization logic
    bool isMeat = n.contains('meat') || n.contains('beef') || n.contains('pork') || n.contains('chicken') || n.contains('steak') || n.contains('lamb');
    bool isFish = n.contains('fish') || n.contains('salmon') || n.contains('tuna') || n.contains('shrimp') || n.contains('seafood');
    bool isDairy = n.contains('milk') || n.contains('cheese') || n.contains('yogurt') || n.contains('butter') || n.contains('cream');
    bool isProduce = n.contains('spinach') || n.contains('salad') || n.contains('tomato') || n.contains('apple') || n.contains('fruit') || n.contains('vegetable') || n.contains('berry');
    bool isBread = n.contains('bread') || n.contains('bun') || n.contains('pastry');

    switch (location) {
      case StorageLocation.freezer:
        if (isMeat) return const Duration(days: 180); // 6 months
        if (isFish) return const Duration(days: 90);  // 3 months
        if (isProduce) return const Duration(days: 240); // 8 months
        if (isBread) return const Duration(days: 60);  // 2 months
        return const Duration(days: 180);

      case StorageLocation.fridge:
        if (isMeat) return const Duration(days: 3);
        if (isFish) return const Duration(days: 2);
        if (isDairy) return const Duration(days: 14);
        if (isProduce) return const Duration(days: 7);
        if (isBread) return const Duration(days: 10);
        return const Duration(days: 5);

      case StorageLocation.shelf:
        if (isProduce) return const Duration(days: 5);
        if (isBread) return const Duration(days: 4);
        if (isDairy) return const Duration(days: 1); // Only for UHT/unopened
        return const Duration(days: 365); // Default pantry item (canned, dried)
    }
  }

  static DateTime suggestExpiry(String name, StorageLocation location) {
    return DateTime.now().add(getSuggestedShelfLife(name, location));
  }
}

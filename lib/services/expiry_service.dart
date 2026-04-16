/// Smart expiry service — suggests shelf life based on food name + storage location.
/// Data sourced from FDA, USDA, and EU food safety guidelines.
library;

import '../models/food_item.dart';

class ExpiryService {
  static final ExpiryService instance = ExpiryService._();
  ExpiryService._();

  /// Returns a suggested expiry date and a human-readable reason.
  ExpiryResult suggestExpiry(String foodName, StorageLocation location) {
    final name = foodName.toLowerCase().trim();
    final category = _detectCategory(name);
    final days = _shelfLifeDays(category, location);
    final label = _categoryLabel(category);

    return ExpiryResult(
      suggestedDate: DateTime.now().add(Duration(days: days)),
      days: days,
      foodCategory: label,
      storageAdvice: _storageAdvice(category, location),
    );
  }

  // ── Category detection ────────────────────────────────────────────────────

  _FoodCategory _detectCategory(String name) {
    // Meat & Poultry
    if (_matches(name, [
      'beef', 'steak', 'mince', 'ground beef', 'veal', 'lamb', 'pork', 'chop',
      'ribs', 'sausage', 'bacon', 'ham', 'prosciutto', 'salami', 'chorizo',
      'pepperoni', 'chicken', 'turkey', 'duck', 'poultry', 'breast', 'thigh',
      'wing', 'drumstick', 'meatball', 'burger', 'patty', 'luncheon meat',
      'deli meat', 'cold cuts', 'venison', 'bison', 'goat', 'rabbit',
    ])) return _FoodCategory.rawMeat;

    // Fish & Seafood
    if (_matches(name, [
      'fish', 'salmon', 'tuna', 'cod', 'halibut', 'tilapia', 'mackerel',
      'trout', 'bass', 'haddock', 'snapper', 'shrimp', 'prawn', 'crab',
      'lobster', 'scallop', 'mussel', 'clam', 'oyster', 'squid', 'octopus',
      'anchovy', 'sardine', 'herring', 'swordfish', 'seafood',
    ])) return _FoodCategory.rawFish;

    // Dairy
    if (_matches(name, [
      'milk', 'whole milk', 'skim milk', 'cream', 'half and half',
      'heavy cream', 'sour cream', 'crème fraîche',
    ])) return _FoodCategory.liquidDairy;

    if (_matches(name, [
      'butter', 'margarine',
    ])) return _FoodCategory.butter;

    if (_matches(name, [
      'cheese', 'cheddar', 'mozzarella', 'parmesan', 'brie', 'camembert',
      'gouda', 'swiss', 'feta', 'ricotta', 'cottage cheese', 'cream cheese',
      'provolone', 'gruyere', 'edam', 'manchego', 'halloumi',
    ])) return _FoodCategory.cheese;

    if (_matches(name, [
      'yogurt', 'yoghurt', 'kefir', 'quark',
    ])) return _FoodCategory.yogurt;

    // Eggs
    if (_matches(name, ['egg', 'eggs'])) return _FoodCategory.eggs;

    // Fruits
    if (_matches(name, [
      'apple', 'pear', 'orange', 'lemon', 'lime', 'grapefruit', 'mandarin',
      'tangerine', 'kiwi', 'grape', 'cherry', 'plum', 'apricot', 'nectarine',
      'peach', 'mango', 'pineapple', 'papaya', 'melon', 'watermelon',
      'cantaloupe', 'honeydew', 'pomegranate', 'fig', 'date', 'passion fruit',
      'guava', 'dragon fruit', 'lychee', 'coconut', 'avocado',
    ])) return _FoodCategory.freshFruit;

    if (_matches(name, [
      'banana', 'plantain',
    ])) return _FoodCategory.banana;

    if (_matches(name, [
      'strawberry', 'raspberry', 'blueberry', 'blackberry', 'cranberry',
      'gooseberry', 'currant', 'berry', 'berries',
    ])) return _FoodCategory.softBerries;

    // Vegetables
    if (_matches(name, [
      'spinach', 'lettuce', 'arugula', 'rocket', 'kale', 'chard',
      'salad', 'mixed greens', 'watercress', 'endive', 'radicchio',
    ])) return _FoodCategory.leafyGreens;

    if (_matches(name, [
      'broccoli', 'cauliflower', 'cabbage', 'brussels sprout', 'asparagus',
      'celery', 'green bean', 'pea', 'corn', 'artichoke', 'leek',
      'fennel', 'bok choy',
    ])) return _FoodCategory.freshVegetable;

    if (_matches(name, [
      'tomato', 'pepper', 'capsicum', 'zucchini', 'courgette', 'eggplant',
      'aubergine', 'cucumber', 'squash', 'mushroom',
    ])) return _FoodCategory.softVegetable;

    if (_matches(name, [
      'carrot', 'potato', 'sweet potato', 'onion', 'garlic', 'beetroot',
      'turnip', 'parsnip', 'radish', 'ginger', 'yam', 'celeriac',
    ])) return _FoodCategory.rootVegetable;

    // Bread & Bakery
    if (_matches(name, [
      'bread', 'loaf', 'baguette', 'sourdough', 'roll', 'bun', 'bagel',
      'muffin', 'croissant', 'brioche', 'ciabatta', 'pita', 'flatbread',
      'tortilla', 'wrap',
    ])) return _FoodCategory.bread;

    if (_matches(name, [
      'cake', 'pastry', 'tart', 'pie', 'eclair', 'donut', 'danish',
      'brownie', 'cookie', 'biscuit',
    ])) return _FoodCategory.pastry;

    // Cooked / Prepared Foods
    if (_matches(name, [
      'cooked', 'leftover', 'roast', 'stew', 'soup', 'curry', 'pasta dish',
      'rice dish', 'casserole', 'lasagna', 'pizza', 'quiche', 'stir fry',
      'fried rice',
    ])) return _FoodCategory.cookedMeal;

    // Processed / Long-life
    if (_matches(name, [
      'canned', 'tinned', 'jar', 'pickle', 'jam', 'jelly', 'preserve',
      'condiment', 'sauce', 'ketchup', 'mustard', 'mayonnaise', 'vinegar',
      'oil', 'olive oil', 'soy sauce', 'hot sauce', 'chutney',
    ])) return _FoodCategory.condiment;

    if (_matches(name, [
      'pasta', 'rice', 'flour', 'sugar', 'salt', 'oat', 'cereal',
      'lentil', 'bean', 'chickpea', 'quinoa', 'couscous', 'semolina',
      'dried', 'grain',
    ])) return _FoodCategory.dryCupboard;

    if (_matches(name, [
      'chocolate', 'candy', 'sweet', 'gummy', 'lolly', 'snack',
      'crisp', 'chip', 'cracker', 'popcorn', 'pretzel', 'nut', 'seed',
      'trail mix', 'granola bar', 'energy bar', 'protein bar',
    ])) return _FoodCategory.snack;

    if (_matches(name, [
      'juice', 'smoothie', 'drink', 'beverage', 'soda', 'water',
      'kombucha', 'lemonade',
    ])) return _FoodCategory.beverage;

    if (_matches(name, [
      'ice cream', 'gelato', 'sorbet', 'frozen yogurt', 'frozen meal',
      'frozen pizza', 'frozen', 'popsicle',
    ])) return _FoodCategory.frozenFood;

    return _FoodCategory.unknown;
  }

  // ── Shelf life table ──────────────────────────────────────────────────────

  int _shelfLifeDays(_FoodCategory cat, StorageLocation loc) {
    switch (loc) {
      case StorageLocation.freezer:
        return _freezerDays(cat);
      case StorageLocation.fridge:
        return _fridgeDays(cat);
      case StorageLocation.shelf:
        return _shelfDays(cat);
    }
  }

  int _freezerDays(_FoodCategory cat) {
    switch (cat) {
      case _FoodCategory.rawMeat:      return 180; // 6 months
      case _FoodCategory.rawFish:      return 90;  // 3 months
      case _FoodCategory.liquidDairy:  return 90;
      case _FoodCategory.butter:       return 270; // 9 months
      case _FoodCategory.cheese:       return 180;
      case _FoodCategory.yogurt:       return 60;
      case _FoodCategory.eggs:         return 365; // 1 year (beaten)
      case _FoodCategory.freshFruit:   return 270;
      case _FoodCategory.banana:       return 90;
      case _FoodCategory.softBerries:  return 270;
      case _FoodCategory.leafyGreens:  return 60;
      case _FoodCategory.freshVegetable: return 270;
      case _FoodCategory.softVegetable:  return 270;
      case _FoodCategory.rootVegetable:  return 365;
      case _FoodCategory.bread:        return 90;
      case _FoodCategory.pastry:       return 60;
      case _FoodCategory.cookedMeal:   return 90;
      case _FoodCategory.frozenFood:   return 270;
      case _FoodCategory.snack:        return 180;
      case _FoodCategory.dryCupboard:  return 730;
      case _FoodCategory.condiment:    return 365;
      case _FoodCategory.beverage:     return 90;
      case _FoodCategory.unknown:      return 180;
    }
  }

  int _fridgeDays(_FoodCategory cat) {
    switch (cat) {
      case _FoodCategory.rawMeat:      return 3;
      case _FoodCategory.rawFish:      return 2;
      case _FoodCategory.liquidDairy:  return 7;
      case _FoodCategory.butter:       return 30;
      case _FoodCategory.cheese:       return 14;
      case _FoodCategory.yogurt:       return 14;
      case _FoodCategory.eggs:         return 21;
      case _FoodCategory.freshFruit:   return 7;
      case _FoodCategory.banana:       return 5;
      case _FoodCategory.softBerries:  return 5;
      case _FoodCategory.leafyGreens:  return 5;
      case _FoodCategory.freshVegetable: return 7;
      case _FoodCategory.softVegetable:  return 5;
      case _FoodCategory.rootVegetable:  return 14;
      case _FoodCategory.bread:        return 7;
      case _FoodCategory.pastry:       return 3;
      case _FoodCategory.cookedMeal:   return 4;
      case _FoodCategory.frozenFood:   return 2; // thawed
      case _FoodCategory.snack:        return 14;
      case _FoodCategory.dryCupboard:  return 30;
      case _FoodCategory.condiment:    return 90;
      case _FoodCategory.beverage:     return 7;
      case _FoodCategory.unknown:      return 7;
    }
  }

  int _shelfDays(_FoodCategory cat) {
    switch (cat) {
      case _FoodCategory.rawMeat:      return 1; // should be in fridge!
      case _FoodCategory.rawFish:      return 1;
      case _FoodCategory.liquidDairy:  return 1;
      case _FoodCategory.butter:       return 7;
      case _FoodCategory.cheese:       return 3;
      case _FoodCategory.yogurt:       return 1;
      case _FoodCategory.eggs:         return 7;
      case _FoodCategory.freshFruit:   return 5;
      case _FoodCategory.banana:       return 5;
      case _FoodCategory.softBerries:  return 2;
      case _FoodCategory.leafyGreens:  return 2;
      case _FoodCategory.freshVegetable: return 4;
      case _FoodCategory.softVegetable:  return 3;
      case _FoodCategory.rootVegetable:  return 14;
      case _FoodCategory.bread:        return 5;
      case _FoodCategory.pastry:       return 2;
      case _FoodCategory.cookedMeal:   return 1;
      case _FoodCategory.frozenFood:   return 1;
      case _FoodCategory.snack:        return 90;
      case _FoodCategory.dryCupboard:  return 365;
      case _FoodCategory.condiment:    return 180;
      case _FoodCategory.beverage:     return 3;
      case _FoodCategory.unknown:      return 7;
    }
  }

  String _categoryLabel(_FoodCategory cat) {
    const labels = {
      _FoodCategory.rawMeat:       'Raw Meat / Poultry',
      _FoodCategory.rawFish:       'Raw Fish / Seafood',
      _FoodCategory.liquidDairy:   'Milk / Cream',
      _FoodCategory.butter:        'Butter / Margarine',
      _FoodCategory.cheese:        'Cheese',
      _FoodCategory.yogurt:        'Yogurt / Kefir',
      _FoodCategory.eggs:          'Eggs',
      _FoodCategory.freshFruit:    'Fresh Fruit',
      _FoodCategory.banana:        'Banana',
      _FoodCategory.softBerries:   'Berries',
      _FoodCategory.leafyGreens:   'Leafy Greens',
      _FoodCategory.freshVegetable:'Fresh Vegetable',
      _FoodCategory.softVegetable: 'Soft Vegetable',
      _FoodCategory.rootVegetable: 'Root Vegetable',
      _FoodCategory.bread:         'Bread / Bakery',
      _FoodCategory.pastry:        'Pastry / Cake',
      _FoodCategory.cookedMeal:    'Cooked Meal',
      _FoodCategory.frozenFood:    'Frozen Food',
      _FoodCategory.snack:         'Snack / Confectionery',
      _FoodCategory.dryCupboard:   'Dry / Cupboard Staple',
      _FoodCategory.condiment:     'Condiment / Sauce',
      _FoodCategory.beverage:      'Beverage / Juice',
      _FoodCategory.unknown:       'General Food',
    };
    return labels[cat] ?? 'General Food';
  }

  String _storageAdvice(_FoodCategory cat, StorageLocation loc) {
    if (cat == _FoodCategory.rawMeat && loc == StorageLocation.shelf) {
      return 'Raw meat must be refrigerated or frozen immediately.';
    }
    if (cat == _FoodCategory.rawFish && loc == StorageLocation.shelf) {
      return 'Raw fish spoils rapidly at room temperature — refrigerate or freeze.';
    }
    if (cat == _FoodCategory.frozenFood && loc != StorageLocation.freezer) {
      return 'Keep frozen until use. Once thawed, use within 1–2 days.';
    }
    if (cat == _FoodCategory.leafyGreens && loc == StorageLocation.shelf) {
      return 'Store in fridge to extend freshness by up to 3x.';
    }
    return '';
  }

  bool _matches(String name, List<String> keywords) =>
      keywords.any((k) => name.contains(k));
}

enum _FoodCategory {
  rawMeat, rawFish, liquidDairy, butter, cheese, yogurt, eggs,
  freshFruit, banana, softBerries, leafyGreens, freshVegetable,
  softVegetable, rootVegetable, bread, pastry, cookedMeal, frozenFood,
  snack, dryCupboard, condiment, beverage, unknown,
}

class ExpiryResult {
  final DateTime suggestedDate;
  final int days;
  final String foodCategory;
  final String storageAdvice;

  const ExpiryResult({
    required this.suggestedDate,
    required this.days,
    required this.foodCategory,
    required this.storageAdvice,
  });

  String get daysLabel {
    if (days >= 365) return '~${(days / 365).round()} year(s)';
    if (days >= 30)  return '~${(days / 30).round()} month(s)';
    return '$days day(s)';
  }
}
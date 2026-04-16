import '../models/food_item.dart';

class DietaryRules {
  static const Map<String, List<String>> allergenKeywords = {
    'gluten': ['gluten', 'wheat', 'barley', 'rye', 'oat', 'spelt', 'kamut', 'farro', 'semolina', 'farina', 'einkorn', 'durum', 'malt', 'triticale', 'bulgur', 'couscous', 'seitan'],
    'milk': ['milk', 'dairy', 'lactose', 'cheese', 'butter', 'cream', 'whey', 'casein', 'fromage', 'yogurt', 'curd', 'ghee', 'kefir', 'paneer'],
    'eggs': ['egg', 'ovum', 'albumin', 'lysozyme', 'mayonnaise', 'meringue', 'lecithin (egg)', 'nog'],
    'nuts': ['nuts', 'almond', 'cashew', 'walnut', 'pecan', 'pistachio', 'macadamia', 'hazelnut', 'brazil nut', 'chestnut', 'pine nut', 'praline', 'gianduja'],
    'peanuts': ['peanut', 'groundnut', 'arachide', 'monkey nut', 'valencia nut'],
    'sesame': ['sesame', 'tahini', 'sesamum', 'gomasio', 'halvah'],
    'soybeans': ['soy', 'soya', 'tofu', 'tempeh', 'miso', 'edamame', 'natto', 'shoyu', 'tamari', 'teriyaki'],
    'fish': ['fish', 'cod', 'salmon', 'tuna', 'halibut', 'anchovy', 'sardine', 'herring', 'trout', 'bass', 'mackerel', 'haddock', 'surimi', 'roe', 'caviar'],
    'shellfish': ['shellfish', 'shrimp', 'crab', 'lobster', 'prawn', 'crayfish', 'scallop', 'oyster', 'mussel', 'clam', 'krill', 'langoustine'],
    'celery': ['celery', 'celeriac', 'celery seed', 'celery salt'],
    'mustard': ['mustard', 'sinapis', 'mustard seed', 'mustard flour'],
    'lupin': ['lupin', 'lupine', 'lupinus', 'lupin flour'],
    'molluscs': ['mollusc', 'mollusk', 'squid', 'octopus', 'snail', 'scallop', 'cuttlefish', 'abalone', 'whelk', 'cockle'],
    'sulphites': ['sulphite', 'sulfite', 'sulphur dioxide', 'so2', 'e220', 'e221', 'e222', 'e223', 'e224', 'e225', 'e226', 'e227', 'e228'],
  };

  static const Map<String, List<String>> dietaryViolations = {
    'vegan': ['meat', 'beef', 'pork', 'chicken', 'turkey', 'fish', 'seafood', 'milk', 'dairy', 'egg', 'cheese', 'butter', 'cream', 'honey', 'gelatin', 'gelatine', 'lard', 'tallow', 'isinglass', 'carmine', 'cochineal', 'rennet', 'whey', 'casein', 'beeswax', 'shellac', 'e120', 'e901', 'e904', 'bone char'],
    'vegetarian': ['meat', 'beef', 'pork', 'chicken', 'turkey', 'fish', 'seafood', 'gelatin', 'gelatine', 'lard', 'tallow', 'rennet', 'isinglass', 'carmine', 'cochineal', 'e120'],
    'paleo': ['grain', 'wheat', 'rice', 'corn', 'oat', 'legume', 'bean', 'lentil', 'soy', 'dairy', 'sugar', 'processed', 'refined oil', 'peanut', 'potato', 'cereal'],
    'keto': ['sugar', 'glucose', 'fructose', 'corn syrup', 'maltose', 'wheat', 'rice', 'corn', 'potato', 'bread', 'pasta', 'starch', 'flour', 'honey', 'maple syrup', 'agave', 'cereal', 'fruit (high carb)'],
    'mediterranean': ['trans fat', 'hydrogenated', 'artificial', 'processed meat', 'red meat', 'refined sugar', 'refined grain', 'margarine'],
    'low-carb': ['sugar', 'glucose', 'fructose', 'corn syrup', 'wheat', 'rice', 'starch', 'bread', 'pasta', 'potato', 'cereal', 'flour'],
  };

  static const Map<String, List<String>> religiousViolations = {
    'halal': [
      'pork', 'pig', 'lard', 'bacon', 'ham', 'swine', 'boar', 'pepperoni (pork)', 'salami (pork)',
      'alcohol', 'wine', 'beer', 'spirits', 'liquor', 'ethanol', 'rum', 'brandy', 'vodka', 'whiskey',
      'gelatin', 'gelatine', 'carmine', 'cochineal', 'e120', 'confectioner\'s glaze',
      'carnivorous animal', 'bird of prey', 'blood', 'non-halal slaughtered', 'isinglass', 'civet'
    ],
    'kosher': [
      'pork', 'pig', 'lard', 'bacon', 'ham', 'swine', 'boar',
      'shellfish', 'shrimp', 'crab', 'lobster', 'prawn', 'crayfish', 'scallop', 'oyster', 'mussel', 'clam',
      'rabbit', 'hare', 'camel', 'horse', 'eel', 'catfish', 'sturgeon', 'swordfish', 'shark', 'ray',
      'gelatin', 'gelatine', 'carmine', 'cochineal', 'e120', 'confectioner\'s glaze',
      'insects', 'reptiles', 'amphibians', 'blood'
    ],
    'christian lent': ['meat', 'beef', 'pork', 'chicken', 'turkey', 'lamb', 'mutton', 'veal', 'ham', 'bacon'],
    'orthodox lent': ['meat', 'dairy', 'egg', 'fish', 'oil', 'wine', 'milk', 'cheese', 'butter', 'cream', 'yogurt', 'mayonnaise'],
    'hindu vegetarian': ['beef', 'veal', 'meat', 'pork', 'chicken', 'egg', 'fish', 'gelatin', 'gelatine', 'lard', 'tallow'],
    'jain': ['meat', 'fish', 'egg', 'onion', 'garlic', 'potato', 'carrot', 'beet', 'radish', 'turnip', 'sweet potato', 'yam', 'honey', 'mushrooms', 'yeast', 'multi-seeded fruits', 'root vegetables', 'tuber'],
    'buddhist vegetarian': ['meat', 'fish', 'egg', 'onion', 'garlic', 'leek', 'chive', 'shallot'],
  };

  // OpenFoodFacts style Quality Rules
  static const Map<String, List<String>> qualityKeywords = {
    'palm_oil': ['palm oil', 'palm fat', 'palmitate'],
    'high_processing': ['maltodextrin', 'high fructose corn syrup', 'artificial flavor', 'artificial colour', 'preservative', 'emulsifier', 'stabilizer', 'thickener'],
    'high_sugar': ['sugar', 'glucose', 'fructose', 'sucrose', 'syrup'],
    'high_salt': ['salt', 'sodium', 'monosodium glutamate', 'msg'],
  };

  static List<String> detectAllergies(FoodItem product, List<String> userAllergies) {
    final searchText = _buildSearchText(product);
    final detected = <String>[];
    for (final userAllergen in userAllergies) {
      final allergenKey = userAllergen.toLowerCase();
      final keywords = allergenKeywords[allergenKey] ?? [allergenKey];
      if (keywords.any((keyword) => searchText.contains(keyword))) {
        detected.add(userAllergen);
      }
    }
    return detected;
  }

  static List<String> detectViolations(
      FoodItem product,
      List<String> dietaryPrefs,
      List<String> religiousPrefs,
      [Map<String, dynamic> settings = const {}]
      ) {
    final searchText = _buildSearchText(product);
    final violations = <String>[];

    for (final pref in dietaryPrefs) {
      final keywords = dietaryViolations[pref.toLowerCase()] ?? [];
      if (keywords.any((k) => searchText.contains(k))) {
        violations.add('Not ${pref[0].toUpperCase()}${pref.substring(1)}');
      }
    }

    for (final pref in religiousPrefs) {
      final keywords = religiousViolations[pref.toLowerCase()] ?? [];
      if (keywords.any((k) => searchText.contains(k))) {
        violations.add('Violates ${pref[0].toUpperCase()}${pref.substring(1)}');
      }
    }

    // Quality warnings (OFF style)
    if (settings['palm_oil_free'] == true) {
      if (qualityKeywords['palm_oil']!.any((k) => searchText.contains(k))) {
        violations.add('Contains Palm Oil');
      }
    }
    if (settings['sugar_free'] == true) {
      if (qualityKeywords['high_sugar']!.any((k) => searchText.contains(k))) {
        violations.add('Contains Added Sugar');
      }
    }
    if (settings['avoid_highly_processed'] == true) {
      if (qualityKeywords['high_processing']!.any((k) => searchText.contains(k))) {
        violations.add('Highly Processed');
      }
    }
    if (settings['low_salt'] == true) {
      if (qualityKeywords['high_salt']!.any((k) => searchText.contains(k))) {
        violations.add('High Salt Content');
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
}

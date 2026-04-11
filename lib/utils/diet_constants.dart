// ─── Complete Diet / Allergy / Religious keyword maps ──────────────────────
// Used by scanner_screen.dart and dev filter preview

const Map<String, List<String>> allergenKeywords = {
  'gluten': [
    'gluten', 'wheat', 'barley', 'rye', 'oat', 'spelt', 'kamut', 'farro',
    'semolina', 'farina', 'einkorn', 'durum', 'bulgur', 'triticale',
    'wheat starch', 'wheat flour', 'wheat protein', 'malt', 'malt extract',
    'malt vinegar', 'brewer\'s yeast',
  ],
  'milk': [
    'milk', 'dairy', 'lactose', 'cheese', 'butter', 'cream', 'whey',
    'casein', 'fromage', 'caseinate', 'lactalbumin', 'lactoglobulin',
    'skimmed milk', 'whole milk', 'buttermilk', 'ghee', 'yogurt',
    'yoghurt', 'kefir', 'quark', 'crème fraîche', 'sour cream',
    'half-and-half', 'milk powder', 'milk solids', 'milk protein',
  ],
  'eggs': [
    'egg', 'ovum', 'albumin', 'lysozyme', 'mayonnaise', 'meringue',
    'egg white', 'egg yolk', 'egg powder', 'dried egg', 'egg protein',
    'globulin', 'livetin', 'ovomucin', 'ovalbumin', 'ovomucoid',
    'silici albuminate', 'vitellin',
  ],
  'nuts': [
    'nuts', 'almond', 'cashew', 'walnut', 'pecan', 'pistachio',
    'macadamia', 'hazelnut', 'brazil nut', 'pine nut', 'chestnut',
    'coconut', 'praline', 'marzipan', 'nut paste', 'nut oil',
    'tree nut', 'mixed nuts', 'trail mix',
  ],
  'peanuts': [
    'peanut', 'groundnut', 'arachide', 'peanut oil', 'peanut butter',
    'peanut flour', 'peanut protein', 'monkey nut', 'beer nuts',
    'mixed nuts', 'cold pressed peanut',
  ],
  'sesame': [
    'sesame', 'tahini', 'sesamum', 'sesame oil', 'sesame seed',
    'sesame flour', 'sesame paste', 'til', 'gingelly', 'benne',
  ],
  'soybeans': [
    'soy', 'soya', 'tofu', 'tempeh', 'miso', 'edamame', 'natto',
    'soy sauce', 'tamari', 'textured vegetable protein', 'tvp',
    'soy milk', 'soy protein', 'soy flour', 'soy oil', 'shoyu',
    'kinako', 'yuba', 'okara',
  ],
  'fish': [
    'fish', 'cod', 'salmon', 'tuna', 'halibut', 'anchovy', 'sardine',
    'herring', 'trout', 'bass', 'plaice', 'haddock', 'mackerel',
    'pollock', 'tilapia', 'swordfish', 'mahi', 'snapper', 'flounder',
    'sole', 'pike', 'perch', 'carp', 'catfish', 'barramundi',
    'fish sauce', 'fish paste', 'fish stock', 'fish extract',
    'worcestershire', 'caesar dressing',
  ],
  'shellfish': [
    'shellfish', 'shrimp', 'crab', 'lobster', 'prawn', 'crayfish',
    'scallop', 'oyster', 'mussel', 'clam', 'barnacle', 'langoustine',
    'abalone', 'cuttlefish', 'krill', 'sea urchin', 'whelk',
  ],
  'celery': [
    'celery', 'celeriac', 'celery seed', 'celery salt', 'celery oil',
    'celery root', 'celery extract',
  ],
  'mustard': [
    'mustard', 'mustard seed', 'mustard oil', 'mustard flour',
    'mustard leaves', 'mustard powder', 'mustard sauce', 'dijon',
    'wholegrain mustard', 'english mustard',
  ],
  'lupin': [
    'lupin', 'lupine', 'lupin flour', 'lupin seed', 'lupin bean',
    'lupin protein', 'lupin extract',
  ],
  'molluscs': [
    'mollusc', 'mollusk', 'squid', 'octopus', 'snail', 'scallop',
    'abalone', 'cuttlefish', 'whelk', 'periwinkle', 'limpet',
    'calamari', 'escargot',
  ],
  'sulphites': [
    'sulphite', 'sulfite', 'sulphur dioxide', 'so2', 'e220', 'e221',
    'e222', 'e223', 'e224', 'e225', 'e226', 'e227', 'e228',
    'sodium metabisulphite', 'potassium metabisulphite',
    'sodium bisulphite', 'potassium bisulphite',
  ],
};

const Map<String, List<String>> dietaryViolationKeywords = {
  'vegan': [
    'meat', 'beef', 'pork', 'chicken', 'turkey', 'lamb', 'veal', 'duck',
    'goose', 'rabbit', 'venison', 'bison', 'fish', 'seafood', 'milk',
    'dairy', 'egg', 'cheese', 'butter', 'cream', 'honey', 'gelatin',
    'gelatine', 'lard', 'tallow', 'suet', 'whey', 'casein', 'albumin',
    'lanolin', 'carmine', 'cochineal', 'e120', 'isinglass', 'rennet',
    'shellac', 'e904', 'beeswax', 'e901', 'royal jelly', 'lactose',
    'pepsin', 'animal fat', 'animal shortening',
  ],
  'vegetarian': [
    'meat', 'beef', 'pork', 'chicken', 'turkey', 'lamb', 'veal', 'duck',
    'goose', 'rabbit', 'venison', 'bison', 'fish', 'seafood', 'gelatin',
    'gelatine', 'lard', 'tallow', 'suet', 'rennet', 'isinglass',
    'animal fat', 'carmine', 'cochineal', 'e120', 'anchovy', 'pepsin',
  ],
  'paleo': [
    'grain', 'wheat', 'rice', 'corn', 'oat', 'legume', 'bean', 'lentil',
    'soy', 'dairy', 'sugar', 'processed', 'peanut', 'potato starch',
    'refined', 'additives', 'preservatives', 'artificial',
  ],
  'keto': [
    'sugar', 'glucose', 'fructose', 'corn syrup', 'maltose', 'sucrose',
    'wheat', 'rice', 'corn', 'potato', 'bread', 'pasta', 'cereal',
    'oat', 'barley', 'honey', 'maple syrup', 'agave', 'molasses',
    'starch', 'dextrose', 'maltodextrin',
  ],
  'mediterranean': [
    'trans fat', 'hydrogenated', 'partially hydrogenated', 'artificial',
    'processed meat', 'red meat', 'lard', 'shortening', 'margarine',
    'high fructose', 'corn syrup',
  ],
  'low-carb': [
    'sugar', 'glucose', 'fructose', 'corn syrup', 'wheat', 'rice',
    'starch', 'bread', 'pasta', 'oat', 'honey', 'maltodextrin',
    'dextrose', 'maltose',
  ],
  'dairy-free': [
    'milk', 'dairy', 'lactose', 'cheese', 'butter', 'cream', 'whey',
    'casein', 'fromage', 'caseinate', 'lactalbumin', 'lactoglobulin',
    'skimmed milk', 'whole milk', 'buttermilk', 'ghee', 'yogurt',
    'kefir', 'quark', 'milk powder', 'milk solids', 'milk protein',
  ],
  'gluten-free': [
    'gluten', 'wheat', 'barley', 'rye', 'oat', 'spelt', 'kamut',
    'semolina', 'durum', 'bulgur', 'malt', 'malt extract',
    'wheat starch', 'wheat flour', 'wheat protein',
  ],
};

const Map<String, List<String>> religiousViolationKeywords = {
  'halal': [
    'pork', 'pig', 'lard', 'bacon', 'ham', 'alcohol', 'wine', 'beer',
    'spirits', 'gelatin', 'gelatine', 'swine', 'prosciutto', 'pancetta',
    'salami', 'chorizo', 'pepperoni', 'carnitas', 'chicharron',
    'blood', 'blood sausage', 'black pudding', 'lard', 'suet',
    'ethanol', 'vanilla extract', 'wine vinegar', 'mirin', 'sake',
    'pork rinds', 'pork belly', 'pork fat', 'dripping',
    // non-halal slaughter derivatives
    'non-halal', 'pork broth', 'pork stock', 'pork extract',
  ],
  'kosher': [
    'pork', 'pig', 'lard', 'bacon', 'ham', 'shellfish', 'shrimp',
    'crab', 'lobster', 'rabbit', 'hare', 'eel', 'catfish', 'squid',
    'octopus', 'oyster', 'mussel', 'clam', 'scallop', 'non-kosher',
    // mixing meat & dairy
    'cheeseburger', 'chicken parmesan',
  ],
  'christian lent': [
    'meat', 'beef', 'pork', 'chicken', 'turkey', 'lamb', 'veal',
    'duck', 'goose', 'venison', 'bison',
  ],
  'orthodox lent': [
    'meat', 'beef', 'pork', 'chicken', 'turkey', 'lamb', 'dairy',
    'milk', 'cheese', 'butter', 'cream', 'egg', 'fish', 'olive oil',
    'wine', 'alcohol',
  ],
  'hindu vegetarian': [
    'beef', 'veal', 'meat', 'pork', 'chicken', 'turkey', 'lamb',
    'egg', 'gelatin', 'gelatine', 'lard', 'rennet', 'animal fat',
    'fish', 'seafood',
  ],
  'jain': [
    'meat', 'fish', 'egg', 'onion', 'garlic', 'potato', 'carrot',
    'beet', 'beetroot', 'radish', 'turnip', 'leek', 'chive',
    'scallion', 'shallot', 'ginger', 'turmeric root', 'animal rennet',
  ],
  'buddhist vegetarian': [
    'meat', 'fish', 'egg', 'onion', 'garlic', 'leek', 'chive',
    'scallion', 'shallot', 'animal product', 'gelatin', 'gelatine',
    'alcohol', 'wine', 'beer',
  ],
  'seventh-day adventist': [
    'pork', 'pig', 'lard', 'bacon', 'ham', 'shellfish', 'shrimp',
    'crab', 'lobster', 'alcohol', 'wine', 'beer', 'coffee', 'caffeine',
    'unclean meat',
  ],
  'hindu (no beef)': [
    'beef', 'veal', 'cattle', 'cow', 'buffalo meat', 'bull',
    'gelatin', 'gelatine', 'rennet', 'beef extract', 'beef broth',
    'beef stock', 'beef fat', 'tallow',
  ],
};

// All available dietary preference options shown in Settings
const List<String> allDietaryPrefs = [
  'vegan',
  'vegetarian',
  'paleo',
  'keto',
  'mediterranean',
  'low-carb',
  'dairy-free',
  'gluten-free',
];

// All available religious diet options shown in Settings
const List<String> allReligiousDiets = [
  'halal',
  'kosher',
  'christian lent',
  'orthodox lent',
  'hindu vegetarian',
  'jain',
  'buddhist vegetarian',
  'seventh-day adventist',
  'hindu (no beef)',
];

// All available allergens shown in Settings
const List<String> allAllergens = [
  'gluten',
  'milk',
  'eggs',
  'nuts',
  'peanuts',
  'sesame',
  'soybeans',
  'fish',
  'shellfish',
  'celery',
  'mustard',
  'lupin',
  'molluscs',
  'sulphites',
];
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
    'non-halal', 'pork broth', 'pork stock', 'pork extract',
  ],
  'kosher': [
    'pork', 'pig', 'lard', 'bacon', 'ham', 'shellfish', 'shrimp',
    'crab', 'lobster', 'rabbit', 'hare', 'eel', 'catfish', 'squid',
    'octopus', 'oyster', 'mussel', 'clam', 'scallop', 'non-kosher',
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

// ── Food Quality / Ingredient Preference Filters ─────────────────────────────
// These flag products that contain undesirable ingredients based on quality
// concerns (not dietary identity). Shown under "Ingredient Preferences".

const Map<String, List<String>> qualityFilterKeywords = {
  'sugar-free': [
    'sugar', 'glucose', 'fructose', 'sucrose', 'dextrose', 'maltose',
    'lactose', 'corn syrup', 'high fructose corn syrup', 'golden syrup',
    'maple syrup', 'agave', 'molasses', 'treacle', 'honey', 'invert sugar',
    'cane sugar', 'beet sugar', 'brown sugar', 'icing sugar', 'powdered sugar',
    'caster sugar', 'raw sugar', 'coconut sugar', 'date sugar',
    'e951', 'e952', 'e954', 'e955', 'e960', // artificial sweeteners still count as sugar alternatives — not flagged here
  ],
  'no palm oil': [
    'palm oil', 'palm kernel oil', 'palm fat', 'palm olein',
    'palm stearin', 'hydrogenated palm', 'fractionated palm',
    'vegetable fat', // often contains palm — flag for review
    'vegetable oil', // often palm-based
  ],
  'low sodium': [
    // flag if product explicitly lists high-sodium ingredients
    'salt', 'sodium chloride', 'sea salt', 'rock salt', 'table salt',
    'monosodium glutamate', 'msg', 'sodium bicarbonate', 'baking soda',
    'baking powder', 'sodium nitrate', 'sodium nitrite', 'sodium benzoate',
    'sodium phosphate', 'disodium', 'trisodium', 'sodium', 'bicarbonate',
  ],
  'no artificial additives': [
    // synthetic colorings
    'e102', 'e104', 'e110', 'e120', 'e122', 'e123', 'e124', 'e127',
    'e128', 'e129', 'e131', 'e132', 'e133', 'e142', 'e151', 'e155',
    'tartrazine', 'sunset yellow', 'carmoisine', 'ponceau', 'brilliant blue',
    'green s', 'allura red', 'brilliant black',
    // synthetic preservatives
    'e210', 'e211', 'e212', 'e213', 'e214', 'e215', 'e216', 'e217',
    'e218', 'e219', 'e249', 'e250', 'e251', 'e252',
    'sodium benzoate', 'potassium sorbate', 'sodium nitrite', 'sodium nitrate',
    'benzoic acid', 'sorbic acid', 'bha', 'bht', 'tbhq',
    'e320', 'e321', 'e319',
    // artificial sweeteners
    'aspartame', 'saccharin', 'sucralose', 'acesulfame', 'neotame',
    'advantame', 'cyclamate', 'e950', 'e951', 'e952', 'e954', 'e955',
    // flavor enhancers
    'monosodium glutamate', 'msg', 'e621', 'e622', 'e623', 'e624', 'e625',
    // artificial flavors
    'artificial flavor', 'artificial flavour', 'artificial colour',
    'artificial color', 'artificial sweetener',
  ],
  'no ultra-processed': [
    // NOVA group 4 markers
    'hydrolyzed', 'hydrolysed', 'modified starch', 'textured vegetable protein',
    'tvp', 'protein isolate', 'whey protein isolate', 'soy protein isolate',
    'interesterified', 'maltodextrin', 'high fructose', 'dextrose',
    'invert sugar syrup', 'isoglucose', 'glucose-fructose syrup',
    'polydextrose', 'oligofructose', 'inulin', // in isolation not a concern, but marker
    'carrageenan', 'xanthan gum', 'guar gum', 'locust bean gum',
    'emulsifier', 'stabilizer', 'thickener', 'humectant',
    'anti-caking', 'bleaching agent', 'bulking agent', 'foaming agent',
    'glazing agent', 'propellant', 'sequestrant', 'flavour enhancer',
  ],
  'no trans fat': [
    'partially hydrogenated', 'hydrogenated vegetable oil',
    'hydrogenated fat', 'trans fat', 'partially hydrogenated soybean',
    'partially hydrogenated cottonseed', 'partially hydrogenated canola',
    'shortening', 'vanaspati',
  ],
  'no high fructose corn syrup': [
    'high fructose corn syrup', 'hfcs', 'isoglucose',
    'glucose-fructose syrup', 'glucose fructose syrup',
    'corn syrup', 'corn sweetener',
  ],
  'no msg': [
    'monosodium glutamate', 'msg', 'e621', 'glutamate', 'autolyzed yeast',
    'hydrolyzed protein', 'yeast extract', 'sodium caseinate',
    'soy protein extract', 'malt extract', 'malt flavoring',
  ],
  'organic only': [
    // flags absence — hard to detect automatically, so we flag non-organic markers
    'conventional', 'pesticide', 'herbicide', 'synthetic fertilizer',
    'gmo', 'genetically modified', 'genetically engineered',
  ],
};

// ── Label display config for quality filters ─────────────────────────────────

const Map<String, String> qualityFilterLabels = {
  'sugar-free':              'No Added Sugar',
  'no palm oil':             'No Palm Oil',
  'low sodium':              'Low Sodium',
  'no artificial additives': 'No Artificial Additives',
  'no ultra-processed':      'Avoid Ultra-Processed',
  'no trans fat':            'No Trans Fat',
  'no high fructose corn syrup': 'No HFCS',
  'no msg':                  'No MSG',
  'organic only':            'Organic / Non-GMO',
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

const List<String> allQualityFilters = [
  'sugar-free',
  'no palm oil',
  'low sodium',
  'no artificial additives',
  'no ultra-processed',
  'no trans fat',
  'no high fructose corn syrup',
  'no msg',
  'organic only',
];
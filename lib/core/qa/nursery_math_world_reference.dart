/// Independent Phase-C QA reference for Nursery Math & My World.
///
/// This file intentionally duplicates expected educational facts instead of
/// importing generator catalogs. That lets the Phase-C audit detect drift in
/// production content/generation rather than validating a source against itself.
const Set<String> nurseryPhaseCMathSkillIds = <String>{
  'math_numbers_0_5',
  'math_numbers_6_10',
  'math_numbers_11_20',
  'math_count_0_5',
  'math_count_6_10',
  'math_number_quantity',
  'math_missing_number',
  'math_more_less',
  'math_same_different',
  'math_add_objects',
  'math_add_numerals',
};

const Set<String> nurseryPhaseCWorldSkillIds = <String>{
  'knowledge_colours',
  'knowledge_shapes',
  'knowledge_animals',
  'knowledge_foods',
  'knowledge_objects',
  'knowledge_body',
  'knowledge_routines',
};

/// Curated expected answers for every authored My World activity.
const Map<String, String> nurseryPhaseCWorldAuthoredAnswers = <String, String>{
  'nursery.knowledge_colours.g1': 'red',
  'nursery.knowledge_colours.i1': 'blue',
  'nursery.knowledge_colours.i2': 'green',
  'nursery.knowledge_colours.t1': 'yellow',
  'nursery.knowledge_shapes.g1': '●',
  'nursery.knowledge_shapes.i1': 'triangle',
  'nursery.knowledge_shapes.i2': '■',
  'nursery.knowledge_shapes.t1': 'rectangle',
  'nursery.knowledge_animals.g1': 'cat',
  'nursery.knowledge_animals.i1': 'fish',
  'nursery.knowledge_animals.i2': 'rabbit',
  'nursery.knowledge_animals.t1': 'goat',
  'nursery.knowledge_foods.g1': 'apple',
  'nursery.knowledge_foods.i1': 'carrot',
  'nursery.knowledge_foods.i2': 'mango',
  'nursery.knowledge_foods.t1': 'apple + carrot',
  'nursery.knowledge_objects.g1': 'cup',
  'nursery.knowledge_objects.i1': 'book',
  'nursery.knowledge_objects.i2': 'ball',
  'nursery.knowledge_objects.t1': 'spoon',
  'nursery.knowledge_body.g1': 'eyes',
  'nursery.knowledge_body.i1': 'ears',
  'nursery.knowledge_body.i2': 'hands',
  'nursery.knowledge_body.t1': 'feet',
  'nursery.knowledge_routines.g1': 'wash hands',
  'nursery.knowledge_routines.i1': 'get dressed for the day',
  'nursery.knowledge_routines.i2': 'brush teeth',
  'nursery.knowledge_routines.t1':
      'stay with the adult and wait until it is safe to cross',
};

/// Visual -> vocabulary mapping expected from generated My World practice.
const Map<String, Map<String, String>> nurseryPhaseCWorldGeneratedCatalog =
    <String, Map<String, String>>{
  'knowledge_animals': <String, String>{
    'cat': 'cat',
    'dog': 'dog',
    'fish': 'fish',
    'rabbit': 'rabbit',
    'goat': 'goat',
    'cow': 'cow',
    'tiger': 'tiger',
    'bird': 'bird',
  },
  'knowledge_foods': <String, String>{
    'apple': 'apple',
    'mango': 'mango',
    'carrot': 'carrot',
    'orange': 'orange',
    'banana': 'banana',
    'potato': 'potato',
    'pear': 'pear',
    'broccoli': 'broccoli',
  },
  'knowledge_objects': <String, String>{
    'ball': 'ball',
    'book': 'book',
    'shoe': 'shoe',
    'cup': 'cup',
    'spoon': 'spoon',
    'pencil': 'pencil',
    'hat': 'hat',
    'key': 'key',
  },
  'knowledge_body': <String, String>{
    'eyes': 'eyes',
    'hands': 'hands',
    'feet': 'feet',
    'ears': 'ears',
    'nose': 'nose',
    'mouth': 'mouth',
  },
};

const Map<String, Map<String, String>> nurseryPhaseCColourCatalog =
    <String, Map<String, String>>{
  'knowledge_colours': <String, String>{
    'colour:red': 'red',
    'colour:blue': 'blue',
    'colour:green': 'green',
    'colour:yellow': 'yellow',
    'colour:orange': 'orange',
    'colour:purple': 'purple',
  },
};

const Map<String, Map<String, String>> nurseryPhaseCShapeCatalog =
    <String, Map<String, String>>{
  'knowledge_shapes': <String, String>{
    'circle': 'circle',
    'square': 'square',
    'triangle': 'triangle',
    'rectangle': 'rectangle',
  },
};

/// Minimum number of distinct sequential generated prompts expected before a
/// skill may repeat. The audit caps the check at 64 items for larger pools.
const Map<String, int> nurseryPhaseCNonRepeatWindow = <String, int>{
  'alpha_uppercase': 26,
  'alpha_lowercase': 26,
  'alpha_case_match': 26,
  'alpha_word_picture': 64,
  'alpha_letter_sounds': 64,
  'alpha_listen_select': 26,
  'alpha_beginning_sound': 64,
  'alpha_visual_discrimination': 26,
  'alpha_trace_upper': 26,
  'alpha_trace_lower': 26,
  'math_numbers_0_5': 6,
  'math_numbers_6_10': 5,
  'math_numbers_11_20': 10,
  'math_count_0_5': 21,
  'math_count_6_10': 20,
  'math_number_quantity': 11,
  'math_missing_number': 19,
  'math_more_less': 64,
  'math_same_different': 21,
  'math_add_objects': 64,
  'math_add_numerals': 25,
  'knowledge_colours': 6,
  'knowledge_shapes': 4,
  'knowledge_animals': 8,
  'knowledge_foods': 8,
  'knowledge_objects': 8,
  'knowledge_body': 6,
  'knowledge_routines': 6,
  'thinking_patterns': 6,
  'thinking_matching': 5,
  'thinking_sorting': 4,
  'thinking_observation_listening': 6,
};

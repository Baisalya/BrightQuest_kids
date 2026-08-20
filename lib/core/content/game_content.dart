enum CodingCommand { move, turnLeft, turnRight, repeatLast }

enum FacingDirection { north, east, south, west }

extension FacingDirectionLogic on FacingDirection {
  FacingDirection get turnLeft => switch (this) {
        FacingDirection.north => FacingDirection.west,
        FacingDirection.west => FacingDirection.south,
        FacingDirection.south => FacingDirection.east,
        FacingDirection.east => FacingDirection.north,
      };

  FacingDirection get turnRight => switch (this) {
        FacingDirection.north => FacingDirection.east,
        FacingDirection.east => FacingDirection.south,
        FacingDirection.south => FacingDirection.west,
        FacingDirection.west => FacingDirection.north,
      };

  (int, int) get delta => switch (this) {
        FacingDirection.north => (0, -1),
        FacingDirection.east => (1, 0),
        FacingDirection.south => (0, 1),
        FacingDirection.west => (-1, 0),
      };
}

class MathQuestion {
  const MathQuestion(
    this.text,
    this.answer,
    this.choices,
    this.hint, {
    this.topicId = 'operations',
    this.difficulty = 1,
  });
  final String text;
  final int answer;
  final List<int> choices;
  final String hint;
  final String topicId;
  final int difficulty;
}

class FractionMission {
  const FractionMission({
    required this.id,
    required this.totalSlices,
    required this.numerator,
    required this.denominator,
    this.topicId = 'fractions',
    this.difficulty = 1,
  });
  final String id;
  final int totalSlices;
  final int numerator;
  final int denominator;
  final String topicId;
  final int difficulty;
}

class ScienceQuizQuestion {
  const ScienceQuizQuestion(
    this.question,
    this.answer,
    this.choices,
    this.explanation, {
    this.topicId = 'science_core',
    this.difficulty = 1,
  });
  final String question;
  final String answer;
  final List<String> choices;
  final String explanation;
  final String topicId;
  final int difficulty;
}

class ScienceReaction {
  const ScienceReaction({
    required this.id,
    required this.title,
    required this.explanation,
    required this.emoji,
  });
  final String id;
  final String title;
  final String explanation;
  final String emoji;
}

class StoryMission {
  const StoryMission({
    required this.id,
    required this.prompt,
    required this.words,
    this.topicId = 'sentence_building',
    this.difficulty = 1,
  });
  final String id;
  final String prompt;
  final List<String> words;
  final String topicId;
  final int difficulty;
}

class GrammarMission {
  const GrammarMission({
    required this.id,
    required this.sentence,
    required this.noun,
    required this.verb,
    required this.adjective,
    this.topicId = 'parts_of_speech',
    this.difficulty = 1,
  });
  final String id;
  final String sentence;
  final String noun;
  final String verb;
  final String adjective;
  final String topicId;
  final int difficulty;
}

class MapQuestion {
  const MapQuestion(
    this.id,
    this.question,
    this.answer,
    this.choices,
    this.hint, {
    this.topicId = 'map_skills',
    this.difficulty = 1,
  });
  final String id;
  final String question;
  final String answer;
  final List<String> choices;
  final String hint;
  final String topicId;
  final int difficulty;
}

class CodingMission {
  const CodingMission({
    required this.id,
    required this.width,
    required this.height,
    required this.startX,
    required this.startY,
    required this.goalX,
    required this.goalY,
    required this.startDirection,
    this.obstacles = const <String>{},
    required this.maxCommands,
    this.topicId = 'algorithms',
    this.difficulty = 1,
  });
  final String id;
  final int width;
  final int height;
  final int startX;
  final int startY;
  final int goalX;
  final int goalY;
  final FacingDirection startDirection;
  final Set<String> obstacles;
  final int maxCommands;
  final String topicId;
  final int difficulty;
}

class RecyclingItem {
  const RecyclingItem(
    this.id,
    this.name,
    this.emoji,
    this.bin, {
    this.topicId = 'waste_sorting',
    this.difficulty = 1,
  });
  final String id;
  final String name;
  final String emoji;
  final String bin;
  final String topicId;
  final int difficulty;
}

List<T> _throughDifficulty<T>(
  List<T> values,
  int difficulty,
  int Function(T value) level,
) {
  final safe = difficulty.clamp(1, 3).toInt();
  final result = values.where((value) => level(value) <= safe).toList();
  return result.isEmpty ? values.take(1).toList() : result;
}

List<MathQuestion> mathQuestionsForClass(int classNumber, {int difficulty = 3}) {
  final bank = switch (classNumber) {
    3 => const <MathQuestion>[
        MathQuestion('24 ÷ 6 = ?', 4, [3, 4, 5, 6], 'Think: 6 × ? = 24.', topicId: 'division', difficulty: 1),
        MathQuestion('7 × 6 = ?', 42, [36, 40, 42, 48], 'Use the 7-times table.', topicId: 'multiplication', difficulty: 1),
        MathQuestion('63 - 28 = ?', 35, [25, 35, 41, 45], 'Subtract 20, then subtract 8.', topicId: 'subtraction', difficulty: 1),
        MathQuestion('125 + 75 = ?', 200, [180, 190, 200, 210], 'Make 125 + 25 first.', topicId: 'addition', difficulty: 1),
        MathQuestion('36 ÷ 4 = ?', 9, [6, 8, 9, 12], 'Think: 4 × ? = 36.', topicId: 'division', difficulty: 2),
        MathQuestion('9 × 5 = ?', 45, [35, 40, 45, 50], 'Five groups of nine make 45.', topicId: 'multiplication', difficulty: 2),
        MathQuestion('208 + 167 = ?', 375, [365, 375, 385, 395], 'Add hundreds, tens and ones.', topicId: 'addition', difficulty: 2),
        MathQuestion('432 - 158 = ?', 274, [264, 274, 284, 294], 'Regroup from hundreds to tens and ones.', topicId: 'subtraction', difficulty: 2),
        MathQuestion('300 - 146 = ?', 154, [144, 154, 164, 174], 'Regroup carefully.', topicId: 'subtraction', difficulty: 3),
        MathQuestion('8 × 9 - 12 = ?', 60, [54, 60, 62, 72], 'Multiply first, then subtract.', topicId: 'mixed_operations', difficulty: 3),
        MathQuestion('6 × 7 + 18 = ?', 60, [52, 58, 60, 66], 'Multiply first, then add.', topicId: 'mixed_operations', difficulty: 3),
        MathQuestion('144 ÷ 12 = ?', 12, [10, 11, 12, 14], 'Think: 12 × ? = 144.', topicId: 'division', difficulty: 3),
      ],
    5 => const <MathQuestion>[
        MathQuestion('144 ÷ 12 = ?', 12, [10, 11, 12, 14], 'Think: 12 × ? = 144.', topicId: 'division', difficulty: 1),
        MathQuestion('375 + 248 = ?', 623, [613, 623, 633, 643], 'Add by place value.', topicId: 'addition', difficulty: 1),
        MathQuestion('900 - 457 = ?', 443, [433, 443, 453, 463], 'Regroup across the zeros.', topicId: 'subtraction', difficulty: 1),
        MathQuestion('32 × 10 = ?', 320, [32, 300, 320, 3200], 'Multiplying by 10 shifts the place value.', topicId: 'multiplication', difficulty: 1),
        MathQuestion('25 × 16 = ?', 400, [350, 375, 400, 425], 'Break 16 into 10 + 6.', topicId: 'multiplication', difficulty: 2),
        MathQuestion('840 ÷ 7 = ?', 120, [110, 120, 130, 140], '84 ÷ 7 = 12, then keep the zero.', topicId: 'division', difficulty: 2),
        MathQuestion('18 × 24 = ?', 432, [412, 422, 432, 442], '18 × 20 plus 18 × 4.', topicId: 'multiplication', difficulty: 2),
        MathQuestion('1,250 - 675 = ?', 575, [565, 575, 585, 595], 'Subtract with regrouping.', topicId: 'subtraction', difficulty: 2),
        MathQuestion('48 × 25 = ?', 1200, [1000, 1100, 1200, 1250], '25 is one quarter of 100.', topicId: 'multiplication', difficulty: 3),
        MathQuestion('960 ÷ 24 = ?', 40, [30, 35, 40, 45], '24 × 4 = 96, then scale by ten.', topicId: 'division', difficulty: 3),
        MathQuestion('36 × 18 - 148 = ?', 500, [480, 490, 500, 510], 'Multiply first: 36 × 18 = 648.', topicId: 'mixed_operations', difficulty: 3),
        MathQuestion('2,400 ÷ 16 = ?', 150, [125, 140, 150, 160], '16 × 15 = 240, then scale by ten.', topicId: 'division', difficulty: 3),
      ],
    _ => const <MathQuestion>[
        MathQuestion('24 ÷ 6 = ?', 4, [3, 4, 5, 6], 'Think: 6 × ? = 24.', topicId: 'division', difficulty: 1),
        MathQuestion('7 × 8 = ?', 56, [48, 54, 56, 64], 'Use 7 × 4 = 28, then double it.', topicId: 'multiplication', difficulty: 1),
        MathQuestion('45 + 27 = ?', 72, [62, 67, 72, 75], '45 + 20 = 65, then +7.', topicId: 'addition', difficulty: 1),
        MathQuestion('96 - 38 = ?', 58, [48, 52, 58, 68], 'Subtract 40, then add 2.', topicId: 'subtraction', difficulty: 1),
        MathQuestion('63 ÷ 9 = ?', 7, [6, 7, 8, 9], 'Think: 9 × ? = 63.', topicId: 'division', difficulty: 2),
        MathQuestion('12 × 6 = ?', 72, [62, 68, 72, 76], '10 × 6 plus 2 × 6.', topicId: 'multiplication', difficulty: 2),
        MathQuestion('275 + 149 = ?', 424, [414, 424, 434, 444], 'Add by place value.', topicId: 'addition', difficulty: 2),
        MathQuestion('650 - 287 = ?', 363, [353, 363, 373, 383], 'Regroup hundreds, tens and ones.', topicId: 'subtraction', difficulty: 2),
        MathQuestion('500 - 286 = ?', 214, [204, 214, 224, 234], 'Regroup from the hundreds.', topicId: 'subtraction', difficulty: 3),
        MathQuestion('15 × 12 = ?', 180, [160, 170, 180, 190], '15 × 10 plus 15 × 2.', topicId: 'multiplication', difficulty: 3),
        MathQuestion('18 × 7 + 24 = ?', 150, [140, 146, 150, 154], 'Multiply first, then add.', topicId: 'mixed_operations', difficulty: 3),
        MathQuestion('864 ÷ 8 = ?', 108, [98, 104, 108, 118], 'Split 864 into 800 + 64.', topicId: 'division', difficulty: 3),
      ],
  };
  return _throughDifficulty(bank, difficulty, (question) => question.difficulty);
}

List<FractionMission> fractionMissionsForClass(int classNumber, {int difficulty = 3}) {
  final bank = switch (classNumber) {
    3 => const <FractionMission>[
        FractionMission(id: 'f3_1', totalSlices: 8, numerator: 1, denominator: 4, topicId: 'unit_fractions', difficulty: 1),
        FractionMission(id: 'f3_2', totalSlices: 6, numerator: 1, denominator: 2, topicId: 'unit_fractions', difficulty: 1),
        FractionMission(id: 'f3_3', totalSlices: 8, numerator: 3, denominator: 4, topicId: 'fraction_models', difficulty: 2),
        FractionMission(id: 'f3_4', totalSlices: 9, numerator: 1, denominator: 3, topicId: 'fraction_models', difficulty: 2),
        FractionMission(id: 'f3_5', totalSlices: 12, numerator: 2, denominator: 3, topicId: 'equivalent_fractions', difficulty: 3),
        FractionMission(id: 'f3_6', totalSlices: 10, numerator: 3, denominator: 5, topicId: 'equivalent_fractions', difficulty: 3),
      ],
    5 => const <FractionMission>[
        FractionMission(id: 'f5_1', totalSlices: 12, numerator: 5, denominator: 6, topicId: 'fraction_models', difficulty: 1),
        FractionMission(id: 'f5_2', totalSlices: 16, numerator: 3, denominator: 8, topicId: 'fraction_models', difficulty: 1),
        FractionMission(id: 'f5_3', totalSlices: 20, numerator: 7, denominator: 10, topicId: 'equivalent_fractions', difficulty: 2),
        FractionMission(id: 'f5_4', totalSlices: 18, numerator: 5, denominator: 9, topicId: 'equivalent_fractions', difficulty: 2),
        FractionMission(id: 'f5_5', totalSlices: 24, numerator: 7, denominator: 12, topicId: 'fraction_reasoning', difficulty: 3),
        FractionMission(id: 'f5_6', totalSlices: 30, numerator: 4, denominator: 5, topicId: 'fraction_reasoning', difficulty: 3),
      ],
    _ => const <FractionMission>[
        FractionMission(id: 'f4_1', totalSlices: 8, numerator: 1, denominator: 4, topicId: 'fraction_models', difficulty: 1),
        FractionMission(id: 'f4_2', totalSlices: 12, numerator: 2, denominator: 3, topicId: 'fraction_models', difficulty: 1),
        FractionMission(id: 'f4_3', totalSlices: 10, numerator: 3, denominator: 5, topicId: 'equivalent_fractions', difficulty: 2),
        FractionMission(id: 'f4_4', totalSlices: 16, numerator: 3, denominator: 4, topicId: 'equivalent_fractions', difficulty: 2),
        FractionMission(id: 'f4_5', totalSlices: 18, numerator: 5, denominator: 6, topicId: 'fraction_reasoning', difficulty: 3),
        FractionMission(id: 'f4_6', totalSlices: 20, numerator: 7, denominator: 10, topicId: 'fraction_reasoning', difficulty: 3),
      ],
  };
  return _throughDifficulty(bank, difficulty, (mission) => mission.difficulty);
}

List<ScienceQuizQuestion> scienceQuestionsForClass(int classNumber, {int difficulty = 3}) {
  final bank = switch (classNumber) {
    3 => const <ScienceQuizQuestion>[
        ScienceQuizQuestion('Which part of a plant usually absorbs water from soil?', 'Roots', ['Roots', 'Flower', 'Fruit', 'Seed'], 'Roots take in water and minerals from the soil.', topicId: 'plants', difficulty: 1),
        ScienceQuizQuestion('Which object is most likely to float in water?', 'Wood', ['Wood', 'Rock', 'Coin', 'Steel Ball'], 'Many kinds of dry wood are less dense than water.', topicId: 'materials', difficulty: 1),
        ScienceQuizQuestion('Which state of matter keeps its own shape?', 'Solid', ['Solid', 'Liquid', 'Gas', 'Steam'], 'A solid keeps a definite shape under ordinary conditions.', topicId: 'matter', difficulty: 1),
        ScienceQuizQuestion('Which part of a plant usually makes seeds?', 'Flower', ['Flower', 'Root', 'Stem', 'Soil'], 'Flowers help many plants reproduce and form seeds.', topicId: 'plants', difficulty: 2),
        ScienceQuizQuestion('What happens to ice when it gets warm enough?', 'It melts into water', ['It melts into water', 'It becomes metal', 'It disappears forever', 'It becomes soil'], 'Heating ice changes it from a solid to a liquid.', topicId: 'matter', difficulty: 2),
        ScienceQuizQuestion('Which material usually absorbs water best?', 'Cotton cloth', ['Cotton cloth', 'Glass', 'Plastic ruler', 'Metal spoon'], 'Cotton has fibres that can take in water.', topicId: 'materials', difficulty: 2),
        ScienceQuizQuestion('Why do green plants need sunlight?', 'To help make food', ['To help make food', 'To make soil', 'To turn roots into flowers', 'To stop using water'], 'Plants use light energy during photosynthesis.', topicId: 'plants', difficulty: 3),
        ScienceQuizQuestion('Water vapour cooling into tiny drops is called…', 'Condensation', ['Condensation', 'Melting', 'Freezing', 'Burning'], 'Cooling water vapour can form liquid droplets.', topicId: 'matter', difficulty: 3),
        ScienceQuizQuestion('Which property helps us choose glass for a window?', 'It is transparent', ['It is transparent', 'It is magnetic', 'It is soft like cloth', 'It dissolves in water'], 'Transparent materials let light pass through.', topicId: 'materials', difficulty: 3),
      ],
    5 => const <ScienceQuizQuestion>[
        ScienceQuizQuestion('Which organ pumps blood around the body?', 'Heart', ['Heart', 'Lungs', 'Stomach', 'Brain'], 'The heart pumps blood through blood vessels.', topicId: 'human_body', difficulty: 1),
        ScienceQuizQuestion('Which state of matter spreads to fill its container?', 'Gas', ['Gas', 'Solid', 'Rock', 'Ice'], 'A gas spreads out and fills available space.', topicId: 'matter', difficulty: 1),
        ScienceQuizQuestion('Which material is attracted strongly by a magnet?', 'Iron', ['Iron', 'Wood', 'Rubber', 'Glass'], 'Iron is a magnetic material.', topicId: 'materials', difficulty: 1),
        ScienceQuizQuestion('Which change can usually be reversed?', 'Melting ice', ['Burning paper', 'Melting ice', 'Cooking an egg', 'Rusting iron'], 'Melted water can freeze back into ice.', topicId: 'changes', difficulty: 2),
        ScienceQuizQuestion('Plants mainly take in which gas for photosynthesis?', 'Carbon dioxide', ['Oxygen', 'Carbon dioxide', 'Nitrogen', 'Helium'], 'Plants use carbon dioxide, water and light to make food.', topicId: 'plants', difficulty: 2),
        ScienceQuizQuestion('Which simple machine helps lift a load using a wheel and rope?', 'Pulley', ['Pulley', 'Magnet', 'Thermometer', 'Compass'], 'A pulley changes the direction of a pulling force.', topicId: 'forces', difficulty: 2),
        ScienceQuizQuestion('Why does a shadow change length during the day?', 'The Sun appears at different angles', ['The Sun appears at different angles', 'The object loses mass', 'Air becomes solid', 'Gravity switches off'], 'The angle of incoming sunlight changes as Earth rotates.', topicId: 'light', difficulty: 3),
        ScienceQuizQuestion('Which body system carries oxygen and nutrients around the body?', 'Circulatory system', ['Circulatory system', 'Digestive system only', 'Skeleton only', 'Skin only'], 'Blood in the circulatory system transports oxygen and nutrients.', topicId: 'human_body', difficulty: 3),
        ScienceQuizQuestion('Rusting is an example of…', 'A chemical change', ['A chemical change', 'A reversible shape change', 'Freezing', 'Evaporation only'], 'Rust forms a new substance when iron reacts with oxygen and moisture.', topicId: 'changes', difficulty: 3),
      ],
    _ => const <ScienceQuizQuestion>[
        ScienceQuizQuestion('Which object is most likely to float in water?', 'Wood', ['Wood', 'Rock', 'Coin', 'Steel Ball'], 'Many kinds of dry wood are less dense than water.', topicId: 'materials', difficulty: 1),
        ScienceQuizQuestion('Which state of matter keeps its own shape?', 'Solid', ['Solid', 'Liquid', 'Gas', 'Steam'], 'A solid keeps a definite shape under ordinary conditions.', topicId: 'matter', difficulty: 1),
        ScienceQuizQuestion('Which part of a plant takes in most water from soil?', 'Roots', ['Roots', 'Flower', 'Fruit', 'Leaf tip'], 'Roots absorb water and minerals.', topicId: 'plants', difficulty: 1),
        ScienceQuizQuestion('Which material is attracted strongly by a magnet?', 'Iron', ['Iron', 'Wood', 'Rubber', 'Glass'], 'Iron is a magnetic material.', topicId: 'materials', difficulty: 2),
        ScienceQuizQuestion('What usually happens to water below its freezing point?', 'It becomes solid ice', ['It becomes solid ice', 'It becomes a gas', 'It disappears', 'It becomes metal'], 'Freezing changes liquid water into solid ice.', topicId: 'matter', difficulty: 2),
        ScienceQuizQuestion('Plants mainly take in which gas for photosynthesis?', 'Carbon dioxide', ['Oxygen', 'Carbon dioxide', 'Nitrogen', 'Helium'], 'Plants use carbon dioxide, water and light to make food.', topicId: 'plants', difficulty: 2),
        ScienceQuizQuestion('A magnet has the strongest pull near its…', 'Poles', ['Poles', 'Middle only', 'Label', 'Shadow'], 'Magnetic force is strongest near the poles.', topicId: 'forces', difficulty: 3),
        ScienceQuizQuestion('Evaporation changes liquid water into…', 'Water vapour', ['Water vapour', 'Ice', 'Soil', 'Metal'], 'During evaporation, liquid water becomes a gas.', topicId: 'matter', difficulty: 3),
        ScienceQuizQuestion('Which investigation is a fair test?', 'Change one factor and keep others the same', ['Change one factor and keep others the same', 'Change everything at once', 'Guess without observing', 'Use different rules each time'], 'A fair test changes one variable while controlling the others.', topicId: 'scientific_method', difficulty: 3),
      ],
  };
  return _throughDifficulty(bank, difficulty, (question) => question.difficulty);
}

List<StoryMission> storyMissionsForClass(int classNumber, {int difficulty = 3}) {
  final bank = switch (classNumber) {
    3 => const <StoryMission>[
        StoryMission(id: 'story3_1', prompt: 'Ria found a red kite near the tree.', words: ['Ria', 'found', 'a', 'red', 'kite', 'near', 'the', 'tree'], topicId: 'sentence_building', difficulty: 1),
        StoryMission(id: 'story3_2', prompt: 'The small puppy ran across the garden.', words: ['The', 'small', 'puppy', 'ran', 'across', 'the', 'garden'], topicId: 'sentence_building', difficulty: 1),
        StoryMission(id: 'story3_3', prompt: 'After lunch, Mina carefully packed her school bag.', words: ['After', 'lunch', 'Mina', 'carefully', 'packed', 'her', 'school', 'bag'], topicId: 'story_sequence', difficulty: 2),
        StoryMission(id: 'story3_4', prompt: 'A bright rainbow appeared above the quiet village.', words: ['A', 'bright', 'rainbow', 'appeared', 'above', 'the', 'quiet', 'village'], topicId: 'descriptive_language', difficulty: 2),
        StoryMission(id: 'story3_5', prompt: 'Before sunset, the friends returned home safely together.', words: ['Before', 'sunset', 'the', 'friends', 'returned', 'home', 'safely', 'together'], topicId: 'story_sequence', difficulty: 3),
        StoryMission(id: 'story3_6', prompt: 'The curious child gently opened the mysterious wooden box.', words: ['The', 'curious', 'child', 'gently', 'opened', 'the', 'mysterious', 'wooden', 'box'], topicId: 'descriptive_language', difficulty: 3),
      ],
    5 => const <StoryMission>[
        StoryMission(id: 'story5_1', prompt: 'Arjun recorded the first clue in his notebook.', words: ['Arjun', 'recorded', 'the', 'first', 'clue', 'in', 'his', 'notebook'], topicId: 'story_sequence', difficulty: 1),
        StoryMission(id: 'story5_2', prompt: 'The patient explorer waited beside the ancient gate.', words: ['The', 'patient', 'explorer', 'waited', 'beside', 'the', 'ancient', 'gate'], topicId: 'descriptive_language', difficulty: 1),
        StoryMission(id: 'story5_3', prompt: 'Although the path was steep, the team continued bravely.', words: ['Although', 'the', 'path', 'was', 'steep', 'the', 'team', 'continued', 'bravely'], topicId: 'complex_sentences', difficulty: 2),
        StoryMission(id: 'story5_4', prompt: 'A sudden storm forced the travellers to change their plan.', words: ['A', 'sudden', 'storm', 'forced', 'the', 'travellers', 'to', 'change', 'their', 'plan'], topicId: 'cause_and_effect', difficulty: 2),
        StoryMission(id: 'story5_5', prompt: 'Because they shared their supplies, everyone reached the village safely.', words: ['Because', 'they', 'shared', 'their', 'supplies', 'everyone', 'reached', 'the', 'village', 'safely'], topicId: 'cause_and_effect', difficulty: 3),
        StoryMission(id: 'story5_6', prompt: 'At dawn, the determined group finally discovered the hidden observatory.', words: ['At', 'dawn', 'the', 'determined', 'group', 'finally', 'discovered', 'the', 'hidden', 'observatory'], topicId: 'descriptive_language', difficulty: 3),
      ],
    _ => const <StoryMission>[
        StoryMission(id: 'story4_1', prompt: 'Ria found a glowing map near the old tree.', words: ['Ria', 'found', 'a', 'glowing', 'map', 'near', 'the', 'old', 'tree'], topicId: 'sentence_building', difficulty: 1),
        StoryMission(id: 'story4_2', prompt: 'The tiny dragon followed her into the forest.', words: ['The', 'tiny', 'dragon', 'followed', 'her', 'into', 'the', 'forest'], topicId: 'sentence_building', difficulty: 1),
        StoryMission(id: 'story4_3', prompt: 'Together they opened the hidden treasure chest.', words: ['Together', 'they', 'opened', 'the', 'hidden', 'treasure', 'chest'], topicId: 'story_sequence', difficulty: 2),
        StoryMission(id: 'story4_4', prompt: 'A gentle breeze carried silver leaves across the path.', words: ['A', 'gentle', 'breeze', 'carried', 'silver', 'leaves', 'across', 'the', 'path'], topicId: 'descriptive_language', difficulty: 2),
        StoryMission(id: 'story4_5', prompt: 'Before sunset, the friends safely returned to their village.', words: ['Before', 'sunset', 'the', 'friends', 'safely', 'returned', 'to', 'their', 'village'], topicId: 'story_sequence', difficulty: 3),
        StoryMission(id: 'story4_6', prompt: 'Because the bridge was broken, they searched for another route.', words: ['Because', 'the', 'bridge', 'was', 'broken', 'they', 'searched', 'for', 'another', 'route'], topicId: 'cause_and_effect', difficulty: 3),
      ],
  };
  return _throughDifficulty(bank, difficulty, (mission) => mission.difficulty);
}

List<GrammarMission> grammarMissionsForClass(int classNumber, {int difficulty = 3}) {
  final bank = switch (classNumber) {
    3 => const <GrammarMission>[
        GrammarMission(id: 'grammar3_1', sentence: 'The brave dog runs.', noun: 'dog', verb: 'runs', adjective: 'brave', difficulty: 1),
        GrammarMission(id: 'grammar3_2', sentence: 'A bright star shines.', noun: 'star', verb: 'shines', adjective: 'bright', difficulty: 1),
        GrammarMission(id: 'grammar3_3', sentence: 'The noisy train moves.', noun: 'train', verb: 'moves', adjective: 'noisy', difficulty: 2),
        GrammarMission(id: 'grammar3_4', sentence: 'The clever fox jumps.', noun: 'fox', verb: 'jumps', adjective: 'clever', difficulty: 2),
        GrammarMission(id: 'grammar3_5', sentence: 'A gentle breeze cools the room.', noun: 'breeze', verb: 'cools', adjective: 'gentle', difficulty: 3),
        GrammarMission(id: 'grammar3_6', sentence: 'The colourful butterfly visits flowers.', noun: 'butterfly', verb: 'visits', adjective: 'colourful', difficulty: 3),
      ],
    5 => const <GrammarMission>[
        GrammarMission(id: 'grammar5_1', sentence: 'The curious student observes.', noun: 'student', verb: 'observes', adjective: 'curious', difficulty: 1),
        GrammarMission(id: 'grammar5_2', sentence: 'A powerful river flows.', noun: 'river', verb: 'flows', adjective: 'powerful', difficulty: 1),
        GrammarMission(id: 'grammar5_3', sentence: 'The ancient monument attracts visitors.', noun: 'monument', verb: 'attracts', adjective: 'ancient', difficulty: 2),
        GrammarMission(id: 'grammar5_4', sentence: 'The careful scientist records results.', noun: 'scientist', verb: 'records', adjective: 'careful', difficulty: 2),
        GrammarMission(id: 'grammar5_5', sentence: 'The enormous telescope reveals distant planets.', noun: 'telescope', verb: 'reveals', adjective: 'enormous', difficulty: 3),
        GrammarMission(id: 'grammar5_6', sentence: 'A determined athlete completes the difficult race.', noun: 'athlete', verb: 'completes', adjective: 'determined', difficulty: 3),
      ],
    _ => const <GrammarMission>[
        GrammarMission(id: 'grammar4_1', sentence: 'The brave dragon flies.', noun: 'dragon', verb: 'flies', adjective: 'brave', difficulty: 1),
        GrammarMission(id: 'grammar4_2', sentence: 'The clever fox jumps.', noun: 'fox', verb: 'jumps', adjective: 'clever', difficulty: 1),
        GrammarMission(id: 'grammar4_3', sentence: 'The noisy train moves.', noun: 'train', verb: 'moves', adjective: 'noisy', difficulty: 2),
        GrammarMission(id: 'grammar4_4', sentence: 'The curious student carefully observes.', noun: 'student', verb: 'observes', adjective: 'curious', difficulty: 2),
        GrammarMission(id: 'grammar4_5', sentence: 'A powerful river crosses the fertile plain.', noun: 'river', verb: 'crosses', adjective: 'powerful', difficulty: 3),
        GrammarMission(id: 'grammar4_6', sentence: 'The patient gardener waters young plants.', noun: 'gardener', verb: 'waters', adjective: 'patient', difficulty: 3),
      ],
  };
  return _throughDifficulty(bank, difficulty, (mission) => mission.difficulty);
}

List<MapQuestion> mapQuestionsForClass(int classNumber, {int difficulty = 3}) {
  final bank = switch (classNumber) {
    3 => const <MapQuestion>[
        MapQuestion('map3_1', 'The Sun rises in which direction?', 'East', ['East', 'West', 'North', 'South'], 'Think about where morning sunlight appears.', topicId: 'directions', difficulty: 1),
        MapQuestion('map3_2', 'If the park is north of your school, which way do you travel to reach it?', 'North', ['North', 'South', 'East', 'West'], 'Use the direction named in the question.', topicId: 'directions', difficulty: 1),
        MapQuestion('map3_3', 'Which place would you use to borrow books?', 'Library', ['Library', 'Hospital', 'Bus stop', 'Farm'], 'Think of a place with shelves of books.', topicId: 'community_places', difficulty: 2),
        MapQuestion('map3_4', 'A map symbol is mainly used to…', 'Represent a place or feature', ['Represent a place or feature', 'Measure temperature', 'Cook food', 'Play music'], 'Symbols make maps easier to read.', topicId: 'map_skills', difficulty: 2),
        MapQuestion('map3_5', 'If you face north, which direction is on your right?', 'East', ['East', 'West', 'South', 'North'], 'Picture a compass with north at the top.', topicId: 'directions', difficulty: 3),
        MapQuestion('map3_6', 'Which map feature explains what symbols mean?', 'Legend or key', ['Legend or key', 'Title only', 'Weather report', 'Ruler only'], 'A key explains map symbols.', topicId: 'map_skills', difficulty: 3),
      ],
    5 => const <MapQuestion>[
        MapQuestion('map5_1', 'Which mountain range forms a major natural boundary in northern India?', 'Himalayas', ['Himalayas', 'Aravallis', 'Western Ghats', 'Nilgiris'], 'It includes many of the world’s highest peaks.', topicId: 'physical_geography', difficulty: 1),
        MapQuestion('map5_2', 'Which ocean lies to the south of India?', 'Indian Ocean', ['Indian Ocean', 'Atlantic Ocean', 'Arctic Ocean', 'Pacific Ocean'], 'The ocean shares India’s name.', topicId: 'physical_geography', difficulty: 1),
        MapQuestion('map5_3', 'If you travel from Mumbai to Kolkata, your main direction is mostly…', 'East', ['East', 'West', 'North', 'South'], 'Kolkata lies east of Mumbai.', topicId: 'directions', difficulty: 2),
        MapQuestion('map5_4', 'Which river is strongly associated with the northern plains of India?', 'Ganga', ['Ganga', 'Nile', 'Amazon', 'Thames'], 'It is one of India’s major river systems.', topicId: 'physical_geography', difficulty: 2),
        MapQuestion('map5_5', 'The Deccan Plateau is mainly in which part of India?', 'Peninsular India', ['Peninsular India', 'Far northern Himalayas', 'Only the Thar Desert', 'Only the Ganga delta'], 'Think of the large plateau south of the northern plains.', topicId: 'physical_geography', difficulty: 3),
        MapQuestion('map5_6', 'Why are map scales useful?', 'They compare map distance with real distance', ['They compare map distance with real distance', 'They show only weather', 'They name every person', 'They replace directions'], 'A scale lets us estimate actual distance.', topicId: 'map_skills', difficulty: 3),
      ],
    _ => const <MapQuestion>[
        MapQuestion('map4_1', 'Which state is famous for Konark Sun Temple?', 'Odisha', ['Odisha', 'Punjab', 'Gujarat', 'Kerala'], 'Look toward India’s eastern coast.', topicId: 'india_places', difficulty: 1),
        MapQuestion('map4_2', 'Jaipur is the capital of which state?', 'Rajasthan', ['Rajasthan', 'Bihar', 'Assam', 'Goa'], 'Think of the Pink City.', topicId: 'states_capitals', difficulty: 1),
        MapQuestion('map4_3', 'Which river flows through Delhi?', 'Yamuna', ['Yamuna', 'Godavari', 'Kaveri', 'Narmada'], 'It is a major tributary of the Ganga.', topicId: 'rivers', difficulty: 2),
        MapQuestion('map4_4', 'Which state is at India’s southern tip on the mainland?', 'Tamil Nadu', ['Tamil Nadu', 'Odisha', 'Punjab', 'Sikkim'], 'Kanyakumari is here.', topicId: 'india_places', difficulty: 2),
        MapQuestion('map4_5', 'If you travel from Mumbai to Kolkata, your main direction is mostly…', 'East', ['East', 'West', 'North', 'South'], 'Kolkata lies east of Mumbai.', topicId: 'directions', difficulty: 3),
        MapQuestion('map4_6', 'Which mountain range lies along much of India’s western edge?', 'Western Ghats', ['Western Ghats', 'Himalayas', 'Aravallis only', 'Vindhyas only'], 'Its name gives a clue about its location.', topicId: 'physical_geography', difficulty: 3),
      ],
  };
  return _throughDifficulty(bank, difficulty, (question) => question.difficulty);
}

const codingMissions = <CodingMission>[
  CodingMission(id: 'code_1', width: 4, height: 3, startX: 0, startY: 0, goalX: 2, goalY: 1, startDirection: FacingDirection.east, maxCommands: 4, topicId: 'sequences', difficulty: 1),
  CodingMission(id: 'code_2', width: 4, height: 4, startX: 0, startY: 2, goalX: 2, goalY: 0, startDirection: FacingDirection.east, obstacles: {'1,1'}, maxCommands: 6, topicId: 'turns', difficulty: 1),
  CodingMission(id: 'code_3', width: 5, height: 4, startX: 1, startY: 3, goalX: 4, goalY: 1, startDirection: FacingDirection.north, obstacles: {'1,1', '3,2'}, maxCommands: 8, topicId: 'route_planning', difficulty: 2),
  CodingMission(id: 'code_4', width: 5, height: 5, startX: 0, startY: 4, goalX: 4, goalY: 0, startDirection: FacingDirection.north, obstacles: {'0,2', '2,3', '3,1'}, maxCommands: 12, topicId: 'route_planning', difficulty: 2),
  CodingMission(id: 'code_5', width: 6, height: 5, startX: 0, startY: 4, goalX: 5, goalY: 0, startDirection: FacingDirection.east, obstacles: {'2,4', '2,3', '4,2'}, maxCommands: 14, topicId: 'efficient_algorithms', difficulty: 3),
  CodingMission(id: 'code_6', width: 6, height: 6, startX: 1, startY: 5, goalX: 5, goalY: 1, startDirection: FacingDirection.north, obstacles: {'1,3', '2,3', '4,4', '4,2'}, maxCommands: 16, topicId: 'efficient_algorithms', difficulty: 3),
];

const _class3CodingMissions = <CodingMission>[
  CodingMission(id: 'c3_code_1', width: 4, height: 3, startX: 0, startY: 1, goalX: 2, goalY: 1, startDirection: FacingDirection.east, maxCommands: 2, topicId: 'sequences', difficulty: 1),
  CodingMission(id: 'c3_code_2', width: 4, height: 4, startX: 0, startY: 3, goalX: 2, goalY: 2, startDirection: FacingDirection.north, maxCommands: 4, topicId: 'turns', difficulty: 1),
  CodingMission(id: 'c3_code_3', width: 5, height: 4, startX: 0, startY: 3, goalX: 3, goalY: 1, startDirection: FacingDirection.east, obstacles: {'2,3'}, maxCommands: 7, topicId: 'route_planning', difficulty: 2),
  CodingMission(id: 'c3_code_4', width: 5, height: 5, startX: 1, startY: 4, goalX: 4, goalY: 2, startDirection: FacingDirection.north, obstacles: {'1,3', '3,3'}, maxCommands: 8, topicId: 'route_planning', difficulty: 2),
  CodingMission(id: 'c3_code_5', width: 5, height: 5, startX: 0, startY: 4, goalX: 4, goalY: 1, startDirection: FacingDirection.east, obstacles: {'2,4', '2,2'}, maxCommands: 10, topicId: 'repeat_patterns', difficulty: 3),
  CodingMission(id: 'c3_code_6', width: 6, height: 5, startX: 1, startY: 4, goalX: 5, goalY: 1, startDirection: FacingDirection.north, obstacles: {'1,2', '3,3'}, maxCommands: 11, topicId: 'repeat_patterns', difficulty: 3),
];

const _class4CodingMissions = <CodingMission>[
  CodingMission(id: 'c4_code_1', width: 4, height: 3, startX: 0, startY: 0, goalX: 2, goalY: 1, startDirection: FacingDirection.east, maxCommands: 4, topicId: 'sequences', difficulty: 1),
  CodingMission(id: 'c4_code_2', width: 4, height: 4, startX: 0, startY: 2, goalX: 2, goalY: 0, startDirection: FacingDirection.east, obstacles: {'1,1'}, maxCommands: 6, topicId: 'turns', difficulty: 1),
  CodingMission(id: 'c4_code_3', width: 5, height: 4, startX: 1, startY: 3, goalX: 4, goalY: 1, startDirection: FacingDirection.north, obstacles: {'1,1', '3,2'}, maxCommands: 8, topicId: 'route_planning', difficulty: 2),
  CodingMission(id: 'c4_code_4', width: 5, height: 5, startX: 0, startY: 4, goalX: 4, goalY: 0, startDirection: FacingDirection.north, obstacles: {'0,2', '2,3', '3,1'}, maxCommands: 12, topicId: 'route_planning', difficulty: 2),
  CodingMission(id: 'c4_code_5', width: 6, height: 5, startX: 0, startY: 4, goalX: 5, goalY: 0, startDirection: FacingDirection.east, obstacles: {'2,4', '2,3', '4,2'}, maxCommands: 14, topicId: 'efficient_algorithms', difficulty: 3),
  CodingMission(id: 'c4_code_6', width: 6, height: 6, startX: 1, startY: 5, goalX: 5, goalY: 1, startDirection: FacingDirection.north, obstacles: {'1,3', '2,3', '4,4', '4,2'}, maxCommands: 16, topicId: 'efficient_algorithms', difficulty: 3),
];

const _class5CodingMissions = <CodingMission>[
  CodingMission(id: 'c5_code_1', width: 5, height: 4, startX: 0, startY: 3, goalX: 3, goalY: 2, startDirection: FacingDirection.east, maxCommands: 5, topicId: 'algorithm_planning', difficulty: 1),
  CodingMission(id: 'c5_code_2', width: 5, height: 5, startX: 1, startY: 4, goalX: 4, goalY: 1, startDirection: FacingDirection.north, obstacles: {'1,2'}, maxCommands: 8, topicId: 'algorithm_planning', difficulty: 1),
  CodingMission(id: 'c5_code_3', width: 6, height: 5, startX: 0, startY: 4, goalX: 5, goalY: 2, startDirection: FacingDirection.east, obstacles: {'2,4', '3,3'}, maxCommands: 10, topicId: 'repeat_and_route', difficulty: 2),
  CodingMission(id: 'c5_code_4', width: 6, height: 6, startX: 1, startY: 5, goalX: 5, goalY: 1, startDirection: FacingDirection.north, obstacles: {'1,3', '3,4', '4,2'}, maxCommands: 13, topicId: 'repeat_and_route', difficulty: 2),
  CodingMission(id: 'c5_code_5', width: 7, height: 6, startX: 0, startY: 5, goalX: 6, goalY: 1, startDirection: FacingDirection.east, obstacles: {'2,5', '2,4', '4,3', '5,2'}, maxCommands: 16, topicId: 'efficient_algorithms', difficulty: 3),
  CodingMission(id: 'c5_code_6', width: 7, height: 7, startX: 1, startY: 6, goalX: 6, goalY: 1, startDirection: FacingDirection.north, obstacles: {'1,4', '2,4', '4,5', '4,3', '5,2'}, maxCommands: 18, topicId: 'debugging_routes', difficulty: 3),
];

List<CodingMission> codingMissionsForClass(int classNumber, {int difficulty = 3}) {
  final bank = switch (classNumber) {
    3 => _class3CodingMissions,
    5 => _class5CodingMissions,
    _ => _class4CodingMissions,
  };
  return _throughDifficulty(bank, difficulty, (mission) => mission.difficulty);
}

List<RecyclingItem> recyclingItemsForClass(int classNumber, {int difficulty = 3}) {
  final bank = switch (classNumber) {
    3 => const <RecyclingItem>[
        RecyclingItem('recycle3_1', 'Newspaper', '📰', 'Paper', topicId: 'sorting_basics', difficulty: 1),
        RecyclingItem('recycle3_2', 'Banana peel', '🍌', 'Organic', topicId: 'sorting_basics', difficulty: 1),
        RecyclingItem('recycle3_3', 'Plastic bottle', '🧴', 'Plastic', topicId: 'sorting_basics', difficulty: 1),
        RecyclingItem('recycle3_4', 'Cardboard box', '📦', 'Paper', topicId: 'clean_surroundings', difficulty: 2),
        RecyclingItem('recycle3_5', 'Vegetable peels', '🥕', 'Organic', topicId: 'clean_surroundings', difficulty: 2),
        RecyclingItem('recycle3_6', 'Clean shampoo bottle', '🧴', 'Plastic', topicId: 'clean_surroundings', difficulty: 2),
        RecyclingItem('recycle3_7', 'Old worksheet', '📄', 'Paper', topicId: 'reuse_and_recycle', difficulty: 3),
        RecyclingItem('recycle3_8', 'Fruit scraps', '🍎', 'Organic', topicId: 'reuse_and_recycle', difficulty: 3),
        RecyclingItem('recycle3_9', 'Clean water bottle', '🧃', 'Plastic', topicId: 'reuse_and_recycle', difficulty: 3),
      ],
    5 => const <RecyclingItem>[
        RecyclingItem('recycle5_1', 'Office paper', '📄', 'Paper', topicId: 'resource_sorting', difficulty: 1),
        RecyclingItem('recycle5_2', 'Fruit peel', '🍊', 'Organic', topicId: 'resource_sorting', difficulty: 1),
        RecyclingItem('recycle5_3', 'Clean plastic jar', '🫙', 'Plastic', topicId: 'resource_sorting', difficulty: 1),
        RecyclingItem('recycle5_4', 'Delivery carton', '📦', 'Paper', topicId: 'resource_conservation', difficulty: 2),
        RecyclingItem('recycle5_5', 'Garden leaves', '🍂', 'Organic', topicId: 'resource_conservation', difficulty: 2),
        RecyclingItem('recycle5_6', 'Clean detergent bottle', '🧴', 'Plastic', topicId: 'resource_conservation', difficulty: 2),
        RecyclingItem('recycle5_7', 'Notebook pages', '📑', 'Paper', topicId: 'sustainability', difficulty: 3),
        RecyclingItem('recycle5_8', 'Vegetable scraps', '🥬', 'Organic', topicId: 'sustainability', difficulty: 3),
        RecyclingItem('recycle5_9', 'Clean plastic container', '🥡', 'Plastic', topicId: 'sustainability', difficulty: 3),
      ],
    _ => const <RecyclingItem>[
        RecyclingItem('recycle4_1', 'Newspaper', '📰', 'Paper', topicId: 'sorting', difficulty: 1),
        RecyclingItem('recycle4_2', 'Banana peel', '🍌', 'Organic', topicId: 'sorting', difficulty: 1),
        RecyclingItem('recycle4_3', 'Plastic bottle', '🧴', 'Plastic', topicId: 'sorting', difficulty: 1),
        RecyclingItem('recycle4_4', 'Cardboard box', '📦', 'Paper', topicId: 'resources', difficulty: 2),
        RecyclingItem('recycle4_5', 'Vegetable peels', '🥕', 'Organic', topicId: 'resources', difficulty: 2),
        RecyclingItem('recycle4_6', 'Clean shampoo bottle', '🧴', 'Plastic', topicId: 'resources', difficulty: 2),
        RecyclingItem('recycle4_7', 'Old worksheet', '📄', 'Paper', topicId: 'environmental_impact', difficulty: 3),
        RecyclingItem('recycle4_8', 'Fruit scraps', '🍎', 'Organic', topicId: 'environmental_impact', difficulty: 3),
        RecyclingItem('recycle4_9', 'Clean juice bottle', '🧃', 'Plastic', topicId: 'environmental_impact', difficulty: 3),
      ],
  };
  return _throughDifficulty(bank, difficulty, (item) => item.difficulty);
}

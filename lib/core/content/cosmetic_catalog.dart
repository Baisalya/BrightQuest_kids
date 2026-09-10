/// Coin-bought visual rewards. These never affect learning, scoring or unlocks.
///
/// IDs that shipped before the equip system are intentionally frozen so older
/// profile ownership continues to work after upgrading.
class CosmeticDefinition {
  const CosmeticDefinition({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.gameId,
    required this.gameTitle,
    required this.cost,
    required this.accentColorValue,
  });

  final String id;
  final String title;
  final String emoji;
  final String description;
  final String gameId;
  final String gameTitle;
  final int cost;
  final int accentColorValue;
}

const List<CosmeticDefinition> cosmeticCatalog = <CosmeticDefinition>[
  CosmeticDefinition(
    id: 'market_rainbow_apron',
    title: 'Rainbow Shop Apron',
    emoji: '🛍️🌈',
    description: 'A bright market-day look for Math Market.',
    gameId: 'math_market',
    gameTitle: 'Math Market',
    cost: 140,
    accentColorValue: 0xFFE14F9B,
  ),
  CosmeticDefinition(
    id: 'market_gold_cart',
    title: 'Golden Cart',
    emoji: '🛒✨',
    description: 'Give Math Market a shiny golden shopping style.',
    gameId: 'math_market',
    gameTitle: 'Math Market',
    cost: 220,
    accentColorValue: 0xFFE3A51A,
  ),
  CosmeticDefinition(
    id: 'market_space_shop',
    title: 'Space Market',
    emoji: '🚀🛒',
    description: 'Turn the market banner into a playful space shop.',
    gameId: 'math_market',
    gameTitle: 'Math Market',
    cost: 320,
    accentColorValue: 0xFF4D65D8,
  ),
  CosmeticDefinition(
    id: 'fraction_chef_hat',
    title: 'Fraction Chef Hat',
    emoji: '👨‍🍳🍕',
    description: 'A chef look for slicing fractions in Fraction Pizza.',
    gameId: 'fraction_pizza',
    gameTitle: 'Fraction Pizza',
    cost: 140,
    accentColorValue: 0xFFE65E38,
  ),
  CosmeticDefinition(
    id: 'fraction_rainbow_pizza',
    title: 'Rainbow Pizza',
    emoji: '🍕🌈',
    description: 'A colorful pizza theme for fraction practice.',
    gameId: 'fraction_pizza',
    gameTitle: 'Fraction Pizza',
    cost: 220,
    accentColorValue: 0xFFB84FD4,
  ),
  CosmeticDefinition(
    id: 'fraction_star_oven',
    title: 'Star Oven',
    emoji: '⭐🔥',
    description: 'A star-chef theme for confident fraction missions.',
    gameId: 'fraction_pizza',
    gameTitle: 'Fraction Pizza',
    cost: 300,
    accentColorValue: 0xFFF09A24,
  ),
  CosmeticDefinition(
    id: 'story_castle_badge',
    title: 'Story Castle Badge',
    emoji: '🏰⭐',
    description: 'The original castle badge for Story Builder.',
    gameId: 'story_builder',
    gameTitle: 'Story Builder',
    cost: 150,
    accentColorValue: 0xFF22A996,
  ),
  CosmeticDefinition(
    id: 'story_dragon_badge',
    title: 'Dragon Story Badge',
    emoji: '🐉📖',
    description: 'A brave dragon badge for imaginative stories.',
    gameId: 'story_builder',
    gameTitle: 'Story Builder',
    cost: 220,
    accentColorValue: 0xFF4D9A61,
  ),
  CosmeticDefinition(
    id: 'story_moon_badge',
    title: 'Moonlight Story Badge',
    emoji: '🌙📚',
    description: 'A moonlit reading badge for Story Builder.',
    gameId: 'story_builder',
    gameTitle: 'Story Builder',
    cost: 280,
    accentColorValue: 0xFF6159C9,
  ),
  CosmeticDefinition(
    id: 'grammar_word_wizard',
    title: 'Word Wizard',
    emoji: '🪄🔤',
    description: 'A magical word theme for Grammar Puzzle.',
    gameId: 'grammar_puzzle',
    gameTitle: 'Grammar Puzzle',
    cost: 160,
    accentColorValue: 0xFF8B52C7,
  ),
  CosmeticDefinition(
    id: 'grammar_owl_scholar',
    title: 'Scholar Owl',
    emoji: '🦉📚',
    description: 'A wise reading companion for grammar missions.',
    gameId: 'grammar_puzzle',
    gameTitle: 'Grammar Puzzle',
    cost: 230,
    accentColorValue: 0xFF6B65B7,
  ),
  CosmeticDefinition(
    id: 'grammar_neon_letters',
    title: 'Neon Letters',
    emoji: '🔤✨',
    description: 'A bright neon letter theme for word challenges.',
    gameId: 'grammar_puzzle',
    gameTitle: 'Grammar Puzzle',
    cost: 300,
    accentColorValue: 0xFF1F9ACB,
  ),
  CosmeticDefinition(
    id: 'lion_lab_coat',
    title: 'Lion Lab Coat',
    emoji: '🥼🦁',
    description: 'The classic scientist coat for the Science Lab lion.',
    gameId: 'science_lab',
    gameTitle: 'Science Lab',
    cost: 200,
    accentColorValue: 0xFF4F8ECB,
  ),
  CosmeticDefinition(
    id: 'science_nebula_coat',
    title: 'Nebula Lab Coat',
    emoji: '🥼🌌',
    description: 'A deep-space coat for the Science Lab mascot.',
    gameId: 'science_lab',
    gameTitle: 'Science Lab',
    cost: 280,
    accentColorValue: 0xFF674BC6,
  ),
  CosmeticDefinition(
    id: 'science_rainbow_goggles',
    title: 'Rainbow Goggles',
    emoji: '🥽🌈',
    description: 'Colorful safety goggles and a bright lab style.',
    gameId: 'science_lab',
    gameTitle: 'Science Lab',
    cost: 340,
    accentColorValue: 0xFFCE4AA4,
  ),
  CosmeticDefinition(
    id: 'map_explorer_satchel',
    title: 'Explorer Satchel',
    emoji: '🎒🗺️',
    description: 'A travel-ready explorer look for Map Quest.',
    gameId: 'map_quest',
    gameTitle: 'Map Quest',
    cost: 160,
    accentColorValue: 0xFF2B9A7C,
  ),
  CosmeticDefinition(
    id: 'map_compass_gold',
    title: 'Golden Compass',
    emoji: '🧭✨',
    description: 'A shiny compass theme for geography adventures.',
    gameId: 'map_quest',
    gameTitle: 'Map Quest',
    cost: 240,
    accentColorValue: 0xFFD79B2B,
  ),
  CosmeticDefinition(
    id: 'map_rocket_explorer',
    title: 'Rocket Explorer',
    emoji: '🚀🌍',
    description: 'A space-explorer style for Map Quest.',
    gameId: 'map_quest',
    gameTitle: 'Map Quest',
    cost: 330,
    accentColorValue: 0xFF4F6FC7,
  ),
  CosmeticDefinition(
    id: 'galaxy_bot_skin',
    title: 'Galaxy Bot Skin',
    emoji: '🤖🌌',
    description: 'The original galaxy skin for the Coding Maze robot.',
    gameId: 'coding_maze',
    gameTitle: 'Coding Maze',
    cost: 350,
    accentColorValue: 0xFF6750C7,
  ),
  CosmeticDefinition(
    id: 'neon_bot_skin',
    title: 'Neon Bot Skin',
    emoji: '🤖⚡',
    description: 'A bright electric skin for the Coding Maze robot.',
    gameId: 'coding_maze',
    gameTitle: 'Coding Maze',
    cost: 220,
    accentColorValue: 0xFF00A99D,
  ),
  CosmeticDefinition(
    id: 'solar_bot_skin',
    title: 'Solar Bot Skin',
    emoji: '🤖☀️',
    description: 'A warm solar-powered look for the Coding Maze robot.',
    gameId: 'coding_maze',
    gameTitle: 'Coding Maze',
    cost: 280,
    accentColorValue: 0xFFE28A18,
  ),
  CosmeticDefinition(
    id: 'eco_hero_crown',
    title: 'Eco Hero Crown',
    emoji: '♻️👑',
    description: 'The original Eco Hero crown for Recycling Challenge.',
    gameId: 'recycling_challenge',
    gameTitle: 'Recycling Challenge',
    cost: 250,
    accentColorValue: 0xFF2A9F5A,
  ),
  CosmeticDefinition(
    id: 'eco_leaf_cape',
    title: 'Leaf Hero Cape',
    emoji: '🌿🦸',
    description: 'A leafy hero style for Recycling Challenge.',
    gameId: 'recycling_challenge',
    gameTitle: 'Recycling Challenge',
    cost: 180,
    accentColorValue: 0xFF45A84B,
  ),
  CosmeticDefinition(
    id: 'eco_ocean_guardian',
    title: 'Ocean Guardian',
    emoji: '🌊♻️',
    description: 'An ocean-protector theme for recycling missions.',
    gameId: 'recycling_challenge',
    gameTitle: 'Recycling Challenge',
    cost: 300,
    accentColorValue: 0xFF238DB6,
  ),
];

CosmeticDefinition? cosmeticById(String id) {
  for (final cosmetic in cosmeticCatalog) {
    if (cosmetic.id == id) return cosmetic;
  }
  return null;
}

List<CosmeticDefinition> cosmeticsForGame(String gameId) => cosmeticCatalog
    .where((cosmetic) => cosmetic.gameId == gameId)
    .toList(growable: false);

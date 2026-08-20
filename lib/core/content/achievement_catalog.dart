import '../models/progress_models.dart';

const achievements = <AchievementDefinition>[
  AchievementDefinition(
    id: 'first_steps',
    title: 'First Steps',
    description: 'Clear your first learning level.',
    emoji: '👣',
    rewardCoins: 20,
  ),
  AchievementDefinition(
    id: 'perfect_level',
    title: 'Perfect Level',
    description: 'Earn 3 stars on a learning level.',
    emoji: '🌟',
    rewardCoins: 30,
  ),
  AchievementDefinition(
    id: 'star_collector_10',
    title: 'Star Collector',
    description: 'Collect 10 learning-path stars.',
    emoji: '⭐',
    rewardCoins: 35,
  ),
  AchievementDefinition(
    id: 'answer_25',
    title: 'Question Crusher',
    description: 'Answer 25 learning questions correctly.',
    emoji: '🎯',
    rewardCoins: 30,
  ),
  AchievementDefinition(
    id: 'maths_mastery',
    title: 'Maths Master',
    description: 'Clear every Maths level for your current class.',
    emoji: '🧮',
    rewardCoins: 60,
  ),
  AchievementDefinition(
    id: 'english_mastery',
    title: 'Word Wizard',
    description: 'Clear every English level for your current class.',
    emoji: '📚',
    rewardCoins: 60,
  ),
  AchievementDefinition(
    id: 'science_mastery',
    title: 'Lab Legend',
    description: 'Clear every Science level for your current class.',
    emoji: '🔬',
    rewardCoins: 50,
  ),
  AchievementDefinition(
    id: 'eco_mastery',
    title: 'Eco Hero',
    description: 'Clear every EVS level for your current class.',
    emoji: '🌱',
    rewardCoins: 50,
  ),
  AchievementDefinition(
    id: 'social_mastery',
    title: 'India Explorer',
    description: 'Clear every Social Studies level for your current class.',
    emoji: '🗺️',
    rewardCoins: 50,
  ),
  AchievementDefinition(
    id: 'coding_mastery',
    title: 'Code Captain',
    description: 'Clear every Coding level for your current class.',
    emoji: '🤖',
    rewardCoins: 50,
  ),
  AchievementDefinition(
    id: 'streak_7',
    title: 'Week Warrior',
    description: 'Reach a 7-day learning streak.',
    emoji: '🔥',
    rewardCoins: 70,
  ),
];

AchievementDefinition? achievementById(String id) {
  for (final achievement in achievements) {
    if (achievement.id == id) return achievement;
  }
  return null;
}

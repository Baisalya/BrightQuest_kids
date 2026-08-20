import 'package:flutter/material.dart';

enum SubjectWorld { maths, english, science, evs, social, coding, art }

class AdventureGame {
  const AdventureGame({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.subject,
    required this.icon,
    required this.color,
    required this.level,
  });

  final String id;
  final String title;
  final String subtitle;
  final SubjectWorld subject;
  final IconData icon;
  final Color color;
  final int level;
}

const games = <AdventureGame>[
  AdventureGame(
    id: 'math_market',
    title: 'Math Market',
    subtitle: 'Division Dash',
    subject: SubjectWorld.maths,
    icon: Icons.storefront_rounded,
    color: Color(0xFF3E88F7),
    level: 7,
  ),
  AdventureGame(
    id: 'fraction_pizza',
    title: 'Fraction Pizza',
    subtitle: 'Slice & Solve',
    subject: SubjectWorld.maths,
    icon: Icons.local_pizza_rounded,
    color: Color(0xFFFF9A35),
    level: 6,
  ),
  AdventureGame(
    id: 'science_lab',
    title: 'Science Lab',
    subtitle: 'Mix & Discover',
    subject: SubjectWorld.science,
    icon: Icons.science_rounded,
    color: Color(0xFF7B4EEB),
    level: 8,
  ),
  AdventureGame(
    id: 'story_builder',
    title: 'Story Builder',
    subtitle: 'Finish the Tale',
    subject: SubjectWorld.english,
    icon: Icons.auto_stories_rounded,
    color: Color(0xFF22B8A7),
    level: 5,
  ),
  AdventureGame(
    id: 'grammar_puzzle',
    title: 'Grammar Puzzle',
    subtitle: 'Word Power',
    subject: SubjectWorld.english,
    icon: Icons.extension_rounded,
    color: Color(0xFFF0549B),
    level: 6,
  ),
  AdventureGame(
    id: 'map_quest',
    title: 'Map Quest',
    subtitle: 'Explore India',
    subject: SubjectWorld.social,
    icon: Icons.public_rounded,
    color: Color(0xFF2B96E9),
    level: 7,
  ),
  AdventureGame(
    id: 'coding_maze',
    title: 'Coding Maze',
    subtitle: 'Guide the Bot',
    subject: SubjectWorld.coding,
    icon: Icons.smart_toy_rounded,
    color: Color(0xFF6652D9),
    level: 6,
  ),
  AdventureGame(
    id: 'recycling_challenge',
    title: 'Recycling Challenge',
    subtitle: 'Sort It Right',
    subject: SubjectWorld.evs,
    icon: Icons.recycling_rounded,
    color: Color(0xFF4BAF52),
    level: 5,
  ),
  AdventureGame(
    id: 'rewards_room',
    title: 'Rewards Room',
    subtitle: 'Treasure & Badges',
    subject: SubjectWorld.art,
    icon: Icons.workspace_premium_rounded,
    color: Color(0xFFF3B31E),
    level: 1,
  ),
];

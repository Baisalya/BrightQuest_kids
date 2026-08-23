import '../models/game_models.dart';
import 'curriculum_catalog.dart';
import 'curriculum_models.dart';
import 'world_mission_models.dart';

/// Maps the existing curriculum path to child-facing world missions.
///
/// This catalog intentionally contains no educational answers and does not
/// inspect authored prompt text. It only decorates stable curriculum metadata
/// (subject, topic, game and level type) with fictional world locations and
/// mission labels.
class WorldMissionCatalog {
  const WorldMissionCatalog._();

  static WorldMissionIdentity identityFor(SubjectWorld subject) =>
      switch (subject) {
        SubjectWorld.maths => const WorldMissionIdentity(
            subject: SubjectWorld.maths,
            worldTitle: 'Maths Kingdom',
            worldEmoji: '🏰',
            journeyTitle: 'Castle Quest Route',
            journeySubtitle:
                'Trade, build and conquer number challenges on the road to the royal vault.',
            heroCallout: 'Your next number quest is ready.',
            sceneGameId: 'math_market',
          ),
        SubjectWorld.english => const WorldMissionIdentity(
            subject: SubjectWorld.english,
            worldTitle: 'Story Forest',
            worldEmoji: '📚',
            journeyTitle: 'Story Trail',
            journeySubtitle:
                'Follow the glowing trail, restore language powers and meet the Story Keeper.',
            heroCallout: 'A new story path is waiting.',
            sceneGameId: 'story_builder',
          ),
        SubjectWorld.science => const WorldMissionIdentity(
            subject: SubjectWorld.science,
            worldTitle: 'Discovery Lab',
            worldEmoji: '🧪',
            journeyTitle: 'Discovery Run',
            journeySubtitle:
                'Observe, test and unlock the lab core through hands-on discovery missions.',
            heroCallout: 'The lab has a new discovery mission.',
            sceneGameId: 'science_lab',
          ),
        SubjectWorld.evs => const WorldMissionIdentity(
            subject: SubjectWorld.evs,
            worldTitle: 'Green Planet',
            worldEmoji: '🌿',
            journeyTitle: 'Planet Rescue Route',
            journeySubtitle:
                'Complete eco missions, restore each zone and become a Planet Guardian.',
            heroCallout: 'The planet needs your next rescue mission.',
            sceneGameId: 'recycling_challenge',
          ),
        SubjectWorld.social => const WorldMissionIdentity(
            subject: SubjectWorld.social,
            worldTitle: 'India Explorer',
            worldEmoji: '🗺️',
            journeyTitle: 'India Expedition',
            journeySubtitle:
                'Read clues, follow routes and clear explorer checkpoints across the expedition.',
            heroCallout: 'Your next explorer checkpoint is ready.',
            sceneGameId: 'map_quest',
          ),
        SubjectWorld.coding => const WorldMissionIdentity(
            subject: SubjectWorld.coding,
            worldTitle: 'Robot City',
            worldEmoji: '🤖',
            journeyTitle: 'Robot City Circuit',
            journeySubtitle:
                'Program routes, clear circuit trials and unlock the city core.',
            heroCallout: 'A robot circuit is ready for your code.',
            sceneGameId: 'coding_maze',
          ),
        SubjectWorld.art => const WorldMissionIdentity(
            subject: SubjectWorld.art,
            worldTitle: 'Creator Cove',
            worldEmoji: '🎨',
            journeyTitle: 'Creative Trail',
            journeySubtitle:
                'Collect rewards and celebrate your BrightQuest journey.',
            heroCallout: 'A creative reward is waiting.',
            sceneGameId: 'rewards_room',
          ),
      };

  static WorldMissionPlan planForLevel(LearningLevel level) {
    final identity = identityFor(level.subject);
    final levels = levelsForSubject(level.classNumber, level.subject);
    final topics = topicsForClass(level.classNumber, subject: level.subject);
    final stageIndex =
        levels.indexWhere((candidate) => candidate.id == level.id);
    final topicIndex = topics.indexWhere(
      (candidate) => candidate.id == level.curriculumTopicId,
    );
    final topic = topicIndex >= 0 ? topics[topicIndex] : null;
    final resolvedTopicIndex = topicIndex < 0 ? 0 : topicIndex;
    final phase = _phaseFor(level.type);
    final zoneTitle = _zoneTitleFor(
      subject: level.subject,
      gameId: level.gameId,
      zoneIndex: resolvedTopicIndex,
    );

    return WorldMissionPlan(
      identity: identity,
      levelId: level.id,
      gameId: level.gameId,
      topicTitle: topic?.title ?? level.title,
      topicSummary: topic?.summary ?? level.summary,
      zoneTitle: zoneTitle,
      phase: phase,
      phaseLabel: _phaseLabelFor(level.subject, phase),
      stageTitle: _stageTitleFor(level.subject, phase, zoneTitle),
      briefing: _briefingFor(
        subject: level.subject,
        phase: phase,
        topicTitle: topic?.title ?? level.title,
        topicSummary: topic?.summary ?? level.summary,
      ),
      actionLabel: _actionLabelFor(level.subject, phase),
      completionHeadline: _completionHeadlineFor(level.subject, phase),
      nextUnlockLabel: _nextUnlockLabelFor(level.subject, phase),
      stageEmoji: _stageEmojiFor(level.subject, phase),
      stageNumber: stageIndex < 0 ? 1 : stageIndex + 1,
      stageCount: levels.isEmpty ? 1 : levels.length,
      zoneNumber: resolvedTopicIndex + 1,
      zoneCount: topics.isEmpty ? 1 : topics.length,
    );
  }

  static WorldMissionPhase _phaseFor(LearningLevelType type) => switch (type) {
        LearningLevelType.practice => WorldMissionPhase.training,
        LearningLevelType.challenge => WorldMissionPhase.challenge,
        LearningLevelType.mastery => WorldMissionPhase.boss,
      };

  static String _zoneTitleFor({
    required SubjectWorld subject,
    required String gameId,
    required int zoneIndex,
  }) {
    final mapped = switch (gameId) {
      'math_market' => 'Market Square',
      'fraction_pizza' => 'Fraction Feast Hall',
      'story_builder' => 'Story Grove',
      'grammar_puzzle' => 'Wordkeeper Woods',
      'science_lab' => 'Experiment Deck',
      'recycling_challenge' => 'Eco Rescue Park',
      'map_quest' => 'Explorer Camp',
      'coding_maze' => 'Circuit District',
      _ => '',
    };
    if (mapped.isNotEmpty) return mapped;

    final noun = switch (subject) {
      SubjectWorld.maths => 'Castle Zone',
      SubjectWorld.english => 'Forest Trail',
      SubjectWorld.science => 'Lab Bay',
      SubjectWorld.evs => 'Eco Zone',
      SubjectWorld.social => 'Explorer Stop',
      SubjectWorld.coding => 'Robot District',
      SubjectWorld.art => 'Creator Stop',
    };
    return '$noun ${zoneIndex + 1}';
  }

  static String _phaseLabelFor(
    SubjectWorld subject,
    WorldMissionPhase phase,
  ) =>
      switch (subject) {
        SubjectWorld.maths => switch (phase) {
            WorldMissionPhase.training => 'Market Training',
            WorldMissionPhase.challenge => 'Castle Trial',
            WorldMissionPhase.boss => 'Vault Boss',
          },
        SubjectWorld.english => switch (phase) {
            WorldMissionPhase.training => 'Trail Training',
            WorldMissionPhase.challenge => 'Forest Quest',
            WorldMissionPhase.boss => 'Story Keeper',
          },
        SubjectWorld.science => switch (phase) {
            WorldMissionPhase.training => 'Lab Training',
            WorldMissionPhase.challenge => 'Discovery Trial',
            WorldMissionPhase.boss => 'Core Experiment',
          },
        SubjectWorld.evs => switch (phase) {
            WorldMissionPhase.training => 'Eco Training',
            WorldMissionPhase.challenge => 'Rescue Mission',
            WorldMissionPhase.boss => 'Planet Guardian',
          },
        SubjectWorld.social => switch (phase) {
            WorldMissionPhase.training => 'Scout Route',
            WorldMissionPhase.challenge => 'Explorer Trial',
            WorldMissionPhase.boss => 'Grand Expedition',
          },
        SubjectWorld.coding => switch (phase) {
            WorldMissionPhase.training => 'Bot Training',
            WorldMissionPhase.challenge => 'Circuit Trial',
            WorldMissionPhase.boss => 'Core Override',
          },
        SubjectWorld.art => switch (phase) {
            WorldMissionPhase.training => 'Creative Warm-up',
            WorldMissionPhase.challenge => 'Creative Quest',
            WorldMissionPhase.boss => 'Showcase',
          },
      };

  static String _stageTitleFor(
    SubjectWorld subject,
    WorldMissionPhase phase,
    String zoneTitle,
  ) =>
      switch (subject) {
        SubjectWorld.maths => switch (phase) {
            WorldMissionPhase.training => 'Train at $zoneTitle',
            WorldMissionPhase.challenge => 'Break the $zoneTitle gate',
            WorldMissionPhase.boss => 'Open the royal vault',
          },
        SubjectWorld.english => switch (phase) {
            WorldMissionPhase.training => 'Follow the $zoneTitle clues',
            WorldMissionPhase.challenge => 'Restore the forest path',
            WorldMissionPhase.boss => 'Meet the Story Keeper',
          },
        SubjectWorld.science => switch (phase) {
            WorldMissionPhase.training => 'Power up $zoneTitle',
            WorldMissionPhase.challenge => 'Run the discovery trial',
            WorldMissionPhase.boss => 'Unlock the lab core',
          },
        SubjectWorld.evs => switch (phase) {
            WorldMissionPhase.training => 'Restore $zoneTitle',
            WorldMissionPhase.challenge => 'Lead the rescue mission',
            WorldMissionPhase.boss => 'Guard the green core',
          },
        SubjectWorld.social => switch (phase) {
            WorldMissionPhase.training => 'Scout from $zoneTitle',
            WorldMissionPhase.challenge => 'Clear the explorer checkpoint',
            WorldMissionPhase.boss => 'Complete the grand expedition',
          },
        SubjectWorld.coding => switch (phase) {
            WorldMissionPhase.training => 'Boot up $zoneTitle',
            WorldMissionPhase.challenge => 'Clear the circuit trial',
            WorldMissionPhase.boss => 'Override the city core',
          },
        SubjectWorld.art => switch (phase) {
            WorldMissionPhase.training => 'Warm up at $zoneTitle',
            WorldMissionPhase.challenge => 'Complete the creative quest',
            WorldMissionPhase.boss => 'Open the showcase',
          },
      };

  static String _briefingFor({
    required SubjectWorld subject,
    required WorldMissionPhase phase,
    required String topicTitle,
    required String topicSummary,
  }) {
    final lead = switch (subject) {
      SubjectWorld.maths => 'Use your number powers',
      SubjectWorld.english => 'Use your language powers',
      SubjectWorld.science => 'Think like a young scientist',
      SubjectWorld.evs => 'Make smart planet-friendly choices',
      SubjectWorld.social => 'Think like an explorer',
      SubjectWorld.coding => 'Think like a robot programmer',
      SubjectWorld.art => 'Use your creative powers',
    };
    final phaseGoal = switch (phase) {
      WorldMissionPhase.training => 'learn the route with guidance',
      WorldMissionPhase.challenge => 'solve the route with less help',
      WorldMissionPhase.boss => 'prove your mastery at the final checkpoint',
    };
    return '$lead to $phaseGoal. Mission focus: $topicTitle. $topicSummary';
  }

  static String _actionLabelFor(
    SubjectWorld subject,
    WorldMissionPhase phase,
  ) =>
      switch (subject) {
        SubjectWorld.maths => switch (phase) {
            WorldMissionPhase.training => 'Enter Market Training',
            WorldMissionPhase.challenge => 'Take the Castle Trial',
            WorldMissionPhase.boss => 'Face the Vault Boss',
          },
        SubjectWorld.english => switch (phase) {
            WorldMissionPhase.training => 'Follow the Story Trail',
            WorldMissionPhase.challenge => 'Enter the Forest Quest',
            WorldMissionPhase.boss => 'Meet the Story Keeper',
          },
        SubjectWorld.science => switch (phase) {
            WorldMissionPhase.training => 'Start Lab Training',
            WorldMissionPhase.challenge => 'Run the Discovery Trial',
            WorldMissionPhase.boss => 'Start the Core Experiment',
          },
        SubjectWorld.evs => switch (phase) {
            WorldMissionPhase.training => 'Start Eco Training',
            WorldMissionPhase.challenge => 'Launch the Rescue Mission',
            WorldMissionPhase.boss => 'Face the Planet Guardian',
          },
        SubjectWorld.social => switch (phase) {
            WorldMissionPhase.training => 'Start the Scout Route',
            WorldMissionPhase.challenge => 'Take the Explorer Trial',
            WorldMissionPhase.boss => 'Begin the Grand Expedition',
          },
        SubjectWorld.coding => switch (phase) {
            WorldMissionPhase.training => 'Boot Bot Training',
            WorldMissionPhase.challenge => 'Run the Circuit Trial',
            WorldMissionPhase.boss => 'Start Core Override',
          },
        SubjectWorld.art => switch (phase) {
            WorldMissionPhase.training => 'Start Creative Warm-up',
            WorldMissionPhase.challenge => 'Start Creative Quest',
            WorldMissionPhase.boss => 'Open Showcase',
          },
      };

  static String _completionHeadlineFor(
    SubjectWorld subject,
    WorldMissionPhase phase,
  ) {
    if (phase == WorldMissionPhase.boss) {
      return switch (subject) {
        SubjectWorld.maths => 'Royal vault cleared!',
        SubjectWorld.english => 'Story Keeper impressed!',
        SubjectWorld.science => 'Lab core unlocked!',
        SubjectWorld.evs => 'Green core protected!',
        SubjectWorld.social => 'Grand expedition cleared!',
        SubjectWorld.coding => 'Robot City core unlocked!',
        SubjectWorld.art => 'Showcase unlocked!',
      };
    }
    return switch (subject) {
      SubjectWorld.maths => 'Kingdom gate cleared!',
      SubjectWorld.english => 'Story trail restored!',
      SubjectWorld.science => 'Discovery checkpoint cleared!',
      SubjectWorld.evs => 'Eco zone restored!',
      SubjectWorld.social => 'Explorer checkpoint cleared!',
      SubjectWorld.coding => 'Circuit checkpoint cleared!',
      SubjectWorld.art => 'Creative checkpoint cleared!',
    };
  }

  static String _nextUnlockLabelFor(
    SubjectWorld subject,
    WorldMissionPhase phase,
  ) {
    if (phase == WorldMissionPhase.boss) {
      return switch (subject) {
        SubjectWorld.maths => 'Next kingdom zone unlocked!',
        SubjectWorld.english => 'Next forest chapter unlocked!',
        SubjectWorld.science => 'Next lab zone unlocked!',
        SubjectWorld.evs => 'Next planet zone unlocked!',
        SubjectWorld.social => 'Next expedition stop unlocked!',
        SubjectWorld.coding => 'Next city district unlocked!',
        SubjectWorld.art => 'Next creative stop unlocked!',
      };
    }
    return switch (subject) {
      SubjectWorld.maths => 'Next castle gate unlocked!',
      SubjectWorld.english => 'Next story path unlocked!',
      SubjectWorld.science => 'Next discovery trial unlocked!',
      SubjectWorld.evs => 'Next rescue mission unlocked!',
      SubjectWorld.social => 'Next explorer route unlocked!',
      SubjectWorld.coding => 'Next circuit unlocked!',
      SubjectWorld.art => 'Next creative mission unlocked!',
    };
  }

  static String _stageEmojiFor(
    SubjectWorld subject,
    WorldMissionPhase phase,
  ) {
    if (phase == WorldMissionPhase.boss) {
      return switch (subject) {
        SubjectWorld.maths => '👑',
        SubjectWorld.english => '🦉',
        SubjectWorld.science => '⚗️',
        SubjectWorld.evs => '🌍',
        SubjectWorld.social => '🏁',
        SubjectWorld.coding => '🧠',
        SubjectWorld.art => '🏆',
      };
    }
    if (phase == WorldMissionPhase.challenge) return '⚡';
    return switch (subject) {
      SubjectWorld.maths => '🛒',
      SubjectWorld.english => '📖',
      SubjectWorld.science => '🔬',
      SubjectWorld.evs => '♻️',
      SubjectWorld.social => '🧭',
      SubjectWorld.coding => '🤖',
      SubjectWorld.art => '🎨',
    };
  }
}

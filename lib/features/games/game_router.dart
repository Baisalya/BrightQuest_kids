import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../app/study_session_tracker.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/session/game_session_models.dart';
import '../../core/session/learning_session_exit.dart';
import '../../core/curriculum/world_mission_catalog.dart';
import '../../core/learning/endless_practice_coordinator.dart';
import '../../core/services/bright_audio_service.dart';
import '../../core/state/game_controller.dart';
import '../learning/lesson_flow_screen.dart';
import 'coding_maze_screen.dart';
import 'fraction_pizza_screen.dart';
import 'grammar_puzzle_screen.dart';
import 'map_quest_screen.dart';
import 'math_market_screen.dart';
import 'recycling_challenge_screen.dart';
import 'rewards_room_screen.dart';
import 'science_lab_screen.dart';
import 'story_builder_screen.dart';

void openGame(BuildContext context, String id) {
  final controller = BrightQuestScope.of(context);
  if (id == 'rewards_room') {
    _openGameInternal(context, id, learningLevel: null);
    return;
  }
  final session = controller.gameSessionFor(
    gameId: id,
    classNumber: controller.selectedClass,
  );
  if (session != null) {
    final isEndless =
        EndlessPracticeCoordinator.isEndlessSessionData(session.data);
    if (session.stage == GameSessionStage.completing ||
        (isEndless && session.isInProgress)) {
      unawaited(resumeGameSession(context, session));
      return;
    }
    if (isEndless && session.stage == GameSessionStage.result) {
      // An explicit normal game launch must not inherit a completed Endless
      // Practice plan from the shared quick-play slot.
      controller.discardGameSession(session);
    }
  }
  _openGameInternal(context, id, learningLevel: null);
}

void openEndlessPractice(BuildContext context, String gameId) {
  final controller = BrightQuestScope.of(context);
  final coreLevels = levelsForGame(controller.selectedClass, gameId);
  final unlocked = coreLevels.length == 3 &&
      coreLevels.every((level) => controller.levelStatsFor(level.id).completed);
  if (!unlocked) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Clear Practice, Challenge and Mastery before Endless Practice.',
        ),
      ),
    );
    return;
  }

  final existing = controller.gameSessionFor(
    gameId: gameId,
    classNumber: controller.selectedClass,
  );
  if (existing != null) {
    final isEndless =
        EndlessPracticeCoordinator.isEndlessSessionData(existing.data);
    if (isEndless && existing.stage == GameSessionStage.completing) {
      unawaited(resumeGameSession(context, existing));
      return;
    }
    if (!isEndless || existing.stage == GameSessionStage.result) {
      controller.discardGameSession(existing);
    }
  }
  _openGameInternal(
    context,
    gameId,
    learningLevel: null,
    endlessPractice: true,
  );
}

void openLearningLevel(BuildContext context, LearningLevel level) {
  final controller = BrightQuestScope.of(context);
  final savedSession = controller.gameSessionFor(
    gameId: level.gameId,
    classNumber: level.classNumber,
    learningLevelId: level.id,
  );
  if (savedSession != null && savedSession.isInProgress) {
    if (savedSession.stage == GameSessionStage.lesson) {
      controller.activateGameSession(savedSession);
      Navigator.of(context)
          .push<bool>(
        MaterialPageRoute<bool>(builder: (_) => LessonFlowScreen(level: level)),
      )
          .then((startPractice) {
        if (startPractice == true && context.mounted) {
          _openGameInternal(context, level.gameId, learningLevel: level);
        }
      });
    } else if (savedSession.stage == GameSessionStage.completing) {
      unawaited(resumeGameSession(context, savedSession));
    } else {
      controller.activateGameSession(savedSession);
      _openGameInternal(context, level.gameId, learningLevel: level);
    }
    return;
  }
  if (savedSession != null) {
    // An explicit World-stage launch after a completed result is a fresh
    // encounter. Progress/rewards are authoritative in PlayerSnapshot, so the
    // old result checkpoint is safe to discard here. Dedicated resume actions
    // can still restore result checkpoints before the child explicitly replays.
    controller.discardGameSession(savedSession);
  }

  final content = BrightQuestScope.contentOf(context);
  if (!controller.isLevelUnlocked(level)) {
    final mission = WorldMissionCatalog.planForLevel(level);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Clear the previous mission before ${mission.phaseLabel}.',
        ),
      ),
    );
    return;
  }
  if (!content.canOpenLearningLevel(
    classNumber: level.classNumber,
    gameId: level.gameId,
    difficulty: level.difficulty,
  )) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DevelopmentPackLockedScreen(
          classNumber: level.classNumber,
        ),
      ),
    );
    return;
  }
  Navigator.of(context)
      .push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => LessonFlowScreen(level: level),
    ),
  )
      .then((startPractice) {
    if (startPractice == true && context.mounted) {
      _openGameInternal(context, level.gameId, learningLevel: level);
    }
  });
}

Future<void> resumeActiveGameSession(BuildContext context) async {
  final controller = BrightQuestScope.of(context);
  final session = controller.activeGameSession;
  if (session == null) return;
  await resumeGameSession(context, session);
}

Future<void> resumeGameSession(
  BuildContext context,
  GameSessionCheckpoint savedSession,
) async {
  final controller = BrightQuestScope.of(context);
  if (savedSession.profileId != controller.activeProfileId ||
      savedSession.classNumber != controller.selectedClass) {
    return;
  }
  var session = controller.gameSessionFor(
    gameId: savedSession.gameId,
    classNumber: savedSession.classNumber,
    learningLevelId: savedSession.learningLevelId,
  );
  if (session == null) return;
  controller.activateGameSession(session);

  final level = session.learningLevelId == null
      ? null
      : learningLevelById(session.learningLevelId!);
  if (session.learningLevelId != null && level == null) {
    controller.discardGameSession(session);
    return;
  }
  if (session.stage == GameSessionStage.lesson && level != null) {
    Navigator.of(context)
        .push<bool>(
      MaterialPageRoute<bool>(builder: (_) => LessonFlowScreen(level: level)),
    )
        .then((startPractice) {
      if (startPractice == true && context.mounted) {
        _openGameInternal(context, level.gameId, learningLevel: level);
      }
    });
    return;
  }
  if (session.stage == GameSessionStage.completing) {
    final fallbackMissionId = session.data['fallbackMissionId'] as String?;
    if (fallbackMissionId == null ||
        fallbackMissionId.isEmpty ||
        session.maxScore <= 0) {
      controller.discardGameSession(session);
      return;
    }
    await controller.completeRunSafely(
      gameId: session.gameId,
      fallbackMissionId: fallbackMissionId,
      score: session.score,
      maxScore: session.maxScore,
      learningLevel: level,
      practiceOnly: session.data['practiceOnly'] == true,
    );
    if (!context.mounted) return;
    session = controller.gameSessionFor(
      gameId: savedSession.gameId,
      classNumber: savedSession.classNumber,
      learningLevelId: savedSession.learningLevelId,
    );
    if (session == null) return;
    controller.activateGameSession(session);
  }
  _openGameInternal(
    context,
    session.gameId,
    learningLevel: level,
    endlessPractice: level == null &&
        EndlessPracticeCoordinator.isEndlessSessionData(session.data),
  );
}

void _openGameInternal(
  BuildContext context,
  String id, {
  required LearningLevel? learningLevel,
  bool endlessPractice = false,
}) {
  final controller = BrightQuestScope.of(context);
  final classNumber = learningLevel?.classNumber ?? controller.selectedClass;
  final content = BrightQuestScope.contentOf(context);
  if (id != 'rewards_room' && !content.canOpenGame(classNumber, id)) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DevelopmentPackLockedScreen(classNumber: classNumber),
      ),
    );
    return;
  }
  if (id != 'rewards_room' && controller.dailyTimeLimitReached) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _TimeLimitReachedScreen(),
      ),
    );
    return;
  }

  final Widget screen = switch (id) {
    'math_market' => MathMarketScreen(
        learningLevel: learningLevel,
        endlessPractice: endlessPractice,
      ),
    'fraction_pizza' => FractionPizzaScreen(
        learningLevel: learningLevel,
        endlessPractice: endlessPractice,
      ),
    'science_lab' => ScienceLabScreen(
        learningLevel: learningLevel,
        endlessPractice: endlessPractice,
      ),
    'story_builder' => StoryBuilderScreen(
        learningLevel: learningLevel,
        endlessPractice: endlessPractice,
      ),
    'grammar_puzzle' => GrammarPuzzleScreen(
        learningLevel: learningLevel,
        endlessPractice: endlessPractice,
      ),
    'map_quest' => MapQuestScreen(
        learningLevel: learningLevel,
        endlessPractice: endlessPractice,
      ),
    'coding_maze' => CodingMazeScreen(
        learningLevel: learningLevel,
        endlessPractice: endlessPractice,
      ),
    'recycling_challenge' => RecyclingChallengeScreen(
        learningLevel: learningLevel,
        endlessPractice: endlessPractice,
      ),
    'rewards_room' => const RewardsRoomScreen(),
    _ => MathMarketScreen(
        learningLevel: learningLevel,
        endlessPractice: endlessPractice,
      ),
  };
  final routedScreen = id == 'rewards_room'
      ? screen
      : _LearningSessionBoundary(controller: controller, child: screen);
  final audio = BrightAudioService.instance;
  if (controller.soundEnabled) {
    unawaited(_startGameAudio(audio, id));
  }
  Navigator.of(context)
      .push<LearningSessionExit>(
    MaterialPageRoute<LearningSessionExit>(builder: (_) => routedScreen),
  )
      .then((exit) {
    unawaited(audio.stopVoice());
    final finishedSession = controller.gameSessionFor(
      gameId: id,
      classNumber: classNumber,
      learningLevelId: learningLevel?.id,
    );
    if (finishedSession?.stage == GameSessionStage.result) {
      controller.discardGameSession(finishedSession!);
    }
    if (controller.soundEnabled) {
      unawaited(audio.playMenuMusic(restart: true));
    }

    final nextLevelId = exit?.nextLevelId;
    final nextLevel =
        nextLevelId == null ? null : learningLevelById(nextLevelId);
    if (exit?.action == LearningSessionExitAction.continueNext &&
        nextLevel != null &&
        nextLevel.classNumber == controller.selectedClass &&
        controller.isLevelUnlocked(nextLevel) &&
        context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        openLearningLevel(context, nextLevel);
      });
    }
  });
}

Future<void> _startGameAudio(BrightAudioService audio, String gameId) async {
  await audio.playGameSfx(gameId, BrightInteractionSfx.start);
  await audio.playGameMusic(gameId, restart: true);
  await audio.speakGameIntro(gameId);
}

class _LearningSessionBoundary extends StatelessWidget {
  const _LearningSessionBoundary(
      {required this.controller, required this.child});

  final GameController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StudySessionTracker(
      controller: controller,
      onLimitReached: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const _TimeLimitReachedScreen(),
            ),
          );
        });
      },
      child: child,
    );
  }
}

class _TimeLimitReachedScreen extends StatelessWidget {
  const _TimeLimitReachedScreen();

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Learning break')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 12),
                    const Text(
                      'Time for a break',
                      key: Key('time_limit_break_title'),
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${controller.activeProfileName} has reached today’s ${controller.dailyTimeLimitMinutes}-minute learning limit.',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Back to BrightQuest'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'A parent can change the daily limit from the locked Parents area.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DevelopmentPackLockedScreen extends StatelessWidget {
  const _DevelopmentPackLockedScreen({required this.classNumber});

  final int classNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Development pack lock')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 58),
                    const SizedBox(height: 14),
                    Text(
                      'Class $classNumber pack is locked for testing',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This screen is enabled only by the development entitlement simulator. It does not start billing or show a child-facing purchase flow.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

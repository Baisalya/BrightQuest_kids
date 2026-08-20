import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../app/study_session_tracker.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/services/bright_audio_service.dart';
import '../../core/state/game_controller.dart';
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
  _openGameInternal(context, id, learningLevel: null);
}

void openLearningLevel(BuildContext context, LearningLevel level) {
  final controller = BrightQuestScope.of(context);
  if (!controller.isLevelUnlocked(level)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Clear the previous level before starting this challenge.'),
      ),
    );
    return;
  }
  _openGameInternal(context, level.gameId, learningLevel: level);
}

void _openGameInternal(
  BuildContext context,
  String id, {
  required LearningLevel? learningLevel,
}) {
  final controller = BrightQuestScope.of(context);
  if (id != 'rewards_room' && controller.dailyTimeLimitReached) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _TimeLimitReachedScreen(),
      ),
    );
    return;
  }

  final Widget screen = switch (id) {
    'math_market' => MathMarketScreen(learningLevel: learningLevel),
    'fraction_pizza' => FractionPizzaScreen(learningLevel: learningLevel),
    'science_lab' => ScienceLabScreen(learningLevel: learningLevel),
    'story_builder' => StoryBuilderScreen(learningLevel: learningLevel),
    'grammar_puzzle' => GrammarPuzzleScreen(learningLevel: learningLevel),
    'map_quest' => MapQuestScreen(learningLevel: learningLevel),
    'coding_maze' => CodingMazeScreen(learningLevel: learningLevel),
    'recycling_challenge' => RecyclingChallengeScreen(learningLevel: learningLevel),
    'rewards_room' => const RewardsRoomScreen(),
    _ => MathMarketScreen(learningLevel: learningLevel),
  };
  final routedScreen = id == 'rewards_room'
      ? screen
      : _LearningSessionBoundary(controller: controller, child: screen);
  final audio = BrightAudioService.instance;
  if (controller.soundEnabled) {
    unawaited(_startGameAudio(audio, id));
  }
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => routedScreen))
      .whenComplete(() {
        unawaited(audio.stopVoice());
        if (controller.soundEnabled) {
          unawaited(audio.playMenuMusic(restart: true));
        }
      });
}


Future<void> _startGameAudio(BrightAudioService audio, String gameId) async {
  await audio.playSfx(BrightSfx.levelStart);
  await audio.playGameMusic(gameId, restart: true);
  await audio.speakGameIntro(gameId);
}

class _LearningSessionBoundary extends StatelessWidget {
  const _LearningSessionBoundary({required this.controller, required this.child});

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
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${controller.activeProfileName} has reached today’s ${controller.dailyTimeLimitMinutes}-minute learning limit.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54, height: 1.4),
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

import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/learning/contextual_feedback_models.dart';
import 'package:brightquest_kids/core/learning/mission_session_models.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/presentation/game_feel_director.dart';
import 'package:brightquest_kids/core/presentation/game_feel_models.dart';
import 'package:brightquest_kids/core/rewards/adventure_reward_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameFeelDirector', () {
    test('success feedback becomes a finite celebration cue', () {
      const feedback = ContextualAttemptFeedback(
        correct: true,
        stage: ContextualFeedbackStage.success,
        cue: ContextualFeedbackCue.celebration,
        headline: 'Cleared',
        message: 'Yes.',
        strategy: 'Good move.',
        worldEmoji: '🏰',
        suggestHint: false,
        suggestRescue: false,
      );

      final moment = GameFeelDirector.forFeedback(feedback);
      expect(moment.kind, BrightMomentKind.success);
      expect(moment.mood, BrightMascotMood.celebrating);
      expect(moment.celebratory, isTrue);
    });

    test('first miss uses thinking reaction without celebration', () {
      const feedback = ContextualAttemptFeedback(
        correct: false,
        stage: ContextualFeedbackStage.nudge,
        cue: ContextualFeedbackCue.compare,
        headline: 'Try again',
        message: 'Not yet.',
        strategy: 'Compare the clue.',
        worldEmoji: '🌲',
        suggestHint: true,
        suggestRescue: false,
      );

      final moment = GameFeelDirector.forFeedback(feedback);
      expect(moment.kind, BrightMomentKind.retry);
      expect(moment.mood, BrightMascotMood.thinking);
      expect(moment.celebratory, isFalse);
    });

    test('power-up feedback becomes encouraging rather than failure', () {
      const feedback = ContextualAttemptFeedback(
        correct: false,
        stage: ContextualFeedbackStage.powerUp,
        cue: ContextualFeedbackCue.robotTrace,
        headline: 'Use a clue',
        message: 'Try the power-up.',
        strategy: 'Trace one command at a time.',
        worldEmoji: '🤖',
        suggestHint: true,
        suggestRescue: true,
      );

      final moment = GameFeelDirector.forFeedback(feedback);
      expect(moment.kind, BrightMomentKind.powerUp);
      expect(moment.mood, BrightMascotMood.encouraging);
    });

    test('boss clear receives heroic game-feel treatment', () {
      final level = learningLevelById('c4_math_operations:math_market:l3')!;
      const reward = MissionReward(
        firstCompletion: true,
        coinsAwarded: 50,
        xpAwarded: 65,
        starsAwarded: 3,
        levelId: 'c4_math_operations:math_market:l3',
        levelCompleted: true,
        levelStars: 3,
        levelStarsAwarded: 3,
        unlockedNextLevel: true,
      );
      final summary = AdventureRewardEngine.summarize(
        level: level,
        reward: reward,
        score: 5,
        maxScore: 5,
      );

      final moment = GameFeelDirector.forReward(summary);
      expect(moment.kind, BrightMomentKind.bossClear);
      expect(moment.mood, BrightMascotMood.heroic);
      expect(moment.celebratory, isTrue);
    });

    test('failed mission gets encouragement rather than heroic treatment', () {
      final level = learningLevelById('c4_math_operations:math_market:l1')!;
      const reward = MissionReward(
        firstCompletion: false,
        coinsAwarded: 0,
        xpAwarded: 0,
        starsAwarded: 0,
        levelId: 'c4_math_operations:math_market:l1',
        levelCompleted: false,
      );
      final summary = AdventureRewardEngine.summarize(
        level: level,
        reward: reward,
        score: 1,
        maxScore: 5,
      );

      final moment = GameFeelDirector.forReward(summary);
      expect(moment.kind, BrightMomentKind.retry);
      expect(moment.mood, BrightMascotMood.encouraging);
      expect(moment.celebratory, isFalse);
    });

    test('guided session phase keeps Leo in coaching mode', () {
      final moment =
          GameFeelDirector.forSessionPhase(MissionSessionPhase.tryWithHelp);
      expect(moment.kind, BrightMomentKind.hint);
      expect(moment.mood, BrightMascotMood.encouraging);
    });

    test('independent session phase stays focused', () {
      final moment =
          GameFeelDirector.forSessionPhase(MissionSessionPhase.tryYourself);
      expect(moment.kind, BrightMomentKind.focus);
      expect(moment.mood, BrightMascotMood.focused);
    });
  });
}

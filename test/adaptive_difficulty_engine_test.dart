import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_models.dart';
import 'package:brightquest_kids/core/learning/adaptive_difficulty_engine.dart';
import 'package:brightquest_kids/core/learning/adaptive_difficulty_models.dart';
import 'package:brightquest_kids/core/learning/lesson_engine.dart';
import 'package:brightquest_kids/core/learning/mission_session_engine.dart';
import 'package:brightquest_kids/core/learning/mission_session_models.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  const adaptive = AdaptiveDifficultyEngine();
  const sessions = MissionSessionEngine();

  LearningLevel levelFor(LearningLevelType type) => levelsForGame(
        3,
        'math_market',
      ).firstWhere((level) => level.type == type);

  test('failed progress moves the next session into support mode', () {
    final level = levelFor(LearningLevelType.practice);
    final policy = adaptive.forLevel(
      level: level,
      levelProgress: LearningLevelProgress(
        attempts: 2,
        bestRatio: 0.4,
      ),
      gameProgress: GameProgress(),
    );

    expect(policy.readiness, AdaptiveReadinessBand.needsSupport);
    expect(policy.posture, AdaptiveMissionPosture.scaffoldedPractice);
    expect(policy.allowPreAttemptHints, isTrue);
    expect(policy.rescueUnlockAfterMisses, 1);
    expect(policy.targetDifficulty, level.difficulty);
  });

  test('established strong performance gets a lighter Practice posture', () {
    final level = levelFor(LearningLevelType.practice);
    final policy = adaptive.forLevel(
      level: level,
      levelProgress: LearningLevelProgress(),
      gameProgress: GameProgress(
        attempts: 10,
        correctAnswers: 9,
        mastery: 0.78,
      ),
    );

    expect(policy.readiness, AdaptiveReadinessBand.stretchReady);
    expect(policy.posture, AdaptiveMissionPosture.lightPractice);
    expect(policy.includeExplanation, isFalse);
    expect(policy.allowPreAttemptHints, isFalse);
    expect(policy.allowsMainGameHints, isTrue);
  });

  test('normal Practice keeps the complete four-phase teaching loop', () {
    final repository = buildContentRepository();
    final level = levelFor(LearningLevelType.practice);
    final flow = const LessonEngine().buildForLevel(
      repository: repository,
      level: level,
    );
    final policy = adaptive.forLevel(
      level: level,
      levelProgress: LearningLevelProgress(),
      gameProgress: GameProgress(),
    );
    final session = sessions.build(flow, policy: policy);

    expect(session.steps, hasLength(7));
    expect(session.activePhases, MissionSessionPhase.values);
    expect(
      session.steps
          .firstWhere(
              (step) => step.lessonStep.kind == LessonStepKind.guidedTry)
          .supportMode,
      MissionSupportMode.coached,
    );
    expect(policy.allowsMainGameHints, isTrue);
  });

  test('Challenge compresses teaching and removes pre-attempt help', () {
    final repository = buildContentRepository();
    final level = levelFor(LearningLevelType.challenge);
    final flow = const LessonEngine().buildForLevel(
      repository: repository,
      level: level,
    );
    final policy = adaptive.forLevel(
      level: level,
      levelProgress: LearningLevelProgress(),
      gameProgress: GameProgress(),
    );
    final session = sessions.build(flow, policy: policy);

    expect(
      session.steps.map((step) => step.lessonStep.kind),
      <LessonStepKind>[
        LessonStepKind.objective,
        LessonStepKind.workedExample,
        LessonStepKind.guidedTry,
        LessonStepKind.exitTicket,
      ],
    );
    expect(policy.allowPreAttemptHints, isFalse);
    expect(policy.hintUnlockAfterMisses, 1);
    expect(policy.allowsMainGameHints, isFalse);
    expect(session.steps.last.supportMode, MissionSupportMode.challenge);
  });

  test(
      'struggling Challenge restores one coached warm-up but not easier level difficulty',
      () {
    final repository = buildContentRepository();
    final level = levelFor(LearningLevelType.challenge);
    final flow = const LessonEngine().buildForLevel(
      repository: repository,
      level: level,
    );
    final policy = adaptive.forLevel(
      level: level,
      levelProgress: LearningLevelProgress(
        attempts: 1,
        bestRatio: 0.25,
      ),
      gameProgress: GameProgress(),
    );
    final session = sessions.build(flow, policy: policy);
    final guided = session.steps.firstWhere(
      (step) => step.lessonStep.kind == LessonStepKind.guidedTry,
    );
    final exit = session.steps.last.lessonStep;
    final exitActivity = repository.activityById(exit.activityId!);

    expect(policy.posture, AdaptiveMissionPosture.supportedChallenge);
    expect(guided.supportMode, MissionSupportMode.coached);
    expect(policy.allowPreAttemptHints, isTrue);
    expect(policy.targetDifficulty, 2);
    expect(exitActivity?.difficulty, 2);
  });

  test('Mastery is a short proof session with no hint or rescue path', () {
    final repository = buildContentRepository();
    final level = levelFor(LearningLevelType.mastery);
    final flow = const LessonEngine().buildForLevel(
      repository: repository,
      level: level,
    );
    final policy = adaptive.forLevel(
      level: level,
      levelProgress: LearningLevelProgress(
        attempts: 3,
        bestRatio: 0.3,
      ),
      gameProgress: GameProgress(
        attempts: 8,
        correctAnswers: 3,
        mastery: 0.2,
      ),
    );
    final session = sessions.build(flow, policy: policy);
    final proof = session.steps.last;
    final proofActivity = repository.activityById(proof.lessonStep.activityId!);

    expect(policy.isMasteryProof, isTrue);
    expect(
      session.steps.map((step) => step.lessonStep.kind),
      <LessonStepKind>[
        LessonStepKind.objective,
        LessonStepKind.exitTicket,
      ],
    );
    expect(proof.supportMode, MissionSupportMode.mastery);
    expect(proofActivity?.difficulty, 3);
    expect(policy.hintsEnabled, isFalse);
    expect(policy.rescueEnabled, isFalse);
    expect(policy.allowsMainGameHints, isFalse);
  });

  test('Learning World lesson activities never exceed the level difficulty',
      () {
    final repository = buildContentRepository();

    for (final classNumber in <int>[3, 4, 5]) {
      for (final level in levelsForClass(classNumber)) {
        final flow = const LessonEngine().buildForLevel(
          repository: repository,
          level: level,
        );
        for (final step in flow.steps) {
          final activityId = step.activityId;
          if (activityId == null) continue;
          final activity = repository.activityById(activityId);
          expect(activity, isNotNull, reason: '${level.id} / ${step.id}');
          expect(
            activity!.difficulty,
            lessThanOrEqualTo(level.difficulty),
            reason: '${level.id} / ${step.id}',
          );
        }
        final exit = flow.steps.firstWhere(
          (step) => step.kind == LessonStepKind.exitTicket,
        );
        expect(
          repository.activityById(exit.activityId!)?.difficulty,
          level.difficulty,
          reason: '${level.id} must finish at its authored level tier',
        );
      }
    }
  });

  test('Quick Play keeps hints while Challenge and Mastery main runs do not',
      () {
    expect(learningLevelAllowsMainGameHints(null), isTrue);
    expect(
      learningLevelAllowsMainGameHints(levelFor(LearningLevelType.practice)),
      isTrue,
    );
    expect(
      learningLevelAllowsMainGameHints(levelFor(LearningLevelType.challenge)),
      isFalse,
    );
    expect(
      learningLevelAllowsMainGameHints(levelFor(LearningLevelType.mastery)),
      isFalse,
    );
  });
}

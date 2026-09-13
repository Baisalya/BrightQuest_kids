import 'dart:io';

import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/models/progress_models.dart';
import 'package:brightquest_kids/core/session/game_session_models.dart';
import 'package:brightquest_kids/core/session/game_session_store.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/core/persistence/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Step 10 game session persistence', () {
    test('checkpoint round-trip preserves resumable mission state', () {
      final checkpoint = GameSessionCheckpoint(
        profileId: 'child-1',
        classNumber: 4,
        gameId: 'math_market',
        learningLevelId: 'c4_math_operations:math_market:l1',
        difficulty: 1,
        stage: GameSessionStage.game,
        cursor: 2,
        score: 1,
        maxScore: 4,
        startedAtIso: '2026-08-22T10:00:00.000',
        updatedAtIso: '2026-08-22T10:04:00.000',
        completedInteractiveStepIds: const <String>{'guided'},
        shownHintIndices: const <int>{0},
        data: const <String, Object?>{
          'selected': 4,
          'wasCorrect': true,
        },
        reward: const GameSessionRewardSnapshot(
          firstCompletion: true,
          coinsAwarded: 30,
          xpAwarded: 45,
          starsAwarded: 2,
        ),
      );

      final restored = GameSessionCheckpoint.fromJson(checkpoint.toJson());
      expect(restored.schemaVersion, 1);
      expect(restored.profileId, 'child-1');
      expect(restored.learningLevelId, checkpoint.learningLevelId);
      expect(restored.stage, GameSessionStage.game);
      expect(restored.cursor, 2);
      expect(restored.score, 1);
      expect(restored.completedInteractiveStepIds, contains('guided'));
      expect(restored.shownHintIndices, contains(0));
      expect(restored.data['selected'], 4);
      expect(restored.reward?.coinsAwarded, 30);
      expect(restored.slotKey, checkpoint.slotKey);
    });

    test('session state persists separately from player snapshot schema',
        () async {
      final progressStore = MemoryProgressStore();
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await controller.load();
      final level = levelsForClass(4).first;

      controller.beginLessonSession(level: level, totalSteps: 7);
      controller.checkpointLessonSession(
        level: level,
        stepIndex: 3,
        totalSteps: 7,
        completedInteractiveStepIds: const <String>{'guided'},
        shownHintIndices: const <int>{0},
      );
      await controller.flushGameSession();
      await controller.flush();

      final rawProgress = await progressStore.read();
      expect(rawProgress?['schemaVersion'], 6);
      expect(rawProgress, isNot(contains('gameSessions')));

      final restored = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await restored.load();
      expect(restored.activeGameSession?.stage, GameSessionStage.lesson);
      expect(restored.activeGameSession?.cursor, 3);
      expect(
        restored.activeGameSession?.completedInteractiveStepIds,
        contains('guided'),
      );
    });

    test('saved sessions remain isolated per child profile', () async {
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(sessionStore: sessionStore);
      await controller.load();
      final firstProfile = controller.activeProfileId;
      final firstLevel = levelsForClass(4).first;
      controller.beginLessonSession(level: firstLevel, totalSteps: 6);

      final secondProfile = controller.createProfile(
        name: 'Mira',
        classNumber: 5,
      );
      final secondLevel = levelsForClass(5).first;
      controller.beginLessonSession(level: secondLevel, totalSteps: 6);
      await controller.flushGameSession();

      expect(controller.activeGameSession?.profileId, secondProfile);
      expect(controller.switchProfile(firstProfile), isTrue);
      expect(controller.activeGameSession?.profileId, firstProfile);
      expect(controller.activeGameSession?.learningLevelId, firstLevel.id);
      expect(controller.switchProfile(secondProfile), isTrue);
      expect(controller.activeGameSession?.learningLevelId, secondLevel.id);
    });

    test('different games keep independent resumable slots', () async {
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(sessionStore: sessionStore);
      await controller.load();
      final classNumber = controller.selectedClass;
      final levels = levelsForClass(classNumber);
      final first = levels.first;
      final second = levels.firstWhere((level) => level.gameId != first.gameId);

      controller.beginOrResumeGameSession(
        gameId: first.gameId,
        classNumber: classNumber,
        difficulty: first.difficulty,
        maxScore: 4,
        learningLevel: first,
      );
      controller.checkpointGameSession(
        gameId: first.gameId,
        classNumber: classNumber,
        difficulty: first.difficulty,
        cursor: 2,
        score: 1,
        maxScore: 4,
        learningLevel: first,
      );
      controller.beginOrResumeGameSession(
        gameId: second.gameId,
        classNumber: classNumber,
        difficulty: second.difficulty,
        maxScore: 5,
        learningLevel: second,
      );
      controller.checkpointGameSession(
        gameId: second.gameId,
        classNumber: classNumber,
        difficulty: second.difficulty,
        cursor: 3,
        score: 2,
        maxScore: 5,
        learningLevel: second,
      );
      await controller.flushGameSession();

      expect(controller.resumableGameSessions, hasLength(2));
      expect(
        controller
            .gameSessionFor(
              gameId: first.gameId,
              classNumber: classNumber,
              learningLevelId: first.id,
            )
            ?.cursor,
        2,
      );
      expect(
        controller
            .gameSessionFor(
              gameId: second.gameId,
              classNumber: classNumber,
              learningLevelId: second.id,
            )
            ?.cursor,
        3,
      );

      final restored = GameController(sessionStore: sessionStore);
      await restored.load();
      expect(restored.resumableGameSessions, hasLength(2));
      expect(
        restored
            .gameSessionFor(
              gameId: first.gameId,
              classNumber: classNumber,
              learningLevelId: first.id,
            )
            ?.score,
        1,
      );
      expect(
        restored
            .gameSessionFor(
              gameId: second.gameId,
              classNumber: classNumber,
              learningLevelId: second.id,
            )
            ?.score,
        2,
      );
    });

    test('completing one saved mission leaves other paused games untouched',
        () async {
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(sessionStore: sessionStore);
      await controller.load();
      final classNumber = controller.selectedClass;
      final levels = levelsForClass(classNumber);
      final first = levels.first;
      final second = levels.firstWhere((level) => level.gameId != first.gameId);

      controller.beginOrResumeGameSession(
        gameId: first.gameId,
        classNumber: classNumber,
        difficulty: first.difficulty,
        maxScore: 4,
        learningLevel: first,
      );
      controller.beginOrResumeGameSession(
        gameId: second.gameId,
        classNumber: classNumber,
        difficulty: second.difficulty,
        maxScore: 4,
        learningLevel: second,
      );

      await controller.completeRunSafely(
        gameId: first.gameId,
        fallbackMissionId: '${first.gameId}:multi-slot-complete',
        score: 4,
        maxScore: 4,
        learningLevel: first,
      );

      expect(
        controller
            .gameSessionFor(
              gameId: first.gameId,
              classNumber: classNumber,
              learningLevelId: first.id,
            )
            ?.stage,
        GameSessionStage.result,
      );
      expect(
        controller
            .gameSessionFor(
              gameId: second.gameId,
              classNumber: classNumber,
              learningLevelId: second.id,
            )
            ?.stage,
        GameSessionStage.game,
      );
      expect(controller.resumableGameSessions, hasLength(2));
    });

    test('same game keeps separate learning-mission slots and discard is local',
        () async {
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(sessionStore: sessionStore);
      await controller.load();
      final classNumber = controller.selectedClass;
      final first = levelsForClass(classNumber).first;
      final sameGameLevels = levelsForGame(classNumber, first.gameId);
      expect(sameGameLevels.length, greaterThanOrEqualTo(2));
      final second = sameGameLevels[1];

      final firstSession = controller.beginLessonSession(
        level: first,
        totalSteps: 7,
      );
      final secondSession = controller.beginLessonSession(
        level: second,
        totalSteps: 7,
      );
      expect(firstSession.slotKey, isNot(secondSession.slotKey));
      expect(controller.resumableGameSessions, hasLength(2));

      controller.discardGameSession(firstSession);
      expect(
        controller.gameSessionFor(
          gameId: first.gameId,
          classNumber: classNumber,
          learningLevelId: first.id,
        ),
        isNull,
      );
      expect(
        controller.gameSessionFor(
          gameId: second.gameId,
          classNumber: classNumber,
          learningLevelId: second.id,
        ),
        isNotNull,
      );
    });

    test('legacy profile-key session payload migrates to canonical slot key',
        () {
      final now = DateTime.now().toIso8601String();
      final checkpoint = GameSessionCheckpoint(
        profileId: 'child-1',
        classNumber: 4,
        gameId: 'math_market',
        difficulty: 1,
        stage: GameSessionStage.game,
        cursor: 1,
        score: 0,
        maxScore: 4,
        startedAtIso: now,
        updatedAtIso: now,
      );
      final restored = decodeGameSessions(<String, Object?>{
        'schemaVersion': 1,
        'sessions': <String, Object?>{
          'child-1': checkpoint.toJson(),
        },
      });
      expect(restored.keys, contains(checkpoint.slotKey));
      expect(restored['child-1'], isNull);
    });

    test('quick-play resume keeps the saved difficulty bank', () async {
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(sessionStore: sessionStore);
      await controller.load();
      final classNumber = controller.selectedClass;
      controller.beginOrResumeGameSession(
        gameId: 'math_market',
        classNumber: classNumber,
        difficulty: 2,
        maxScore: 4,
      );

      expect(
        controller.resumableDifficulty(
          gameId: 'math_market',
          classNumber: classNumber,
          fallbackDifficulty: 3,
        ),
        2,
      );
    });

    test('changing class hides but preserves other-class saved sessions',
        () async {
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(sessionStore: sessionStore);
      await controller.load();
      final classFourLevel = levelsForClass(4).first;
      controller.beginLessonSession(level: classFourLevel, totalSteps: 6);
      expect(controller.hasResumableGameSession, isTrue);

      controller.setClass(5);
      await controller.flushGameSession();
      expect(controller.activeGameSession, isNull);
      expect(controller.resumableGameSessions, isEmpty);
      expect(controller.allResumableGameSessionsForActiveProfile, hasLength(1));

      controller.setClass(4);
      expect(controller.activeGameSession?.learningLevelId, classFourLevel.id);
    });

    test('answer evidence marker prevents double scoring across resume',
        () async {
      final progressStore = MemoryProgressStore();
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await controller.load();
      final level = levelsForClass(controller.selectedClass).first;
      controller.beginOrResumeGameSession(
        gameId: level.gameId,
        classNumber: level.classNumber,
        difficulty: level.difficulty,
        maxScore: 4,
        learningLevel: level,
      );
      final startingCoins = controller.coins;

      await controller.recordAnswerSafely(
        gameId: level.gameId,
        correct: true,
        attemptMarker: 'answer:0',
        itemId: 'step10-test-item',
        competencyId: 'step10-test-competency',
        evidenceKind: LearningAttemptKind.independent,
      );
      final attempts = controller.statsFor(level.gameId).attempts;
      final evidenceCount = controller.learningState.attemptEvidence.length;
      final coins = controller.coins;
      expect(attempts, greaterThan(0));
      expect(coins, greaterThan(startingCoins));

      await controller.recordAnswerSafely(
        gameId: level.gameId,
        correct: true,
        attemptMarker: 'answer:0',
        itemId: 'step10-test-item',
        competencyId: 'step10-test-competency',
        evidenceKind: LearningAttemptKind.independent,
      );
      expect(controller.statsFor(level.gameId).attempts, attempts);
      expect(controller.learningState.attemptEvidence.length, evidenceCount);
      expect(controller.coins, coins);
      await controller.flushGameSession();

      final restored = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await restored.load();
      await restored.recordAnswerSafely(
        gameId: level.gameId,
        correct: true,
        attemptMarker: 'answer:0',
        itemId: 'step10-test-item',
        competencyId: 'step10-test-competency',
        evidenceKind: LearningAttemptKind.independent,
      );
      expect(restored.statsFor(level.gameId).attempts, attempts);
      expect(restored.learningState.attemptEvidence.length, evidenceCount);
      expect(restored.coins, coins);
    });

    test('answer transaction marker protects scoring without learning evidence',
        () async {
      final progressStore = MemoryProgressStore();
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await controller.load();
      final level = levelsForClass(controller.selectedClass).first;
      controller.beginOrResumeGameSession(
        gameId: level.gameId,
        classNumber: level.classNumber,
        difficulty: level.difficulty,
        maxScore: 4,
        learningLevel: level,
      );
      final startingCoins = controller.coins;

      await controller.recordAnswerSafely(
        gameId: level.gameId,
        correct: true,
        attemptMarker: 'answer:no-evidence',
      );
      final attempts = controller.statsFor(level.gameId).attempts;
      final coins = controller.coins;
      expect(attempts, greaterThan(0));
      expect(coins, greaterThan(startingCoins));
      await controller.flushGameSession();

      final restored = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await restored.load();
      await restored.recordAnswerSafely(
        gameId: level.gameId,
        correct: true,
        attemptMarker: 'answer:no-evidence',
      );
      expect(restored.statsFor(level.gameId).attempts, attempts);
      expect(restored.coins, coins);
    });

    test('duplicate in-flight session actions are coalesced', () async {
      final progressStore = MemoryProgressStore();
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await controller.load();
      final level = levelsForClass(controller.selectedClass).first;
      controller.beginOrResumeGameSession(
        gameId: level.gameId,
        classNumber: level.classNumber,
        difficulty: level.difficulty,
        maxScore: 4,
        learningLevel: level,
      );

      final baseAnswerAttempts = controller.statsFor(level.gameId).attempts;
      await Future.wait(<Future<AnswerReward>>[
        controller.recordAnswerSafely(
          gameId: level.gameId,
          correct: true,
          attemptMarker: 'answer:double-tap',
        ),
        controller.recordAnswerSafely(
          gameId: level.gameId,
          correct: true,
          attemptMarker: 'answer:double-tap',
        ),
      ]);
      expect(
        controller.statsFor(level.gameId).attempts,
        baseAnswerAttempts + 1,
      );

      final coinsBeforeHint = controller.coins;
      final hintsBefore = controller.statsFor(level.gameId).hintsUsed;
      final hintResults = await Future.wait(<Future<bool>>[
        controller.useHintSafely(
          gameId: level.gameId,
          cost: 5,
          marker: 'hint:double-tap',
        ),
        controller.useHintSafely(
          gameId: level.gameId,
          cost: 5,
          marker: 'hint:double-tap',
        ),
      ]);
      expect(hintResults, everyElement(isTrue));
      expect(controller.coins, coinsBeforeHint - 5);
      expect(controller.statsFor(level.gameId).hintsUsed, hintsBefore + 1);

      final levelAttemptsBefore = controller.levelStatsFor(level.id).attempts;
      final completionResults = await Future.wait(<Future<MissionReward>>[
        controller.completeRunSafely(
          gameId: level.gameId,
          fallbackMissionId: '${level.gameId}:test:double-tap',
          learningLevel: level,
          score: 4,
          maxScore: 4,
        ),
        controller.completeRunSafely(
          gameId: level.gameId,
          fallbackMissionId: '${level.gameId}:test:double-tap',
          learningLevel: level,
          score: 4,
          maxScore: 4,
        ),
      ]);
      expect(
          controller.levelStatsFor(level.id).attempts, levelAttemptsBefore + 1);
      expect(
        completionResults[1].coinsAwarded,
        completionResults[0].coinsAwarded,
      );
    });

    test('paid hint marker prevents double charging across resume', () async {
      final progressStore = MemoryProgressStore();
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await controller.load();
      final level = levelsForClass(4)
          .firstWhere((candidate) => candidate.gameId == 'math_market');
      controller.beginOrResumeGameSession(
        gameId: level.gameId,
        classNumber: level.classNumber,
        difficulty: level.difficulty,
        maxScore: 4,
        learningLevel: level,
      );
      final startingCoins = controller.coins;

      expect(
        await controller.useHintSafely(
          gameId: level.gameId,
          cost: 5,
          marker: 'math:0',
        ),
        isTrue,
      );
      expect(controller.coins, startingCoins - 5);
      expect(controller.statsFor(level.gameId).hintsUsed, 1);
      expect(
        await controller.useHintSafely(
          gameId: level.gameId,
          cost: 5,
          marker: 'math:0',
        ),
        isTrue,
      );
      expect(controller.coins, startingCoins - 5);
      await controller.flush();
      await controller.flushGameSession();

      final restored = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await restored.load();
      expect(
        await restored.useHintSafely(
          gameId: level.gameId,
          cost: 5,
          marker: 'math:0',
        ),
        isTrue,
      );
      expect(restored.coins, startingCoins - 5);
      expect(restored.statsFor(level.gameId).hintsUsed, 1);
    });

    test('completed run cannot be rewarded twice after normal resume',
        () async {
      final progressStore = MemoryProgressStore();
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await controller.load();
      final level = levelsForClass(4).first;
      controller.beginOrResumeGameSession(
        gameId: level.gameId,
        classNumber: level.classNumber,
        difficulty: level.difficulty,
        maxScore: 4,
        learningLevel: level,
      );

      final firstReward = await controller.completeRunSafely(
        gameId: level.gameId,
        fallbackMissionId: '${level.gameId}:test:resume',
        learningLevel: level,
        score: 4,
        maxScore: 4,
      );
      final attemptsAfterFirst = controller.levelStatsFor(level.id).attempts;
      final coinsAfterFirst = controller.coins;

      final restored = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await restored.load();
      final resumedReward = await restored.completeRunSafely(
        gameId: level.gameId,
        fallbackMissionId: '${level.gameId}:test:resume',
        learningLevel: level,
        score: 4,
        maxScore: 4,
      );

      expect(restored.levelStatsFor(level.id).attempts, attemptsAfterFirst);
      expect(restored.coins, coinsAfterFirst);
      expect(resumedReward.coinsAwarded, firstReward.coinsAwarded);
      expect(resumedReward.xpAwarded, firstReward.xpAwarded);
      expect(resumedReward.levelStars, firstReward.levelStars);
    });

    test('completion recovery detects progress committed before result marker',
        () async {
      final progressStore = MemoryProgressStore();
      final sessionStore = MemoryGameSessionStore();
      final controller = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await controller.load();
      final level = levelsForClass(4).first;
      final checkpoint = controller.beginOrResumeGameSession(
        gameId: level.gameId,
        classNumber: level.classNumber,
        difficulty: level.difficulty,
        maxScore: 4,
        learningLevel: level,
      );
      // Drain the checkpoint created by beginOrResumeGameSession before
      // injecting the simulated crash-state checkpoint. Otherwise that earlier
      // queued write can race with this manual store write and replace the
      // `completing` checkpoint with the pre-completion `game` checkpoint.
      await controller.flushGameSession();

      final pending = checkpoint.copyWith(
        stage: GameSessionStage.completing,
        score: 4,
        maxScore: 4,
        data: <String, Object?>{
          'fallbackMissionId': '${level.gameId}:test:crash',
          'score': 4,
          'maxScore': 4,
          'baseCoins': controller.coins,
          'baseXp': controller.xp,
          'baseStars': controller.stars,
          'baseGameCompletedRuns':
              controller.statsFor(level.gameId).completedRuns,
          'baseLevelAttempts': controller.levelStatsFor(level.id).attempts,
          'baseLevelCompletedRuns':
              controller.levelStatsFor(level.id).completedRuns,
          'baseLevelStars': controller.levelStatsFor(level.id).earnedStars,
          'baseMissionCompleted': false,
          'baseAchievementIds': controller.unlockedAchievementIds.toList(),
        },
      );
      await sessionStore.writeAll(<String, GameSessionCheckpoint>{
        controller.activeProfileId: pending,
      });
      expect(
        (await sessionStore.readAll())[pending.slotKey]?.stage,
        GameSessionStage.completing,
      );

      controller.completeRun(
        gameId: level.gameId,
        fallbackMissionId: '${level.gameId}:test:crash',
        learningLevel: level,
        score: 4,
        maxScore: 4,
      );
      await controller.flush();
      final attemptsAfterCommit = controller.levelStatsFor(level.id).attempts;
      final coinsAfterCommit = controller.coins;

      final restored = GameController(
        store: progressStore,
        sessionStore: sessionStore,
      );
      await restored.load();
      final reward = await restored.completeRunSafely(
        gameId: level.gameId,
        fallbackMissionId: '${level.gameId}:test:crash',
        learningLevel: level,
        score: 4,
        maxScore: 4,
      );

      expect(restored.levelStatsFor(level.id).attempts, attemptsAfterCommit);
      expect(restored.coins, coinsAfterCommit);
      expect(reward.firstCompletion, isTrue);
      expect(restored.activeGameSession?.stage, GameSessionStage.result);
    });

    test('unsupported session-store schema fails closed', () {
      final restored = decodeGameSessions(<String, Object?>{
        'schemaVersion': 99,
        'sessions': <String, Object?>{
          'child-1': <String, Object?>{},
        },
      });
      expect(restored, isEmpty);
    });

    test('checkpoint without its schema marker fails closed', () {
      expect(
        () => GameSessionCheckpoint.fromJson(<String, Object?>{
          'profileId': 'child-1',
          'classNumber': 4,
          'gameId': 'math_market',
          'difficulty': 1,
          'stage': 'game',
        }),
        throwsFormatException,
      );
    });

    test('saved checkpoints from another class remain isolated and resumable',
        () async {
      final sessionStore = MemoryGameSessionStore();
      final seed = GameController(sessionStore: sessionStore);
      await seed.load();
      final profileId = seed.activeProfileId;
      final originalClass = seed.selectedClass;
      final otherClass = originalClass == 5 ? 4 : 5;
      final now = DateTime.now().toIso8601String();
      final checkpoint = GameSessionCheckpoint(
        profileId: profileId,
        classNumber: otherClass,
        gameId: 'math_market',
        difficulty: 1,
        stage: GameSessionStage.game,
        cursor: 0,
        score: 0,
        maxScore: 4,
        startedAtIso: now,
        updatedAtIso: now,
      );
      await sessionStore.writeAll(<String, GameSessionCheckpoint>{
        profileId: checkpoint,
      });

      final restored = GameController(sessionStore: sessionStore);
      await restored.load();
      expect(restored.activeGameSession, isNull);
      expect(restored.allResumableGameSessionsForActiveProfile, hasLength(1));
      expect((await sessionStore.readAll())[checkpoint.slotKey], isNotNull);

      restored.setClass(otherClass);
      expect(restored.activeGameSession?.slotKey, checkpoint.slotKey);
    });

    test('result checkpoint without a persisted reward is discarded', () async {
      final sessionStore = MemoryGameSessionStore();
      final seed = GameController(sessionStore: sessionStore);
      await seed.load();
      final level = levelsForClass(seed.selectedClass).first;
      final now = DateTime.now().toIso8601String();
      await sessionStore.writeAll(<String, GameSessionCheckpoint>{
        seed.activeProfileId: GameSessionCheckpoint(
          profileId: seed.activeProfileId,
          classNumber: level.classNumber,
          gameId: level.gameId,
          learningLevelId: level.id,
          difficulty: level.difficulty,
          stage: GameSessionStage.result,
          cursor: 0,
          score: 1,
          maxScore: 1,
          startedAtIso: now,
          updatedAtIso: now,
        ),
      });

      final restored = GameController(sessionStore: sessionStore);
      await restored.load();
      expect(restored.activeGameSession, isNull);
      expect(await sessionStore.readAll(), isEmpty);
    });

    test('malformed completing checkpoint is discarded before resume',
        () async {
      final sessionStore = MemoryGameSessionStore();
      final seed = GameController(sessionStore: sessionStore);
      await seed.load();
      final level = levelsForClass(seed.selectedClass).first;
      final now = DateTime.now().toIso8601String();
      await sessionStore.writeAll(<String, GameSessionCheckpoint>{
        seed.activeProfileId: GameSessionCheckpoint(
          profileId: seed.activeProfileId,
          classNumber: level.classNumber,
          gameId: level.gameId,
          learningLevelId: level.id,
          difficulty: level.difficulty,
          stage: GameSessionStage.completing,
          cursor: 0,
          score: 1,
          maxScore: 1,
          startedAtIso: now,
          updatedAtIso: now,
          data: const <String, Object?>{
            'fallbackMissionId': 'incomplete-baseline',
          },
        ),
      });

      final restored = GameController(sessionStore: sessionStore);
      await restored.load();
      expect(restored.activeGameSession, isNull);
      expect(await sessionStore.readAll(), isEmpty);
    });

    test('unknown game checkpoint is discarded', () async {
      final sessionStore = MemoryGameSessionStore();
      final seed = GameController(sessionStore: sessionStore);
      await seed.load();
      final now = DateTime.now().toIso8601String();
      await sessionStore.writeAll(<String, GameSessionCheckpoint>{
        seed.activeProfileId: GameSessionCheckpoint(
          profileId: seed.activeProfileId,
          classNumber: seed.selectedClass,
          gameId: 'unknown_game',
          difficulty: 1,
          stage: GameSessionStage.game,
          cursor: 0,
          score: 0,
          maxScore: 1,
          startedAtIso: now,
          updatedAtIso: now,
        ),
      });

      final restored = GameController(sessionStore: sessionStore);
      await restored.load();
      expect(restored.activeGameSession, isNull);
      expect(await sessionStore.readAll(), isEmpty);
    });

    test('learning-level identity mismatch is rejected on load', () async {
      final sessionStore = MemoryGameSessionStore();
      final seed = GameController(sessionStore: sessionStore);
      await seed.load();
      final level = levelsForClass(seed.selectedClass).first;
      final mismatchedGame =
          level.gameId == 'math_market' ? 'story_builder' : 'math_market';
      final now = DateTime.now().toIso8601String();
      await sessionStore.writeAll(<String, GameSessionCheckpoint>{
        seed.activeProfileId: GameSessionCheckpoint(
          profileId: seed.activeProfileId,
          classNumber: level.classNumber,
          gameId: mismatchedGame,
          learningLevelId: level.id,
          difficulty: level.difficulty,
          stage: GameSessionStage.game,
          cursor: 0,
          score: 0,
          maxScore: 4,
          startedAtIso: now,
          updatedAtIso: now,
        ),
      });

      final restored = GameController(sessionStore: sessionStore);
      await restored.load();
      expect(restored.activeGameSession, isNull);
    });

    test('stale checkpoints fail closed instead of blocking the child',
        () async {
      final sessionStore = MemoryGameSessionStore();
      final level = levelsForClass(4).first;
      await sessionStore.writeAll(<String, GameSessionCheckpoint>{
        'child-1': GameSessionCheckpoint(
          profileId: 'child-1',
          classNumber: 4,
          gameId: level.gameId,
          learningLevelId: level.id,
          difficulty: level.difficulty,
          stage: GameSessionStage.game,
          cursor: 1,
          score: 1,
          maxScore: 4,
          startedAtIso: '2020-01-01T00:00:00.000',
          updatedAtIso: '2020-01-01T00:00:00.000',
        ),
      });
      final controller = GameController(sessionStore: sessionStore);
      await controller.load();
      expect(controller.activeGameSession, isNull);
    });

    test('all eight main games use resumable checkpoints and safe completion',
        () {
      const files = <String>[
        'math_market_screen.dart',
        'fraction_pizza_screen.dart',
        'science_lab_screen.dart',
        'story_builder_screen.dart',
        'grammar_puzzle_screen.dart',
        'map_quest_screen.dart',
        'coding_maze_screen.dart',
        'recycling_challenge_screen.dart',
      ];
      for (final name in files) {
        final source = File('lib/features/games/$name').readAsStringSync();
        expect(source, contains('beginOrResumeGameSession'), reason: name);
        expect(source, contains('checkpointGameSession'), reason: name);
        expect(source, contains('recordAnswerSafely'), reason: name);
        expect(source, contains('attemptSerial'), reason: name);
        expect(source, contains('completeRunSafely'), reason: name);
      }
      final mainSource = File('lib/main.dart').readAsStringSync();
      expect(mainSource, contains('SharedPreferencesGameSessionStore'));
      final routerSource =
          File('lib/features/games/game_router.dart').readAsStringSync();
      expect(routerSource, contains('resumeActiveGameSession'));
      expect(routerSource, contains('resumeGameSession'));
      expect(routerSource, isNot(contains('You already have a saved mission')));
      expect(routerSource, contains('GameSessionStage.completing'));
      final homeSource =
          File('lib/features/home/home_screen.dart').readAsStringSync();
      expect(homeSource, contains('controller.resumableGameSessions'));
      expect(homeSource, contains('resumeGameSession(context, session)'));

      final adventuresSource =
          File('lib/features/adventures/adventures_screen.dart')
              .readAsStringSync();
      expect(adventuresSource, contains('controller.resumableGameSessions'));
      expect(
        adventuresSource,
        isNot(contains('resumeGameSession(context, session)')),
      );

      final worldSource =
          File('lib/features/adventures/learning_world_screen.dart')
              .readAsStringSync();
      expect(worldSource, contains('resumeGameSession(context, session)'));
      expect(
        worldSource,
        contains('onDiscardSaved: controller.discardGameSession'),
      );
      final lessonSource = File(
        'lib/features/learning/lesson_flow_screen.dart',
      ).readAsStringSync();
      expect(lessonSource, contains('checkpointLessonSession'));
      expect(lessonSource, contains('flushGameSession'));
      final trackerSource =
          File('lib/app/study_session_tracker.dart').readAsStringSync();
      expect(trackerSource, contains('flushGameSession'));
      final sessionStoreSource = File(
        'lib/core/session/shared_preferences_game_session_store.dart',
      ).readAsStringSync();
      expect(
        sessionStoreSource,
        contains('brightquest.active_game_sessions.v1'),
      );
    });
  });
}

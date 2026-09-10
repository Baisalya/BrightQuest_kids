import 'package:brightquest_kids/core/content/content_repository.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/learning/endless_practice_coordinator.dart';
import 'package:brightquest_kids/core/learning/mission_exposure_memory.dart';
import 'package:brightquest_kids/core/learning/mission_run_game_content.dart';
import 'package:brightquest_kids/core/learning/mission_run_models.dart';
import 'package:brightquest_kids/core/session/game_session_models.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/adventures/learning_world_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';
import 'support/content_fixture.dart';

void main() {
  const coordinator = EndlessPracticeCoordinator();
  const adapter = MissionRunGameContent();
  const gameIds = <String>[
    'math_market',
    'fraction_pizza',
    'story_builder',
    'grammar_puzzle',
    'science_lab',
    'map_quest',
    'coding_maze',
    'recycling_challenge',
  ];

  test(
      'canonical curriculum stays 72 levels while every game gets 10-item endless rounds',
      () {
    final repository = buildContentRepository();
    expect(learningLevels, hasLength(72));

    for (final classNumber in const <int>[3, 4, 5]) {
      expect(levelsForClass(classNumber), hasLength(24));
      for (final gameId in gameIds) {
        expect(levelsForGame(classNumber, gameId), hasLength(3));
        final plan = coordinator.createOrRestore(
          repository: repository,
          classNumber: classNumber,
          gameId: gameId,
          now: DateTime.utc(2026, 8, 24, classNumber),
        );
        expect(EndlessPracticeCoordinator.isEndlessPlan(plan), isTrue,
            reason: 'c$classNumber $gameId');
        expect(plan.trainingItems, isEmpty, reason: 'c$classNumber $gameId');
        expect(plan.gameItems, hasLength(10), reason: 'c$classNumber $gameId');
        expect(plan.hasContentShortfall, isFalse,
            reason: 'c$classNumber $gameId');
        expect(plan.hasInternalContentRepeat, isFalse,
            reason: 'c$classNumber $gameId');
        expect(
          plan.gameItems.every((item) =>
              item.candidate.classNumber == classNumber &&
              item.candidate.gameId == gameId &&
              item.candidate.isGenerated),
          isTrue,
          reason: 'c$classNumber $gameId',
        );
        expect(_renderableCount(adapter, repository, plan), 10,
            reason: 'c$classNumber $gameId');
      }
    }
  });

  test(
      'every class/game can rotate through 200 endless practice missions safely',
      () {
    final repository = buildContentRepository();
    var missionCount = 0;

    for (final classNumber in const <int>[3, 4, 5]) {
      for (var gameIndex = 0; gameIndex < gameIds.length; gameIndex++) {
        final gameId = gameIds[gameIndex];
        final memory = MissionExposureMemory();
        var plan = coordinator.createOrRestore(
          repository: repository,
          classNumber: classNumber,
          gameId: gameId,
          history: memory.historyFor(
            classNumber: classNumber,
            gameId: gameId,
          ),
          now: DateTime.utc(2026, 8, 24, 8, gameIndex),
        );
        Set<String>? previousFingerprints;

        for (var round = 0; round < 20; round++) {
          if (round > 0) {
            plan = coordinator.createNextRound(
              repository: repository,
              previousPlan: plan,
              history: memory.historyFor(
                classNumber: classNumber,
                gameId: gameId,
              ),
              now: DateTime.utc(2026, 8, 24, 8, gameIndex)
                  .add(Duration(minutes: round)),
            );
          }
          expect(plan.gameItems, hasLength(10),
              reason: 'c$classNumber $gameId round $round');
          expect(plan.hasInternalContentRepeat, isFalse,
              reason: 'c$classNumber $gameId round $round');
          expect(plan.hasContentShortfall, isFalse,
              reason: 'c$classNumber $gameId round $round');

          final fingerprints = plan.gameItems
              .map((item) => item.candidate.contentFingerprint)
              .toSet();
          expect(fingerprints, hasLength(10),
              reason: 'c$classNumber $gameId round $round');
          if (previousFingerprints != null) {
            expect(
              fingerprints.intersection(previousFingerprints),
              isEmpty,
              reason: 'Immediate Endless Practice repeat in c$classNumber '
                  '$gameId round $round',
            );
          }
          previousFingerprints = fingerprints;

          expect(
            memory.recordPlan(
              plan: plan,
              runId: 'endless:$classNumber:$gameId:$round',
              seenAt: DateTime.utc(2026, 8, 24).add(
                Duration(minutes: round),
              ),
            ),
            isTrue,
          );
          missionCount += plan.gameItems.length;
        }

        final classMemory = memory.byClass[classNumber]!;
        expect(
          classMemory.recent.length,
          lessThanOrEqualTo(MissionExposureMemory.maxRecentItemsPerClass),
        );
        expect(
          classMemory.recordedRunIds.length,
          lessThanOrEqualTo(MissionExposureMemory.maxRecordedRunIdsPerClass),
        );
      }
    }

    expect(missionCount, 3 * 8 * 20 * 10);
  });

  test('high generated seeds rehydrate canonically and remain needsReview', () {
    final repository = buildContentRepository();
    const seed = 987654321;
    const families = <String, String>{
      'math_market': 'math',
      'fraction_pizza': 'fraction',
      'story_builder': 'story',
      'grammar_puzzle': 'grammar',
      'science_lab': 'science',
      'map_quest': 'map',
      'coding_maze': 'coding',
      'recycling_challenge': 'recycling',
    };

    for (final entry in families.entries) {
      final legacyId = 'gen_${entry.value}_c5_d3_s$seed';
      final activity = repository.activityForLegacyContent(
        classNumber: 5,
        gameId: entry.key,
        legacyContentId: legacyId,
      );
      expect(activity, isNotNull, reason: entry.key);
      expect(activity!.status, 'needsReview', reason: entry.key);
      expect(activity.generation.mode, 'generated', reason: entry.key);
      expect(activity.generation.deterministicSeed, legacyId,
          reason: entry.key);
      final canonical = repository.activityById(activity.id);
      expect(canonical, isNotNull, reason: entry.key);
      expect(canonical!.legacyContentId, legacyId, reason: entry.key);
      expect(canonical.prompt, activity.prompt, reason: entry.key);
    }
  });

  test('endless checkpoint restores the exact persisted 10 missions', () {
    final repository = buildContentRepository();
    final plan = coordinator.createOrRestore(
      repository: repository,
      classNumber: 4,
      gameId: 'math_market',
      now: DateTime.utc(2026, 8, 24, 10),
    );
    final checkpoint = GameSessionCheckpoint(
      profileId: 'child-1',
      classNumber: 4,
      gameId: 'math_market',
      difficulty: 3,
      stage: GameSessionStage.game,
      cursor: 4,
      score: 3,
      maxScore: 10,
      startedAtIso: DateTime.utc(2026, 8, 24, 10).toIso8601String(),
      updatedAtIso: DateTime.utc(2026, 8, 24, 10, 2).toIso8601String(),
      data: coordinator.sessionDataFor(plan),
    );

    final restored = coordinator.createOrRestore(
      repository: repository,
      classNumber: 4,
      gameId: 'math_market',
      checkpoint: checkpoint,
      now: DateTime.utc(2026, 8, 25),
    );
    expect(restored.toJson(), plan.toJson());
  });

  test('practice-only completion is crash-idempotent and never creates stars',
      () async {
    final repository = buildContentRepository();
    final controller = GameController();
    await controller.load();
    controller.setClass(4);
    const id = 'endless_practice:c4:math_market';
    final plan = coordinator.createOrRestore(
      repository: repository,
      classNumber: 4,
      gameId: 'math_market',
      now: DateTime.utc(2026, 8, 24, 11),
    );
    controller.beginOrResumeGameSession(
      gameId: 'math_market',
      classNumber: 4,
      difficulty: 3,
      maxScore: 10,
      sessionData: coordinator.sessionDataFor(plan),
    );
    final starsBefore = controller.stars;
    expect(controller.isMissionCompleted(id), isFalse);

    final first = await controller.completeRunSafely(
      gameId: 'math_market',
      fallbackMissionId: id,
      score: 10,
      maxScore: 10,
      practiceOnly: true,
    );
    final coinsAfterFirst = controller.coins;
    final xpAfterFirst = controller.xp;
    final historyAfterFirst = controller.missionExposureHistoryForGame(
      classNumber: 4,
      gameId: 'math_market',
    );

    final second = await controller.completeRunSafely(
      gameId: 'math_market',
      fallbackMissionId: id,
      score: 10,
      maxScore: 10,
      practiceOnly: true,
    );

    expect(first.firstCompletion, isFalse);
    expect(second.firstCompletion, isFalse);
    expect(first.starsAwarded, 0);
    expect(second.starsAwarded, 0);
    expect(first.coinsAwarded, greaterThanOrEqualTo(5));
    expect(controller.coins, coinsAfterFirst);
    expect(controller.xp, xpAfterFirst);
    expect(controller.stars, starsBefore);
    expect(controller.isMissionCompleted(id), isFalse);
    expect(historyAfterFirst.activityKeys, hasLength(10));
    expect(
      controller
          .missionExposureHistoryForGame(
            classNumber: 4,
            gameId: 'math_market',
          )
          .activityKeys,
      historyAfterFirst.activityKeys,
    );
  });

  testWidgets('World card unlocks only after the three core game levels clear',
      (tester) async {
    final controller = GameController();
    await controller.load();
    controller.setClass(4);
    controller.setReducedMotionEnabled(true);
    final repository = buildContentRepository();

    await tester.pumpWidget(
      buildTestScope(
        controller: controller,
        contentRepository: repository,
        child: MaterialApp(
          home: LearningWorldScreen(world: learningWorlds.first),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final buttonFinder =
        find.byKey(const Key('endless_practice_button_math_market'));
    await tester.scrollUntilVisible(
      buttonFinder,
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(buttonFinder, findsOneWidget);
    expect(tester.widget<FilledButton>(buttonFinder).onPressed, isNull);

    for (final level in levelsForGame(4, 'math_market')) {
      final reward = controller.completeLearningLevel(
        level: level,
        score: 10,
        maxScore: 10,
      );
      expect(reward.levelCompleted, isTrue, reason: level.id);
    }
    await tester.pump();
    expect(tester.widget<FilledButton>(buttonFinder).onPressed, isNotNull);

    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
    expect(find.textContaining('∞ Endless Practice'), findsOneWidget);
  });
}

int _renderableCount(
  MissionRunGameContent adapter,
  ContentRepository repository,
  MissionRunPlan plan,
) =>
    switch (plan.gameId) {
      'math_market' =>
        adapter.mathQuestions(repository: repository, plan: plan).length,
      'fraction_pizza' =>
        adapter.fractionMissions(repository: repository, plan: plan).length,
      'story_builder' =>
        adapter.storyMissions(repository: repository, plan: plan).length,
      'grammar_puzzle' =>
        adapter.grammarMissions(repository: repository, plan: plan).length,
      'science_lab' =>
        adapter.scienceQuestions(repository: repository, plan: plan).length,
      'map_quest' =>
        adapter.mapQuestions(repository: repository, plan: plan).length,
      'coding_maze' =>
        adapter.codingMissions(repository: repository, plan: plan).length,
      'recycling_challenge' =>
        adapter.recyclingItems(repository: repository, plan: plan).length,
      _ => 0,
    };

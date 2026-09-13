import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/session/game_session_models.dart';
import 'package:brightquest_kids/core/session/game_session_store.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/adventures/learning_world_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

void main() {
  testWidgets(
      'Today owns latest resume while Learning Worlds stays exploration-only',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const <Size>[Size(360, 640), Size(1280, 800)]) {
      final fixture = await _savedSessionFixture();
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(buildTestApp(fixture.controller));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_primary_action')), findsOneWidget);
      expect(
        find.text(learningLevelById(fixture.latest.learningLevelId!)!.title),
        findsOneWidget,
      );

      await tester.tap(find.bySemanticsLabel('Worlds'));
      await tester.pumpAndSettle();

      expect(find.text('Learning Worlds'), findsOneWidget);
      expect(find.text('Choose a world'), findsOneWidget);
      expect(find.text('Recent saved mission'), findsNothing);
      expect(find.text('Quick Play'), findsNothing);
      expect(find.byKey(const Key('world_card_maths')), findsOneWidget);
      expect(find.text('Saved'), findsWidgets);
      expect(tester.takeException(), isNull,
          reason: 'consolidated Worlds at $size');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('each world game zone shows only saves that belong to that game',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(900, 760));
    final fixture = await _savedSessionFixture();

    await tester.pumpWidget(
      MaterialApp(
        home: buildTestScope(
          controller: fixture.controller,
          child: LearningWorldScreen(world: learningWorlds.first),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mathSaved = find.byKey(
      const Key('saved_missions_in_game_math_market'),
    );
    await tester.scrollUntilVisible(
      mathSaved,
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(mathSaved, findsOneWidget);
    expect(
      find.byKey(Key('game_saved_mission_${fixture.latest.slotKey}')),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('game_saved_mission_${fixture.olderMath.slotKey}')),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('game_saved_mission_${fixture.olderStory.slotKey}')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<_SavedSessionFixture> _savedSessionFixture() async {
  final mathLevels = levelsForGame(4, 'math_market');
  final storyLevel = levelsForGame(4, 'story_builder').first;

  final now = DateTime.now().toUtc();
  final latest = _checkpoint(
    gameId: 'math_market',
    learningLevelId: mathLevels[1].id,
    difficulty: mathLevels[1].difficulty,
    updatedAtIso: now.subtract(const Duration(minutes: 1)).toIso8601String(),
  );
  final olderMath = _checkpoint(
    gameId: 'math_market',
    learningLevelId: mathLevels[0].id,
    difficulty: mathLevels[0].difficulty,
    updatedAtIso: now.subtract(const Duration(minutes: 2)).toIso8601String(),
  );
  final olderStory = _checkpoint(
    gameId: 'story_builder',
    learningLevelId: storyLevel.id,
    difficulty: storyLevel.difficulty,
    updatedAtIso: now.subtract(const Duration(minutes: 3)).toIso8601String(),
  );
  final sessions = <GameSessionCheckpoint>[
    latest,
    olderMath,
    olderStory,
  ];
  final store = MemoryGameSessionStore();
  await store.writeAll(<String, GameSessionCheckpoint>{
    for (final session in sessions) session.slotKey: session,
  });
  final controller = GameController(sessionStore: store);
  await controller.load();
  controller.setClass(4);
  controller.setReducedMotionEnabled(true);

  expect(controller.resumableGameSessions, hasLength(3));
  expect(controller.resumableGameSessions.first.slotKey, latest.slotKey);

  return _SavedSessionFixture(
    controller: controller,
    sessions: sessions,
    latest: latest,
    olderMath: olderMath,
    olderStory: olderStory,
  );
}

GameSessionCheckpoint _checkpoint({
  required String gameId,
  required String learningLevelId,
  required int difficulty,
  required String updatedAtIso,
}) {
  final updatedAt = DateTime.parse(updatedAtIso);
  return GameSessionCheckpoint(
    profileId: 'child-1',
    classNumber: 4,
    gameId: gameId,
    learningLevelId: learningLevelId,
    difficulty: difficulty,
    stage: GameSessionStage.game,
    cursor: 2,
    score: 1,
    maxScore: 5,
    startedAtIso:
        updatedAt.subtract(const Duration(minutes: 5)).toIso8601String(),
    updatedAtIso: updatedAtIso,
  );
}

class _SavedSessionFixture {
  const _SavedSessionFixture({
    required this.controller,
    required this.sessions,
    required this.latest,
    required this.olderMath,
    required this.olderStory,
  });

  final GameController controller;
  final List<GameSessionCheckpoint> sessions;
  final GameSessionCheckpoint latest;
  final GameSessionCheckpoint olderMath;
  final GameSessionCheckpoint olderStory;
}

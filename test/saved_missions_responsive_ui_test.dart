import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/session/game_session_models.dart';
import 'package:brightquest_kids/core/session/game_session_store.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/adventures/adventures_screen.dart';
import 'package:brightquest_kids/features/adventures/learning_world_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

void main() {
  testWidgets(
      'Learning Worlds shows one recent save and keeps the full list behind Show all',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = await _savedSessionFixture();

    for (final size in const <Size>[Size(360, 640), Size(1280, 800)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: buildTestScope(
            controller: fixture.controller,
            child: const AdventuresScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final recentCard = find.byKey(const Key('recent_saved_mission_card'));
      for (var attempt = 0;
          attempt < 5 && recentCard.evaluate().isEmpty;
          attempt++) {
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -180),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('Recent saved mission'), findsOneWidget);
      expect(recentCard, findsOneWidget);
      expect(
        find.byKey(Key('resume_saved_mission_${fixture.latest.slotKey}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('resume_saved_mission_${fixture.olderMath.slotKey}')),
        findsNothing,
      );
      expect(
        find.byKey(Key('resume_saved_mission_${fixture.olderStory.slotKey}')),
        findsNothing,
      );
      expect(tester.takeException(), isNull, reason: 'recent card at $size');

      final showAllButton = find.byKey(const Key('show_all_saved_missions'));
      expect(showAllButton, findsOneWidget);
      await tester.ensureVisible(showAllButton);
      await tester.pumpAndSettle();
      await tester.tap(showAllButton);
      await tester.pumpAndSettle();

      expect(find.text('All saved missions'), findsOneWidget);
      final savedList = find.byKey(const Key('all_saved_missions_list'));
      expect(savedList, findsOneWidget);
      expect(
        find.byKey(Key('all_saved_mission_${fixture.latest.slotKey}')),
        findsOneWidget,
      );
      final oldestCard =
          find.byKey(Key('all_saved_mission_${fixture.olderStory.slotKey}'));
      for (var attempt = 0;
          attempt < 5 && oldestCard.evaluate().isEmpty;
          attempt++) {
        await tester.drag(savedList, const Offset(0, -180));
        await tester.pumpAndSettle();
      }
      expect(oldestCard, findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'saved overlay at $size');

      await tester.tap(find.byKey(const Key('all_saved_missions_close')));
      await tester.pumpAndSettle();
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

  final latest = _checkpoint(
    gameId: 'math_market',
    learningLevelId: mathLevels[1].id,
    difficulty: mathLevels[1].difficulty,
    updatedAtIso: '2026-08-23T16:03:00.000Z',
  );
  final olderMath = _checkpoint(
    gameId: 'math_market',
    learningLevelId: mathLevels[0].id,
    difficulty: mathLevels[0].difficulty,
    updatedAtIso: '2026-08-23T16:02:00.000Z',
  );
  final olderStory = _checkpoint(
    gameId: 'story_builder',
    learningLevelId: storyLevel.id,
    difficulty: storyLevel.difficulty,
    updatedAtIso: '2026-08-23T16:01:00.000Z',
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
}) =>
    GameSessionCheckpoint(
      profileId: 'child-1',
      classNumber: 4,
      gameId: gameId,
      learningLevelId: learningLevelId,
      difficulty: difficulty,
      stage: GameSessionStage.game,
      cursor: 2,
      score: 1,
      maxScore: 5,
      startedAtIso: '2026-08-23T16:00:00.000Z',
      updatedAtIso: updatedAtIso,
    );

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

import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/nursery/nursery_home_screen.dart';
import 'package:brightquest_kids/features/nursery/nursery_lesson_screen.dart';
import 'package:brightquest_kids/features/nursery/nursery_play_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_fixture.dart';

NurseryContentPack _pack() => NurseryContentPack.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          File('assets/content/nursery/pack_v1.json').readAsStringSync(),
        ) as Map,
      ),
    );

Widget _host(GameController controller, Widget child) => buildTestScope(
      controller: controller,
      child: MaterialApp(home: child),
    );

void main() {
  group('Nursery simple game flow', () {
    test('Play Now always selects the first unfinished authored game', () {
      final pack = _pack();
      final activities = pack.activitiesForSkill('math_count_0_5');

      expect(
        nurseryRecommendedActivity(activities, const <String>{})?.id,
        activities.first.id,
      );
      expect(
        nurseryRecommendedActivity(
          activities,
          <String>{activities.first.id},
        )?.id,
        activities[1].id,
      );
      expect(
        nurseryRecommendedActivity(
          activities,
          activities.map((activity) => activity.id).toSet(),
        )?.id,
        activities.first.id,
      );
    });

    test('Next Game skips games already completed', () {
      final pack = _pack();
      final activities = pack.activitiesForSkill('math_count_0_5');
      final next = nurseryNextUnplayedActivity(
        activities,
        <String>{activities[1].id},
        activities.first,
      );
      expect(next?.id, activities[2].id);
    });

    testWidgets('skill opens with a clear three-step learning journey',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _host(
          GameController(),
          const NurseryLessonScreen(skillId: 'math_count_0_5'),
        ),
      );
      await tester.pump();

      expect(find.text('Let’s play!'), findsOneWidget);
      expect(find.text('3 easy steps'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Guided Play'), findsOneWidget);
      expect(find.text('Independent Game'), findsOneWidget);
      expect(find.text('Play Now'), findsOneWidget);
      expect(find.text('Learn First'), findsOneWidget);
      expect(find.text('More games'), findsOneWidget);
      expect(find.text('Game 1'), findsNothing);
      expect(find.text('Star Game'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('correct answer continues straight to Next Game',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = GameController();
      final activities = _pack().activitiesForSkill('math_count_0_5');

      await tester.pumpWidget(
        _host(
          controller,
          const NurseryLessonScreen(skillId: 'math_count_0_5'),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Play Now'));
      await tester.tap(find.text('Play Now'));
      await tester.pump(const Duration(milliseconds: 350));

      final correct = activities.first.correctResponseRule['value'] as String;
      final answer = find.bySemanticsLabel('Answer $correct');
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pump();
      expect(find.text('Great job!'), findsOneWidget);
      expect(find.text('Next Game'), findsOneWidget);

      final nextGame = find.text('Next Game');
      await tester.ensureVisible(nextGame);
      await tester.tap(nextGame);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(activities[1].prompt), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Nursery home hides adult-facing tracing copy from children',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester
          .pumpWidget(_host(GameController(), const NurseryHomeScreen()));
      await tester.pump();

      expect(find.text('Ready to play?'), findsOneWidget);
      expect(find.text('Choose a world'), findsOneWidget);
      expect(find.text('ABC & Sounds'), findsOneWidget);
      expect(find.text('Numbers'), findsOneWidget);
      expect(find.text('My World'), findsOneWidget);
      expect(find.text('Match & Think'), findsOneWidget);
      expect(find.text('Big letters A–Z'), findsNothing);
      expect(find.text('ABC Picture Book'), findsNothing);

      await tester.tap(find.byKey(const Key('nursery-world-alphabet')));
      await tester.pumpAndSettle();

      final worldList = find.byKey(
        const PageStorageKey<String>('nursery-world-alphabet-paths'),
      );
      expect(worldList, findsOneWidget);

      final pictureBook = find.text('ABC Picture Book');
      final worldScrollable = find.descendant(
        of: worldList,
        matching: find.byType(Scrollable),
      );
      expect(worldScrollable, findsOneWidget);

      final scrollState = tester.state<ScrollableState>(worldScrollable);
      for (var attempt = 0;
          attempt < 6 && pictureBook.evaluate().isEmpty;
          attempt += 1) {
        final position = scrollState.position;
        final remaining = position.maxScrollExtent - position.pixels;
        if (remaining <= 0) {
          break;
        }
        final delta = remaining < 220.0 ? remaining : 220.0;
        position.jumpTo(position.pixels + delta);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(pictureBook, findsOneWidget);
      expect(find.textContaining('does not claim to score'), findsNothing);
      expect(find.text('A for Apple'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

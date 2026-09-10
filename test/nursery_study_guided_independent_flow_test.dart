import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/nursery/nursery_spoken_labels.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/nursery/nursery_lesson_journey.dart';
import 'package:brightquest_kids/features/nursery/nursery_lesson_screen.dart';
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
  test('every Nursery skill maps cleanly into guided then independent play', () {
    final pack = _pack();
    for (final skill in pack.skills) {
      final activities = pack.activitiesForSkill(skill.id);
      final plan = NurseryLessonJourneyPlanner.build(
        activities: activities,
        completedActivityIds: const <String>{},
        studyVisited: false,
      );

      expect(plan.guidedActivity, isNotNull, reason: skill.id);
      expect(plan.guidedActivity!.phase, 'guided', reason: skill.id);
      expect(plan.independentActivities, isNotEmpty, reason: skill.id);
      expect(
        <String>{
          plan.guidedActivity!.id,
          ...plan.independentActivities.map((activity) => activity.id),
        },
        activities.map((activity) => activity.id).toSet(),
        reason: skill.id,
      );
      expect(
        plan.independentActivities.map((activity) => activity.id).toSet().length,
        plan.independentActivities.length,
        reason: skill.id,
      );
    }
  });

  test('journey recommendation advances study to guided to independent', () {
    final activities = _pack().activitiesForSkill('math_count_0_5');
    final guided = activities.firstWhere((activity) => activity.phase == 'guided');

    final firstVisit = NurseryLessonJourneyPlanner.build(
      activities: activities,
      completedActivityIds: const <String>{},
      studyVisited: false,
    );
    expect(firstVisit.recommendedStage, NurseryLessonJourneyStage.study);

    final afterStudy = NurseryLessonJourneyPlanner.build(
      activities: activities,
      completedActivityIds: const <String>{},
      studyVisited: true,
    );
    expect(afterStudy.recommendedStage, NurseryLessonJourneyStage.guidedPlay);

    final afterGuided = NurseryLessonJourneyPlanner.build(
      activities: activities,
      completedActivityIds: <String>{guided.id},
      studyVisited: false,
    );
    expect(
      afterGuided.recommendedStage,
      NurseryLessonJourneyStage.independentGame,
    );
    expect(afterGuided.guidedComplete, isTrue);
  });

  testWidgets('child can move Study to Guided Play to Independent Game',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = GameController();
    final activities = _pack().activitiesForSkill('math_count_0_5');
    final guided = activities.firstWhere((activity) => activity.phase == 'guided');
    final independent = activities.firstWhere(
      (activity) => activity.phase == 'independent',
    );

    await tester.pumpWidget(
      _host(
        controller,
        const NurseryLessonScreen(skillId: 'math_count_0_5'),
      ),
    );
    await tester.pump();

    expect(find.text('3 easy steps'), findsOneWidget);
    expect(find.text('Study'), findsOneWidget);
    expect(find.text('Guided Play'), findsOneWidget);
    expect(find.text('Independent Game'), findsOneWidget);
    expect(find.byKey(const Key('nursery-stage-study')), findsOneWidget);
    expect(find.byKey(const Key('nursery-stage-guided')), findsOneWidget);
    expect(find.byKey(const Key('nursery-stage-independent')), findsOneWidget);

    await tester.ensureVisible(find.text('Learn First'));
    await tester.tap(find.text('Learn First'));
    await tester.pumpAndSettle();
    expect(find.text('Study'), findsOneWidget);
    expect(find.text('Go to Guided Play'), findsOneWidget);

    await tester.ensureVisible(find.text('Go to Guided Play'));
    await tester.tap(find.text('Go to Guided Play'));
    await tester.pumpAndSettle();
    expect(find.text('Guided Play'), findsOneWidget);
    expect(find.text(nurseryVisualFreeText(guided.prompt)), findsOneWidget);
    expect(find.text('Try it with me. You can tap Help anytime.'), findsOneWidget);

    final correct = guided.correctResponseRule['value'] as String;
    final answer = find.bySemanticsLabel('Answer $correct');
    await tester.ensureVisible(answer);
    await tester.tap(answer);
    await tester.pump();
    expect(find.text('Great job!'), findsOneWidget);

    await tester.ensureVisible(find.text('Next Game'));
    await tester.tap(find.text('Next Game'));
    await tester.pumpAndSettle();
    expect(find.text('Independent Game'), findsOneWidget);
    expect(find.text(nurseryVisualFreeText(independent.prompt)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('journey presentation remains persistence-free', () {
    for (final path in <String>[
      'lib/features/nursery/nursery_lesson_journey.dart',
      'lib/features/nursery/nursery_lesson_stage_indicator.dart',
      'lib/features/nursery/nursery_lesson_journey_board.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('BrightQuestScope')), reason: path);
      expect(source, isNot(contains('recordNurseryEvidence')), reason: path);
      expect(source, isNot(contains('GameController')), reason: path);
    }
  });
}

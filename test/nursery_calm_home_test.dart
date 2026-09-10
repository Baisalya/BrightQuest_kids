import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/nursery/nursery_learning_models.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/nursery/nursery_home_plan.dart';
import 'package:brightquest_kids/features/nursery/nursery_home_screen.dart';
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

NurserySkillMastery _mastery(
  String skillId,
  LearningEvidenceState state, {
  String? lastEvidenceIso,
}) =>
    NurserySkillMastery(
      skillId: skillId,
      state: state,
      lastEvidenceIso: lastEvidenceIso,
    );

Widget _host(GameController controller, Widget child) => MaterialApp(
      home: buildTestScope(controller: controller, child: child),
    );

void main() {
  test('calm home planner prioritizes due review over other learning', () {
    final pack = _pack();
    final dueSkill = pack.skills[3];
    final plan = NurseryHomePlanner.build(
      pack: pack,
      dueTasks: <NurseryReviewTask>[
        NurseryReviewTask(
          id: 'review-1',
          packId: NurseryContentPack.nurseryPackId,
          skillId: dueSkill.id,
          dueIso: DateTime(2026, 8, 24).toIso8601String(),
          intervalIndex: 0,
          sourceItemId: 'source-1',
        ),
      ],
      masteryFor: (id) => _mastery(
        id,
        id == pack.skills.first.id
            ? LearningEvidenceState.practising
            : LearningEvidenceState.notStarted,
      ),
    );

    expect(plan.primaryAction.kind, NurseryHomeActionKind.review);
    expect(plan.primaryAction.reviewMode, isTrue);
    expect(plan.primaryAction.skill.id, dueSkill.id);
    expect(plan.reviewCount, 1);
  });

  test('calm home planner continues the most recently played skill', () {
    final pack = _pack();
    final older = pack.skills.first;
    final newer = pack.skills[1];
    final masteries = <String, NurserySkillMastery>{
      older.id: _mastery(
        older.id,
        LearningEvidenceState.practising,
        lastEvidenceIso: '2026-08-20T10:00:00.000',
      ),
      newer.id: _mastery(
        newer.id,
        LearningEvidenceState.introduced,
        lastEvidenceIso: '2026-08-23T10:00:00.000',
      ),
    };

    final plan = NurseryHomePlanner.build(
      pack: pack,
      dueTasks: const <NurseryReviewTask>[],
      masteryFor: (id) =>
          masteries[id] ?? NurserySkillMastery(skillId: id),
    );

    expect(plan.primaryAction.kind, NurseryHomeActionKind.continueLearning);
    expect(plan.primaryAction.skill.id, newer.id);
    expect(plan.primaryAction.reviewMode, isFalse);
  });

  testWidgets('calm Nursery home exposes one primary action and four worlds',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(GameController(), const NurseryHomeScreen()));
    await tester.pump();

    expect(find.byKey(const Key('nursery-primary-action')), findsOneWidget);
    expect(find.byKey(const Key('nursery-world-alphabet')), findsOneWidget);
    expect(find.byKey(const Key('nursery-world-math')), findsOneWidget);
    expect(find.byKey(const Key('nursery-world-knowledge')), findsOneWidget);
    expect(find.byKey(const Key('nursery-world-thinking')), findsOneWidget);
    expect(find.text('ABC Picture Book'), findsNothing);
    expect(find.text('Choose a world'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

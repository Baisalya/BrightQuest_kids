import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/learning/learning_models.dart';
import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/nursery/nursery_learning_models.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:brightquest_kids/features/nursery/nursery_home_screen.dart';
import 'package:brightquest_kids/features/nursery/nursery_world_plan.dart';
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

Widget _host(GameController controller, Widget child) => buildTestScope(
      controller: controller,
      child: MaterialApp(home: child),
    );

void main() {
  test('every authored Nursery skill appears in exactly one progressive path',
      () {
    final pack = _pack();
    final expectedPathCounts = <String, int>{
      'alphabet': 4,
      'math': 4,
      'knowledge': 3,
      'thinking': 3,
    };

    for (final domain in pack.domains) {
      final plan = NurseryWorldPlanner.build(
        pack: pack,
        domainId: domain.id,
        masteryFor: (id) => NurserySkillMastery(skillId: id),
      );
      expect(plan.paths.length, expectedPathCounts[domain.id]);

      final plannedIds = plan.paths
          .expand((path) => path.skills)
          .map((skill) => skill.id)
          .toList(growable: false);
      final authoredIds = pack
          .skillsForDomain(domain.id)
          .map((skill) => skill.id)
          .toList(growable: false);

      expect(plannedIds.toSet(), authoredIds.toSet());
      expect(plannedIds.length, plannedIds.toSet().length);
      expect(
        plan.paths.every((path) => path.skills.length <= 3),
        isTrue,
        reason: '${domain.id} should expose only small child-friendly groups',
      );
    }
  });

  test('world planner resumes the path containing the most recent active skill',
      () {
    final pack = _pack();
    final masteries = <String, NurserySkillMastery>{
      'math_numbers_0_5': _mastery(
        'math_numbers_0_5',
        LearningEvidenceState.practising,
        lastEvidenceIso: '2026-08-20T10:00:00.000',
      ),
      'math_add_objects': _mastery(
        'math_add_objects',
        LearningEvidenceState.introduced,
        lastEvidenceIso: '2026-08-24T10:00:00.000',
      ),
    };

    final plan = NurseryWorldPlanner.build(
      pack: pack,
      domainId: 'math',
      masteryFor: (id) => masteries[id] ?? NurserySkillMastery(skillId: id),
    );

    expect(plan.recommendedPathId, 'math_add_together');
    expect(
      plan.pathById('math_add_together')?.recommendedSkill.id,
      'math_add_objects',
    );
  });

  test('due review takes priority inside its learning path', () {
    final pack = _pack();
    final plan = NurseryWorldPlanner.build(
      pack: pack,
      domainId: 'alphabet',
      masteryFor: (id) => NurserySkillMastery(skillId: id),
      dueSkillIds: const <String>['alpha_beginning_sound'],
    );

    expect(plan.recommendedPathId, 'alphabet_sounds');
    final path = plan.pathById('alphabet_sounds');
    expect(path?.recommendedSkill.id, 'alpha_beginning_sound');
    expect(path?.recommendedReviewMode, isTrue);
  });

  testWidgets('world screen shows paths first and reveals skills inside a path',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(GameController(), const NurseryHomeScreen()));
    await tester.pumpAndSettle();

    final mathWorld = find.byKey(const Key('nursery-world-math'));
    await tester.ensureVisible(mathWorld);
    await tester.pumpAndSettle();
    await tester.tap(mathWorld);
    await tester.pumpAndSettle();

    expect(find.text('Pick a learning path'), findsOneWidget);
    expect(find.byKey(const Key('nursery-world-next-path')), findsOneWidget);
    expect(find.byKey(const Key('nursery-path-math_meet_numbers')),
        findsOneWidget);
    expect(
        find.byKey(const Key('nursery-path-math_count_match')), findsOneWidget);
    expect(find.byKey(const Key('nursery-path-math_compare_find')),
        findsOneWidget);
    expect(find.byKey(const Key('nursery-path-math_add_together')),
        findsOneWidget);
    expect(find.text('Numbers 0–5'), findsNothing);
    expect(tester.takeException(), isNull);

    final firstPath = find.byKey(const Key('nursery-path-math_meet_numbers'));
    await tester.ensureVisible(firstPath);
    await tester.pumpAndSettle();
    await tester.tap(firstPath);
    await tester.pumpAndSettle();

    expect(find.text('Choose a little game'), findsOneWidget);
    expect(find.byKey(const Key('nursery-skill-math_numbers_0_5')),
        findsOneWidget);
    expect(find.byKey(const Key('nursery-skill-math_numbers_6_10')),
        findsOneWidget);
    expect(find.byKey(const Key('nursery-skill-math_numbers_11_20')),
        findsOneWidget);
    expect(find.byKey(const Key('nursery-skill-math_count_0_5')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

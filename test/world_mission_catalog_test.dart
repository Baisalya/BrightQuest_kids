import 'package:brightquest_kids/core/curriculum/curriculum_catalog.dart';
import 'package:brightquest_kids/core/curriculum/world_mission_catalog.dart';
import 'package:brightquest_kids/core/curriculum/world_mission_models.dart';
import 'package:brightquest_kids/core/models/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('World mission identity', () {
    test('all six learning worlds have distinct deterministic identities', () {
      const subjects = <SubjectWorld>[
        SubjectWorld.maths,
        SubjectWorld.english,
        SubjectWorld.science,
        SubjectWorld.evs,
        SubjectWorld.social,
        SubjectWorld.coding,
      ];

      final identities =
          subjects.map(WorldMissionCatalog.identityFor).toList(growable: false);

      expect(
        identities.map((identity) => identity.worldTitle).toSet(),
        hasLength(subjects.length),
      );
      expect(
        identities.map((identity) => identity.journeyTitle).toSet(),
        hasLength(subjects.length),
      );
      expect(
        identities.every((identity) => identity.sceneGameId.isNotEmpty),
        isTrue,
      );
    });

    test('maths practice challenge and mastery become one zone mission arc',
        () {
      final training = WorldMissionCatalog.planForLevel(
        learningLevelById('c4_math_operations:math_market:l1')!,
      );
      final challenge = WorldMissionCatalog.planForLevel(
        learningLevelById('c4_math_operations:math_market:l2')!,
      );
      final boss = WorldMissionCatalog.planForLevel(
        learningLevelById('c4_math_operations:math_market:l3')!,
      );

      expect(training.zoneTitle, 'Market Square');
      expect(challenge.zoneTitle, training.zoneTitle);
      expect(boss.zoneTitle, training.zoneTitle);
      expect(training.phase, WorldMissionPhase.training);
      expect(challenge.phase, WorldMissionPhase.challenge);
      expect(boss.phase, WorldMissionPhase.boss);
      expect(boss.isBoss, isTrue);
      expect(boss.phaseLabel, contains('Boss'));
      expect(training.stageNumber, 1);
      expect(challenge.stageNumber, 2);
      expect(boss.stageNumber, 3);
      expect(boss.stageCount, 6);
    });

    test('second maths topic becomes a second world zone without changing ids',
        () {
      final level = learningLevelById('c4_math_fractions:fraction_pizza:l1')!;
      final plan = WorldMissionCatalog.planForLevel(level);

      expect(plan.levelId, level.id);
      expect(plan.gameId, level.gameId);
      expect(plan.zoneTitle, 'Fraction Feast Hall');
      expect(plan.zoneNumber, 2);
      expect(plan.zoneCount, 2);
      expect(plan.stageNumber, 4);
    });

    test('every existing learning level maps to presentation only metadata',
        () {
      for (final level in learningLevels) {
        final plan = WorldMissionCatalog.planForLevel(level);
        expect(plan.levelId, level.id, reason: level.id);
        expect(plan.gameId, level.gameId, reason: level.id);
        expect(plan.topicTitle, isNotEmpty, reason: level.id);
        expect(plan.zoneTitle, isNotEmpty, reason: level.id);
        expect(plan.phaseLabel, isNotEmpty, reason: level.id);
        expect(plan.stageTitle, isNotEmpty, reason: level.id);
        expect(plan.briefing, isNotEmpty, reason: level.id);
        expect(plan.actionLabel, isNotEmpty, reason: level.id);
        expect(plan.stageNumber, inInclusiveRange(1, plan.stageCount));
      }
    });
  });
}

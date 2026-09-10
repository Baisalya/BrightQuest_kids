import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/nursery/nursery_legacy_visual_aliases.dart';
import 'package:brightquest_kids/core/nursery/nursery_practice_generator.dart';
import 'package:brightquest_kids/core/nursery/nursery_response_evaluator.dart';
import 'package:brightquest_kids/features/nursery/nursery_lesson_journey.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _rawPack() => Map<String, dynamic>.from(
      jsonDecode(
        File('assets/content/nursery/pack_v1.json').readAsStringSync(),
      ) as Map,
    );

NurseryContentPack _pack() => NurseryContentPack.fromJson(_rawPack());

Object? _correctResponseForRule(Map<String, dynamic> rule) {
  return switch (rule['type']) {
    'choice' => rule['value'],
    'pairMatch' => Map<String, String>.from(rule['pairs'] as Map),
    'sortBuckets' => Map<String, String>.from(rule['assignments'] as Map),
    'traceCheckpoints' => List<int>.generate(
        (rule['checkpointCount'] as num).toInt(),
        (index) => index,
      ),
    _ => null,
  };
}

bool _containsLegacyVisualDeep(Object? value) {
  if (value is String) return nurseryContainsLegacyEmoji(value);
  if (value is List) return value.any(_containsLegacyVisualDeep);
  if (value is Map) {
    return value.entries.any(
      (entry) =>
          _containsLegacyVisualDeep(entry.key.toString()) ||
          _containsLegacyVisualDeep(entry.value),
    );
  }
  return false;
}

void main() {
  group('Nursery final release gate', () {
    test('canonical content topology is stable and shipping stays fail-closed',
        () {
      final raw = _rawPack();
      expect(NurseryContentValidator.validate(raw), isEmpty);
      final pack = NurseryContentPack.fromJson(raw);

      expect(pack.packId, NurseryContentPack.nurseryPackId);
      expect(pack.locale, 'en-IN');
      expect(pack.domains, hasLength(4));
      expect(pack.letterAssociations, hasLength(26));
      expect(pack.skills, hasLength(32));
      expect(pack.activities, hasLength(132));

      expect(pack.skills.map((skill) => skill.id).toSet(), hasLength(32));
      expect(
        pack.activities.map((activity) => activity.id).toSet(),
        hasLength(132),
      );

      expect(pack.commercial.permanentOneTimePriceInr, 299);
      expect(pack.commercial.purchaseModel, 'oneTimePack');
      expect(pack.commercial.paidEligibility, isFalse);
      expect(pack.commercial.freeSampleActivityIds, hasLength(4));
      expect(pack.releaseGates.allExternalGatesRecorded, isFalse);

      for (final activityId in pack.commercial.freeSampleActivityIds) {
        expect(pack.activityById(activityId), isNotNull, reason: activityId);
      }
    });

    test('all 32 skills preserve Study to Guided to Independent reachability',
        () {
      final pack = _pack();

      for (final skill in pack.skills) {
        final activities = pack.activitiesForSkill(skill.id);
        expect(activities, isNotEmpty, reason: skill.id);
        expect(
          activities.where((activity) => activity.phase == 'guided'),
          hasLength(1),
          reason: skill.id,
        );

        final firstPlan = NurseryLessonJourneyPlanner.build(
          activities: activities,
          completedActivityIds: const <String>{},
          studyVisited: false,
        );
        expect(
          firstPlan.recommendedStage,
          NurseryLessonJourneyStage.study,
          reason: skill.id,
        );
        expect(firstPlan.guidedActivity, isNotNull, reason: skill.id);
        expect(firstPlan.independentActivities, isNotEmpty, reason: skill.id);

        final afterStudy = NurseryLessonJourneyPlanner.build(
          activities: activities,
          completedActivityIds: const <String>{},
          studyVisited: true,
        );
        expect(
          afterStudy.recommendedStage,
          NurseryLessonJourneyStage.guidedPlay,
          reason: skill.id,
        );

        final guidedId = firstPlan.guidedActivity!.id;
        final afterGuided = NurseryLessonJourneyPlanner.build(
          activities: activities,
          completedActivityIds: <String>{guidedId},
          studyVisited: true,
        );
        expect(
          afterGuided.recommendedStage,
          NurseryLessonJourneyStage.independentGame,
          reason: skill.id,
        );
        expect(afterGuided.recommendedIndependentActivity, isNotNull,
            reason: skill.id);
      }
    });

    test('all authored rules are semantic, reachable and self-evaluable', () {
      final pack = _pack();
      const evaluator = NurseryResponseEvaluator();
      const allowedInteractions = <String>{
        'choice',
        'pairMatch',
        'sortBuckets',
        'trace',
      };
      const allowedPhases = <String>{
        'guided',
        'independent',
        'transfer',
        'practice',
      };

      for (final activity in pack.activities) {
        expect(pack.skillById(activity.skillId), isNotNull,
            reason: activity.id);
        expect(allowedInteractions, contains(activity.interaction),
            reason: activity.id);
        expect(allowedPhases, contains(activity.phase), reason: activity.id);
        expect(nurseryContainsLegacyEmoji(activity.prompt), isFalse,
            reason: '${activity.id} prompt');
        expect(_containsLegacyVisualDeep(activity.payload), isFalse,
            reason: '${activity.id} payload');
        expect(_containsLegacyVisualDeep(activity.correctResponseRule), isFalse,
            reason: '${activity.id} rule');

        final response = _correctResponseForRule(activity.correctResponseRule);
        expect(response, isNotNull, reason: '${activity.id} rule type');
        expect(
          evaluator.evaluate(activity, response).correct,
          isTrue,
          reason: activity.id,
        );
      }
    });

    test('generated practice stays deterministic, semantic and self-evaluable',
        () {
      final pack = _pack();
      const generator = NurseryPracticeGenerator();
      const evaluator = NurseryResponseEvaluator();

      for (final skill in pack.skills) {
        expect(skill.generatorFamily, isNotNull, reason: skill.id);
        for (var seed = 0; seed < 64; seed += 1) {
          final first = generator.generate(pack: pack, skill: skill, seed: seed);
          final second = generator.generate(pack: pack, skill: skill, seed: seed);

          expect(second.id, first.id, reason: '${skill.id}/$seed id');
          expect(second.prompt, first.prompt,
              reason: '${skill.id}/$seed prompt');
          expect(second.narration, first.narration,
              reason: '${skill.id}/$seed narration');
          expect(second.correctResponseRule, first.correctResponseRule,
              reason: '${skill.id}/$seed rule');
          expect(
            second.options.map((option) => option.id).toList(),
            first.options.map((option) => option.id).toList(),
            reason: '${skill.id}/$seed options',
          );

          expect(nurseryContainsLegacyEmoji(first.prompt), isFalse,
              reason: '${skill.id}/$seed prompt emoji');
          expect(_containsLegacyVisualDeep(first.visualTokens), isFalse,
              reason: '${skill.id}/$seed visuals');
          expect(_containsLegacyVisualDeep(first.correctResponseRule), isFalse,
              reason: '${skill.id}/$seed rule emoji');

          final response = _correctResponseForRule(first.correctResponseRule);
          expect(response, isNotNull, reason: '${skill.id}/$seed rule type');
          expect(
            evaluator.evaluateGenerated(first, response).correct,
            isTrue,
            reason: '${skill.id}/$seed evaluation',
          );
        }
      }
    });

    test('asset, architecture and motion release boundaries remain bounded', () {
      final assets = Directory('assets/nursery/letter_cards')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.png'))
          .toList(growable: false);
      expect(assets, hasLength(208));

      var totalBytes = 0;
      for (final file in assets) {
        final bytes = file.readAsBytesSync();
        totalBytes += bytes.length;
        expect(bytes.length, lessThanOrEqualTo(128 * 1024), reason: file.path);
        expect(bytes.length, greaterThanOrEqualTo(24), reason: file.path);
        final data = ByteData.sublistView(Uint8List.fromList(bytes));
        expect(data.getUint32(16, Endian.big), lessThanOrEqualTo(512),
            reason: file.path);
        expect(data.getUint32(20, Endian.big), lessThanOrEqualTo(512),
            reason: file.path);
      }
      expect(totalBytes, lessThanOrEqualTo(6 * 1024 * 1024));

      final nurseryPresentation = Directory('lib/features/nursery')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.readAsStringSync())
          .join('\n');
      expect(nurseryPresentation, isNot(contains('Timer.periodic(')));
      expect(nurseryPresentation, isNot(contains('.repeat(')));

      final motion = File('lib/features/nursery/nursery_motion.dart')
          .readAsStringSync();
      expect(motion, contains('disableAnimations'));
      expect(motion, contains('Platform.isWindows'));
      expect(motion, isNot(contains('BrightQuestScope')));
      expect(motion, isNot(contains('recordNurseryEvidence')));

      final visual = File('lib/features/nursery/nursery_visual.dart')
          .readAsStringSync();
      final reaction = File('lib/features/nursery/nursery_asset_reaction.dart')
          .readAsStringSync();
      for (final source in <String>[visual, reaction]) {
        expect(source, contains('cacheWidth: 128'));
        expect(source, contains('cacheHeight: 128'));
      }
    });
  });
}

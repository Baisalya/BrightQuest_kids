import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/nursery/nursery_visuals.dart';
import 'package:flutter_test/flutter_test.dart';

NurseryContentPack _pack() => NurseryContentPack.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          File('assets/content/nursery/pack_v1.json').readAsStringSync(),
        ) as Map,
      ),
    );

void main() {
  test('every Nursery domain and skill resolves to a semantic visual', () {
    final pack = _pack();

    for (final domain in pack.domains) {
      final visual = NurseryVisualResolver.forDomain(domain);
      expect(visual.semanticLabel, isNotEmpty, reason: domain.id);
      expect(
        visual.source,
        NurseryVisualSource.painted,
        reason: 'Domain ${domain.id} should not depend on raw emoji.',
      );
    }

    for (final skill in pack.skills) {
      final visual = NurseryVisualResolver.forSkill(skill);
      expect(visual.semanticLabel, isNotEmpty, reason: skill.id);
      expect(
        visual.concept,
        isNot(NurseryVisualConcept.text),
        reason: 'Skill ${skill.id} needs an authored semantic concept.',
      );
    }
  });

  test('every authored Nursery activity can use the semantic visual boundary', () {
    final pack = _pack();

    for (final skill in pack.skills) {
      for (final activity in pack.activitiesForSkill(skill.id)) {
        final visual = NurseryVisualResolver.forActivity(skill, activity);
        expect(visual.semanticLabel, isNotEmpty, reason: activity.id);
        expect(
          visual.source,
          NurseryVisualSource.painted,
          reason: 'Activity ${activity.id} should resolve without emoji UI.',
        );
      }
    }
  });

  test('letter examples preserve bundled local illustration paths', () {
    final pack = _pack();
    var assetBackedExamples = 0;

    for (final letter in pack.letterAssociations) {
      for (final example in letter.examples) {
        final visual = NurseryVisualResolver.forLetterExample(letter, example);
        if (example.assetPath.isEmpty) continue;
        assetBackedExamples += 1;
        expect(visual.source, NurseryVisualSource.localAsset);
        expect(visual.assetPath, example.assetPath);
        expect(
          File(example.assetPath).existsSync(),
          isTrue,
          reason: '${letter.uppercase} ${example.word}',
        );
      }
    }

    expect(assetBackedExamples, greaterThanOrEqualTo(200));
  });

  test('semantic Nursery tokens resolve without pictographic source values', () {
    const semanticTokens = <String>[
      'alphabet',
      'numbers',
      'thinking',
      'listening',
      'pencil',
      'sorting',
      'eyes',
      'star',
      'apple',
      'dog',
      'triangle',
    ];

    for (final token in semanticTokens) {
      final visual = NurseryVisualResolver.forInteractionValue(token);
      expect(
        visual.source,
        isNot(NurseryVisualSource.typography),
        reason: '$token should resolve to a painted vector or bundled asset.',
      );
      expect(visual.semanticLabel, isNotEmpty, reason: token);
    }

    expect(
      NurseryVisualResolver.forInteractionValue('apple').source,
      NurseryVisualSource.localAsset,
    );
    expect(
      NurseryVisualResolver.forInteractionValue('dog').source,
      NurseryVisualSource.localAsset,
    );
  });

  test('migrated Nursery navigation does not render legacy emoji contracts', () {
    final home = File('lib/features/nursery/nursery_home_screen.dart')
        .readAsStringSync();
    final world = File('lib/features/nursery/nursery_world_screen.dart')
        .readAsStringSync();
    final playBoard = File('lib/features/nursery/nursery_play_board.dart')
        .readAsStringSync();
    final lesson = File('lib/features/nursery/nursery_lesson_screen.dart')
        .readAsStringSync();
    final activityStage =
        File('lib/features/nursery/nursery_lesson_activity.dart')
            .readAsStringSync();

    expect(home, isNot(contains('domain.emoji')));
    expect(home, isNot(contains('_skillEmoji')));
    expect(world, isNot(contains('domain.emoji')));
    expect(world, isNot(contains('_skillEmoji')));
    expect(playBoard, isNot(contains('style.emoji')));
    expect(lesson, isNot(contains('portalStyle.emoji')));
    expect(activityStage, isNot(contains('portalStyle.emoji')));
    expect(activityStage, contains('visual: portalStyle.visual'));
    expect(playBoard, isNot(contains('final String emoji')));
  });
}

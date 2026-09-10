import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/nursery/nursery_legacy_visual_aliases.dart';
import 'package:brightquest_kids/core/nursery/nursery_practice_generator.dart';
import 'package:brightquest_kids/core/nursery/nursery_response_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _rawPack() => Map<String, dynamic>.from(
      jsonDecode(
        File('assets/content/nursery/pack_v1.json').readAsStringSync(),
      ) as Map,
    );

NurseryContentPack _pack() => NurseryContentPack.fromJson(_rawPack());

bool _containsLegacyDeep(Object? value) {
  if (value is String) return nurseryContainsLegacyEmoji(value);
  if (value is List) return value.any(_containsLegacyDeep);
  if (value is Map) {
    return value.entries.any(
      (entry) =>
          _containsLegacyDeep(entry.key.toString()) ||
          _containsLegacyDeep(entry.value),
    );
  }
  return false;
}

void main() {
  test('canonical Nursery pack is semantic and validator-clean', () {
    final raw = _rawPack();
    expect(NurseryContentValidator.validate(raw), isEmpty);
    expect(_containsLegacyDeep(raw), isFalse);

    final domains = List<Map<String, dynamic>>.from(
      (raw['domains'] as List).map((value) => Map<String, dynamic>.from(value as Map)),
    );
    for (final domain in domains) {
      expect(domain.containsKey('visualKey'), isTrue, reason: '${domain['id']}');
      expect(domain.containsKey('emoji'), isFalse, reason: '${domain['id']}');
      expect(domain['visualKey'], isA<String>());
      expect((domain['visualKey'] as String).trim(), isNotEmpty);
    }
  });

  test('all authored letter and activity visual payloads are semantic', () {
    final pack = _pack();
    expect(pack.letterAssociations, hasLength(26));
    expect(pack.skills, hasLength(32));
    expect(pack.activities, hasLength(132));

    var pictureCards = 0;
    for (final letter in pack.letterAssociations) {
      for (final example in letter.examples) {
        pictureCards += 1;
        expect(nurseryContainsLegacyEmoji(example.picture), isFalse);
        expect(example.picture, example.word.toLowerCase());
        expect(File(example.assetPath).existsSync(), isTrue, reason: example.assetPath);
      }
    }
    expect(pictureCards, 208);

    for (final activity in pack.activities) {
      expect(nurseryContainsLegacyEmoji(activity.prompt), isFalse, reason: activity.id);
      expect(nurseryContainsLegacyEmoji(activity.narration), isFalse, reason: activity.id);
      expect(_containsLegacyDeep(activity.payload), isFalse, reason: activity.id);
      expect(_containsLegacyDeep(activity.correctResponseRule), isFalse, reason: activity.id);
      for (final option in activity.options) {
        expect(nurseryContainsLegacyEmoji(option.id), isFalse, reason: activity.id);
        expect(nurseryContainsLegacyEmoji(option.label), isFalse, reason: activity.id);
      }
    }
  });

  test('deterministic generated Nursery practice emits semantic values only', () {
    const generator = NurseryPracticeGenerator();
    final pack = _pack();

    for (final skill in pack.skills) {
      for (var seed = 0; seed < 64; seed += 1) {
        final practice = generator.generate(pack: pack, skill: skill, seed: seed);
        expect(nurseryContainsLegacyEmoji(practice.prompt), isFalse,
            reason: '${skill.id}/$seed prompt');
        expect(nurseryContainsLegacyEmoji(practice.narration), isFalse,
            reason: '${skill.id}/$seed narration');
        expect(_containsLegacyDeep(practice.visualTokens), isFalse,
            reason: '${skill.id}/$seed visuals');
        expect(_containsLegacyDeep(practice.correctResponseRule), isFalse,
            reason: '${skill.id}/$seed rule');
        for (final option in practice.options) {
          expect(nurseryContainsLegacyEmoji(option.id), isFalse,
              reason: '${skill.id}/$seed option id');
          expect(nurseryContainsLegacyEmoji(option.label), isFalse,
              reason: '${skill.id}/$seed option label');
        }
      }
    }
  });

  test('legacy pre-migration responses still evaluate against semantic rules', () {
    final pack = _pack();
    const evaluator = NurseryResponseEvaluator();

    expect(
      evaluator.evaluate(
        pack.activityById('nursery.knowledge_animals.g1')!,
        '🐱',
      ).correct,
      isTrue,
    );
    expect(
      evaluator.evaluate(
        pack.activityById('nursery.thinking_matching.g1')!,
        <String, String>{'🍎': '🍎', '⚽': '⚽'},
      ).correct,
      isTrue,
    );
    expect(
      evaluator.evaluate(
        pack.activityById('nursery.thinking_sorting.g1')!,
        <String, String>{'🍎': 'fruit', '🐶': 'animal'},
      ).correct,
      isTrue,
    );
    expect(
      evaluator.evaluate(
        pack.activityById('nursery.thinking_observation_listening.g1')!,
        '⭐ ⚽',
      ).correct,
      isTrue,
    );
  });

  test('legacy pictograms are isolated to the compatibility boundary', () {
    final files = <File>[
      ...Directory('lib/core/nursery')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      ...Directory('lib/features/nursery')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      ...Directory('lib/core/qa')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.dart') &&
              file.path.split(Platform.pathSeparator).last.startsWith('nursery_')),
      File('assets/content/nursery/pack_v1.json'),
    ];

    for (final file in files) {
      if (file.path.endsWith('nursery_legacy_visual_aliases.dart')) continue;
      final source = file.readAsStringSync();
      for (final token in NurseryLegacyVisualAliases.exact.keys) {
        expect(source, isNot(contains(token)), reason: '${file.path}: $token');
      }
    }
  });
}

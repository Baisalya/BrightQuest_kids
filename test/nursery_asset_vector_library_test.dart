import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_asset_catalog.dart';
import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/nursery/nursery_legacy_visual_aliases.dart';
import 'package:brightquest_kids/core/nursery/nursery_spoken_labels.dart';
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
  test('Step 2 catalog exposes only bundled Nursery illustrations', () {
    expect(NurseryAssetCatalog.illustrationCount, 206);

    for (final word in NurseryAssetCatalog.authoredWords) {
      final path = NurseryAssetCatalog.assetForLabel(word);
      expect(path, isNotNull, reason: word);
      expect(File(path!).existsSync(), isTrue, reason: '$word -> $path');
    }
  });

  test('semantic concrete objects prefer bundled assets', () {
    for (final token in <String>[
      'apple',
      'dog',
      'fish',
      'ball',
      'book',
      'sun',
      'kite',
      'duck',
    ]) {
      final visual = NurseryVisualResolver.forInteractionValue(token);
      expect(visual.source, NurseryVisualSource.localAsset, reason: token);
      expect(visual.assetPath, isNotNull, reason: token);
      expect(File(visual.assetPath!).existsSync(), isTrue, reason: token);
      expect(visual.semanticLabel, isNotEmpty, reason: token);
    }
  });

  test('semantic colours and shapes resolve to painted variants', () {
    final red = NurseryVisualResolver.forInteractionValue('colour:red');
    expect(red.source, NurseryVisualSource.painted);
    expect(red.concept, NurseryVisualConcept.colours);
    expect(red.variant, 'red');

    final triangle = NurseryVisualResolver.forInteractionValue('triangle');
    expect(triangle.source, NurseryVisualSource.painted);
    expect(triangle.concept, NurseryVisualConcept.shapes);
    expect(triangle.variant, 'triangle');
  });

  test('semantic counted visuals keep quantity without raw emoji rendering', () {
    final apples = NurseryVisualResolver.forInteractionValue('3 apples');
    expect(apples.source, NurseryVisualSource.localAsset);
    expect(apples.count, 3);
    expect(apples.variant, 'apple');

    final dots = NurseryVisualResolver.forInteractionValue('4 dots');
    expect(dots.source, NurseryVisualSource.painted);
    expect(dots.concept, NurseryVisualConcept.counting);
    expect(dots.count, 4);
    expect(dots.variant, 'dot');
  });

  test('repeated semantic generated visuals compact into calm picture groups', () {
    expect(
      NurseryVisualResolver.compactVisualTokens(
        const <String>[
          'apple',
          'apple',
          'apple',
          '+',
          'fish',
          'fish',
          '=',
          '5',
        ],
      ),
      const <String>['3 apples', '+', '2 fish', '=', '5'],
    );
  });

  test('authored visual-heavy activities use structured semantic tokens', () {
    final pack = _pack();
    final count = pack.activityById('nursery.math_count_0_5.g1')!;
    expect(count.prompt, 'How many apples are shown?');
    expect(count.visualTokens, const <String>['apple', 'apple']);
    expect(
      NurseryVisualResolver.compactVisualTokens(count.visualTokens),
      const <String>['2 apples'],
    );
    expect(nurseryVisualFreeText(count.prompt), count.prompt);
    expect(nurseryContainsRawVisualToken(count.prompt), isFalse);

    final observation =
        pack.activityById('nursery.thinking_observation_listening.g1')!;
    expect(observation.visualTokens, const <String>['star', 'ball']);
    expect(nurseryVisualFreeText(observation.prompt), observation.prompt);
  });

  test('Nursery presentation layer contains no hard-coded legacy emoji UI glyphs', () {
    final source = Directory('lib/features/nursery')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    for (final token in NurseryLegacyVisualAliases.exact.keys) {
      expect(source, isNot(contains(token)), reason: token);
    }
    expect(source, isNot(contains('Text(option.label')));
    expect(source, contains('NurseryVisualToken'));
    expect(source, contains('NurseryPromptVisuals'));
  });
}

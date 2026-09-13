import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/nursery/nursery_spoken_labels.dart';
import 'package:brightquest_kids/core/nursery/nursery_visuals.dart';
import 'package:brightquest_kids/features/nursery/nursery_game_value.dart';
import 'package:brightquest_kids/features/nursery/nursery_interactions.dart';
import 'package:brightquest_kids/features/nursery/nursery_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

NurseryContentPack _pack() => NurseryContentPack.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          File('assets/content/nursery/pack_v1.json').readAsStringSync(),
        ) as Map,
      ),
    );

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

void main() {
  test('extracted activity stage imports its visual text helper', () {
    final source = File('lib/features/nursery/nursery_lesson_activity.dart')
        .readAsStringSync();
    expect(source, contains("nursery_spoken_labels.dart"));
    expect(source, contains('nurseryVisualFreeText(activity.prompt)'));
  });

  test('plain game values resolve to pictures or vectors with context', () {
    final dog = NurseryVisualResolver.forInteractionValue(
      'Dog',
      skillId: 'knowledge_animals',
      prompt: 'Which animal?',
    );
    expect(dog.source, NurseryVisualSource.localAsset);
    expect(dog.assetPath, isNotNull);

    final colour = NurseryVisualResolver.forInteractionValue(
      'orange',
      skillId: 'knowledge_colours',
      prompt: 'Which colour?',
    );
    expect(colour.source, NurseryVisualSource.painted);
    expect(colour.concept, NurseryVisualConcept.colours);
    expect(colour.variant, 'orange');

    final fruit = NurseryVisualResolver.forInteractionValue(
      'orange',
      skillId: 'knowledge_foods',
      prompt: 'Which fruit?',
    );
    expect(fruit.source, NurseryVisualSource.localAsset);

    final shape = NurseryVisualResolver.forInteractionValue(
      'triangle',
      skillId: 'knowledge_shapes',
      prompt: 'Which shape?',
    );
    expect(shape.concept, NurseryVisualConcept.shapes);
    expect(shape.variant, 'triangle');

    final alphabetWord = NurseryVisualResolver.forInteractionValue(
      'SUN',
      skillId: 'alpha_trace_upper',
      prompt: 'Which sign begins with B?',
    );
    expect(alphabetWord.source, NurseryVisualSource.typography);
    expect(alphabetWord.text, 'SUN');

    final wordPicture = NurseryVisualResolver.forInteractionValue(
      'Ball',
      skillId: 'alpha_word_picture',
      prompt: 'B is for which familiar word?',
    );
    expect(wordPicture.source, NurseryVisualSource.localAsset);
  });

  test('all authored interaction values have safe semantic visual plans', () {
    final pack = _pack();
    for (final activity in pack.activities) {
      final values = <String>[
        ...activity.options.map((option) => option.label),
        if (activity.interaction == 'pairMatch')
          ...List<String>.from(activity.payload['left'] as List),
        if (activity.interaction == 'pairMatch')
          ...List<String>.from(activity.payload['right'] as List),
        if (activity.interaction == 'sortBuckets')
          ...List<String>.from(activity.payload['items'] as List),
        if (activity.interaction == 'sortBuckets')
          ...List<String>.from(activity.payload['buckets'] as List),
      ];
      for (final value in values) {
        final spec = NurseryVisualResolver.forInteractionValue(
          value,
          skillId: activity.skillId,
          prompt: activity.prompt,
        );
        expect(spec.semanticLabel.trim(), isNotEmpty, reason: activity.id);
        expect(
          nurseryContainsRawVisualToken(spec.semanticLabel),
          isFalse,
          reason: '${activity.id}: $value',
        );
      }
    }
  });

  test('picture-first game widgets remain presentation-only', () {
    for (final path in <String>[
      'lib/features/nursery/nursery_game_value.dart',
      'lib/features/nursery/nursery_game_chrome.dart',
      'lib/features/nursery/nursery_interactions.dart',
      'lib/features/nursery/nursery_choice_game.dart',
      'lib/features/nursery/nursery_match_game.dart',
      'lib/features/nursery/nursery_sort_game.dart',
      'lib/features/nursery/nursery_trace_game.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('BrightQuestScope')), reason: path);
      expect(source, isNot(contains('recordNurseryEvidence')), reason: path);
      expect(source, isNot(contains('NurseryResponseEvaluator')), reason: path);
      expect(source, isNot(contains('NurseryPracticeGenerator')), reason: path);
    }
  });

  test('interaction dispatcher stays thin and game-specific', () {
    final dispatcher = File('lib/features/nursery/nursery_interactions.dart')
        .readAsStringSync();
    expect(dispatcher.split('\n').length, lessThan(100));
    expect(dispatcher, contains('NurseryChoiceGame('));
    expect(dispatcher, contains('NurseryPairMatchGame('));
    expect(dispatcher, contains('NurserySortBucketsGame('));
    expect(dispatcher, contains('NurseryTraceGame('));
  });

  testWidgets('choice cards are picture-first and keep answer semantics',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final activity = _pack().activityById('nursery.knowledge_animals.g1')!;
    Object? submitted;

    await tester.pumpWidget(
      _host(
        NurseryActivityInteraction(
          activity: activity,
          enabled: true,
          reducedMotion: true,
          onSubmitted: (value) => submitted = value,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(NurseryGameAnswerCard), findsNWidgets(3));
    expect(find.byType(NurseryVisual), findsAtLeastNWidgets(3));
    final catOption = activity.options.singleWhere(
      (option) => nurserySpokenLabel(option.label) == 'cat',
    );
    expect(find.bySemanticsLabel('Answer cat'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Answer cat'));
    await tester.pump();
    expect(submitted, catOption.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pair match keeps the authored map response contract',
      (tester) async {
    final activity = _pack().activityById('nursery.alpha_case_match.g1')!;
    Object? submitted;

    await tester.pumpWidget(
      _host(
        NurseryActivityInteraction(
          activity: activity,
          enabled: true,
          reducedMotion: true,
          onSubmitted: (value) => submitted = value,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Pick A'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Match a'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Pick B'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Match b'));
    await tester.pump();

    expect(submitted, <String, String>{'A': 'a', 'B': 'b'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('sorting keeps raw item keys and authored bucket values',
      (tester) async {
    final activity = _pack().activityById('nursery.thinking_sorting.g1')!;
    Object? submitted;

    await tester.pumpWidget(
      _host(
        NurseryActivityInteraction(
          activity: activity,
          enabled: true,
          reducedMotion: true,
          onSubmitted: (value) => submitted = value,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Pick apple'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Put in fruit'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Pick dog'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Put in animal'));
    await tester.pump();

    expect(
      submitted,
      <String, String>{'apple': 'fruit', 'dog': 'animal'},
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long routine answers use a calm single-column layout',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final activity = _pack().activityById('nursery.knowledge_routines.t1')!;

    await tester.pumpWidget(
      _host(
        NurseryActivityInteraction(
          activity: activity,
          enabled: true,
          reducedMotion: true,
          onSubmitted: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(NurseryGameAnswerCard), findsNWidgets(3));
    expect(
      find.bySemanticsLabel(
        'Answer stay with the adult and wait until it is safe to cross',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

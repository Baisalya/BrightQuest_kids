import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

String _normalise(Object? value) => '${value ?? ''}'
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ');

void main() {
  group('Step 4 authored teaching quality', () {
    test('all 111 blueprints separate concept teaching from worked examples', () {
      final seenTeach = <String, String>{};
      final seenWorked = <String, String>{};
      var total = 0;

      for (final classNumber in const <int>[3, 4, 5]) {
        final pack = _json(
          'assets/content/class_$classNumber/learning_blueprints.json',
        );
        final rows = (pack['blueprints'] as List).whereType<Map>().toList();
        expect(rows, hasLength(37));

        for (final raw in rows) {
          final id = '${raw['competencyId']}';
          final teach = _normalise(raw['teach']);
          final worked = _normalise(raw['workedExample']);
          final narration = _normalise(raw['narrationText']);

          expect(teach, isNotEmpty, reason: '$id / teach');
          expect(worked, isNotEmpty, reason: '$id / workedExample');
          expect(teach, isNot(worked), reason: '$id repeats teach as example');
          expect(narration, teach, reason: '$id narration must teach the concept');

          final previousTeach = seenTeach[teach];
          expect(
            previousTeach,
            isNull,
            reason: '$id duplicates concept teaching from $previousTeach',
          );
          seenTeach[teach] = id;

          final previousWorked = seenWorked[worked];
          expect(
            previousWorked,
            isNull,
            reason: '$id duplicates worked example from $previousWorked',
          );
          seenWorked[worked] = id;
          total += 1;
        }
      }

      expect(total, 111);
    });

    test('concept teaching no longer reads like a copied answer or old hint', () {
      const forbidden = <String>[
        'the correct answer is',
        'the correct value is',
        'arrange the words in sentence order to rebuild',
        'find the naming word, then the action word, then the describing word',
        'a correct algorithm stays inside the grid',
        'in this brightquest sorting activity',
      ];

      for (final classNumber in const <int>[3, 4, 5]) {
        final pack = _json(
          'assets/content/class_$classNumber/learning_blueprints.json',
        );
        for (final raw in (pack['blueprints'] as List).whereType<Map>()) {
          final id = '${raw['competencyId']}';
          final teach = _normalise(raw['teach']);
          expect(
            teach.split(' ').where((word) => word.isNotEmpty).length,
            greaterThanOrEqualTo(12),
            reason: '$id needs an explanatory concept-teaching sentence',
          );
          for (final phrase in forbidden) {
            expect(teach, isNot(contains(phrase)), reason: '$id / $phrase');
          }
        }
      }
    });

    test('English grammar competencies teach their own concept', () {
      final class3 = _json('assets/content/class_3/learning_blueprints.json');
      final class4 = _json('assets/content/class_4/learning_blueprints.json');
      final class5 = _json('assets/content/class_5/learning_blueprints.json');

      Map<dynamic, dynamic> row(Map<String, dynamic> pack, String id) =>
          (pack['blueprints'] as List)
              .whereType<Map>()
              .firstWhere((item) => item['competencyId'] == id);

      final nouns = row(class3, 'c3_eng_nouns_pronouns');
      expect(_normalise(nouns['teach']), contains('noun is a naming word'));
      expect(_normalise(nouns['teach']), contains('pronoun'));
      expect(_normalise(nouns['workedExample']), contains('ria'));
      expect(_normalise(nouns['workedExample']), isNot(contains('r i a')));

      final verbs = row(class3, 'c3_eng_verbs_tense');
      expect(_normalise(verbs['teach']), contains('verb'));
      expect(_normalise(verbs['teach']), contains('simple past'));
      expect(_normalise(verbs['workedExample']), contains('ria walks'));
      expect(_normalise(verbs['workedExample']), contains('ria walked'));

      final parts = row(class4, 'c4_eng_parts_speech');
      final tense = row(class4, 'c4_eng_tense');
      final agreement = row(class4, 'c4_eng_agreement_pronouns');
      expect(_normalise(parts['teach']), contains('adverbs'));
      expect(_normalise(tense['teach']), contains('consistent'));
      expect(_normalise(agreement['teach']), contains('agree'));
      expect(_normalise(parts['teach']), isNot(_normalise(tense['teach'])));
      expect(_normalise(tense['teach']), isNot(_normalise(agreement['teach'])));

      final readCompare = row(class4, 'c4_eng_read_compare');
      expect(_normalise(readCompare['workedExample']), contains('riya walks'));
      expect(_normalise(readCompare['workedExample']), isNot(contains('r i y a')));

      final class5Parts = row(class5, 'c5_eng_parts_speech');
      final class5Agreement = row(class5, 'c5_eng_tense_agreement');
      expect(_normalise(class5Parts['teach']), contains('part of speech'));
      expect(_normalise(class5Agreement['teach']), contains('subject'));
      expect(
        _normalise(class5Parts['teach']),
        isNot(_normalise(class5Agreement['teach'])),
      );
    });

    test('coding competencies teach sequence, pattern, decomposition and debugging distinctly', () {
      final teaches = <String, String>{};
      for (final classNumber in const <int>[3, 4, 5]) {
        final pack = _json(
          'assets/content/class_$classNumber/learning_blueprints.json',
        );
        for (final raw in (pack['blueprints'] as List).whereType<Map>()) {
          final id = '${raw['competencyId']}';
          if (!id.contains('_ct_')) continue;
          teaches[id] = _normalise(raw['teach']);
        }
      }

      expect(teaches['c3_ct_sequences'], contains('ordered set of instructions'));
      expect(teaches['c3_ct_patterns_repeats'], contains('repeating block'));
      expect(teaches['c4_ct_decomposition'], contains('mini-goal'));
      expect(teaches['c5_ct_algorithm_efficiency'], contains('compare'));
      expect(teaches['c5_ct_debugging'], contains('first faulty step'));
      expect(teaches.values.toSet(), hasLength(teaches.length));
    });
  });
}

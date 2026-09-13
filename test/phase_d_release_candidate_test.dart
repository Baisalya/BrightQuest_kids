import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

void main() {
  group('Phase D release-candidate contract', () {
    test('all authored learning packs remain en-IN only', () {
      for (final classNumber in <int>[3, 4, 5]) {
        final pack = _json('assets/content/class_$classNumber/pack.json');
        expect(pack['locale'], 'en-IN');
        for (final raw in (pack['activities'] as List).whereType<Map>()) {
          expect(raw['locale'], 'en-IN', reason: '${raw['id']}');
          for (final key in <String>['prompt', 'explanation']) {
            expect(
              '${raw[key] ?? ''}'.trim(),
              isNotEmpty,
              reason: '${raw['id']} / $key',
            );
          }
          final narration = Map<String, dynamic>.from(
            raw['narration'] as Map? ?? const {},
          );
          expect(
            '${narration['text'] ?? ''}'.trim(),
            isNotEmpty,
            reason: '${raw['id']} / narration.text',
          );
        }

        final blueprints = _json(
          'assets/content/class_$classNumber/learning_blueprints.json',
        );
        for (final raw in (blueprints['blueprints'] as List).whereType<Map>()) {
          final id = raw['id'] ?? raw['competencyId'];
          expect(raw['locale'], 'en-IN', reason: '$id');
          expect(
            '${raw['narrationText'] ?? ''}'.trim(),
            isNotEmpty,
            reason: '$id / narrationText',
          );
        }
      }

      final nursery = _json('assets/content/nursery/pack_v1.json');
      expect(nursery['locale'], 'en-IN');
      for (final raw in (nursery['activities'] as List).whereType<Map>()) {
        for (final key in <String>[
          'prompt',
          'narration',
          'hint',
          'successFeedback',
          'wrongFeedback',
        ]) {
          expect(
            '${raw[key] ?? ''}'.trim(),
            isNotEmpty,
            reason: '${raw['id']} / $key',
          );
        }
      }
    });

    test('external Nursery shipping gates remain fail-closed', () {
      final nursery = _json('assets/content/nursery/pack_v1.json');
      final commercial = Map<String, dynamic>.from(
        nursery['commercial'] as Map,
      );
      final gates = Map<String, dynamic>.from(
        nursery['releaseGates'] as Map,
      );
      expect(commercial['paidEligibility'], isFalse);
      expect(gates.values.whereType<bool>().any((value) => value), isFalse);
    });

    test('Nursery motion remains finite and thumbnail decoding is bounded', () {
      final source = Directory('lib/features/nursery')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.readAsStringSync())
          .join('\n');
      expect(source, isNot(contains('Timer.periodic(')));
      expect(source, isNot(contains('.repeat(')));
      final semanticVisual =
          File('lib/features/nursery/nursery_visual.dart').readAsStringSync();
      final animatedAsset = File(
        'lib/features/nursery/nursery_asset_reaction.dart',
      ).readAsStringSync();
      for (final assetBoundary in <String>[semanticVisual, animatedAsset]) {
        expect(assetBoundary, contains('cacheWidth: 128'));
        expect(assetBoundary, contains('cacheHeight: 128'));
      }
    });

    test('208 local letter cards stay within the Phase D asset budget', () {
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
    });

    test('Phase D release-candidate deliverables exist', () {
      for (final path in <String>[
        'docs/PHASE_D_POLISH_RELEASE_QA.md',
        'docs/PHASE_D_RELEASE_CANDIDATE_CHECKLIST.md',
        'tool/qa/phase_d_release_candidate_audit.dart',
        'tool/qa/run_phase_d.ps1',
        'tool/qa/run_phase_d.sh',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });
  });
}

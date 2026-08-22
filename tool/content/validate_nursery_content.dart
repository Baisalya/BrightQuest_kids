import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';
import 'package:brightquest_kids/core/nursery/nursery_practice_generator.dart';

Map<String, dynamic> _readJson(String path) => Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );

Never _fail(String message) {
  stderr.writeln('Nursery content validation FAILED: $message');
  exit(1);
}

void main() {
  final raw = _readJson('assets/content/nursery/pack_v1.json');
  final issues = NurseryContentValidator.validate(raw);
  if (issues.isNotEmpty) {
    for (final issue in issues) stderr.writeln('  - $issue');
    exit(1);
  }
  final pack = NurseryContentPack.fromJson(raw);
  if (pack.skills.length != 32 || pack.activities.length != 132) {
    _fail('Expected 32 skills and 132 authored activities.');
  }
  if (pack.letterAssociations.length != 26) {
    _fail('Expected a complete 26-letter association catalog.');
  }
  final letterAssetPaths = <String>{};
  for (final letter in pack.letterAssociations) {
    if (letter.examples.length < 8) {
      _fail('${letter.uppercase} requires at least eight discovery examples.');
    }
    for (final example in letter.examples) {
      if (example.assetPath.isEmpty || !File(example.assetPath).existsSync()) {
        _fail(
          '${letter.uppercase} ${example.word} is missing bundled asset ${example.assetPath}.',
        );
      }
      if (!letterAssetPaths.add(example.assetPath)) {
        _fail('Duplicate letter picture asset: ${example.assetPath}.');
      }
    }
  }
  if (letterAssetPaths.length < 200) {
    _fail('Expected at least 200 unique A–Z discovery picture assets.');
  }
  if (pack.commercial.paidEligibility ||
      pack.releaseGates.allExternalGatesRecorded) {
    _fail('Draft Nursery content may not be commercially approved in source.');
  }

  const generator = NurseryPracticeGenerator();
  var generatedChecks = 0;
  for (final skill in pack.skills) {
    for (var seed = 0; seed < 100; seed += 1) {
      final first = generator.generate(pack: pack, skill: skill, seed: seed);
      final again = generator.generate(pack: pack, skill: skill, seed: seed);
      final firstOptions = first.options.map((option) => option.id).toList();
      final againOptions = again.options.map((option) => option.id).toList();
      if (first.prompt != again.prompt ||
          first.skillId != skill.id ||
          firstOptions.join('|') != againOptions.join('|') ||
          firstOptions.length != firstOptions.toSet().length ||
          !firstOptions.contains(first.correctResponseRule['value'])) {
        _fail('${skill.id} seed $seed is invalid or non-deterministic.');
      }
      if (skill.generatorFamily == 'addition') {
        final answer = int.tryParse('${first.correctResponseRule['value']}');
        if (answer == null || answer < 0 || answer > 10) {
          _fail('${skill.id} seed $seed produced an out-of-range sum.');
        }
      }
      generatedChecks += 1;
    }
  }

  stdout.writeln('BrightQuest Nursery content validation: PASS');
  stdout.writeln('Skills: ${pack.skills.length}');
  stdout.writeln('Authored activities: ${pack.activities.length}');
  stdout.writeln('Letter associations: ${pack.letterAssociations.length}');
  stdout
      .writeln('Letter discovery examples/assets: ${letterAssetPaths.length}');
  stdout
      .writeln('Free samples: ${pack.commercial.freeSampleActivityIds.length}');
  stdout.writeln('Deterministic generated variants checked: $generatedChecks');
  stdout.writeln('Commercial eligibility: BLOCKED by design');
}

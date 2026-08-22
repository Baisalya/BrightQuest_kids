import 'dart:io';

import 'package:brightquest_kids/core/nursery/nursery_content.dart';

import 'qa_fixture_loader.dart';

void main() {
  // Construction validates the Classes 3–5 schema, curriculum mappings,
  // content packs, learning-blueprint references, and the Nursery pack.
  final repository = loadQaContentRepository();
  final nurseryRaw = readQaJson('assets/content/nursery/pack_v1.json');
  final nurserySchema = readQaJson('assets/content/nursery/schema_v1.json');

  final nurseryIssues = NurseryContentValidator.validate(nurseryRaw);
  if (nurseryIssues.isNotEmpty) {
    for (final issue in nurseryIssues) {
      stderr.writeln('Nursery contract: $issue');
    }
    exitCode = 1;
    return;
  }

  final schemaVersion = (nurserySchema['schemaVersion'] as num?)?.toInt();
  if (schemaVersion != 1 ||
      nurserySchema['packId'] != NurseryContentPack.nurseryPackId) {
    stderr.writeln(
        'FAIL: Nursery schema identity/version does not match the pack contract.');
    exitCode = 1;
    return;
  }

  final requiredTopLevel =
      List<String>.from(nurserySchema['requiredTopLevel'] as List? ?? const []);
  for (final field in requiredTopLevel) {
    if (!nurseryRaw.containsKey(field)) {
      stderr.writeln(
          'FAIL: Nursery schema requires missing top-level field $field.');
      exitCode = 1;
      return;
    }
  }

  final supportedInteractions = Set<String>.from(
    nurserySchema['supportedInteractions'] as List? ?? const [],
  );
  final supportedRuleTypes = Set<String>.from(
    nurserySchema['supportedRuleTypes'] as List? ?? const [],
  );
  for (final rawActivity
      in (nurseryRaw['activities'] as List? ?? const []).whereType<Map>()) {
    final interaction = rawActivity['interaction'];
    final rawRule = rawActivity['correctResponseRule'];
    final ruleType = rawRule is Map ? rawRule['type'] : null;
    if (interaction is! String ||
        !supportedInteractions.contains(interaction)) {
      stderr.writeln(
          'FAIL: Nursery schema does not allow interaction $interaction.');
      exitCode = 1;
      return;
    }
    if (ruleType is! String || !supportedRuleTypes.contains(ruleType)) {
      stderr.writeln(
          'FAIL: Nursery schema does not allow response rule $ruleType.');
      exitCode = 1;
      return;
    }
  }

  final contract = Map<String, dynamic>.from(
    nurserySchema['letterAssociationContract'] as Map? ?? const {},
  );
  final requiredPerLetter =
      (contract['requiredExamplesPerLetter'] as num?)?.toInt() ?? 0;
  final requiredTotal =
      (contract['requiredTotalPictureCards'] as num?)?.toInt() ?? 0;
  final requiredExampleFields = Set<String>.from(
    contract['requiredExampleFields'] as List? ?? const [],
  );
  final rawLetters = (nurseryRaw['letterAssociations'] as List? ?? const []);
  for (final rawLetter in rawLetters.whereType<Map>()) {
    for (final rawExample
        in (rawLetter['examples'] as List? ?? const []).whereType<Map>()) {
      for (final field in requiredExampleFields) {
        if (!rawExample.containsKey(field)) {
          stderr.writeln(
            'FAIL: Nursery example ${rawExample['word']} is missing schema field $field.',
          );
          exitCode = 1;
          return;
        }
      }
    }
  }

  final nursery = repository.nurseryPack!;
  final assets = <String>{};

  if (requiredPerLetter < 3 || requiredTotal < 200) {
    stderr.writeln(
      'FAIL: Nursery schema metadata is weaker than the current 200-card contract.',
    );
    exitCode = 1;
    return;
  }

  for (final letter in nursery.letterAssociations) {
    if (letter.examples.length < requiredPerLetter) {
      stderr.writeln(
        'FAIL: ${letter.uppercase} has ${letter.examples.length} examples; schema requires $requiredPerLetter.',
      );
      exitCode = 1;
      return;
    }
    for (final example in letter.examples) {
      if (!assets.add(example.assetPath)) {
        stderr.writeln('FAIL: duplicate Nursery asset ${example.assetPath}.');
        exitCode = 1;
        return;
      }
      if (!File(example.assetPath).existsSync()) {
        stderr.writeln('FAIL: missing Nursery asset ${example.assetPath}.');
        exitCode = 1;
        return;
      }
    }
  }

  if (assets.length < requiredTotal) {
    stderr.writeln(
      'FAIL: Nursery has ${assets.length} unique cards; schema requires $requiredTotal.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('BrightQuest content contract validation: PASS');
  stdout.writeln('Class packs: ${repository.packs.length}');
  stdout.writeln('Class activities: ${repository.allActivities.length}');
  stdout.writeln('Nursery skills: ${nursery.skills.length}');
  stdout.writeln('Nursery activities: ${nursery.activities.length}');
  stdout.writeln('Nursery picture cards: ${assets.length}');
}

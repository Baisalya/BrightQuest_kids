import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/content/content_duplicate_detector.dart';
import 'package:brightquest_kids/core/content/content_generators.dart';
import 'package:brightquest_kids/core/content/content_repository.dart';
import 'package:brightquest_kids/core/curriculum/content_contract.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_contract_validator.dart';
import 'package:brightquest_kids/core/curriculum/current_content_inventory.dart';

Map<String, dynamic> _readJson(String path) {
  final file = File(path);
  if (!file.existsSync()) throw StateError('Missing required file: $path');
  return Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map);
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}

void main(List<String> args) {
  final curriculumJson = _readJson('assets/content/curriculum_map.json');
  final packJson = <Map<String, dynamic>>[
    _readJson('assets/content/class_3/pack.json'),
    _readJson('assets/content/class_4/pack.json'),
    _readJson('assets/content/class_5/pack.json'),
  ];

  late ContentRepository repository;
  try {
    repository = ContentRepository.fromJsonPacks(
      curriculumJson: curriculumJson,
      schemaJson: _readJson('assets/content/content_schema_v1.json'),
      packJson: packJson,
      blueprintJson: <Map<String, dynamic>>[
        _readJson('assets/content/class_3/learning_blueprints.json'),
        _readJson('assets/content/class_4/learning_blueprints.json'),
        _readJson('assets/content/class_5/learning_blueprints.json'),
      ],
      nurseryJson: _readJson('assets/content/nursery/pack_v1.json'),
    );
  } on ContentPackFormatException catch (error) {
    stderr.writeln('BrightQuest content-pack validation FAILED:');
    for (final issue in error.issues.where((value) => !value.warning)) {
      stderr.writeln('  - ${issue.code}: ${issue.message}');
    }
    exitCode = 1;
    return;
  }

  final contract = CurriculumContract.fromJson(curriculumJson);
  final audit = CurrentContentAudit.fromJson(
    _readJson('assets/content/current_content_audit.json'),
  );
  final inventory = currentContentInventory(repository);
  const curriculumValidator = CurriculumContractValidator();
  final curriculumResult = curriculumValidator.validate(
    contract: contract,
    audit: audit,
    currentContent: inventory,
  );
  if (!curriculumResult.isValid) {
    stderr.writeln('Curriculum/content compatibility validation FAILED:');
    for (final issue in curriculumResult.errors) {
      stderr.writeln('  - ${issue.code}: ${issue.message}');
    }
    exitCode = 1;
    return;
  }

  if (inventory.length != 189) {
    _fail(
        'Expected 189 migrated legacy learning records, found ${inventory.length}.');
  }

  _validateGenerators();
  _validateLearningBlueprints(curriculumJson);

  final duplicates = findDuplicateContentGroups(repository.allActivities);
  stdout.writeln('BrightQuest Kids content validation: PASS');
  stdout.writeln('Class packs: 3 + Nursery review pack');
  stdout.writeln(
      'Nursery authored activities: ${repository.nurseryPack?.activities.length ?? 0}');
  stdout.writeln('Legacy migrated activities: ${inventory.length}');
  stdout.writeln(
      'Authored Class 3–5 activities: ${repository.allActivities.length}');
  stdout.writeln('Legacy selectors preserved: ${audit.selectors.length}');
  stdout.writeln(
      'Exact duplicate prompt/answer groups reported: ${duplicates.length}');
  stdout.writeln(
      'Deterministic generator samples checked: 900 per generator family.');
  stdout.writeln(
      'Teach/guided/independent/mastery/review blueprints checked: 111.');
}

void _validateGenerators() {
  const generators = DeterministicContentGenerators();
  var samples = 0;
  for (final classNumber in const <int>[3, 4, 5]) {
    for (final difficulty in const <int>[1, 2, 3]) {
      for (var seed = 0; seed < 100; seed += 1) {
        final arithmetic = generators.arithmetic(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        final arithmeticAgain = generators.arithmetic(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        if (arithmetic.text != arithmeticAgain.text ||
            arithmetic.answer != arithmeticAgain.answer ||
            arithmetic.choices.join(',') != arithmeticAgain.choices.join(',')) {
          _fail(
              'Arithmetic seed $seed is not deterministic for Class $classNumber difficulty $difficulty.');
        }
        if (arithmetic.choices.toSet().length != arithmetic.choices.length ||
            arithmetic.choices
                    .where((value) => value == arithmetic.answer)
                    .length !=
                1) {
          _fail('Arithmetic seed $seed has invalid choices.');
        }

        final fraction = generators.fraction(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        final selectedNumerator = fraction.totalSlices * fraction.numerator;
        if (fraction.denominator <= 0 ||
            selectedNumerator % fraction.denominator != 0 ||
            selectedNumerator ~/ fraction.denominator > fraction.totalSlices) {
          _fail('Fraction seed $seed has no valid whole-slice solution.');
        }
        final fractionAgain = generators.fraction(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        if (fraction.id != fractionAgain.id ||
            fraction.totalSlices != fractionAgain.totalSlices ||
            fraction.numerator != fractionAgain.numerator ||
            fraction.denominator != fractionAgain.denominator) {
          _fail('Fraction seed $seed is not deterministic.');
        }

        final grammar = generators.grammar(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        if (!grammar.sentence
                .toLowerCase()
                .contains(grammar.noun.toLowerCase()) ||
            !grammar.sentence
                .toLowerCase()
                .contains(grammar.verb.toLowerCase()) ||
            !grammar.sentence
                .toLowerCase()
                .contains(grammar.adjective.toLowerCase())) {
          _fail('Grammar seed $seed has an impossible labelled solution.');
        }
        final grammarAgain = generators.grammar(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        if (grammar.sentence != grammarAgain.sentence ||
            grammar.noun != grammarAgain.noun ||
            grammar.verb != grammarAgain.verb ||
            grammar.adjective != grammarAgain.adjective) {
          _fail('Grammar seed $seed is not deterministic.');
        }

        final map = generators.mapDirection(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        if (map.choices.toSet().length != map.choices.length ||
            map.choices.where((value) => value == map.answer).length != 1) {
          _fail('Map-direction seed $seed has an invalid answer set.');
        }
        final mapAgain = generators.mapDirection(
          classNumber: classNumber,
          difficulty: difficulty,
          seed: seed,
        );
        if (map.question != mapAgain.question ||
            map.answer != mapAgain.answer) {
          _fail('Map-direction seed $seed is not deterministic.');
        }
        samples += 1;
      }
    }
  }
  if (samples != 900)
    _fail('Generator validation sample count drifted: $samples.');
}

void _validateLearningBlueprints(Map<String, dynamic> curriculumJson) {
  var total = 0;
  for (final rawClass in (curriculumJson['classes'] as List).whereType<Map>()) {
    final classMap = Map<String, dynamic>.from(rawClass);
    final classNumber = classMap['classNumber'] as int;
    final expected = (classMap['competencies'] as List)
        .whereType<Map>()
        .map((row) => row['id'] as String)
        .toSet();
    final blueprint = _readJson(
      'assets/content/class_$classNumber/learning_blueprints.json',
    );
    final rows = (blueprint['blueprints'] as List).whereType<Map>().toList();
    final ids = rows.map((row) => row['competencyId'] as String).toList();
    if (ids.length != ids.toSet().length ||
        ids.toSet().difference(expected).isNotEmpty ||
        expected.difference(ids.toSet()).isNotEmpty) {
      _fail('Class $classNumber learning blueprint coverage drifted.');
    }
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw);
      final guided = Map<String, dynamic>.from(row['guidedTry'] as Map);
      final transfer = Map<String, dynamic>.from(row['masteryTransfer'] as Map);
      if ((row['teach'] as String).trim().isEmpty ||
          (row['workedExample'] as String).trim().isEmpty ||
          (guided['hintLevel1'] as String).trim().isEmpty ||
          (guided['hintLevel2'] as String).trim().isEmpty ||
          transfer['requireUnseenWording'] != true ||
          transfer['hintAllowed'] != false ||
          (row['reviewPrompt'] as String).trim().isEmpty) {
        _fail(
            '${row['competencyId']} does not satisfy the lesson blueprint contract.');
      }
      total += 1;
    }
  }
  if (total != 111) _fail('Expected 111 competency blueprints, found $total.');

  final transcripts = _readJson('assets/content/shared/audio_transcripts.json');
  final cues = Map<String, dynamic>.from(transcripts['cues'] as Map);
  for (final cue in <String>[
    'levelStart',
    'hint',
    'correct',
    'wrong',
    'unlock',
    'complete'
  ]) {
    if ((cues[cue] as String?)?.trim().isEmpty ?? true) {
      _fail('Missing visible transcript for audio cue $cue.');
    }
  }
}

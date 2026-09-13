import '../nursery/nursery_content.dart';
import '../nursery/nursery_practice_generator.dart';
import '../nursery/nursery_spoken_labels.dart';
import 'nursery_math_world_reference.dart';
import 'teaching_correctness_audit.dart';

/// Phase-C teacher-facing audit for Nursery Math & My World.
///
/// It cross-checks authored answers, counting/arithmetic visuals, generated
/// practice, speech/visual normalization and sequential non-repetition.
class NurseryMathWorldAudit {
  const NurseryMathWorldAudit({this.generatedSeedsPerSkill = 256});

  final int generatedSeedsPerSkill;

  TeachingAuditReport audit(NurseryContentPack pack) {
    var report = TeachingAuditReport.empty;
    report = report.merge(_auditRequiredSkills(pack));
    report = report.merge(_auditAuthoredMath(pack));
    report = report.merge(_auditAuthoredWorld(pack));
    report = report.merge(_auditGeneratedMath(pack));
    report = report.merge(_auditGeneratedWorld(pack));
    report = report.merge(_auditSequentialNonRepetition(pack));
    return report;
  }

  TeachingAuditReport _auditRequiredSkills(NurseryContentPack pack) {
    var checks = 0;
    final findings = <TeachingAuditFinding>[];
    final ids = pack.skills.map((skill) => skill.id).toSet();

    for (final id in <String>{
      ...nurseryPhaseCMathSkillIds,
      ...nurseryPhaseCWorldSkillIds,
    }) {
      checks += 1;
      if (!ids.contains(id)) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'phase_c.required_skill_missing',
            location: id,
            message: 'Required Math/My World skill is missing.',
          ),
        );
      }
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  TeachingAuditReport _auditAuthoredMath(NurseryContentPack pack) {
    var checks = 0;
    final findings = <TeachingAuditFinding>[];

    for (final skillId in nurseryPhaseCMathSkillIds) {
      final skill = pack.skillById(skillId);
      if (skill == null) continue;
      for (final activity in pack.activitiesForSkill(skillId)) {
        final location = '$skillId/${activity.id}';
        final rule = activity.correctResponseRule;
        final type = '${rule['type']}';

        checks += 1;
        if (nurserySpeakableText(activity.prompt) !=
            nurserySpeakableText(activity.narration)) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.high,
              code: 'phase_c.math.prompt_narration_drift',
              location: location,
              message:
                  'Visible prompt and spoken narration describe different content.',
            ),
          );
        }

        if (type == 'choice') {
          final answer = '${rule['value']}';
          checks += 1;
          if (!activity.options.any((option) => option.id == answer)) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'phase_c.math.answer_missing_from_choices',
                location: location,
                message: 'Scored answer $answer is not an available choice.',
              ),
            );
          }
        }

        if (skillId.startsWith('math_count_')) {
          checks += 1;
          final answer = int.tryParse('${rule['value']}');
          final expected = activity.visualTokens.isNotEmpty
              ? _visualQuantity(activity.visualTokens)
              : activity.prompt.toLowerCase().startsWith('no stars')
                  ? 0
                  : _countObjectsInText(activity.prompt);
          if (answer == null || expected != answer) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'phase_c.math.authored_count_mismatch',
                location: location,
                message:
                    'Counting prompt represents $expected objects but scores ${rule['value']}.',
              ),
            );
          }
        }

        if (skillId == 'math_number_quantity' && type == 'pairMatch') {
          final rawPairs = rule['pairs'];
          if (rawPairs is Map) {
            for (final entry in rawPairs.entries) {
              checks += 1;
              final numeral = int.tryParse('${entry.key}');
              final quantity = _dotQuantity('${entry.value}');
              if (numeral == null || quantity != numeral) {
                findings.add(
                  TeachingAuditFinding(
                    severity: TeachingAuditSeverity.blocker,
                    code: 'phase_c.math.authored_quantity_pair_mismatch',
                    location: location,
                    message:
                        'Numeral ${entry.key} is paired with quantity ${entry.value}.',
                  ),
                );
              }
            }
          }
        }

        if (skillId == 'math_add_objects') {
          checks += 1;
          final equation = activity.visualTokens.isNotEmpty
              ? _objectAdditionFromVisualTokens(activity.visualTokens)
              : _objectAdditionFromPrompt(activity.prompt);
          final answer = int.tryParse('${rule['value']}');
          if (equation == null || answer == null || equation != answer) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'phase_c.math.authored_object_addition_mismatch',
                location: location,
                message:
                    'Object addition does not equal the scored answer ${rule['value']}.',
              ),
            );
          }
        }

        if (skillId == 'math_add_numerals') {
          checks += 1;
          final match =
              RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(activity.prompt);
          final answer = int.tryParse('${rule['value']}');
          final sum = match == null
              ? null
              : int.parse(match.group(1)!) + int.parse(match.group(2)!);
          if (sum == null || answer == null || sum != answer || sum > 10) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'phase_c.math.authored_numeral_addition_mismatch',
                location: location,
                message:
                    'Numeral addition must be correct and remain within total 10.',
              ),
            );
          }
        }
      }
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  TeachingAuditReport _auditAuthoredWorld(NurseryContentPack pack) {
    var checks = 0;
    final findings = <TeachingAuditFinding>[];

    for (final entry in nurseryPhaseCWorldAuthoredAnswers.entries) {
      final activity = pack.activityById(entry.key);
      checks += 1;
      if (activity == null) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'phase_c.world.authored_activity_missing',
            location: entry.key,
            message: 'Curated My World activity is missing.',
          ),
        );
        continue;
      }

      final answer = '${activity.correctResponseRule['value']}';
      checks += 1;
      if (answer != entry.value) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'phase_c.world.curated_answer_mismatch',
            location: entry.key,
            message: 'Expected ${entry.value} but content scores $answer.',
          ),
        );
      }

      checks += 1;
      if (nurserySpeakableText(activity.prompt) !=
          nurserySpeakableText(activity.narration)) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.high,
            code: 'phase_c.world.prompt_narration_drift',
            location: entry.key,
            message:
                'Visible prompt and spoken narration are not synchronized.',
          ),
        );
      }

      for (final option in activity.options) {
        checks += 1;
        final spoken = nurserySpokenLabel(option.label);
        if (spoken.trim().isEmpty ||
            (nurseryContainsRawVisualToken(option.label) &&
                nurseryContainsRawVisualToken(spoken))) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.high,
              code: 'phase_c.world.option_missing_spoken_equivalent',
              location: '${entry.key}/${option.id}',
              message: 'Visual answer choice has no stable spoken equivalent.',
            ),
          );
        }
      }
    }

    checks += 4;
    if (!(pack.activityById('nursery.knowledge_shapes.t1')?.prompt ?? '')
        .toLowerCase()
        .contains('front face')) {
      findings.add(
        const TeachingAuditFinding(
          severity: TeachingAuditSeverity.high,
          code: 'phase_c.world.shape_3d_2d_ambiguity',
          location: 'nursery.knowledge_shapes.t1',
          message:
              'Door example must refer to its 2D front face, not the whole 3D object.',
        ),
      );
    }
    if (!(pack.activityById('nursery.knowledge_animals.t1')?.prompt ?? '')
        .toLowerCase()
        .contains('hooves')) {
      findings.add(
        const TeachingAuditFinding(
          severity: TeachingAuditSeverity.high,
          code: 'phase_c.world.farm_animal_ambiguity',
          location: 'nursery.knowledge_animals.t1',
          message: 'Farm-animal transfer needs a distinguishing clue.',
        ),
      );
    }
    if (!(pack.activityById('nursery.knowledge_body.t1')?.prompt ?? '')
        .toLowerCase()
        .contains('end of each leg')) {
      findings.add(
        const TeachingAuditFinding(
          severity: TeachingAuditSeverity.high,
          code: 'phase_c.world.body_part_ambiguity',
          location: 'nursery.knowledge_body.t1',
          message:
              'Body-part transfer must identify feet without relying on shoes or ground contact.',
        ),
      );
    }
    if (pack
            .activityById('nursery.knowledge_routines.t1')
            ?.correctResponseRule['value'] !=
        'stay with the adult and wait until it is safe to cross') {
      findings.add(
        const TeachingAuditFinding(
          severity: TeachingAuditSeverity.blocker,
          code: 'phase_c.world.road_safety_answer_drift',
          location: 'nursery.knowledge_routines.t1',
          message:
              'Road-safety transfer must keep the child with the adult and waiting for a safe crossing.',
        ),
      );
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  TeachingAuditReport _auditGeneratedMath(NurseryContentPack pack) {
    const generator = NurseryPracticeGenerator();
    var checks = 0;
    final findings = <TeachingAuditFinding>[];

    for (final skillId in nurseryPhaseCMathSkillIds) {
      final skill = pack.skillById(skillId);
      if (skill == null) continue;
      for (var seed = 0; seed < generatedSeedsPerSkill; seed += 1) {
        final practice =
            generator.generate(pack: pack, skill: skill, seed: seed);
        final location = '$skillId/seed:$seed';
        final answerText = '${practice.correctResponseRule['value']}';

        checks += 1;
        final optionIds = practice.options.map((option) => option.id).toList();
        if (optionIds.toSet().length != optionIds.length ||
            !optionIds.contains(answerText)) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'phase_c.math.generated_choice_invalid',
              location: location,
              message: 'Generated choices are duplicated or omit the answer.',
            ),
          );
        }

        if (skillId.startsWith('math_count_')) {
          checks += 1;
          final answer = int.tryParse(answerText);
          final visualCount = _visualQuantity(practice.visualTokens);
          if (answer == null || answer != visualCount) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'phase_c.math.generated_count_mismatch',
                location: location,
                message:
                    'Generated count shows $visualCount but scores $answerText.',
              ),
            );
          }
        }

        if (skillId == 'math_number_quantity') {
          checks += 1;
          final match = RegExp(r'shows\s+(\d+)\s+objects', caseSensitive: false)
              .firstMatch(practice.prompt);
          final expected = match == null ? null : int.tryParse(match.group(1)!);
          final actual = _dotQuantity(answerText);
          if (expected == null || expected != actual) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'phase_c.math.generated_quantity_mismatch',
                location: location,
                message: 'Generated quantity prompt and answer disagree.',
              ),
            );
          }
        }

        if (skillId == 'math_add_objects' || skillId == 'math_add_numerals') {
          checks += 1;
          final answer = int.tryParse(answerText);
          int? sum;
          if (skillId == 'math_add_objects') {
            final plus = practice.visualTokens.indexOf('+');
            final equals = practice.visualTokens.indexOf('=');
            if (plus > 0 && equals > plus) {
              final left = _visualQuantity(practice.visualTokens.take(plus));
              final right = _visualQuantity(
                practice.visualTokens.skip(plus + 1).take(equals - plus - 1),
              );
              sum = left + right;
            }
          } else {
            final match =
                RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(practice.prompt);
            if (match != null) {
              sum = int.parse(match.group(1)!) + int.parse(match.group(2)!);
            }
          }
          if (answer == null || sum == null || sum != answer || answer > 10) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'phase_c.math.generated_addition_mismatch',
                location: location,
                message: 'Generated addition is incorrect or exceeds total 10.',
              ),
            );
          }
        }
      }
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  TeachingAuditReport _auditGeneratedWorld(NurseryContentPack pack) {
    const generator = NurseryPracticeGenerator();
    var checks = 0;
    final findings = <TeachingAuditFinding>[];

    for (final skillId in nurseryPhaseCWorldSkillIds) {
      final skill = pack.skillById(skillId);
      if (skill == null) continue;
      for (var seed = 0; seed < generatedSeedsPerSkill; seed += 1) {
        final practice =
            generator.generate(pack: pack, skill: skill, seed: seed);
        final location = '$skillId/seed:$seed';
        final answer = '${practice.correctResponseRule['value']}';

        checks += 1;
        final spokenNarration = nurserySpeakableText(practice.narration);
        if (spokenNarration.isEmpty ||
            nurseryContainsRawVisualToken(spokenNarration)) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.high,
              code: 'phase_c.world.generated_audio_not_normalized',
              location: location,
              message:
                  'Generated My World narration still depends on raw visual symbols.',
            ),
          );
        }

        final visual =
            practice.visualTokens.isEmpty ? null : practice.visualTokens.first;
        final expectedCatalog = nurseryPhaseCWorldGeneratedCatalog[skillId] ??
            nurseryPhaseCColourCatalog[skillId] ??
            nurseryPhaseCShapeCatalog[skillId];
        if (expectedCatalog != null) {
          checks += 1;
          final expected = visual == null ? null : expectedCatalog[visual];
          if (expected == null || expected != answer) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'phase_c.world.generated_visual_answer_mismatch',
                location: location,
                message:
                    'Visual $visual should map to $expected but scores $answer.',
              ),
            );
          }
        }

        for (final option in practice.options) {
          checks += 1;
          if (nurserySpokenLabel(option.label).trim().isEmpty) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.high,
                code: 'phase_c.world.generated_choice_missing_speech',
                location: '$location/${option.id}',
                message: 'Generated choice has no spoken equivalent.',
              ),
            );
          }
        }
      }
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  TeachingAuditReport _auditSequentialNonRepetition(NurseryContentPack pack) {
    const generator = NurseryPracticeGenerator();
    var checks = 0;
    final findings = <TeachingAuditFinding>[];

    for (final skill in pack.skills) {
      final requested = nurseryPhaseCNonRepeatWindow[skill.id];
      if (requested == null) {
        checks += 1;
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.high,
            code: 'phase_c.non_repeat.skill_not_referenced',
            location: skill.id,
            message:
                'No Phase-C non-repetition window is defined for this skill.',
          ),
        );
        continue;
      }
      final window = requested.clamp(2, 64).toInt();
      final signatures = <String>{};
      for (var seed = 0; seed < window; seed += 1) {
        final practice =
            generator.generate(pack: pack, skill: skill, seed: seed);
        final signature =
            '${practice.prompt}|${practice.correctResponseRule['value']}';
        checks += 1;
        if (!signatures.add(signature)) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.high,
              code: 'phase_c.non_repeat.early_repeat',
              location: '${skill.id}/seed:$seed',
              message:
                  'Generated practice repeated before the $window-item review window was exhausted.',
            ),
          );
          break;
        }
      }
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  int _countObjectsInText(String value) {
    const tokens = <String>['●', '★'];
    var count = 0;
    for (final token in tokens) {
      count += RegExp(RegExp.escape(token)).allMatches(value).length;
    }
    return count;
  }

  int _visualQuantity(Iterable<String> tokens) {
    var count = 0;
    for (final raw in tokens) {
      final token = raw.trim().toLowerCase();
      if (token.isEmpty ||
          token == '+' ||
          token == '=' ||
          token == 'matches' ||
          token == 'then' ||
          token == 'empty counting space') {
        continue;
      }
      final counted = RegExp(r'^(\d+)\s+[a-z][a-z ]*$').firstMatch(token);
      if (counted != null) {
        count += int.parse(counted.group(1)!);
      } else if (RegExp(r'^\d+$').hasMatch(token)) {
        // Standalone numerals are equation labels, not picture quantities.
        continue;
      } else {
        count += 1;
      }
    }
    return count;
  }

  int _dotQuantity(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'none' || normalized == 'empty group') return 0;
    final semantic = RegExp(r'^(\d+)\s+dots?$').firstMatch(normalized);
    if (semantic != null) return int.parse(semantic.group(1)!);
    return RegExp(RegExp.escape('●')).allMatches(value).length;
  }

  int? _objectAdditionFromVisualTokens(List<String> tokens) {
    final plus = tokens.indexOf('+');
    final equals = tokens.indexOf('=');
    final end = equals > plus ? equals : tokens.length;
    if (plus <= 0 || end <= plus) return null;
    final leftCount = _visualQuantity(tokens.take(plus));
    final rightCount =
        _visualQuantity(tokens.skip(plus + 1).take(end - plus - 1));
    if (leftCount == 0 || rightCount == 0) return null;
    return leftCount + rightCount;
  }

  int? _objectAdditionFromPrompt(String prompt) {
    final plus = prompt.indexOf('+');
    final equals = prompt.indexOf('=');
    if (plus <= 0 || equals <= plus) return null;
    final left = prompt.substring(0, plus);
    final right = prompt.substring(plus + 1, equals);
    final leftCount = _countObjectsInText(left);
    final rightCount = _countObjectsInText(right);
    if (leftCount == 0 || rightCount == 0) return null;
    return leftCount + rightCount;
  }
}

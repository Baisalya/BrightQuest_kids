import '../content/content_repository.dart';
import '../learning/activity_response_evaluator.dart';
import 'phase_e_legacy_reference.dart';
import 'phase_e_skill_reference.dart';

enum ClassCurriculumAuditSeverity { blocker, high, medium, low }

class ClassCurriculumAuditFinding {
  const ClassCurriculumAuditFinding({
    required this.severity,
    required this.code,
    required this.message,
  });

  final ClassCurriculumAuditSeverity severity;
  final String code;
  final String message;

  bool get releaseBlocking =>
      severity == ClassCurriculumAuditSeverity.blocker ||
      severity == ClassCurriculumAuditSeverity.high;

  @override
  String toString() => '[${severity.name.toUpperCase()}] $code · $message';
}

class ClassCurriculumHardeningReport {
  const ClassCurriculumHardeningReport({
    required this.checksRun,
    required this.findings,
    required this.constructedResponseGapIds,
  });

  final int checksRun;
  final List<ClassCurriculumAuditFinding> findings;
  final Set<String> constructedResponseGapIds;

  List<ClassCurriculumAuditFinding> get releaseBlockingFindings => findings
      .where((finding) => finding.releaseBlocking)
      .toList(growable: false);
}

/// Phase E's independent technical curriculum hardening audit.
///
/// This does not claim qualified-teacher approval. It verifies structural
/// coverage, scoring integrity, known ambiguity regressions, blueprint quality
/// and fail-closed treatment of productive constructed responses.
class ClassCurriculumHardeningAudit {
  const ClassCurriculumHardeningAudit();

  static const Set<String> constructedResponseCompetencies = <String>{
    'c3_eng_short_composition',
    'c5_eng_explain_justify',
  };

  static const List<String> _genericBlueprintPhrases = <String>[
    'Learn the idea in small steps:',
    'Use a new example to show that you can:',
    'Apply this idea in a different situation:',
    'Remember and explain one example of:',
  ];

  ClassCurriculumHardeningReport audit(ContentRepository repository) {
    final findings = <ClassCurriculumAuditFinding>[];
    var checks = 0;
    const evaluator = ActivityResponseEvaluator();
    final scorableCoverage = <String>{};

    void finding(
      ClassCurriculumAuditSeverity severity,
      String code,
      String message,
    ) {
      findings.add(ClassCurriculumAuditFinding(
        severity: severity,
        code: code,
        message: message,
      ));
    }

    for (final classNumber in const <int>[3, 4, 5]) {
      final contract = repository.curriculum.classPack(classNumber)!;
      final pack = repository.packForClass(classNumber);
      final studio = pack.activities
          .where((activity) => activity.gameId == 'skill_studio')
          .toList(growable: false);

      checks += 3;
      if (contract.competencies.length != 37) {
        finding(
          ClassCurriculumAuditSeverity.blocker,
          'phase_e.competency_count',
          'Class $classNumber must retain 37 curriculum competencies; found ${contract.competencies.length}.',
        );
      }
      if (pack.activities.length != 111) {
        finding(
          ClassCurriculumAuditSeverity.blocker,
          'phase_e.activity_count',
          'Class $classNumber must contain 63 legacy + 48 Skill Studio activities; found ${pack.activities.length}.',
        );
      }
      if (studio.length != 48) {
        finding(
          ClassCurriculumAuditSeverity.blocker,
          'phase_e.skill_studio_count',
          'Class $classNumber must contain 48 Phase-E Skill Studio activities; found ${studio.length}.',
        );
      }

      final studioPrompts = <String>{};
      for (final activity in studio) {
        checks += 9;
        if (!studioPrompts.add(activity.prompt.trim().toLowerCase())) {
          finding(
            ClassCurriculumAuditSeverity.high,
            'phase_e.duplicate_studio_prompt',
            '${activity.id} duplicates another Skill Studio prompt in Class $classNumber.',
          );
        }
        if (activity.status == 'approved') {
          finding(
            ClassCurriculumAuditSeverity.blocker,
            'phase_e.false_approval',
            '${activity.id} was marked approved without external teacher evidence.',
          );
        }
        if (activity.narrationText.trim().isEmpty ||
            activity.explanation.trim().isEmpty) {
          finding(
            ClassCurriculumAuditSeverity.blocker,
            'phase_e.missing_teaching_text',
            '${activity.id} needs narration and explanation text.',
          );
        }
        if (activity.payload['masteryEligible'] is! bool ||
            '${activity.payload['evidenceScope']}'.trim().isEmpty) {
          finding(
            ClassCurriculumAuditSeverity.blocker,
            'phase_e.evidence_contract',
            '${activity.id} must explicitly declare masteryEligible and evidenceScope.',
          );
        }

        final expected = phaseESkillExpectedAnswers[activity.id];
        if (expected == null ||
            activity.correctResponseRule['value'] != expected ||
            activity.payload['answer'] != expected) {
          finding(
            ClassCurriculumAuditSeverity.blocker,
            'phase_e.reference_drift',
            '${activity.id} answer drifted from the frozen Phase-E reference.',
          );
        }
        if (!evaluator.evaluate(activity, expected).correct) {
          finding(
            ClassCurriculumAuditSeverity.blocker,
            'phase_e.correct_rejected',
            '${activity.id} rejects its frozen correct response.',
          );
        }
        final choices = evaluator.choicesFor(activity);
        if (choices.length < 2 || choices.toSet().length != choices.length) {
          finding(
            ClassCurriculumAuditSeverity.blocker,
            'phase_e.choice_integrity',
            '${activity.id} must expose distinct answer choices.',
          );
        }
        for (final choice in choices) {
          if (choice == expected) continue;
          if (evaluator.evaluate(activity, choice).correct) {
            finding(
              ClassCurriculumAuditSeverity.blocker,
              'phase_e.distractor_accepted',
              '${activity.id} incorrectly accepts distractor $choice.',
            );
          }
        }

        final requiresCaseSensitiveScoring = <String>{
          'c3_eng_punctuation_capitals',
          'c4_eng_punctuation',
          'c5_eng_punctuation_editing',
        }.contains(activity.competencyId);
        if (requiresCaseSensitiveScoring &&
            activity.correctResponseRule['type'] != 'exactTextCaseSensitive') {
          finding(
            ClassCurriculumAuditSeverity.blocker,
            'phase_e.case_sensitive_editing',
            '${activity.id} must preserve case because capitalization/editing is part of the scored skill.',
          );
        }

        final expectedPracticeOnly =
            constructedResponseCompetencies.contains(activity.competencyId);
        if (expectedPracticeOnly &&
            activity.payload['masteryEligible'] != false) {
          finding(
            ClassCurriculumAuditSeverity.blocker,
            'phase_e.constructed_response_false_mastery',
            '${activity.id} must stay practice-only until a constructed response is externally reviewed.',
          );
        }
        if (!expectedPracticeOnly &&
            activity.payload['masteryEligible'] == false) {
          finding(
            ClassCurriculumAuditSeverity.high,
            'phase_e.unexpected_practice_only',
            '${activity.id} unexpectedly disables scorable mastery evidence.',
          );
        }
      }

      for (final competency in contract.competencies) {
        checks += 5;
        final activities = repository.activitiesForCompetency(
          classNumber,
          competency.id,
        );
        if (activities.isEmpty) {
          finding(
            ClassCurriculumAuditSeverity.blocker,
            'phase_e.no_activity',
            '${competency.id} has no authored activity.',
          );
          continue;
        }
        final masteryEligible = activities
            .where((activity) => activity.payload['masteryEligible'] != false)
            .toList(growable: false);
        if (masteryEligible.isNotEmpty) scorableCoverage.add(competency.id);

        final blueprint =
            repository.learningBlueprintForCompetency(competency.id);
        if (blueprint == null) {
          finding(
            ClassCurriculumAuditSeverity.blocker,
            'phase_e.missing_blueprint',
            '${competency.id} has no learning blueprint.',
          );
          continue;
        }
        if (blueprint.review.status.name == 'approved') {
          finding(
            ClassCurriculumAuditSeverity.blocker,
            'phase_e.blueprint_false_approval',
            '${competency.id} blueprint was marked approved without external sign-off.',
          );
        }
        final blueprintText = <String>[
          blueprint.teach,
          blueprint.workedExample,
          blueprint.guidedPrompt,
          blueprint.independentFallbackPrompt,
          blueprint.transferPrompt,
          blueprint.reviewPrompt,
          blueprint.narrationText,
        ].join('\n');
        for (final phrase in _genericBlueprintPhrases) {
          if (blueprintText.contains(phrase)) {
            finding(
              ClassCurriculumAuditSeverity.high,
              'phase_e.generic_blueprint',
              '${competency.id} still contains the old generic blueprint phrase "$phrase".',
            );
          }
        }
        checks += 1;
        if (blueprintText.toLowerCase().contains('draft class') ||
            blueprintText.toLowerCase().contains('draft range')) {
          finding(
            ClassCurriculumAuditSeverity.medium,
            'phase_e.child_facing_internal_jargon',
            '${competency.id} exposes internal draft/review jargon in child-facing teaching text.',
          );
        }
        if (blueprint.independentSourceActivityIds.isEmpty) {
          finding(
            ClassCurriculumAuditSeverity.high,
            'phase_e.empty_independent_source',
            '${competency.id} has no authored independent-practice source.',
          );
        }
        for (final id in blueprint.independentSourceActivityIds) {
          final source = repository.activityById(id);
          if (source == null || source.classNumber != classNumber) {
            finding(
              ClassCurriculumAuditSeverity.blocker,
              'phase_e.invalid_blueprint_source',
              '${competency.id} references invalid source activity $id.',
            );
            continue;
          }
          if (!constructedResponseCompetencies.contains(competency.id) &&
              source.payload['masteryEligible'] == false) {
            finding(
              ClassCurriculumAuditSeverity.high,
              'phase_e.non_scorable_blueprint_source',
              '${competency.id} points to a practice-only source $id.',
            );
          }
        }
      }
    }

    checks += phaseESkillExpectedAnswers.length;
    final actualStudioIds = repository.allActivities
        .where((activity) => activity.gameId == 'skill_studio')
        .map((activity) => activity.id)
        .toSet();
    if (phaseESkillExpectedAnswers.length != 144 ||
        actualStudioIds.length != 144 ||
        !actualStudioIds.containsAll(phaseESkillExpectedAnswers.keys) ||
        !phaseESkillExpectedAnswers.keys.toSet().containsAll(actualStudioIds)) {
      finding(
        ClassCurriculumAuditSeverity.blocker,
        'phase_e.reference_inventory',
        'The frozen Skill Studio answer inventory must exactly match 144 authored activities.',
      );
    }

    const expectedC3MathExplanation =
        '125 + 75 = 125 + 25 + 50 = 150 + 50 = 200.';
    checks += 1;
    if (repository.activityById('c3_math_market_q04')?.explanation !=
        expectedC3MathExplanation) {
      finding(
        ClassCurriculumAuditSeverity.high,
        'phase_e.c3_math_explanation_regression',
        'Class 3 addition must show the complete bridge-to-150 reasoning.',
      );
    }

    for (final entry in phaseEGrammarSentences.entries) {
      checks += 1;
      if (repository.activityById(entry.key)?.payload['sentence'] !=
          entry.value) {
        finding(
          ClassCurriculumAuditSeverity.high,
          'phase_e.grammar_ambiguity_regression',
          '${entry.key} drifted from the independently reviewed single-target grammar sentence.',
        );
      }
    }

    for (final entry in phaseELegacyFactAnswers.entries) {
      checks += 2;
      final activity = repository.activityById(entry.key);
      if (activity == null ||
          activity.correctResponseRule['value'] != entry.value) {
        finding(
          ClassCurriculumAuditSeverity.blocker,
          'phase_e.legacy_fact_answer_drift',
          '${entry.key} drifted from the Phase-E science/map factual answer reference.',
        );
      } else if (!evaluator.evaluate(activity, entry.value).correct) {
        finding(
          ClassCurriculumAuditSeverity.blocker,
          'phase_e.legacy_fact_rejected',
          '${entry.key} rejects its independently reviewed factual answer.',
        );
      }
    }

    for (final entry in phaseEScienceReactionIngredients.entries) {
      checks += 1;
      final activity = repository.activityById(entry.key);
      final raw = activity?.payload['requiredIngredients'];
      final actual = raw is List ? raw.whereType<String>().toSet() : <String>{};
      final expected = entry.value.toSet();
      if (activity == null ||
          actual.length != expected.length ||
          !actual.containsAll(expected)) {
        finding(
          ClassCurriculumAuditSeverity.blocker,
          'phase_e.science_reaction_drift',
          '${entry.key} changed its reviewed virtual reaction ingredients.',
        );
      }
    }

    for (final activity in repository.allActivities.where(
      (activity) => activity.gameId == 'recycling_challenge',
    )) {
      checks += 1;
      if (!activity.explanation
          .contains('Real local recycling rules can differ.')) {
        finding(
          ClassCurriculumAuditSeverity.high,
          'phase_e.recycling_local_rule',
          '${activity.id} must not present a BrightQuest material group as a universal recycling rule.',
        );
      }
    }

    final missingScorable = repository.curriculum.classes
        .expand((classContract) => classContract.competencies)
        .map((competency) => competency.id)
        .where((id) => !scorableCoverage.contains(id))
        .toSet();
    checks += 1;
    if (missingScorable.length != 2 ||
        !missingScorable.containsAll(constructedResponseCompetencies)) {
      finding(
        ClassCurriculumAuditSeverity.blocker,
        'phase_e.scorable_gap_contract',
        'Exactly the two productive constructed-response competencies must remain outside automatic mastery; found ${missingScorable.join(', ')}.',
      );
    }

    return ClassCurriculumHardeningReport(
      checksRun: checks,
      findings: List<ClassCurriculumAuditFinding>.unmodifiable(findings),
      constructedResponseGapIds: Set<String>.unmodifiable(missingScorable),
    );
  }
}

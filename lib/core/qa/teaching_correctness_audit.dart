import '../content/content_activity.dart';
import '../content/content_generators.dart';
import '../content/content_repository.dart';
import '../content/game_content.dart';
import '../gameplay/game_logic.dart';
import '../learning/activity_response_evaluator.dart';
import '../nursery/nursery_content.dart';
import '../nursery/nursery_practice_generator.dart';
import '../nursery/nursery_response_evaluator.dart';

enum TeachingAuditSeverity { blocker, high, medium, low }

class TeachingAuditFinding {
  const TeachingAuditFinding({
    required this.severity,
    required this.code,
    required this.location,
    required this.message,
  });

  final TeachingAuditSeverity severity;
  final String code;
  final String location;
  final String message;

  bool get releaseBlocking =>
      severity == TeachingAuditSeverity.blocker ||
      severity == TeachingAuditSeverity.high;

  @override
  String toString() =>
      '[${severity.name.toUpperCase()}] $code · $location · $message';
}

class TeachingAuditReport {
  const TeachingAuditReport({
    required this.checksRun,
    required this.findings,
  });

  final int checksRun;
  final List<TeachingAuditFinding> findings;

  bool get hasReleaseBlockingFindings =>
      findings.any((finding) => finding.releaseBlocking);

  int count(TeachingAuditSeverity severity) =>
      findings.where((finding) => finding.severity == severity).length;

  TeachingAuditReport merge(TeachingAuditReport other) => TeachingAuditReport(
        checksRun: checksRun + other.checksRun,
        findings: List<TeachingAuditFinding>.unmodifiable(
          <TeachingAuditFinding>[...findings, ...other.findings],
        ),
      );

  static const empty = TeachingAuditReport(
    checksRun: 0,
    findings: <TeachingAuditFinding>[],
  );
}

/// Deterministic, side-effect-free correctness audit for authored and generated
/// BrightQuest learning content.
///
/// This is deliberately stricter than UI smoke testing. A question is only
/// considered healthy when its rule accepts the authored answer, rejects its
/// distractors, generated choices are bounded and unique, and the explanation
/// shown to a learner is consistent with the answer that was actually scored.
class TeachingCorrectnessAudit {
  const TeachingCorrectnessAudit({
    this.generatedSeedsPerSkill = 128,
    this.generatedSeedsPerClassFamily = 128,
  });

  final int generatedSeedsPerSkill;
  final int generatedSeedsPerClassFamily;

  TeachingAuditReport auditRepository(ContentRepository repository) {
    var report = _auditClassActivities(repository.allActivities);
    report = report.merge(_auditClassGenerators());
    final nursery = repository.nurseryPack;
    if (nursery != null) {
      report = report.merge(auditNurseryPack(nursery));
    }
    return report;
  }

  TeachingAuditReport auditNurseryActivity({
    required NurserySkill skill,
    required NurseryActivity activity,
  }) =>
      _auditNurseryActivity(
        skill: skill,
        activity: activity,
        evaluator: const NurseryResponseEvaluator(),
      );

  TeachingAuditReport auditClassActivity(ContentActivity activity) =>
      _auditClassActivities(<ContentActivity>[activity]);

  TeachingAuditReport auditNurseryPack(
    NurseryContentPack pack, {
    bool Function(NurserySkill skill)? includeSkill,
  }) {
    var checks = 0;
    final findings = <TeachingAuditFinding>[];
    const evaluator = NurseryResponseEvaluator();
    const generator = NurseryPracticeGenerator();

    for (final letter in pack.letterAssociations) {
      for (final example in letter.examples) {
        checks += 1;
        final firstLetter = _firstAlphabeticCharacter(example.word);
        if ((example.beginningSoundEligible || example.soundPracticeEligible) &&
            firstLetter != letter.uppercase) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'nursery.phonics.eligible_word_mismatch',
              location: '${letter.uppercase}/${example.word}',
              message:
                  'The example is eligible for sound evidence but its first alphabetic letter is $firstLetter, not ${letter.uppercase}.',
            ),
          );
        }

        checks += 1;
        if (example.beginningSoundEligible &&
            !example.displayPhrase.toUpperCase().contains(letter.uppercase)) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.high,
              code: 'nursery.phonics.display_phrase_mismatch',
              location: '${letter.uppercase}/${example.word}',
              message:
                  'Beginning-sound evidence is enabled but the visible phrase does not identify ${letter.uppercase}.',
            ),
          );
        }
      }
    }

    for (final skill in pack.skills) {
      if (includeSkill != null && !includeSkill(skill)) continue;
      final activities = pack.activitiesForSkill(skill.id);
      for (final activity in activities) {
        final result = _auditNurseryActivity(
          skill: skill,
          activity: activity,
          evaluator: evaluator,
        );
        checks += result.checksRun;
        findings.addAll(result.findings);
      }

      for (var seed = 0; seed < generatedSeedsPerSkill; seed += 1) {
        final first = generator.generate(pack: pack, skill: skill, seed: seed);
        final second = generator.generate(pack: pack, skill: skill, seed: seed);
        final result = _auditGeneratedNurseryPractice(
          skill: skill,
          practice: first,
          repeat: second,
          evaluator: evaluator,
        );
        checks += result.checksRun;
        findings.addAll(result.findings);
      }
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  TeachingAuditReport _auditNurseryActivity({
    required NurserySkill skill,
    required NurseryActivity activity,
    required NurseryResponseEvaluator evaluator,
  }) {
    var checks = 0;
    final findings = <TeachingAuditFinding>[];
    final location = '${skill.id}/${activity.id}';
    final correct = _nurseryCorrectResponse(activity.correctResponseRule);

    checks += 1;
    if (!evaluator.evaluate(activity, correct).correct) {
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.blocker,
          code: 'nursery.authored.correct_answer_rejected',
          location: location,
          message:
              'The authored correct response ${evaluator.responseLabel(correct)} is rejected by the response evaluator.',
        ),
      );
    }

    if (activity.correctResponseRule['type'] == 'choice') {
      final correctId = '${activity.correctResponseRule['value']}';
      final ids = activity.options.map((option) => option.id).toList();
      final labels = activity.options.map((option) => option.label).toList();

      checks += 1;
      if (ids.length != ids.toSet().length ||
          labels.map((value) => value.trim()).toSet().length != labels.length) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.authored.duplicate_choice',
            location: location,
            message: 'Choice IDs or visible labels are duplicated.',
          ),
        );
      }

      checks += 1;
      if (!ids.contains(correctId)) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.authored.answer_missing_from_choices',
            location: location,
            message: 'Correct answer $correctId is not present in the choices.',
          ),
        );
      }

      for (final option
          in activity.options.where((item) => item.id != correctId)) {
        checks += 1;
        if (evaluator.evaluate(activity, option.id).correct) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'nursery.authored.distractor_accepted',
              location: location,
              message: 'Distractor ${option.id} is incorrectly accepted.',
            ),
          );
        }
      }
    } else {
      final wrong = _nurseryKnownWrongResponse(activity.correctResponseRule);
      if (wrong != null) {
        checks += 1;
        if (evaluator.evaluate(activity, wrong).correct) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'nursery.authored.wrong_response_accepted',
              location: location,
              message: 'A known-wrong response is accepted by the evaluator.',
            ),
          );
        }
      }
    }

    checks += 1;
    final explanation = evaluator.explanationFor(activity);
    final correctLabel = evaluator.correctResponseLabel(activity);
    if (explanation.text.trim().isEmpty) {
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.high,
          code: 'nursery.explanation.empty',
          location: location,
          message: 'A scored activity has no learner-facing explanation.',
        ),
      );
    } else if (activity.correctResponseRule['type'] == 'choice' &&
        !_containsWholeToken(explanation.text, correctLabel) &&
        !explanation.visualTokens.any(
          (token) => token.trim().toLowerCase() == correctLabel.toLowerCase(),
        )) {
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.blocker,
          code: 'nursery.explanation.answer_mismatch',
          location: location,
          message:
              'Explanation "${explanation.text}" does not identify the scored answer $correctLabel.',
        ),
      );
    }

    checks += 1;
    if (activity.narration.trim().isEmpty || activity.prompt.trim().isEmpty) {
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.high,
          code: 'nursery.authored.missing_instruction',
          location: location,
          message: 'Prompt or visible-equivalent narration is empty.',
        ),
      );
    }

    final pedagogic = _auditAuthoredNurseryPedagogy(activity, evaluator);
    checks += pedagogic.checksRun;
    findings.addAll(pedagogic.findings);

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  TeachingAuditReport _auditGeneratedNurseryPractice({
    required NurserySkill skill,
    required NurseryGeneratedPractice practice,
    required NurseryGeneratedPractice repeat,
    required NurseryResponseEvaluator evaluator,
  }) {
    var checks = 0;
    final findings = <TeachingAuditFinding>[];
    final location = '${skill.id}/seed:${practice.seed}';

    checks += 1;
    if (!_sameGeneratedPractice(practice, repeat)) {
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.blocker,
          code: 'nursery.generated.non_deterministic',
          location: location,
          message: 'The same skill and seed produced different practice.',
        ),
      );
    }

    checks += 1;
    if (practice.skillId != skill.id) {
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.blocker,
          code: 'nursery.generated.skill_mismatch',
          location: location,
          message:
              'Generated practice is recorded against ${practice.skillId} instead of ${skill.id}.',
        ),
      );
    }

    final answer = practice.correctResponseRule['value'];
    final optionIds = practice.options.map((option) => option.id).toList();
    final normalizedLabels =
        practice.options.map((option) => option.label.trim()).toList();

    checks += 1;
    if (optionIds.length < 2 ||
        optionIds.length != optionIds.toSet().length ||
        normalizedLabels.length != normalizedLabels.toSet().length) {
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.blocker,
          code: 'nursery.generated.invalid_choices',
          location: location,
          message: 'Generated choices are missing or duplicated.',
        ),
      );
    }

    checks += 1;
    if (!optionIds.contains('$answer')) {
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.blocker,
          code: 'nursery.generated.answer_missing_from_choices',
          location: location,
          message: 'Generated answer $answer is not present in the choices.',
        ),
      );
    }

    checks += 1;
    if (!evaluator.evaluateGenerated(practice, answer).correct) {
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.blocker,
          code: 'nursery.generated.correct_answer_rejected',
          location: location,
          message: 'Generated correct answer $answer is rejected.',
        ),
      );
    }

    for (final option
        in practice.options.where((item) => item.id != '$answer')) {
      checks += 1;
      if (evaluator.evaluateGenerated(practice, option.id).correct) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.generated.distractor_accepted',
            location: location,
            message: 'Generated distractor ${option.id} is accepted.',
          ),
        );
      }
    }

    checks += 1;
    if (practice.explanation.trim().isEmpty ||
        practice.prompt.trim().isEmpty ||
        practice.narration.trim().isEmpty) {
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.high,
          code: 'nursery.generated.missing_teaching_text',
          location: location,
          message: 'Generated prompt, narration, or explanation is empty.',
        ),
      );
    }

    final pedagogic = _auditGeneratedNurseryPedagogy(skill, practice);
    checks += pedagogic.checksRun;
    findings.addAll(pedagogic.findings);

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  TeachingAuditReport _auditAuthoredNurseryPedagogy(
    NurseryActivity activity,
    NurseryResponseEvaluator evaluator,
  ) {
    if (activity.correctResponseRule['type'] != 'choice') {
      return TeachingAuditReport.empty;
    }
    var checks = 0;
    final findings = <TeachingAuditFinding>[];
    final prompt = activity.prompt;
    final answer = evaluator.correctResponseLabel(activity);
    final location = activity.id;

    void expectAnswer(String expected, String code, String reason) {
      checks += 1;
      if (answer.trim() != expected.trim()) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: code,
            location: location,
            message:
                '$reason Expected $expected but the scored answer is $answer.',
          ),
        );
      }
    }

    final signFirstLetter = RegExp(
      r'\bsign\s+says\s+([A-Za-z]+).*\bfirst\s+letter\b',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (signFirstLetter != null) {
      final word = signFirstLetter.group(1)!;
      expectAnswer(
        _firstAlphabeticCharacter(word),
        'nursery.authored.first_letter_answer_mismatch',
        '$word has a different first letter.',
      );
    }

    final directBeginning = RegExp(
      r'\bWhich\s+letter\s+(?:starts|begins)\s+([A-Za-z]+)',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (directBeginning != null) {
      final word = directBeginning.group(1)!;
      expectAnswer(
        _firstAlphabeticCharacter(word),
        'nursery.authored.beginning_letter_answer_mismatch',
        '$word has a different beginning letter.',
      );
    }

    final smallBeginning = RegExp(
      r'\bword\s+([A-Za-z]+)\s+begins\s+with\s+which\s+small\s+letter',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (smallBeginning != null) {
      final word = smallBeginning.group(1)!;
      expectAnswer(
        _firstAlphabeticCharacter(word).toLowerCase(),
        'nursery.authored.small_beginning_letter_answer_mismatch',
        '$word has a different lowercase beginning letter.',
      );
    }

    final explicitNumber = RegExp(
      r'\b(?:tap|find)\s+the\s+number\s+(\d+)\b',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (explicitNumber != null) {
      expectAnswer(
        explicitNumber.group(1)!,
        'nursery.authored.number_prompt_answer_mismatch',
        'The prompt explicitly names a different number.',
      );
    }

    final explicitNumeral = RegExp(
      r'\bWhich\s+numeral\s+is\s+(\d+)\b',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (explicitNumeral != null) {
      expectAnswer(
        explicitNumeral.group(1)!,
        'nursery.authored.numeral_prompt_answer_mismatch',
        'The prompt explicitly names a different numeral.',
      );
    }

    final afterNumber = RegExp(
      r'\bnumber\s+comes\s+after\s+(\d+)\b',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (afterNumber != null) {
      expectAnswer(
        '${int.parse(afterNumber.group(1)!) + 1}',
        'nursery.authored.next_number_answer_mismatch',
        'The next-number sequence is inconsistent.',
      );
    }

    final numericAddition =
        RegExp(r'\b(\d+)\s*\+\s*(\d+)\s*=').firstMatch(prompt);
    if (numericAddition != null) {
      expectAnswer(
        '${int.parse(numericAddition.group(1)!) + int.parse(numericAddition.group(2)!)}',
        'nursery.authored.addition_answer_mismatch',
        'The arithmetic expression has a different sum.',
      );
    }

    if (prompt.toLowerCase().contains('what is missing?')) {
      final blankAtEnd =
          RegExp(r'(\d+)\s*,\s*(\d+)\s*,\s*__').firstMatch(prompt);
      final blankInMiddle =
          RegExp(r'(\d+)\s*,\s*__\s*,\s*(\d+)').firstMatch(prompt);
      final blankBeforeLast = RegExp(
        r'(\d+)\s*,\s*(\d+)\s*,\s*__\s*,\s*(\d+)',
      ).firstMatch(prompt);

      if (blankBeforeLast != null) {
        final first = int.parse(blankBeforeLast.group(1)!);
        final second = int.parse(blankBeforeLast.group(2)!);
        final last = int.parse(blankBeforeLast.group(3)!);
        if (second == first + 1 && last == second + 2) {
          expectAnswer(
            '${second + 1}',
            'nursery.authored.sequence_answer_mismatch',
            'The consecutive-number sequence has a different missing value.',
          );
        }
      } else if (blankInMiddle != null) {
        final first = int.parse(blankInMiddle.group(1)!);
        final last = int.parse(blankInMiddle.group(2)!);
        if (last == first + 2) {
          expectAnswer(
            '${first + 1}',
            'nursery.authored.sequence_answer_mismatch',
            'The consecutive-number sequence has a different missing value.',
          );
        }
      } else if (blankAtEnd != null) {
        final first = int.parse(blankAtEnd.group(1)!);
        final second = int.parse(blankAtEnd.group(2)!);
        if (second == first + 1) {
          expectAnswer(
            '${second + 1}',
            'nursery.authored.sequence_answer_mismatch',
            'The consecutive-number sequence has a different missing value.',
          );
        }
      }
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  TeachingAuditReport _auditGeneratedNurseryPedagogy(
    NurserySkill skill,
    NurseryGeneratedPractice practice,
  ) {
    var checks = 0;
    final findings = <TeachingAuditFinding>[];
    final location = '${skill.id}/seed:${practice.seed}';
    final answer = '${practice.correctResponseRule['value']}';

    if (skill.generatorFamily == 'letterChoice') {
      checks += 1;
      final match = RegExp(
        r'Find\s+(lowercase|uppercase)\s+([A-Za-z])',
        caseSensitive: false,
      ).firstMatch(practice.prompt);
      if (match == null || match.group(2) != answer) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.alphabet.letter_choice_answer_mismatch',
            location: location,
            message:
                'Letter-choice prompt and scored answer disagree ($answer).',
          ),
        );
      }
    }

    if (skill.generatorFamily == 'caseMatch') {
      checks += 1;
      final match = RegExp(
        r'small\s+letter\s+matches\s+big\s+([A-Z])',
        caseSensitive: false,
      ).firstMatch(practice.prompt);
      final expected = match?.group(1)?.toLowerCase();
      if (expected == null || expected != answer) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.alphabet.case_match_answer_mismatch',
            location: location,
            message:
                'Upper/lowercase matching prompt scores $answer incorrectly.',
          ),
        );
      }
    }

    if (skill.generatorFamily == 'listenLetter') {
      checks += 1;
      final match = RegExp(
        r'find\s+letter\s+([A-Z])',
        caseSensitive: false,
      ).firstMatch(practice.prompt);
      if (match == null || match.group(1)! != answer) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.alphabet.listen_letter_answer_mismatch',
            location: location,
            message:
                'Listen-and-select prompt and scored answer disagree ($answer).',
          ),
        );
      }
    }

    if (skill.generatorFamily == 'counting') {
      checks += 1;
      final numericAnswer = int.tryParse(answer);
      final zeroVisual = practice.prompt.toLowerCase().contains('no objects') ||
          practice.prompt.toLowerCase().contains('empty counting space') ||
          (practice.visualTokens.length == 1 &&
              practice.visualTokens.single == 'empty counting space');
      final recomputed = zeroVisual
          ? 0
          : practice.visualTokens
              .where((token) => token != '0' && token != 'empty counting space')
              .length;
      if (numericAnswer == null || recomputed != numericAnswer) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.math.counting_answer_mismatch',
            location: location,
            message:
                'Counting visual has $recomputed objects but the scored answer is $answer.',
          ),
        );
      }
    }

    if (skill.generatorFamily == 'numberQuantity') {
      checks += 1;
      final match = RegExp(
        r'group\s+shows\s+(\d+)\s+objects',
        caseSensitive: false,
      ).firstMatch(practice.prompt);
      final expectedCount = match == null ? null : int.parse(match.group(1)!);
      final answerCount = _nurseryQuantityAnswerCount(answer);
      if (expectedCount == null || expectedCount != answerCount) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.math.number_quantity_answer_mismatch',
            location: location,
            message:
                'Quantity prompt expects $expectedCount objects but answer represents $answerCount.',
          ),
        );
      }
    }

    if (skill.generatorFamily == 'comparison') {
      checks += 1;
      final sameMatch = RegExp(
        r'Are\s+(\d+)\s+and\s+(\d+)\s+the\s+same\s+or\s+different',
        caseSensitive: false,
      ).firstMatch(practice.prompt);
      final compareMatch = RegExp(
        r'Which\s+number\s+is\s+(more|less):\s*(\d+)\s+or\s+(\d+)',
        caseSensitive: false,
      ).firstMatch(practice.prompt);
      String? expected;
      if (sameMatch != null) {
        final left = int.parse(sameMatch.group(1)!);
        final right = int.parse(sameMatch.group(2)!);
        expected = left == right ? 'same' : 'different';
      } else if (compareMatch != null) {
        final left = int.parse(compareMatch.group(2)!);
        final right = int.parse(compareMatch.group(3)!);
        expected = compareMatch.group(1)!.toLowerCase() == 'more'
            ? '${left > right ? left : right}'
            : '${left < right ? left : right}';
      }
      if (expected == null || expected.toLowerCase() != answer.toLowerCase()) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.math.comparison_answer_mismatch',
            location: location,
            message: 'Comparison prompt and scored answer disagree ($answer).',
          ),
        );
      }
    }

    if (skill.generatorFamily == 'addition') {
      checks += 1;
      final numericAnswer = int.tryParse(answer);
      final match = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(practice.prompt);
      int? recomputed;
      if (match != null) {
        recomputed = int.parse(match.group(1)!) + int.parse(match.group(2)!);
      } else if (skill.id == 'math_add_objects') {
        final plusIndex = practice.visualTokens.indexOf('+');
        final equalsIndex = practice.visualTokens.indexOf('=');
        if (plusIndex > 0 && equalsIndex > plusIndex) {
          final left = practice.visualTokens.take(plusIndex).length;
          final right = practice.visualTokens
              .skip(plusIndex + 1)
              .take(equalsIndex - plusIndex - 1)
              .length;
          recomputed = left + right;
        }
      }
      if (recomputed == null || recomputed != numericAnswer) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.math.addition_answer_mismatch',
            location: location,
            message:
                'The generated addition prompt/visual does not mathematically equal answer $answer.',
          ),
        );
      }
      checks += 1;
      if (numericAnswer == null || numericAnswer < 0 || numericAnswer > 10) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.math.addition_out_of_range',
            location: location,
            message: 'Early addition answer $answer is outside 0–10.',
          ),
        );
      }
    }

    if (skill.generatorFamily == 'missingNumber') {
      checks += 1;
      final match =
          RegExp(r'(\d+)\s*,\s*__\s*,\s*(\d+)').firstMatch(practice.prompt);
      if (match == null ||
          int.parse(match.group(1)!) + 1 != int.tryParse(answer) ||
          int.parse(match.group(2)!) - 1 != int.tryParse(answer)) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.math.sequence_answer_mismatch',
            location: location,
            message:
                'Missing-number answer $answer does not complete the sequence.',
          ),
        );
      }
    }

    if (skill.generatorFamily == 'numberRecognition') {
      checks += 1;
      final match = RegExp(r'number\s+(\d+)', caseSensitive: false)
          .firstMatch(practice.prompt);
      if (match == null || match.group(1) != answer) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'nursery.math.number_prompt_mismatch',
            location: location,
            message:
                'Number-recognition prompt and scored answer disagree ($answer).',
          ),
        );
      }
    }

    if (skill.generatorFamily == 'wordPicture') {
      checks += 1;
      if (practice.visualTokens.isEmpty) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.high,
            code: 'nursery.alphabet.word_picture_missing_visual',
            location: location,
            message: 'Word-picture practice has no visual token.',
          ),
        );
      } else {
        final letter = practice.visualTokens.first.trim().toUpperCase();
        final firstLetter = _firstAlphabeticCharacter(answer);
        if (letter.length == 1 && firstLetter != letter) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'nursery.alphabet.word_picture_letter_mismatch',
              location: location,
              message: '$answer does not start with displayed letter $letter.',
            ),
          );
        }
      }
    }

    if (skill.generatorFamily == 'beginningSound') {
      checks += 1;
      final match = RegExp(
        r'Which letter begins\s+([^?]+)',
        caseSensitive: false,
      ).firstMatch(practice.prompt);
      if (match != null) {
        final word = match.group(1)!.trim();
        final firstLetter = _firstAlphabeticCharacter(word);
        if (firstLetter != answer.toUpperCase()) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'nursery.phonics.beginning_sound_answer_mismatch',
              location: location,
              message:
                  '$word begins with $firstLetter but the scored answer is $answer.',
            ),
          );
        }
      }
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  int? _nurseryQuantityAnswerCount(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'empty group' || normalized == 'none') return 0;
    final semantic = RegExp(r'^(\d+)\s+dots?$').firstMatch(normalized);
    if (semantic != null) return int.parse(semantic.group(1)!);
    final legacyDots = RegExp(RegExp.escape('●')).allMatches(value).length;
    return legacyDots > 0 ? legacyDots : null;
  }

  TeachingAuditReport _auditClassActivities(
    Iterable<ContentActivity> activities,
  ) {
    var checks = 0;
    final findings = <TeachingAuditFinding>[];
    const evaluator = ActivityResponseEvaluator();

    for (final activity in activities) {
      final location = 'class-${activity.classNumber}/${activity.id}';
      final correct = _classCorrectResponse(activity);
      if (activity.correctResponseRule['type'] == 'reachGridGoal' &&
          correct == null) {
        checks += 1;
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'class.authored.coding_goal_unreachable',
            location: location,
            message:
                'No bounded command sequence reaches the authored coding goal.',
          ),
        );
      } else if (correct != null) {
        checks += 1;
        if (!evaluator.evaluate(activity, correct).correct) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'class.authored.correct_answer_rejected',
              location: location,
              message:
                  'The authored correct response is rejected by the shared evaluator.',
            ),
          );
        }
      }

      for (final distractor in activity.distractors) {
        checks += 1;
        if (evaluator.evaluate(activity, distractor.value).correct) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'class.authored.distractor_accepted',
              location: location,
              message: 'Distractor ${distractor.value} is accepted as correct.',
            ),
          );
        }
      }

      checks += 1;
      if (activity.prompt.trim().isEmpty ||
          activity.explanation.trim().isEmpty ||
          activity.narrationText.trim().isEmpty) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.high,
            code: 'class.authored.missing_teaching_text',
            location: location,
            message: 'Prompt, explanation, or narration is empty.',
          ),
        );
      }

      if (activity.correctResponseRule['type'] == 'exactText') {
        final choices = evaluator.choicesFor(activity);
        final normalized =
            choices.map((value) => '$value'.trim().toLowerCase()).toList();
        checks += 1;
        if (choices.isEmpty ||
            !normalized.contains(
              '${activity.correctResponseRule['value']}'.trim().toLowerCase(),
            )) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'class.authored.answer_missing_from_choices',
              location: location,
              message: 'Exact-text answer is absent from displayed choices.',
            ),
          );
        }
        checks += 1;
        if (normalized.length != normalized.toSet().length) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'class.authored.duplicate_choices',
              location: location,
              message: 'Displayed exact-text choices contain duplicates.',
            ),
          );
        }
      }

      final pedagogic = _auditAuthoredClassPedagogy(activity);
      checks += pedagogic.checksRun;
      findings.addAll(pedagogic.findings);
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  TeachingAuditReport _auditAuthoredClassPedagogy(
    ContentActivity activity,
  ) {
    var checks = 0;
    final findings = <TeachingAuditFinding>[];
    final location = 'class-${activity.classNumber}/${activity.id}';
    final rule = activity.correctResponseRule;
    final type = '${rule['type']}';

    void mismatch(String code, String message) {
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.blocker,
          code: code,
          location: location,
          message: message,
        ),
      );
    }

    if (activity.gameId == 'math_market' && type == 'exactNumber') {
      checks += 1;
      final expected = _solveArithmeticPrompt(activity.prompt);
      final scored = (rule['value'] as num?)?.toInt();
      if (expected == null || scored != expected) {
        mismatch(
          'class.authored.arithmetic_answer_mismatch',
          '${activity.prompt} scores $scored, but independent recomputation gives $expected.',
        );
      }

      checks += 1;
      final payloadAnswer = (activity.payload['answer'] as num?)?.toInt();
      if (payloadAnswer != scored) {
        mismatch(
          'class.authored.arithmetic_payload_drift',
          'Math payload answer $payloadAnswer disagrees with rule answer $scored.',
        );
      }
    }

    if (activity.gameId == 'fraction_pizza' && type == 'selectedSlices') {
      checks += 1;
      final total = (activity.payload['totalSlices'] as num?)?.toInt();
      final numerator = (activity.payload['numerator'] as num?)?.toInt();
      final denominator = (activity.payload['denominator'] as num?)?.toInt();
      final scored = (rule['value'] as num?)?.toInt();
      int? expected;
      if (total != null &&
          numerator != null &&
          denominator != null &&
          denominator > 0 &&
          (total * numerator) % denominator == 0) {
        expected = (total * numerator) ~/ denominator;
      }
      if (expected == null || scored != expected) {
        mismatch(
          'class.authored.fraction_answer_mismatch',
          'Fraction ${numerator ?? '?'} / ${denominator ?? '?'} of ${total ?? '?'} slices should select $expected slices, not $scored.',
        );
      }

      checks += 1;
      final ruleTotal = (rule['totalSlices'] as num?)?.toInt();
      if (ruleTotal != total) {
        mismatch(
          'class.authored.fraction_total_drift',
          'Fraction rule totalSlices $ruleTotal disagrees with payload totalSlices $total.',
        );
      }
    }

    if (activity.gameId == 'story_builder' && type == 'orderedWords') {
      checks += 1;
      final ordered =
          (rule['value'] as List?)?.map((value) => '$value').toList();
      final payloadWords = (activity.payload['words'] as List?)
          ?.map((value) => '$value')
          .toList();
      final promptWords = _wordTokens(activity.prompt);
      if (ordered == null ||
          payloadWords == null ||
          !_sameStringList(ordered, payloadWords) ||
          !_sameStringList(
            ordered.map((value) => value.toLowerCase()).toList(),
            promptWords,
          )) {
        mismatch(
          'class.authored.story_order_mismatch',
          'Ordered-word rule, payload, and visible sentence do not describe the same sentence.',
        );
      }
    }

    if (activity.gameId == 'grammar_puzzle' && type == 'grammarParts') {
      checks += 1;
      final sentence = '${activity.payload['sentence'] ?? activity.prompt}';
      final noun = '${rule['noun'] ?? ''}'.trim();
      final verb = '${rule['verb'] ?? ''}'.trim();
      final adjective = '${rule['adjective'] ?? ''}'.trim();
      final sentenceTokens = _wordTokens(sentence).toSet();
      if (noun.isEmpty ||
          verb.isEmpty ||
          adjective.isEmpty ||
          !sentenceTokens.contains(noun.toLowerCase()) ||
          !sentenceTokens.contains(verb.toLowerCase()) ||
          !sentenceTokens.contains(adjective.toLowerCase())) {
        mismatch(
          'class.authored.grammar_parts_mismatch',
          'The scored noun/verb/adjective are not all present in the authored sentence.',
        );
      }

      checks += 1;
      if ('${activity.payload['noun'] ?? ''}' != noun ||
          '${activity.payload['verb'] ?? ''}' != verb ||
          '${activity.payload['adjective'] ?? ''}' != adjective) {
        mismatch(
          'class.authored.grammar_payload_drift',
          'Grammar payload parts disagree with the scoring rule.',
        );
      }
    }

    if (activity.gameId == 'recycling_challenge' && type == 'exactText') {
      checks += 1;
      final scored = '${rule['value'] ?? ''}'.trim();
      final bin = '${activity.payload['bin'] ?? ''}'.trim();
      final item = '${activity.payload['name'] ?? ''}'.trim();
      if (scored.isEmpty || bin != scored || item.isEmpty) {
        mismatch(
          'class.authored.recycling_payload_drift',
          'Recycling item/bin payload disagrees with the scored bin.',
        );
      }

      checks += 1;
      if (!_containsWholeToken(activity.prompt, item)) {
        mismatch(
          'class.authored.recycling_prompt_drift',
          'Recycling prompt does not name the payload item "$item".',
        );
      }
    }

    if ((activity.gameId == 'science_lab' || activity.gameId == 'map_quest') &&
        type == 'exactText') {
      checks += 1;
      final scored = '${rule['value'] ?? ''}'.trim();
      final payloadAnswer = '${activity.payload['answer'] ?? ''}'.trim();
      if (scored.isEmpty || payloadAnswer != scored) {
        mismatch(
          'class.authored.exact_text_payload_drift',
          'Question payload answer "$payloadAnswer" disagrees with rule answer "$scored".',
        );
      }

      if (activity.gameId == 'map_quest') {
        checks += 1;
        if (!_containsWholeToken(activity.explanation, scored)) {
          mismatch(
            'class.authored.explanation_answer_mismatch',
            'Map explanation does not identify the scored answer "$scored".',
          );
        }
      }
    }

    if (activity.gameId == 'science_lab' && type == 'experimentOutcome') {
      checks += 1;
      final scored = '${rule['reactionId'] ?? ''}'.trim();
      final payloadReaction = '${activity.payload['reactionId'] ?? ''}'.trim();
      if (scored.isEmpty || payloadReaction != scored) {
        mismatch(
          'class.authored.experiment_payload_drift',
          'Experiment payload reaction "$payloadReaction" disagrees with rule reaction "$scored".',
        );
      }
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  TeachingAuditReport _auditClassGenerators() {
    var checks = 0;
    final findings = <TeachingAuditFinding>[];
    const generators = DeterministicContentGenerators();

    for (final classNumber in const <int>[3, 4, 5]) {
      for (final difficulty in const <int>[1, 2, 3]) {
        for (var seed = 0; seed < generatedSeedsPerClassFamily; seed += 1) {
          final math = generators.arithmetic(
            classNumber: classNumber,
            difficulty: difficulty,
            seed: seed,
          );
          checks += 1;
          final expected = _solveArithmeticPrompt(math.text);
          if (expected == null || expected != math.answer) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'class.generated.arithmetic_answer_mismatch',
                location: 'class-$classNumber/math/d$difficulty/seed:$seed',
                message:
                    '${math.text} scores ${math.answer}, but recomputation gives $expected.',
              ),
            );
          }
          checks += 1;
          if (math.choices.length != math.choices.toSet().length ||
              !math.choices.contains(math.answer)) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'class.generated.arithmetic_invalid_choices',
                location: 'class-$classNumber/math/d$difficulty/seed:$seed',
                message:
                    'Arithmetic choices are duplicated or omit the answer.',
              ),
            );
          }

          final fraction = generators.fraction(
            classNumber: classNumber,
            difficulty: difficulty,
            seed: seed,
          );
          checks += 1;
          if (fraction.denominator <= 1 ||
              fraction.numerator <= 0 ||
              fraction.numerator >= fraction.denominator ||
              fraction.totalSlices % fraction.denominator != 0) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'class.generated.invalid_fraction',
                location: 'class-$classNumber/fraction/d$difficulty/seed:$seed',
                message:
                    'Generated fraction ${fraction.numerator}/${fraction.denominator} with ${fraction.totalSlices} slices is invalid.',
              ),
            );
          }

          final grammar = generators.grammar(
            classNumber: classNumber,
            difficulty: difficulty,
            seed: seed,
          );
          checks += 1;
          final sentenceLower = grammar.sentence.toLowerCase();
          if (!sentenceLower.contains(grammar.noun.toLowerCase()) ||
              !sentenceLower.contains(grammar.verb.toLowerCase()) ||
              !sentenceLower.contains(grammar.adjective.toLowerCase())) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'class.generated.grammar_parts_missing',
                location: 'class-$classNumber/grammar/d$difficulty/seed:$seed',
                message:
                    'Generated sentence does not contain all scored grammar parts.',
              ),
            );
          }

          final map = generators.mapDirection(
            classNumber: classNumber,
            difficulty: difficulty,
            seed: seed,
          );
          checks += 1;
          final mapAnswer = _solveDirectionPrompt(map.question);
          if (mapAnswer == null || mapAnswer != map.answer) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'class.generated.direction_answer_mismatch',
                location: 'class-$classNumber/map/d$difficulty/seed:$seed',
                message:
                    '${map.question} scores ${map.answer}, but recomputation gives $mapAnswer.',
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

  Object? _nurseryCorrectResponse(Map<String, dynamic> rule) {
    return switch (rule['type']) {
      'choice' => rule['value'],
      'pairMatch' => Map<String, String>.from(rule['pairs'] as Map),
      'sortBuckets' => Map<String, String>.from(rule['assignments'] as Map),
      'traceCheckpoints' => List<int>.generate(
          (rule['checkpointCount'] as num).toInt(),
          (index) => index,
        ),
      _ => null,
    };
  }

  Object? _nurseryKnownWrongResponse(Map<String, dynamic> rule) {
    return switch (rule['type']) {
      'pairMatch' => <String, String>{},
      'sortBuckets' => <String, String>{},
      'traceCheckpoints' => List<int>.generate(
          (rule['checkpointCount'] as num).toInt(),
          (index) => index,
        ).reversed.toList(),
      _ => null,
    };
  }

  Object? _classCorrectResponse(ContentActivity activity) {
    final rule = activity.correctResponseRule;
    return switch (rule['type']) {
      'exactNumber' => rule['value'],
      'exactText' => rule['value'],
      'selectedSlices' => rule['value'],
      'orderedWords' => List<Object?>.from(rule['value'] as List),
      'grammarParts' => <String, Object?>{
          'noun': rule['noun'],
          'verb': rule['verb'],
          'adjective': rule['adjective'],
        },
      'experimentOutcome' =>
        List<String>.from(activity.payload['requiredIngredients'] as List),
      'reachGridGoal' => _solveCodingActivity(activity),
      _ => null,
    };
  }

  List<CodingCommand>? _solveCodingActivity(ContentActivity activity) {
    final payload = activity.payload;
    final direction = FacingDirection.values.where(
      (candidate) => candidate.name == payload['startDirection'],
    );
    if (direction.isEmpty) return null;
    final mission = CodingMission(
      id: activity.id,
      width: payload['width'] as int,
      height: payload['height'] as int,
      startX: payload['startX'] as int,
      startY: payload['startY'] as int,
      goalX: payload['goalX'] as int,
      goalY: payload['goalY'] as int,
      startDirection: direction.first,
      obstacles: Set<String>.from(payload['obstacles'] as List),
      maxCommands: payload['maxCommands'] as int,
      topicId: activity.topicId,
      difficulty: activity.difficulty,
    );
    final queue = <List<CodingCommand>>[const <CodingCommand>[]];
    var cursor = 0;
    while (cursor < queue.length) {
      final path = queue[cursor++];
      final run = runCodingMission(mission, path);
      if (run.success) return path;
      if (path.length >= mission.maxCommands) continue;
      for (final command in const <CodingCommand>[
        CodingCommand.move,
        CodingCommand.turnLeft,
        CodingCommand.turnRight,
      ]) {
        queue.add(<CodingCommand>[...path, command]);
      }
    }
    return null;
  }

  bool _sameGeneratedPractice(
    NurseryGeneratedPractice left,
    NurseryGeneratedPractice right,
  ) =>
      left.id == right.id &&
      left.skillId == right.skillId &&
      left.prompt == right.prompt &&
      left.narration == right.narration &&
      left.explanation == right.explanation &&
      _sameStringList(
        left.options.map((option) => '${option.id}|${option.label}').toList(),
        right.options.map((option) => '${option.id}|${option.label}').toList(),
      ) &&
      '${left.correctResponseRule}' == '${right.correctResponseRule}';

  bool _sameStringList(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  String _firstAlphabeticCharacter(String value) {
    final match = RegExp(r'[A-Za-z]').firstMatch(value);
    return match?.group(0)?.toUpperCase() ?? '';
  }

  bool _containsWholeToken(String source, String token) {
    if (token.trim().isEmpty) return false;
    final escaped = RegExp.escape(token.trim());
    return RegExp(
      '(^|[^A-Za-z0-9])$escaped([^A-Za-z0-9]|\$)',
      caseSensitive: false,
    ).hasMatch(source);
  }

  int? _solveArithmeticPrompt(String prompt) {
    final expression = prompt
        .replaceAll(',', '')
        .replaceFirst(RegExp(r'\s*=\s*\?\s*$'), '')
        .trim();
    final tokenMatches = RegExp(r'\d+|[+\-×÷]').allMatches(expression).toList();
    final rebuilt = tokenMatches.map((match) => match.group(0)!).join();
    if (rebuilt != expression.replaceAll(RegExp(r'\s+'), '') ||
        tokenMatches.isEmpty ||
        tokenMatches.length.isEven) {
      return null;
    }

    final values = <int>[];
    final operators = <String>[];
    for (var index = 0; index < tokenMatches.length; index += 1) {
      final token = tokenMatches[index].group(0)!;
      if (index.isEven) {
        final value = int.tryParse(token);
        if (value == null) return null;
        values.add(value);
      } else {
        operators.add(token);
      }
    }

    for (var index = 0; index < operators.length;) {
      final operator = operators[index];
      if (operator != '×' && operator != '÷') {
        index += 1;
        continue;
      }
      final left = values[index];
      final right = values[index + 1];
      final result = operator == '×'
          ? left * right
          : (right != 0 && left % right == 0 ? left ~/ right : null);
      if (result == null) return null;
      values[index] = result;
      values.removeAt(index + 1);
      operators.removeAt(index);
    }

    var result = values.first;
    for (var index = 0; index < operators.length; index += 1) {
      final right = values[index + 1];
      result = operators[index] == '+' ? result + right : result - right;
    }
    return result;
  }

  List<String> _wordTokens(String value) => RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)?")
      .allMatches(value)
      .map((match) => match.group(0)!.toLowerCase())
      .toList(growable: false);

  String? _solveDirectionPrompt(String prompt) {
    final match = RegExp(
      r'face\s+(North|East|South|West).*direction is\s+(on your right|on your left|behind you)',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (match == null) return null;
    const directions = <String>['North', 'East', 'South', 'West'];
    final facingIndex = directions.indexWhere(
      (value) => value.toLowerCase() == match.group(1)!.toLowerCase(),
    );
    final relation = match.group(2)!.toLowerCase();
    final answerIndex = switch (relation) {
      'on your right' => (facingIndex + 1) % 4,
      'on your left' => (facingIndex + 3) % 4,
      _ => (facingIndex + 2) % 4,
    };
    return directions[answerIndex];
  }
}

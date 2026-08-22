import '../nursery/nursery_content.dart';
import '../nursery/nursery_practice_generator.dart';
import 'nursery_phonics_reference.dart';
import 'teaching_correctness_audit.dart';

/// Phase-B teacher-facing audit for letter/sound correctness.
///
/// It is intentionally stricter than the generic Phase-A audit. Discovery
/// vocabulary may be broad, but only curated simple onsets may contribute to
/// Nursery phonics evidence.
class NurseryPhonicsAudit {
  const NurseryPhonicsAudit({this.generatedSeedsPerSkill = 512});

  final int generatedSeedsPerSkill;

  TeachingAuditReport audit(NurseryContentPack pack) {
    var checks = 0;
    final findings = <TeachingAuditFinding>[];
    final allWords = <String>{};

    for (final letter in pack.letterAssociations) {
      final expected = nurserySimplePhonicsWords[letter.uppercase];
      checks += 1;
      if (expected == null) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'phase_b.phonics.missing_reference_letter',
            location: letter.uppercase,
            message:
                'No independent phonics QA reference exists for this letter.',
          ),
        );
        continue;
      }

      checks += 1;
      if (letter.examples.length < 8) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.high,
            code: 'phase_b.phonics.discovery_pool_too_small',
            location: letter.uppercase,
            message:
                'Expected at least 8 discovery words; found ${letter.examples.length}.',
          ),
        );
      }

      for (final example in letter.examples) {
        final location = '${letter.uppercase}/${example.word}';
        final shouldBeSimple = expected.contains(example.word);
        final firstLetter = _firstAlphabeticCharacter(example.word);
        allWords.add(example.word);

        checks += 1;
        if (letter.uppercase != 'X' && firstLetter != letter.uppercase) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'phase_b.alphabet.discovery_word_letter_mismatch',
              location: location,
              message:
                  'Discovery word ${example.word} does not begin with ${letter.uppercase}.',
            ),
          );
        }

        checks += 1;
        if (letter.uppercase == 'X' &&
            !example.word.toUpperCase().contains('X')) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'phase_b.alphabet.x_word_missing_x',
              location: location,
              message: 'An X discovery word must visibly contain X.',
            ),
          );
        }

        checks += 1;
        final expectedPhrase = firstLetter == letter.uppercase
            ? '${letter.uppercase} for ${example.word}'
            : '${example.word} has ${letter.uppercase}';
        if (example.displayPhrase != expectedPhrase) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.high,
              code: 'phase_b.alphabet.display_phrase_mismatch',
              location: location,
              message:
                  'Expected display phrase "$expectedPhrase" but found "${example.displayPhrase}".',
            ),
          );
        }

        checks += 1;
        if (example.soundPracticeEligible != shouldBeSimple) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'phase_b.phonics.sound_eligibility_mismatch',
              location: location,
              message:
                  'soundPracticeEligible=${example.soundPracticeEligible}, expected $shouldBeSimple.',
            ),
          );
        }

        checks += 1;
        if (example.beginningSoundEligible != shouldBeSimple) {
          findings.add(
            TeachingAuditFinding(
              severity: TeachingAuditSeverity.blocker,
              code: 'phase_b.phonics.beginning_eligibility_mismatch',
              location: location,
              message:
                  'beginningSoundEligible=${example.beginningSoundEligible}, expected $shouldBeSimple.',
            ),
          );
        }

        if (shouldBeSimple) {
          checks += 1;
          if (firstLetter != letter.uppercase) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'phase_b.phonics.simple_word_letter_mismatch',
                location: location,
                message:
                    'Simple phonics evidence is linked to ${letter.uppercase}, but the word begins with $firstLetter.',
              ),
            );
          }

          checks += 1;
          final expectedCue =
              'Listen to the first sound in ${example.word.toLowerCase()}.';
          if (example.soundCue != expectedCue) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.high,
                code: 'phase_b.phonics.simple_cue_drift',
                location: location,
                message:
                    'Simple phonics cue should be "$expectedCue" but is "${example.soundCue}".',
              ),
            );
          }
        } else {
          checks += 1;
          if (!nurseryAdvancedPhonicsReason.containsKey(example.word)) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.high,
                code: 'phase_b.phonics.unreviewed_exclusion',
                location: location,
                message:
                    'This discovery word is excluded from simple phonics but has no explicit QA reason.',
              ),
            );
          }

          checks += 1;
          if (example.soundCue
              .toLowerCase()
              .startsWith('listen to the first sound')) {
            findings.add(
              TeachingAuditFinding(
                severity: TeachingAuditSeverity.blocker,
                code: 'phase_b.phonics.advanced_word_uses_simple_cue',
                location: location,
                message:
                    'An irregular/advanced discovery word is narrated as simple first-sound practice.',
              ),
            );
          }
        }
      }
    }

    checks += 1;
    if (allWords.length < 180) {
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.medium,
          code: 'phase_b.phonics.discovery_variety_low',
          location: 'letterAssociations',
          message:
              'The 208-card pack contains only ${allWords.length} distinct word labels.',
        ),
      );
    }

    for (final letter in const <String>['Q', 'X']) {
      checks += 1;
      final association = pack.letterAssociations.firstWhere(
        (candidate) => candidate.uppercase == letter,
      );
      if (association.soundPracticeExamples.isNotEmpty ||
          association.beginningSoundExamples.isNotEmpty) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'phase_b.phonics.advanced_letter_in_simple_mastery',
            location: letter,
            message:
                '$letter must remain discovery-only for simple Nursery phonics evidence.',
          ),
        );
      }
    }

    final soundSkill = pack.skillById('alpha_letter_sounds');
    final beginningSkill = pack.skillById('alpha_beginning_sound');
    if (soundSkill == null || beginningSkill == null) {
      checks += 1;
      findings.add(
        const TeachingAuditFinding(
          severity: TeachingAuditSeverity.blocker,
          code: 'phase_b.phonics.skill_missing',
          location: 'alphabet',
          message: 'Letter-sound or beginning-sound skill is missing.',
        ),
      );
    } else {
      final soundResult = _auditGeneratedSimplePhonics(
        pack: pack,
        skill: soundSkill,
      );
      checks += soundResult.checksRun;
      findings.addAll(soundResult.findings);

      final beginningResult = _auditGeneratedSimplePhonics(
        pack: pack,
        skill: beginningSkill,
      );
      checks += beginningResult.checksRun;
      findings.addAll(beginningResult.findings);
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  TeachingAuditReport _auditGeneratedSimplePhonics({
    required NurseryContentPack pack,
    required NurserySkill skill,
  }) {
    const generator = NurseryPracticeGenerator();
    var checks = 0;
    final findings = <TeachingAuditFinding>[];
    final seenPairs = <String>{};
    final expectedPairs = <String>{
      for (final entry in nurserySimplePhonicsWords.entries)
        for (final word in entry.value) '${entry.key}|$word',
    };

    for (var seed = 0; seed < generatedSeedsPerSkill; seed += 1) {
      final practice = generator.generate(pack: pack, skill: skill, seed: seed);
      final answer = '${practice.correctResponseRule['value']}';
      final word = _wordFromVisualTokens(pack, practice.visualTokens);
      final location = '${skill.id}/seed:$seed';

      checks += 1;
      if (word == null) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'phase_b.phonics.generated_word_missing',
            location: location,
            message:
                'Generated phonics practice does not identify its source word.',
          ),
        );
        continue;
      }

      checks += 1;
      if (!nurseryWordIsSimplePhonicsEligible(answer, word)) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'phase_b.phonics.generated_advanced_word',
            location: location,
            message:
                '$word/$answer is not approved for simple Nursery phonics evidence.',
          ),
        );
      }

      checks += 1;
      if (answer == 'Q' || answer == 'X') {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.blocker,
            code: 'phase_b.phonics.generated_advanced_letter',
            location: location,
            message: '$answer entered simple generated phonics practice.',
          ),
        );
      }

      checks += 1;
      if (practice.prompt.toLowerCase().contains('sound cue')) {
        findings.add(
          TeachingAuditFinding(
            severity: TeachingAuditSeverity.high,
            code: 'phase_b.phonics.generator_uses_meta_language',
            location: location,
            message:
                'Child-facing generated prompt uses the implementation phrase "sound cue".',
          ),
        );
      }

      seenPairs.add('$answer|$word');
    }

    checks += 1;
    if (generatedSeedsPerSkill >= expectedPairs.length &&
        !seenPairs.containsAll(expectedPairs)) {
      final missing = expectedPairs.difference(seenPairs).take(8).join(', ');
      findings.add(
        TeachingAuditFinding(
          severity: TeachingAuditSeverity.high,
          code: 'phase_b.phonics.generated_coverage_gap',
          location: skill.id,
          message:
              'Deterministic generator did not cover all ${expectedPairs.length} simple examples. Missing sample: $missing',
        ),
      );
    }

    return TeachingAuditReport(
      checksRun: checks,
      findings: List<TeachingAuditFinding>.unmodifiable(findings),
    );
  }

  String? _wordFromVisualTokens(
    NurseryContentPack pack,
    List<String> visualTokens,
  ) {
    final knownWords = <String>{
      for (final letter in pack.letterAssociations)
        for (final example in letter.examples) example.word,
    };
    for (final token in visualTokens) {
      if (knownWords.contains(token)) return token;
    }
    return null;
  }

  String _firstAlphabeticCharacter(String value) {
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune).toUpperCase();
      if (RegExp(r'^[A-Z]$').hasMatch(character)) return character;
    }
    return '';
  }
}

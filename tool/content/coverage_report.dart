import 'dart:convert';
import 'dart:io';

import 'package:brightquest_kids/core/content/content_duplicate_detector.dart';
import 'package:brightquest_kids/core/content/content_repository.dart';
import 'package:brightquest_kids/core/curriculum/content_contract.dart';
import 'package:brightquest_kids/core/curriculum/curriculum_contract_validator.dart';
import 'package:brightquest_kids/core/curriculum/current_content_inventory.dart';

Map<String, dynamic> _readJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('Missing required file: $path');
  }
  return Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map);
}

void main(List<String> args) {
  const curriculumPath = 'assets/content/curriculum_map.json';
  const auditPath = 'assets/content/current_content_audit.json';

  final curriculumJson = _readJson(curriculumPath);
  final contract = CurriculumContract.fromJson(curriculumJson);
  final audit = CurrentContentAudit.fromJson(_readJson(auditPath));
  final repository = ContentRepository.fromJsonPacks(
    curriculumJson: curriculumJson,
    schemaJson: _readJson('assets/content/content_schema_v1.json'),
    packJson: <Map<String, dynamic>>[
      _readJson('assets/content/class_3/pack.json'),
      _readJson('assets/content/class_4/pack.json'),
      _readJson('assets/content/class_5/pack.json'),
    ],
  );
  final currentContent = currentContentInventory(repository);
  const validator = CurriculumContractValidator();
  final validation = validator.validate(
    contract: contract,
    audit: audit,
    currentContent: currentContent,
  );
  final coverage = validator.coverage(
    contract: contract,
    currentContent: currentContent,
  );
  final duplicates = duplicateCurrentContentGroups(currentContent);
  final packDuplicates = findDuplicateContentGroups(repository.allActivities);

  stdout.writeln('BrightQuest Kids — Phase 1 repository + curriculum coverage');
  stdout.writeln('Contract: ${contract.contractId}');
  stdout.writeln(
    'Current authored learning records: ${currentContent.length} across ${audit.selectors.length} selectors',
  );
  stdout.writeln('');
  for (final value in coverage) {
    final pack = repository.packForClass(value.classNumber);
    stdout.writeln(
      'Class ${value.classNumber}: '
      '${value.totalCompetencies} competencies | '
      '${value.mappedCompetencies} touched by current content | '
      '${value.missingCompetencies} missing from current content | '
      '${value.unreviewedCompetencies} unreviewed | '
      '${pack.activities.length} authored/migrated + '
      '${ContentRepository.generatedPracticeVariantCountPerClass} deterministic practice variants | '
      '${pack.commercial.freeSampleActivityIds.length} free demos',
    );
    final coveredIds = <String>{
      for (final activity in pack.activities) ...activity.allCompetencyIds,
    };
    final classContract = contract.classPack(value.classNumber)!;
    for (final competency in classContract.competencies.where(
      (competency) => !coveredIds.contains(competency.id),
    )) {
      stdout.writeln(
        '  NEEDS AUTHORING: ${competency.id} — ${competency.objective}',
      );
    }
  }
  stdout.writeln('');
  stdout.writeln(
    'Legacy inventory duplicate fingerprints across class packs: ${duplicates.length}',
  );
  for (final group in duplicates) {
    stdout.writeln(
      '  - ${group.map((item) => '${item.id} (${item.displayText})').join(' <-> ')}',
    );
  }
  stdout.writeln('');
  stdout.writeln(
    'Repository duplicate prompt/answer groups: ${packDuplicates.length}',
  );
  for (final group in packDuplicates) {
    stdout.writeln(
      '  - ${group.activities.map((item) => item.id).join(' <-> ')}',
    );
  }
  stdout.writeln('');
  if (validation.warnings.isNotEmpty) {
    stdout.writeln('Warnings:');
    for (final issue in validation.warnings) {
      stdout.writeln('  - ${issue.code}: ${issue.message}');
    }
  }

  if (!validation.isValid) {
    stderr
        .writeln('Phase 1 repository/curriculum technical validation FAILED:');
    for (final issue in validation.errors) {
      stderr.writeln('  - ${issue.code}: ${issue.message}');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Phase 1 repository/curriculum technical validation: PASS');
  stdout.writeln(
    'Phase 0 qualified-reviewer approval gate: PENDING (no approval has been invented).',
  );
  stdout.writeln('Paid-pack eligibility: BLOCKED pending human review.');
}

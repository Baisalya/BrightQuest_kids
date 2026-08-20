import 'content_contract.dart';
import 'current_content_inventory.dart';

enum ContractIssueSeverity { error, warning }

class ContractValidationIssue {
  const ContractValidationIssue({
    required this.code,
    required this.message,
    this.severity = ContractIssueSeverity.error,
  });

  final String code;
  final String message;
  final ContractIssueSeverity severity;

  @override
  String toString() => '${severity.name}: $code — $message';
}

class ContractValidationResult {
  const ContractValidationResult(this.issues);

  final List<ContractValidationIssue> issues;

  bool get isValid =>
      issues.every((issue) => issue.severity != ContractIssueSeverity.error);

  List<ContractValidationIssue> get errors => issues
      .where((issue) => issue.severity == ContractIssueSeverity.error)
      .toList(growable: false);

  List<ContractValidationIssue> get warnings => issues
      .where((issue) => issue.severity == ContractIssueSeverity.warning)
      .toList(growable: false);
}

class ClassCoverageSummary {
  const ClassCoverageSummary({
    required this.classNumber,
    required this.totalCompetencies,
    required this.mappedCompetencies,
    required this.missingCompetencies,
    required this.unreviewedCompetencies,
    required this.currentContentRecords,
  });

  final int classNumber;
  final int totalCompetencies;
  final int mappedCompetencies;
  final int missingCompetencies;
  final int unreviewedCompetencies;
  final int currentContentRecords;
}

class CurriculumContractValidator {
  const CurriculumContractValidator();

  static const _subjects = <String>{
    'maths',
    'english',
    'science',
    'evs',
    'social',
    'coding',
  };

  ContractValidationResult validate({
    required CurriculumContract contract,
    required CurrentContentAudit audit,
    required List<CurrentContentRecord> currentContent,
  }) {
    final issues = <ContractValidationIssue>[];

    void error(String code, String message) => issues.add(
          ContractValidationIssue(code: code, message: message),
        );
    void warning(String code, String message) => issues.add(
          ContractValidationIssue(
            code: code,
            message: message,
            severity: ContractIssueSeverity.warning,
          ),
        );

    if (contract.schemaVersion != 1) {
      error('contract.schema_version', 'Expected curriculum schemaVersion 1.');
    }
    if (audit.schemaVersion != 1) {
      error('audit.schema_version',
          'Expected current-content audit schemaVersion 1.');
    }

    final expectedClasses = <int>{3, 4, 5};
    final actualClasses =
        contract.classes.map((value) => value.classNumber).toSet();
    if (actualClasses.length != contract.classes.length ||
        !actualClasses.containsAll(expectedClasses) ||
        !expectedClasses.containsAll(actualClasses)) {
      error(
        'contract.class_packs',
        'Curriculum must contain exactly one pack each for Classes 3, 4 and 5.',
      );
    }

    if (contract.product['offlineFirst'] != true ||
        contract.product['adFree'] != true ||
        contract.product['childSafe'] != true) {
      error(
        'product.safety_boundary',
        'Product contract must remain offline-first, ad-free and child-safe.',
      );
    }
    final claims = contract.product['certificationClaims'];
    if (claims is! List || claims.isNotEmpty) {
      error(
        'product.certification_claim',
        'Phase 0 must not contain CBSE/NCERT certification claims.',
      );
    }
    final platforms = Set<String>.from(contract.product['platforms'] as List);
    const requiredPlatforms = <String>{
      'androidPhone',
      'androidTablet',
      'androidFreeForm',
      'windowsDesktop',
    };
    if (!platforms.containsAll(requiredPlatforms)) {
      error(
        'product.platforms',
        'Android phone/tablet/free-form and Windows desktop are required.',
      );
    }

    final sourceIds = contract.sources.map((source) => source.id).toSet();
    if (sourceIds.length != contract.sources.length) {
      error('source.duplicate_id', 'Curriculum source IDs must be unique.');
    }
    final reviewerById = <String, ReviewerOwner>{
      for (final reviewer in contract.reviewers) reviewer.id: reviewer,
    };
    if (!reviewerById.containsKey('primary_teacher_reviewer')) {
      error(
        'reviewer.owner_missing',
        'A qualified primary-teacher review owner must be recorded.',
      );
    }

    final allIds = <String>{};
    final mappingByKey = <String, CurrentContentMapping>{};
    for (final classPack in contract.classes) {
      final classNumber = classPack.classNumber;
      final prefix = 'c${classNumber}_';
      if (classPack.commercial.permanentOneTimePriceInr != 299 ||
          classPack.commercial.purchaseModel != 'oneTimePerClass') {
        error(
          'commercial.price_model',
          'Class $classNumber must be ₹299 as a permanent one-time purchase.',
        );
      }
      if (!classPack.packId.contains('class_$classNumber')) {
        error(
          'commercial.pack_id',
          'Class $classNumber packId must remain class-specific.',
        );
      }
      if (classPack.competencies.length < 30 ||
          classPack.competencies.length > 40) {
        error(
          'competency.count',
          'Class $classNumber has ${classPack.competencies.length} competencies; Phase 0 requires 30–40.',
        );
      }

      final units = <String, CurriculumUnitContract>{};
      for (final unit in classPack.units) {
        if (!allIds.add(unit.id)) {
          error('id.duplicate', 'Duplicate curriculum ID ${unit.id}.');
        }
        if (!unit.id.startsWith(prefix)) {
          error(
              'id.class_boundary', '${unit.id} is outside Class $classNumber.');
        }
        if (!_subjects.contains(unit.subject)) {
          error('subject.invalid',
              'Unknown subject ${unit.subject} in ${unit.id}.');
        }
        units[unit.id] = unit;
      }

      final outcomes = <String, LearningOutcomeContract>{};
      for (final outcome in classPack.learningOutcomes) {
        if (!allIds.add(outcome.id)) {
          error('id.duplicate', 'Duplicate curriculum ID ${outcome.id}.');
        }
        if (!outcome.id.startsWith(prefix)) {
          error(
            'id.class_boundary',
            '${outcome.id} is outside Class $classNumber.',
          );
        }
        outcomes[outcome.id] = outcome;
      }

      final competencies = <String, CompetencyContract>{};
      for (final competency in classPack.competencies) {
        if (!allIds.add(competency.id)) {
          error('id.duplicate', 'Duplicate curriculum ID ${competency.id}.');
        }
        if (!competency.id.startsWith(prefix)) {
          error(
            'id.class_boundary',
            '${competency.id} is outside Class $classNumber.',
          );
        }
        final unit = units[competency.unitId];
        if (unit == null) {
          error(
            'competency.unit_missing',
            '${competency.id} references missing unit ${competency.unitId}.',
          );
        } else if (unit.subject != competency.subject) {
          error(
            'competency.subject_mismatch',
            '${competency.id} subject does not match ${unit.id}.',
          );
        }
        if (!_subjects.contains(competency.subject)) {
          error(
            'subject.invalid',
            'Unknown subject ${competency.subject} in ${competency.id}.',
          );
        }
        for (final sourceRef in competency.sourceRefs) {
          if (!sourceIds.contains(sourceRef)) {
            error(
              'competency.source_missing',
              '${competency.id} references missing source $sourceRef.',
            );
          }
        }
        competencies[competency.id] = competency;
      }

      for (final outcome in classPack.learningOutcomes) {
        final competency = competencies[outcome.competencyId];
        if (competency == null) {
          error(
            'outcome.competency_missing',
            '${outcome.id} references missing competency ${outcome.competencyId}.',
          );
          continue;
        }
        if (!competency.learningOutcomeIds.contains(outcome.id)) {
          error(
            'outcome.back_reference',
            '${outcome.id} is not listed by ${competency.id}.',
          );
        }
      }
      for (final competency in classPack.competencies) {
        if (competency.learningOutcomeIds.isEmpty) {
          error(
            'competency.outcome_empty',
            '${competency.id} must have at least one learning outcome.',
          );
        }
        for (final outcomeId in competency.learningOutcomeIds) {
          final outcome = outcomes[outcomeId];
          if (outcome == null) {
            error(
              'competency.outcome_missing',
              '${competency.id} references missing outcome $outcomeId.',
            );
          } else if (outcome.competencyId != competency.id) {
            error(
              'competency.outcome_mismatch',
              '$outcomeId belongs to ${outcome.competencyId}, not ${competency.id}.',
            );
          }
        }
      }

      for (final mapping in classPack.currentContentMappings) {
        if (!allIds.add(mapping.id)) {
          error('id.duplicate', 'Duplicate curriculum ID ${mapping.id}.');
        }
        if (!mapping.id.startsWith(prefix)) {
          error('id.class_boundary',
              '${mapping.id} is outside Class $classNumber.');
        }
        if (mapping.disposition == 'mapped' && mapping.competencyIds.isEmpty) {
          error(
            'mapping.empty',
            '${mapping.id} is marked mapped without a competency.',
          );
        }
        for (final competencyId in mapping.competencyIds) {
          if (!competencies.containsKey(competencyId)) {
            error(
              'mapping.cross_class_or_missing',
              '${mapping.id} references missing or cross-class competency $competencyId.',
            );
          }
        }
        final key = mapping.selectorKey(classNumber);
        if (mappingByKey.containsKey(key)) {
          error(
              'mapping.duplicate_selector', 'Duplicate mapping selector $key.');
        }
        mappingByKey[key] = mapping;
      }

      final allApproved = classPack.competencies.every(
            (value) => value.review.status == ContentReviewState.approved,
          ) &&
          classPack.learningOutcomes.every(
            (value) => value.review.status == ContentReviewState.approved,
          ) &&
          classPack.units.every(
            (value) => value.review.status == ContentReviewState.approved,
          ) &&
          classPack.boundaries.approvalState == 'approved' &&
          classPack.commercial.freeSampleState == 'approved';
      if (!allApproved && classPack.commercial.paidEligibility) {
        error(
          'commercial.unreviewed_paid_claim',
          'Class $classNumber cannot be paid-eligible while curriculum or boundaries are unreviewed.',
        );
      }
      if (!allApproved) {
        warning(
          'human_review.pending',
          'Class $classNumber still requires qualified reviewer approval.',
        );
      }
    }

    final auditByKey = <String, CurrentContentAuditSelector>{};
    for (final selector in audit.selectors) {
      if (auditByKey.containsKey(selector.key)) {
        error('audit.duplicate_selector',
            'Duplicate audit selector ${selector.key}.');
      }
      auditByKey[selector.key] = selector;
      final mapping = mappingByKey[selector.key];
      if (mapping == null) {
        error(
          'audit.mapping_missing',
          'Audit selector ${selector.key} has no curriculum mapping.',
        );
      } else {
        final expected = mapping.competencyIds.toSet();
        final audited = selector.competencyIds.toSet();
        if (expected.length != audited.length ||
            !expected.containsAll(audited)) {
          error(
            'audit.mapping_drift',
            'Audit competency mapping drifted for ${selector.key}.',
          );
        }
      }
    }

    final liveCounts = currentContentSelectorCounts(currentContent);
    for (final entry in liveCounts.entries) {
      final selector = auditByKey[entry.key];
      if (selector == null) {
        error(
          'coverage.unmapped_current_content',
          'Current content selector ${entry.key} has no Phase 0 audit mapping.',
        );
        continue;
      }
      if (selector.expectedCurrentRecordCount != entry.value) {
        error(
          'coverage.current_count_drift',
          '${entry.key} expected ${selector.expectedCurrentRecordCount} current records but runtime inventory has ${entry.value}.',
        );
      }
    }
    for (final selector in audit.selectors) {
      if (!liveCounts.containsKey(selector.key)) {
        error(
          'coverage.stale_audit_selector',
          'Audit selector ${selector.key} no longer exists in current content.',
        );
      }
    }

    final declaredRecordTotal = audit.totals['currentRecordCount'];
    if (declaredRecordTotal is! int ||
        declaredRecordTotal != currentContent.length) {
      error(
        'coverage.total_drift',
        'Audit total does not match ${currentContent.length} current content records.',
      );
    }
    final declaredSelectorTotal = audit.totals['selectorCount'];
    if (declaredSelectorTotal is! int ||
        declaredSelectorTotal != audit.selectors.length) {
      error(
        'coverage.selector_total_drift',
        'Audit selector total does not match the selector list.',
      );
    }

    return ContractValidationResult(List.unmodifiable(issues));
  }

  List<ClassCoverageSummary> coverage({
    required CurriculumContract contract,
    required List<CurrentContentRecord> currentContent,
  }) {
    final summaries = <ClassCoverageSummary>[];
    for (final classPack in contract.classes) {
      final mapped = <String>{};
      for (final mapping in classPack.currentContentMappings) {
        if (mapping.disposition == 'mapped') {
          mapped.addAll(mapping.competencyIds);
        }
      }
      final all = classPack.competencies.map((value) => value.id).toSet();
      final unreviewed = classPack.competencies
          .where((value) => value.review.status != ContentReviewState.approved)
          .length;
      summaries.add(ClassCoverageSummary(
        classNumber: classPack.classNumber,
        totalCompetencies: all.length,
        mappedCompetencies: all.intersection(mapped).length,
        missingCompetencies: all.difference(mapped).length,
        unreviewedCompetencies: unreviewed,
        currentContentRecords: currentContent
            .where((value) => value.classNumber == classPack.classNumber)
            .length,
      ));
    }
    summaries.sort((a, b) => a.classNumber.compareTo(b.classNumber));
    return summaries;
  }
}

class ContentActivityValidator {
  const ContentActivityValidator();

  static const _requiredFields = <String>{
    'id',
    'classNumber',
    'subject',
    'unitId',
    'competencyId',
    'learningOutcomeId',
    'activityType',
    'difficulty',
    'prompt',
    'correctResponseRule',
    'explanation',
    'distractors',
    'hints',
    'narration',
    'locale',
    'author',
    'reviewerOwnerId',
    'status',
    'revision',
    'generation',
  };

  ContractValidationResult validate(
    Map<String, dynamic> activity,
    CurriculumContract contract,
  ) {
    final issues = <ContractValidationIssue>[];
    void error(String code, String message) => issues.add(
          ContractValidationIssue(code: code, message: message),
        );

    for (final field in _requiredFields) {
      if (!activity.containsKey(field)) {
        error('content.required', 'Missing required field $field.');
      }
    }
    if (issues.isNotEmpty) return ContractValidationResult(issues);

    final classNumber = activity['classNumber'];
    if (classNumber is! int || !const <int>{3, 4, 5}.contains(classNumber)) {
      error('content.class_boundary', 'classNumber must be 3, 4 or 5.');
      return ContractValidationResult(issues);
    }
    final classPack = contract.classPack(classNumber);
    if (classPack == null) {
      error('content.class_missing',
          'No curriculum pack for Class $classNumber.');
      return ContractValidationResult(issues);
    }

    final id = activity['id'];
    if (id is! String ||
        !RegExp('^c$classNumber' r'_[a-z0-9_]+$').hasMatch(id)) {
      error(
          'content.id', 'Activity ID must be a stable Class $classNumber ID.');
    }
    final subject = activity['subject'];
    final unitId = activity['unitId'];
    final competencyId = activity['competencyId'];
    final outcomeId = activity['learningOutcomeId'];
    final unit =
        classPack.units.where((value) => value.id == unitId).firstOrNull;
    final competency = classPack.competencies
        .where((value) => value.id == competencyId)
        .firstOrNull;
    final outcome = classPack.learningOutcomes
        .where((value) => value.id == outcomeId)
        .firstOrNull;
    if (unit == null) {
      error('content.unit', 'Unknown or cross-class unit $unitId.');
    }
    if (competency == null) {
      error(
        'content.competency',
        'Unknown or cross-class competency $competencyId.',
      );
    }
    if (outcome == null) {
      error('content.outcome', 'Unknown or cross-class outcome $outcomeId.');
    }
    if (unit != null && subject != unit.subject) {
      error('content.subject', 'Activity subject does not match its unit.');
    }
    if (competency != null && competency.unitId != unitId) {
      error('content.unit_competency',
          'Competency does not belong to unit $unitId.');
    }
    if (competency != null &&
        !competency.learningOutcomeIds.contains(outcomeId)) {
      error(
        'content.outcome_competency',
        'Learning outcome does not belong to competency $competencyId.',
      );
    }

    final prompt = activity['prompt'];
    final explanation = activity['explanation'];
    final author = activity['author'];
    final locale = activity['locale'];
    if (prompt is! String || prompt.trim().isEmpty) {
      error('content.prompt', 'prompt must be non-empty.');
    }
    if (explanation is! String || explanation.trim().isEmpty) {
      error('content.explanation', 'explanation must be non-empty.');
    }
    if (author is! String || author.trim().isEmpty) {
      error('content.author', 'author must be non-empty.');
    }
    if (locale is! String || locale.trim().length < 2) {
      error('content.locale', 'locale must be present.');
    }
    final difficulty = activity['difficulty'];
    if (difficulty is! int || difficulty < 1 || difficulty > 5) {
      error('content.difficulty', 'difficulty must be between 1 and 5.');
    }
    final revision = activity['revision'];
    if (revision is! int || revision < 1) {
      error('content.revision', 'revision must be at least 1.');
    }
    if (activity['correctResponseRule'] is! Map) {
      error('content.correct_rule', 'correctResponseRule must be an object.');
    }
    final narration = activity['narration'];
    if (narration is! Map ||
        narration['text'] is! String ||
        (narration['text'] as String).trim().isEmpty) {
      error('content.narration', 'narration.text must be non-empty.');
    }

    final distractors = activity['distractors'];
    if (distractors is! List) {
      error('content.distractors', 'distractors must be a list.');
    } else {
      final seen = <String>{};
      for (final value in distractors) {
        if (value is! Map) {
          error('content.distractor_shape',
              'Every distractor must be an object.');
          continue;
        }
        final misconceptionId = value['misconceptionId'];
        if (misconceptionId is! String || misconceptionId.trim().isEmpty) {
          error(
            'content.misconception',
            'Every distractor must identify a misconception.',
          );
        }
        final key = value['value'].toString();
        if (!seen.add(key)) {
          error('content.duplicate_distractor',
              'Distractor values must be unique.');
        }
      }
    }

    final hints = activity['hints'];
    if (hints is! List) {
      error('content.hints', 'hints must be a list.');
    } else {
      final steps = <int>{};
      for (final value in hints) {
        if (value is! Map ||
            value['step'] is! int ||
            value['text'] is! String ||
            (value['text'] as String).trim().isEmpty) {
          error('content.hint_shape',
              'Every hint needs an integer step and text.');
          continue;
        }
        if (!steps.add(value['step'] as int)) {
          error('content.hint_step', 'Hint steps must be unique.');
        }
      }
    }

    ContentReviewState? status;
    try {
      status = ContentReviewState.parse(activity['status'] as String);
    } on Object {
      error('content.review_state',
          'Unknown review status ${activity['status']}.');
    }
    final reviewerOwnerId = activity['reviewerOwnerId'];
    if (reviewerOwnerId != null && reviewerOwnerId is! String) {
      error('content.reviewer', 'reviewerOwnerId must be a string or null.');
    }
    if (status == ContentReviewState.approved) {
      final owner = contract.reviewers
          .where((value) => value.id == reviewerOwnerId)
          .firstOrNull;
      if (owner == null ||
          owner.ownerName == null ||
          owner.ownerName!.trim().isEmpty) {
        error(
          'content.approval_without_reviewer',
          'Approved content requires a named reviewer owner.',
        );
      }
    }

    final generation = activity['generation'];
    if (generation is! Map) {
      error('content.generation', 'generation must be an object.');
    } else {
      final mode = generation['mode'];
      if (mode != 'authored' && mode != 'generated') {
        error('content.generation_mode', 'generation.mode is invalid.');
      }
      if (mode == 'generated') {
        final seed = generation['deterministicSeed'];
        if (seed is! String || seed.trim().isEmpty) {
          error(
            'content.generation_seed',
            'Generated content requires a deterministic seed.',
          );
        }
      }
    }

    return ContractValidationResult(List.unmodifiable(issues));
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final value in this) {
      return value;
    }
    return null;
  }
}

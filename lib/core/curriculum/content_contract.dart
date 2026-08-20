enum ContentReviewState {
  draft,
  needsReview,
  inReview,
  changesRequested,
  approved,
  retired;

  static ContentReviewState parse(String value) {
    for (final state in ContentReviewState.values) {
      if (state.name == value) return state;
    }
    throw FormatException('Unknown review state: $value');
  }
}

class ReviewMetadata {
  const ReviewMetadata({
    required this.status,
    required this.revision,
    required this.author,
    required this.reviewerOwnerId,
    required this.reviewedAt,
  });

  final ContentReviewState status;
  final int revision;
  final String author;
  final String? reviewerOwnerId;
  final String? reviewedAt;

  factory ReviewMetadata.fromJson(Map<String, dynamic> json) => ReviewMetadata(
        status: ContentReviewState.parse(json['status'] as String),
        revision: json['revision'] as int,
        author: json['author'] as String,
        reviewerOwnerId: json['reviewerOwnerId'] as String?,
        reviewedAt: json['reviewedAt'] as String?,
      );
}

class CurriculumSourceReference {
  const CurriculumSourceReference({
    required this.id,
    required this.title,
    required this.publisher,
    required this.url,
    required this.usage,
  });

  final String id;
  final String title;
  final String publisher;
  final String url;
  final String usage;

  factory CurriculumSourceReference.fromJson(Map<String, dynamic> json) =>
      CurriculumSourceReference(
        id: json['id'] as String,
        title: json['title'] as String,
        publisher: json['publisher'] as String,
        url: json['url'] as String,
        usage: json['usage'] as String,
      );
}

class ReviewerOwner {
  const ReviewerOwner({
    required this.id,
    required this.role,
    required this.ownerName,
    required this.state,
  });

  final String id;
  final String role;
  final String? ownerName;
  final String state;

  factory ReviewerOwner.fromJson(Map<String, dynamic> json) => ReviewerOwner(
        id: json['id'] as String,
        role: json['role'] as String,
        ownerName: json['ownerName'] as String?,
        state: json['state'] as String,
      );
}

class CurriculumUnitContract {
  const CurriculumUnitContract({
    required this.id,
    required this.subject,
    required this.title,
    required this.review,
  });

  final String id;
  final String subject;
  final String title;
  final ReviewMetadata review;

  factory CurriculumUnitContract.fromJson(Map<String, dynamic> json) =>
      CurriculumUnitContract(
        id: json['id'] as String,
        subject: json['subject'] as String,
        title: json['title'] as String,
        review: ReviewMetadata.fromJson(
          Map<String, dynamic>.from(json['review'] as Map),
        ),
      );
}

class LearningOutcomeContract {
  const LearningOutcomeContract({
    required this.id,
    required this.competencyId,
    required this.statement,
    required this.evidence,
    required this.review,
  });

  final String id;
  final String competencyId;
  final String statement;
  final String evidence;
  final ReviewMetadata review;

  factory LearningOutcomeContract.fromJson(Map<String, dynamic> json) =>
      LearningOutcomeContract(
        id: json['id'] as String,
        competencyId: json['competencyId'] as String,
        statement: json['statement'] as String,
        evidence: json['evidence'] as String,
        review: ReviewMetadata.fromJson(
          Map<String, dynamic>.from(json['review'] as Map),
        ),
      );
}

class CompetencyContract {
  const CompetencyContract({
    required this.id,
    required this.subject,
    required this.unitId,
    required this.title,
    required this.objective,
    required this.learningOutcomeIds,
    required this.sourceRefs,
    required this.review,
  });

  final String id;
  final String subject;
  final String unitId;
  final String title;
  final String objective;
  final List<String> learningOutcomeIds;
  final List<String> sourceRefs;
  final ReviewMetadata review;

  factory CompetencyContract.fromJson(Map<String, dynamic> json) =>
      CompetencyContract(
        id: json['id'] as String,
        subject: json['subject'] as String,
        unitId: json['unitId'] as String,
        title: json['title'] as String,
        objective: json['objective'] as String,
        learningOutcomeIds:
            List<String>.from(json['learningOutcomeIds'] as List),
        sourceRefs: List<String>.from(json['sourceRefs'] as List),
        review: ReviewMetadata.fromJson(
          Map<String, dynamic>.from(json['review'] as Map),
        ),
      );
}

class CurrentContentMapping {
  const CurrentContentMapping({
    required this.id,
    required this.gameId,
    required this.topicId,
    required this.competencyIds,
    required this.disposition,
    required this.boundaryStatus,
    required this.review,
  });

  final String id;
  final String gameId;
  final String topicId;
  final List<String> competencyIds;
  final String disposition;
  final String boundaryStatus;
  final ReviewMetadata review;

  String selectorKey(int classNumber) => '$classNumber::$gameId::$topicId';

  factory CurrentContentMapping.fromJson(Map<String, dynamic> json) =>
      CurrentContentMapping(
        id: json['id'] as String,
        gameId: json['gameId'] as String,
        topicId: json['topicId'] as String,
        competencyIds: List<String>.from(json['competencyIds'] as List),
        disposition: json['disposition'] as String,
        boundaryStatus: json['boundaryStatus'] as String,
        review: ReviewMetadata.fromJson(
          Map<String, dynamic>.from(json['review'] as Map),
        ),
      );
}

class ClassCommercialContract {
  const ClassCommercialContract({
    required this.permanentOneTimePriceInr,
    required this.purchaseModel,
    required this.paidEligibility,
    required this.paidEligibilityReason,
    required this.freeSampleState,
    required this.freeSampleCandidateUnitIds,
  });

  final int permanentOneTimePriceInr;
  final String purchaseModel;
  final bool paidEligibility;
  final String paidEligibilityReason;
  final String freeSampleState;
  final List<String> freeSampleCandidateUnitIds;

  factory ClassCommercialContract.fromJson(Map<String, dynamic> json) {
    final freeSample =
        Map<String, dynamic>.from(json['freeSampleBoundary'] as Map);
    return ClassCommercialContract(
      permanentOneTimePriceInr: json['permanentOneTimePriceInr'] as int,
      purchaseModel: json['purchaseModel'] as String,
      paidEligibility: json['paidEligibility'] as bool,
      paidEligibilityReason: json['paidEligibilityReason'] as String,
      freeSampleState: freeSample['state'] as String,
      freeSampleCandidateUnitIds:
          List<String>.from(freeSample['candidateUnitIds'] as List),
    );
  }
}

class ClassBoundaryContract {
  const ClassBoundaryContract({
    required this.reading,
    required this.vocabulary,
    required this.number,
    required this.approvalState,
  });

  final Map<String, dynamic> reading;
  final Map<String, dynamic> vocabulary;
  final Map<String, dynamic> number;
  final String approvalState;

  factory ClassBoundaryContract.fromJson(Map<String, dynamic> json) =>
      ClassBoundaryContract(
        reading: Map<String, dynamic>.from(json['reading'] as Map),
        vocabulary: Map<String, dynamic>.from(json['vocabulary'] as Map),
        number: Map<String, dynamic>.from(json['number'] as Map),
        approvalState: json['approvalState'] as String,
      );
}

class ClassCurriculumContract {
  const ClassCurriculumContract({
    required this.classNumber,
    required this.packId,
    required this.commercial,
    required this.boundaries,
    required this.units,
    required this.learningOutcomes,
    required this.competencies,
    required this.currentContentMappings,
  });

  final int classNumber;
  final String packId;
  final ClassCommercialContract commercial;
  final ClassBoundaryContract boundaries;
  final List<CurriculumUnitContract> units;
  final List<LearningOutcomeContract> learningOutcomes;
  final List<CompetencyContract> competencies;
  final List<CurrentContentMapping> currentContentMappings;

  factory ClassCurriculumContract.fromJson(Map<String, dynamic> json) =>
      ClassCurriculumContract(
        classNumber: json['classNumber'] as int,
        packId: json['packId'] as String,
        commercial: ClassCommercialContract.fromJson(
          Map<String, dynamic>.from(json['commercial'] as Map),
        ),
        boundaries: ClassBoundaryContract.fromJson(
          Map<String, dynamic>.from(json['boundaries'] as Map),
        ),
        units: (json['units'] as List)
            .map((value) => CurriculumUnitContract.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ))
            .toList(growable: false),
        learningOutcomes: (json['learningOutcomes'] as List)
            .map((value) => LearningOutcomeContract.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ))
            .toList(growable: false),
        competencies: (json['competencies'] as List)
            .map((value) => CompetencyContract.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ))
            .toList(growable: false),
        currentContentMappings: (json['currentContentMappings'] as List)
            .map((value) => CurrentContentMapping.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ))
            .toList(growable: false),
      );
}

class MasteryContract {
  const MasteryContract({
    required this.runtimeStatus,
    required this.legacyRuntimePassRatio,
    required this.independentCorrectMinimum,
    required this.requiresTransferItem,
    required this.finalMasteryHintAllowed,
    required this.confidenceTarget,
    required this.delayedReviewRequired,
    required this.suggestedReviewDays,
    required this.evidenceRubric,
  });

  final String runtimeStatus;
  final double legacyRuntimePassRatio;
  final int independentCorrectMinimum;
  final bool requiresTransferItem;
  final bool finalMasteryHintAllowed;
  final double confidenceTarget;
  final bool delayedReviewRequired;
  final List<int> suggestedReviewDays;
  final List<String> evidenceRubric;

  factory MasteryContract.fromJson(Map<String, dynamic> json) =>
      MasteryContract(
        runtimeStatus: json['runtimeStatus'] as String,
        legacyRuntimePassRatio:
            (json['legacyRuntimePassRatio'] as num).toDouble(),
        independentCorrectMinimum: json['independentCorrectMinimum'] as int,
        requiresTransferItem: json['requiresTransferItem'] as bool,
        finalMasteryHintAllowed: json['finalMasteryHintAllowed'] as bool,
        confidenceTarget: (json['confidenceTarget'] as num).toDouble(),
        delayedReviewRequired: json['delayedReviewRequired'] as bool,
        suggestedReviewDays:
            List<int>.from(json['suggestedReviewDays'] as List),
        evidenceRubric: List<String>.from(json['evidenceRubric'] as List),
      );
}

class CurriculumContract {
  const CurriculumContract({
    required this.schemaVersion,
    required this.contractId,
    required this.product,
    required this.reviewStates,
    required this.reviewers,
    required this.sources,
    required this.masteryContract,
    required this.classes,
    required this.phase0Gate,
  });

  final int schemaVersion;
  final String contractId;
  final Map<String, dynamic> product;
  final List<String> reviewStates;
  final List<ReviewerOwner> reviewers;
  final List<CurriculumSourceReference> sources;
  final MasteryContract masteryContract;
  final List<ClassCurriculumContract> classes;
  final Map<String, dynamic> phase0Gate;

  ClassCurriculumContract? classPack(int classNumber) {
    for (final value in classes) {
      if (value.classNumber == classNumber) return value;
    }
    return null;
  }

  factory CurriculumContract.fromJson(Map<String, dynamic> json) =>
      CurriculumContract(
        schemaVersion: json['schemaVersion'] as int,
        contractId: json['contractId'] as String,
        product: Map<String, dynamic>.from(json['product'] as Map),
        reviewStates: List<String>.from(json['reviewStates'] as List),
        reviewers: (json['reviewers'] as List)
            .map((value) => ReviewerOwner.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ))
            .toList(growable: false),
        sources: (json['sources'] as List)
            .map((value) => CurriculumSourceReference.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ))
            .toList(growable: false),
        masteryContract: MasteryContract.fromJson(
          Map<String, dynamic>.from(json['masteryContract'] as Map),
        ),
        classes: (json['classes'] as List)
            .map((value) => ClassCurriculumContract.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ))
            .toList(growable: false),
        phase0Gate: Map<String, dynamic>.from(json['phase0Gate'] as Map),
      );
}

class CurrentContentAuditSelector {
  const CurrentContentAuditSelector({
    required this.classNumber,
    required this.gameId,
    required this.topicId,
    required this.expectedCurrentRecordCount,
    required this.competencyIds,
    required this.disposition,
    required this.boundaryStatus,
  });

  final int classNumber;
  final String gameId;
  final String topicId;
  final int expectedCurrentRecordCount;
  final List<String> competencyIds;
  final String disposition;
  final String boundaryStatus;

  String get key => '$classNumber::$gameId::$topicId';

  factory CurrentContentAuditSelector.fromJson(Map<String, dynamic> json) =>
      CurrentContentAuditSelector(
        classNumber: json['classNumber'] as int,
        gameId: json['gameId'] as String,
        topicId: json['topicId'] as String,
        expectedCurrentRecordCount: json['expectedCurrentRecordCount'] as int,
        competencyIds: List<String>.from(json['competencyIds'] as List),
        disposition: json['disposition'] as String,
        boundaryStatus: json['boundaryStatus'] as String,
      );
}

class CurrentContentAudit {
  const CurrentContentAudit({
    required this.schemaVersion,
    required this.boundaryAssessment,
    required this.selectors,
    required this.totals,
  });

  final int schemaVersion;
  final String boundaryAssessment;
  final List<CurrentContentAuditSelector> selectors;
  final Map<String, dynamic> totals;

  factory CurrentContentAudit.fromJson(Map<String, dynamic> json) =>
      CurrentContentAudit(
        schemaVersion: json['schemaVersion'] as int,
        boundaryAssessment: json['boundaryAssessment'] as String,
        selectors: (json['selectors'] as List)
            .map((value) => CurrentContentAuditSelector.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ))
            .toList(growable: false),
        totals: Map<String, dynamic>.from(json['totals'] as Map),
      );
}

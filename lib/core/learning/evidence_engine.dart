import 'learning_models.dart';

class EvidenceEngine {
  const EvidenceEngine({
    this.masteryConfidenceThreshold = 0.72,
    this.maxEvidencePerProfile = 1200,
  });

  final double masteryConfidenceThreshold;
  final int maxEvidencePerProfile;

  LearningProfileState record(
    LearningProfileState state,
    AttemptEvidence evidence,
  ) {
    final evidenceList = <AttemptEvidence>[...state.attemptEvidence, evidence];
    if (evidenceList.length > maxEvidencePerProfile) {
      evidenceList.removeRange(0, evidenceList.length - maxEvidencePerProfile);
    }

    final mastery = Map<String, SkillMastery>.from(state.skillMastery);
    final current = mastery[evidence.competencyId] ??
        SkillMastery(competencyId: evidence.competencyId);
    mastery[evidence.competencyId] = updateMastery(current, evidence);

    return state.copyWith(
      attemptEvidence: List<AttemptEvidence>.unmodifiable(evidenceList),
      skillMastery: Map<String, SkillMastery>.unmodifiable(mastery),
    );
  }

  SkillMastery updateMastery(
    SkillMastery current,
    AttemptEvidence evidence,
  ) {
    final evidenceCount = current.evidenceCount + 1;
    final correctCount = current.correctCount + (evidence.correct ? 1 : 0);
    final independentCorrectCount = current.independentCorrectCount +
        (evidence.correct && evidence.independent ? 1 : 0);
    final transferCorrectCount = current.transferCorrectCount +
        (evidence.correct && evidence.transfer && evidence.independent ? 1 : 0);
    final delayedReviewSuccesses = current.delayedReviewSuccesses +
        (evidence.correct && evidence.delayed && evidence.independent ? 1 : 0);

    final misconceptionCounts =
        Map<String, int>.from(current.misconceptionCounts);
    final misconceptionId = evidence.misconceptionId;
    if (!evidence.correct &&
        misconceptionId != null &&
        misconceptionId.isNotEmpty) {
      misconceptionCounts[misconceptionId] =
          (misconceptionCounts[misconceptionId] ?? 0) + 1;
    }

    final correctnessWeight = evidence.correct ? 1.0 : 0.0;
    final independenceWeight = evidence.independent ? 1.0 : 0.55;
    final kindWeight = switch (evidence.kind) {
      LearningAttemptKind.diagnostic => 0.8,
      LearningAttemptKind.guided => 0.55,
      LearningAttemptKind.independent => 0.9,
      LearningAttemptKind.transfer => 1.0,
      LearningAttemptKind.review => 1.0,
      LearningAttemptKind.project => 0.95,
    };
    final observation = correctnessWeight *
        independenceWeight *
        kindWeight *
        evidence.confidence;
    final priorWeight = current.evidenceCount.clamp(0, 8).toDouble();
    final confidence =
        ((current.confidence * priorWeight) + observation) / (priorWeight + 1);

    final provisional = SkillMastery(
      competencyId: current.competencyId,
      state: current.state,
      evidenceCount: evidenceCount,
      correctCount: correctCount,
      independentCorrectCount: independentCorrectCount,
      transferCorrectCount: transferCorrectCount,
      delayedReviewSuccesses: delayedReviewSuccesses,
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
      lastEvidenceIso: evidence.recordedAtIso,
      nextReviewIso: current.nextReviewIso,
      misconceptionCounts: Map<String, int>.unmodifiable(misconceptionCounts),
    );

    return provisional.copyWith(state: classify(provisional));
  }

  LearningEvidenceState classify(SkillMastery mastery) {
    if (mastery.evidenceCount == 0) return LearningEvidenceState.notStarted;

    // Never classify a child as needing support from one answer.
    if (mastery.evidenceCount >= 2 && mastery.accuracy < 0.45) {
      return LearningEvidenceState.needsSupport;
    }

    if (mastery.delayedReviewSuccesses >= 1 &&
        mastery.independentCorrectCount >= 2 &&
        mastery.transferCorrectCount >= 1 &&
        mastery.confidence >= masteryConfidenceThreshold) {
      return LearningEvidenceState.secure;
    }

    if (mastery.independentCorrectCount >= 2 &&
        mastery.transferCorrectCount >= 1 &&
        mastery.confidence >= masteryConfidenceThreshold) {
      return LearningEvidenceState.masteredNow;
    }

    if (mastery.correctCount > 0) return LearningEvidenceState.practising;
    return LearningEvidenceState.introduced;
  }

  DiagnosticBand diagnosticBandFor(Iterable<AttemptEvidence> evidence) {
    final values = evidence.toList(growable: false);
    if (values.isEmpty) return DiagnosticBand.ready;
    if (values.length < 2) {
      return values.first.correct
          ? DiagnosticBand.ready
          : DiagnosticBand.learning;
    }
    final correct = values.where((item) => item.correct).length;
    final ratio = correct / values.length;
    final independentCorrect =
        values.where((item) => item.correct && item.independent).length;
    if (ratio < 0.45) return DiagnosticBand.needsSupport;
    if (ratio >= 0.8 && independentCorrect >= 2) return DiagnosticBand.strong;
    if (ratio >= 0.55) return DiagnosticBand.ready;
    return DiagnosticBand.learning;
  }
}

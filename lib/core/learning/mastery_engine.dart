import 'evidence_engine.dart';
import 'learning_models.dart';

class MasteryEngine {
  const MasteryEngine({this.confidenceThreshold = 0.72});

  final double confidenceThreshold;

  bool qualifiesForMasteredNow(SkillMastery skill) =>
      skill.independentCorrectCount >= 2 &&
      skill.transferCorrectCount >= 1 &&
      skill.confidence >= confidenceThreshold;

  bool qualifiesForSecure(SkillMastery skill) =>
      qualifiesForMasteredNow(skill) && skill.delayedReviewSuccesses >= 1;

  LearningEvidenceState stateFor(SkillMastery skill) => EvidenceEngine(
        masteryConfidenceThreshold: confidenceThreshold,
      ).classify(skill);

  bool guessingCannotSecure(Iterable<AttemptEvidence> evidence) {
    final values = evidence.toList();
    if (values.isEmpty) return true;
    final independentCorrect =
        values.where((item) => item.correct && item.independent).length;
    final transfer = values.where(
      (item) => item.correct && item.independent && item.transfer,
    );
    final delayed = values.where(
      (item) => item.correct && item.independent && item.delayed,
    );
    return independentCorrect < 2 || transfer.isEmpty || delayed.isEmpty;
  }
}

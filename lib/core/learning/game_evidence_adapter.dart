import '../content/content_activity.dart';
import '../content/content_repository.dart';
import '../curriculum/curriculum_models.dart';
import 'learning_models.dart';

class GameEvidenceAdapter {
  const GameEvidenceAdapter();

  ContentActivity? resolve({
    required ContentRepository repository,
    required int classNumber,
    required String gameId,
    required String legacyContentId,
  }) =>
      repository.activityForLegacyContent(
        classNumber: classNumber,
        gameId: gameId,
        legacyContentId: legacyContentId,
      );

  String? misconceptionFor(ContentActivity? activity, Object? response) {
    if (activity == null) return null;
    for (final distractor in activity.distractors) {
      if (distractor.value == response) return distractor.misconceptionId;
    }
    return null;
  }

  LearningAttemptKind kindFor(LearningLevel? level) {
    if (level?.isMastery == true) return LearningAttemptKind.transfer;
    return LearningAttemptKind.independent;
  }
}

import 'nursery_learning_models.dart';

/// Chooses the next deterministic generated-review seed for one Nursery skill.
///
/// The first seed is stable for a skill. Every later review advances from the
/// most recently recorded generated seed, so a child does not get the same
/// generated review merely because a calendar-based seed happened to collide.
class NurseryReviewSeedPlanner {
  const NurseryReviewSeedPlanner();

  int nextSeed({
    required String skillId,
    required Iterable<NurseryAttemptEvidence> evidence,
  }) {
    NurseryAttemptEvidence? latest;
    DateTime? latestTime;

    for (final candidate in evidence) {
      if (candidate.skillId != skillId || candidate.generatedSeed == null) {
        continue;
      }
      final candidateTime = DateTime.tryParse(candidate.recordedAtIso) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      if (latest == null ||
          latestTime == null ||
          !candidateTime.isBefore(latestTime)) {
        latest = candidate;
        latestTime = candidateTime;
      }
    }

    final previous = latest?.generatedSeed;
    if (previous != null) return previous + 1;
    return _stableHash('nursery-review:$skillId');
  }

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

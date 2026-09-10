import 'gameplay_activity_models.dart';
import 'mission_run_models.dart';

/// Deterministic in-run balance policy used by [MissionRunPlanner].
///
/// Adaptive evidence is still allowed to favour a competency, but repeated
/// selection of the same competency/topic/archetype progressively costs more.
/// The penalties only apply when the current exact-tier pool actually contains
/// alternatives, so single-topic or single-mechanic worlds never lose capacity.
class MissionBalancePolicy {
  const MissionBalancePolicy({
    this.competencyRepeatPenalty = 44,
    this.topicRepeatPenalty = 68,
    this.archetypeRepeatPenalty = 28,
    this.mechanicRepeatPenalty = 14,
  });

  final int competencyRepeatPenalty;
  final int topicRepeatPenalty;
  final int archetypeRepeatPenalty;
  final int mechanicRepeatPenalty;

  int repeatPenaltyFor({
    required MissionCandidate candidate,
    required Map<String, int> selectedCompetencies,
    required Map<String, int> selectedTopics,
    required Map<String, int> selectedArchetypes,
    required Map<LearningGameMechanic, int> selectedMechanics,
    required Set<String> eligibleCompetencies,
    required Set<String> eligibleTopics,
    required Set<String> eligibleArchetypes,
    required Set<LearningGameMechanic> eligibleMechanics,
  }) {
    var penalty = 0;

    if (eligibleCompetencies.length > 1) {
      var strongestPressure = 0;
      for (final competencyId in candidate.allCompetencyIds) {
        final pressure = selectedCompetencies[competencyId] ?? 0;
        if (pressure > strongestPressure) strongestPressure = pressure;
      }
      penalty += strongestPressure * competencyRepeatPenalty;
    }

    if (eligibleTopics.length > 1 && candidate.topicId.isNotEmpty) {
      penalty += (selectedTopics[candidate.topicId] ?? 0) * topicRepeatPenalty;
    }

    if (eligibleArchetypes.length > 1 && candidate.archetypeId.isNotEmpty) {
      penalty += (selectedArchetypes[candidate.archetypeId] ?? 0) *
          archetypeRepeatPenalty;
    }

    if (eligibleMechanics.length > 1) {
      penalty +=
          (selectedMechanics[candidate.mechanic] ?? 0) * mechanicRepeatPenalty;
    }

    return penalty;
  }

  /// Quality-audit threshold for a neutral run. A multi-family pool should not
  /// let one family occupy every slot when other families have enough content.
  /// This is an audit expectation only; the runtime selector remains soft and
  /// can exceed it when adaptive evidence or scarce content makes that useful.
  int neutralMaxOccurrences({
    required int itemCount,
    required int distinctFamilies,
  }) {
    if (itemCount <= 0) return 0;
    if (distinctFamilies <= 1) return itemCount;
    return (itemCount / distinctFamilies).ceil() + 1;
  }
}

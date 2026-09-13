import '../../core/learning/learning_models.dart';
import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_learning_models.dart';

enum NurseryHomeActionKind {
  review,
  continueLearning,
  startLearning,
  replay,
}

class NurseryHomeAction {
  const NurseryHomeAction({
    required this.kind,
    required this.skill,
    required this.reviewMode,
    required this.title,
    required this.subtitle,
  });

  final NurseryHomeActionKind kind;
  final NurserySkill skill;
  final bool reviewMode;
  final String title;
  final String subtitle;
}

class NurseryDomainProgress {
  const NurseryDomainProgress({
    required this.domainId,
    required this.totalSkills,
    required this.startedSkills,
    required this.secureSkills,
  });

  final String domainId;
  final int totalSkills;
  final int startedSkills;
  final int secureSkills;

  double get progress => totalSkills == 0 ? 0.0 : startedSkills / totalSkills;
}

class NurseryHomePlan {
  const NurseryHomePlan({
    required this.primaryAction,
    required this.reviewCount,
    required this.domainProgress,
  });

  final NurseryHomeAction primaryAction;
  final int reviewCount;
  final Map<String, NurseryDomainProgress> domainProgress;

  NurseryDomainProgress progressFor(String domainId) =>
      domainProgress[domainId] ??
      NurseryDomainProgress(
        domainId: domainId,
        totalSkills: 0,
        startedSkills: 0,
        secureSkills: 0,
      );
}

abstract final class NurseryHomePlanner {
  static NurseryHomePlan build({
    required NurseryContentPack pack,
    required List<NurseryReviewTask> dueTasks,
    required NurserySkillMastery Function(String skillId) masteryFor,
  }) {
    if (pack.skills.isEmpty) {
      throw StateError('Nursery pack must contain at least one skill.');
    }

    final domainProgress = <String, NurseryDomainProgress>{};
    for (final domain in pack.domains) {
      final skills = pack.skillsForDomain(domain.id);
      var started = 0;
      var secure = 0;
      for (final skill in skills) {
        final state = masteryFor(skill.id).state;
        if (state != LearningEvidenceState.notStarted) started += 1;
        if (state == LearningEvidenceState.secure) secure += 1;
      }
      domainProgress[domain.id] = NurseryDomainProgress(
        domainId: domain.id,
        totalSkills: skills.length,
        startedSkills: started,
        secureSkills: secure,
      );
    }

    final reviewSkill = dueTasks
        .map((task) => pack.skillById(task.skillId))
        .whereType<NurserySkill>()
        .firstOrNull;
    if (reviewSkill != null) {
      return NurseryHomePlan(
        primaryAction: NurseryHomeAction(
          kind: NurseryHomeActionKind.review,
          skill: reviewSkill,
          reviewMode: true,
          title: 'Play again',
          subtitle: dueTasks.length == 1
              ? '${reviewSkill.title} is ready for a quick replay.'
              : '${dueTasks.length} little games are ready. Start with ${reviewSkill.title}.',
        ),
        reviewCount: dueTasks.length,
        domainProgress: Map<String, NurseryDomainProgress>.unmodifiable(
          domainProgress,
        ),
      );
    }

    final continuing = _mostRecentStartedSkill(pack, masteryFor);
    if (continuing != null) {
      return NurseryHomePlan(
        primaryAction: NurseryHomeAction(
          kind: NurseryHomeActionKind.continueLearning,
          skill: continuing,
          reviewMode: false,
          title: 'Keep playing',
          subtitle: 'Continue ${continuing.title}.',
        ),
        reviewCount: 0,
        domainProgress: Map<String, NurseryDomainProgress>.unmodifiable(
          domainProgress,
        ),
      );
    }

    final newSkill = pack.skills.firstWhere(
      (skill) => masteryFor(skill.id).state == LearningEvidenceState.notStarted,
      orElse: () => pack.skills.first,
    );
    final allSecure = pack.skills.every(
      (skill) => masteryFor(skill.id).state == LearningEvidenceState.secure,
    );

    return NurseryHomePlan(
      primaryAction: NurseryHomeAction(
        kind: allSecure
            ? NurseryHomeActionKind.replay
            : NurseryHomeActionKind.startLearning,
        skill: newSkill,
        reviewMode: false,
        title: allSecure ? 'Play a favourite' : 'Start playing',
        subtitle: allSecure
            ? 'Everything is remembered. Pick a favourite game.'
            : 'Begin with ${newSkill.title}.',
      ),
      reviewCount: 0,
      domainProgress: Map<String, NurseryDomainProgress>.unmodifiable(
        domainProgress,
      ),
    );
  }

  static NurserySkill? _mostRecentStartedSkill(
    NurseryContentPack pack,
    NurserySkillMastery Function(String skillId) masteryFor,
  ) {
    NurserySkill? best;
    DateTime? bestTime;
    for (final skill in pack.skills) {
      final mastery = masteryFor(skill.id);
      if (!_isContinueState(mastery.state)) continue;
      final timestamp = mastery.lastEvidenceIso == null
          ? null
          : DateTime.tryParse(mastery.lastEvidenceIso!);
      if (best == null || _isMoreRecent(timestamp, bestTime)) {
        best = skill;
        bestTime = timestamp;
      }
    }
    return best;
  }

  static bool _isContinueState(LearningEvidenceState state) => switch (state) {
        LearningEvidenceState.introduced ||
        LearningEvidenceState.practising ||
        LearningEvidenceState.masteredNow ||
        LearningEvidenceState.reviewDue ||
        LearningEvidenceState.needsSupport =>
          true,
        LearningEvidenceState.notStarted ||
        LearningEvidenceState.secure =>
          false,
      };

  static bool _isMoreRecent(DateTime? candidate, DateTime? current) {
    if (candidate == null) return false;
    if (current == null) return true;
    return candidate.isAfter(current);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

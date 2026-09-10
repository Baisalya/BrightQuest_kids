import '../../core/learning/learning_models.dart';
import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_learning_models.dart';

class NurseryLearningPathDefinition {
  const NurseryLearningPathDefinition({
    required this.id,
    required this.domainId,
    required this.title,
    required this.subtitle,
    required this.skillIds,
  });

  final String id;
  final String domainId;
  final String title;
  final String subtitle;
  final List<String> skillIds;
}

class NurseryLearningPathPlan {
  const NurseryLearningPathPlan({
    required this.definition,
    required this.skills,
    required this.startedSkills,
    required this.secureSkills,
    required this.recommendedSkill,
    required this.recommendedReviewMode,
  });

  final NurseryLearningPathDefinition definition;
  final List<NurserySkill> skills;
  final int startedSkills;
  final int secureSkills;
  final NurserySkill recommendedSkill;
  final bool recommendedReviewMode;

  int get totalSkills => skills.length;
  double get progress => totalSkills == 0 ? 0 : startedSkills / totalSkills;
  bool get complete => totalSkills > 0 && secureSkills == totalSkills;
}

class NurseryWorldPlan {
  const NurseryWorldPlan({
    required this.domainId,
    required this.paths,
    required this.recommendedPathId,
  });

  final String domainId;
  final List<NurseryLearningPathPlan> paths;
  final String recommendedPathId;

  NurseryLearningPathPlan? pathById(String id) {
    for (final path in paths) {
      if (path.definition.id == id) return path;
    }
    return null;
  }
}

/// Builds a child-facing progression over the existing Nursery skill IDs.
///
/// This layer intentionally does not persist anything and does not alter the
/// authored content schema. It only groups the stable skill IDs into a small
/// number of progressive paths for navigation.
abstract final class NurseryWorldPlanner {
  static const Map<String, List<NurseryLearningPathDefinition>> _catalog = {
    'alphabet': [
      NurseryLearningPathDefinition(
        id: 'alphabet_letters',
        domainId: 'alphabet',
        title: 'Meet the Letters',
        subtitle: 'Big letters, small letters and their partners',
        skillIds: [
          'alpha_uppercase',
          'alpha_lowercase',
          'alpha_case_match',
        ],
      ),
      NurseryLearningPathDefinition(
        id: 'alphabet_sounds',
        domainId: 'alphabet',
        title: 'Hear the Sounds',
        subtitle: 'Listen, notice and find beginning sounds',
        skillIds: [
          'alpha_letter_sounds',
          'alpha_listen_select',
          'alpha_beginning_sound',
        ],
      ),
      NurseryLearningPathDefinition(
        id: 'alphabet_picture_words',
        domainId: 'alphabet',
        title: 'Picture Words',
        subtitle: 'Connect letters with pictures and look closely',
        skillIds: [
          'alpha_word_picture',
          'alpha_visual_discrimination',
        ],
      ),
      NurseryLearningPathDefinition(
        id: 'alphabet_tracing',
        domainId: 'alphabet',
        title: 'Trace the Letters',
        subtitle: 'Follow easy paths for big and small letters',
        skillIds: [
          'alpha_trace_upper',
          'alpha_trace_lower',
        ],
      ),
    ],
    'math': [
      NurseryLearningPathDefinition(
        id: 'math_meet_numbers',
        domainId: 'math',
        title: 'Meet the Numbers',
        subtitle: 'Learn numbers from 0 to 20 in small steps',
        skillIds: [
          'math_numbers_0_5',
          'math_numbers_6_10',
          'math_numbers_11_20',
        ],
      ),
      NurseryLearningPathDefinition(
        id: 'math_count_match',
        domainId: 'math',
        title: 'Count & Match',
        subtitle: 'Count pictures and match numbers to amounts',
        skillIds: [
          'math_count_0_5',
          'math_count_6_10',
          'math_number_quantity',
        ],
      ),
      NurseryLearningPathDefinition(
        id: 'math_compare_find',
        domainId: 'math',
        title: 'Find & Compare',
        subtitle: 'Spot missing numbers, more, less and same',
        skillIds: [
          'math_missing_number',
          'math_more_less',
          'math_same_different',
        ],
      ),
      NurseryLearningPathDefinition(
        id: 'math_add_together',
        domainId: 'math',
        title: 'Add Together',
        subtitle: 'Join little groups and try easy addition',
        skillIds: [
          'math_add_objects',
          'math_add_numerals',
        ],
      ),
    ],
    'knowledge': [
      NurseryLearningPathDefinition(
        id: 'knowledge_colours_shapes',
        domainId: 'knowledge',
        title: 'Colours & Shapes',
        subtitle: 'See bright colours and simple shapes',
        skillIds: [
          'knowledge_colours',
          'knowledge_shapes',
        ],
      ),
      NurseryLearningPathDefinition(
        id: 'knowledge_animals_food',
        domainId: 'knowledge',
        title: 'Animals & Food',
        subtitle: 'Learn familiar animals, fruits and vegetables',
        skillIds: [
          'knowledge_animals',
          'knowledge_foods',
        ],
      ),
      NurseryLearningPathDefinition(
        id: 'knowledge_everyday',
        domainId: 'knowledge',
        title: 'Me & My Day',
        subtitle: 'Objects, body parts and everyday routines',
        skillIds: [
          'knowledge_objects',
          'knowledge_body',
          'knowledge_routines',
        ],
      ),
    ],
    'thinking': [
      NurseryLearningPathDefinition(
        id: 'thinking_match_sort',
        domainId: 'thinking',
        title: 'Match & Sort',
        subtitle: 'Put same things together and sort groups',
        skillIds: [
          'thinking_matching',
          'thinking_sorting',
        ],
      ),
      NurseryLearningPathDefinition(
        id: 'thinking_patterns',
        domainId: 'thinking',
        title: 'Spot the Pattern',
        subtitle: 'Look for what comes next',
        skillIds: ['thinking_patterns'],
      ),
      NurseryLearningPathDefinition(
        id: 'thinking_look_listen',
        domainId: 'thinking',
        title: 'Look & Listen',
        subtitle: 'Notice, remember and listen carefully',
        skillIds: ['thinking_observation_listening'],
      ),
    ],
  };

  static NurseryWorldPlan build({
    required NurseryContentPack pack,
    required String domainId,
    required NurserySkillMastery Function(String skillId) masteryFor,
    Iterable<String> dueSkillIds = const <String>[],
  }) {
    final domainSkills = pack.skillsForDomain(domainId);
    if (domainSkills.isEmpty) {
      throw StateError('Nursery domain $domainId has no skills.');
    }

    final due = dueSkillIds.toSet();
    final definitions = _definitionsFor(domainId, domainSkills);
    final paths = <NurseryLearningPathPlan>[];

    for (final definition in definitions) {
      final skills = <NurserySkill>[];
      for (final skillId in definition.skillIds) {
        final skill = pack.skillById(skillId);
        if (skill != null && skill.domainId == domainId) skills.add(skill);
      }
      if (skills.isEmpty) continue;

      var started = 0;
      var secure = 0;
      for (final skill in skills) {
        final state = masteryFor(skill.id).state;
        if (state != LearningEvidenceState.notStarted) started += 1;
        if (state == LearningEvidenceState.secure) secure += 1;
      }
      final recommended = _recommendedSkill(
        skills: skills,
        masteryFor: masteryFor,
        dueSkillIds: due,
      );
      paths.add(
        NurseryLearningPathPlan(
          definition: definition,
          skills: List<NurserySkill>.unmodifiable(skills),
          startedSkills: started,
          secureSkills: secure,
          recommendedSkill: recommended,
          recommendedReviewMode: due.contains(recommended.id),
        ),
      );
    }

    if (paths.isEmpty) {
      throw StateError('Nursery domain $domainId has no navigable paths.');
    }

    final duePath = paths.where(
      (path) => path.skills.any((skill) => due.contains(skill.id)),
    );
    final recentActiveSkill = _mostRecentActiveSkill(domainSkills, masteryFor);
    final recentActivePath = recentActiveSkill == null
        ? null
        : paths.where(
            (path) => path.skills.any((skill) => skill.id == recentActiveSkill.id),
          ).firstOrNull;
    final unfinishedPath = paths.where((path) => !path.complete);
    final recommendedPath = duePath.firstOrNull ??
        recentActivePath ??
        unfinishedPath.firstOrNull ??
        paths.first;

    return NurseryWorldPlan(
      domainId: domainId,
      paths: List<NurseryLearningPathPlan>.unmodifiable(paths),
      recommendedPathId: recommendedPath.definition.id,
    );
  }

  static List<NurseryLearningPathDefinition> _definitionsFor(
    String domainId,
    List<NurserySkill> domainSkills,
  ) {
    final authored = _catalog[domainId] ?? const <NurseryLearningPathDefinition>[];
    final mapped = authored.expand((path) => path.skillIds).toSet();
    final uncatalogued = domainSkills
        .where((skill) => !mapped.contains(skill.id))
        .map((skill) => skill.id)
        .toList(growable: false);
    if (uncatalogued.isEmpty) return authored;
    return <NurseryLearningPathDefinition>[
      ...authored,
      NurseryLearningPathDefinition(
        id: '${domainId}_more',
        domainId: domainId,
        title: 'More to Explore',
        subtitle: 'A few more games in this world',
        skillIds: List<String>.unmodifiable(uncatalogued),
      ),
    ];
  }

  static NurserySkill _recommendedSkill({
    required List<NurserySkill> skills,
    required NurserySkillMastery Function(String skillId) masteryFor,
    required Set<String> dueSkillIds,
  }) {
    for (final skill in skills) {
      if (dueSkillIds.contains(skill.id)) return skill;
    }

    NurserySkill? mostRecent;
    DateTime? mostRecentTime;
    for (final skill in skills) {
      final mastery = masteryFor(skill.id);
      if (!_isActive(mastery.state)) continue;
      final timestamp = mastery.lastEvidenceIso == null
          ? null
          : DateTime.tryParse(mastery.lastEvidenceIso!);
      if (mostRecent == null || _isMoreRecent(timestamp, mostRecentTime)) {
        mostRecent = skill;
        mostRecentTime = timestamp;
      }
    }
    if (mostRecent != null) return mostRecent;

    for (final skill in skills) {
      if (masteryFor(skill.id).state == LearningEvidenceState.notStarted) {
        return skill;
      }
    }
    return skills.first;
  }

  static NurserySkill? _mostRecentActiveSkill(
    List<NurserySkill> skills,
    NurserySkillMastery Function(String skillId) masteryFor,
  ) {
    NurserySkill? best;
    DateTime? bestTime;
    for (final skill in skills) {
      final mastery = masteryFor(skill.id);
      if (!_isActive(mastery.state)) continue;
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

  static bool _isActive(LearningEvidenceState state) => switch (state) {
        LearningEvidenceState.introduced ||
        LearningEvidenceState.practising ||
        LearningEvidenceState.masteredNow ||
        LearningEvidenceState.reviewDue ||
        LearningEvidenceState.needsSupport =>
          true,
        LearningEvidenceState.notStarted || LearningEvidenceState.secure => false,
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

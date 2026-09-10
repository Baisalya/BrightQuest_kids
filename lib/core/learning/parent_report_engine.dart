import '../curriculum/content_contract.dart';
import 'learning_models.dart';
import 'mission_mastery_intelligence.dart';
import 'mission_mastery_models.dart';

class ParentCompetencyRow {
  const ParentCompetencyRow({
    required this.competencyId,
    required this.subject,
    required this.unitId,
    required this.title,
    required this.state,
    required this.longTermStatus,
    required this.longTermLabel,
    required this.longTermReason,
    required this.longTermConfidence,
    required this.evidenceCount,
    required this.lastPracticeIso,
    required this.nextReviewIso,
    required this.parentNote,
  });

  final String competencyId;
  final String subject;
  final String unitId;
  final String title;
  final LearningEvidenceState state;
  final LongTermMasteryStatus longTermStatus;
  final String longTermLabel;
  final String longTermReason;
  final double longTermConfidence;
  final int evidenceCount;
  final String? lastPracticeIso;
  final String? nextReviewIso;
  final String parentNote;
}

class WeeklyLearningSummary {
  const WeeklyLearningSummary({
    required this.learned,
    required this.retained,
    required this.needsSupport,
    required this.suggestedFiveMinuteActivity,
    required this.evidenceWindowStartIso,
    required this.evidenceWindowEndIso,
  });

  final int learned;
  final int retained;
  final int needsSupport;
  final String suggestedFiveMinuteActivity;
  final String evidenceWindowStartIso;
  final String evidenceWindowEndIso;
}

class ParentLearningReport {
  const ParentLearningReport({
    required this.classNumber,
    required this.rows,
    required this.weekly,
    required this.projectEvidence,
  });

  final int classNumber;
  final List<ParentCompetencyRow> rows;
  final WeeklyLearningSummary weekly;
  final List<ProjectEvidence> projectEvidence;
}

class ParentReportEngine {
  const ParentReportEngine();

  ParentLearningReport build({
    required CurriculumContract curriculum,
    required LearningProfileState learning,
    required int classNumber,
    required DateTime now,
  }) {
    final classPack = curriculum.classPack(classNumber);
    if (classPack == null) {
      return ParentLearningReport(
        classNumber: classNumber,
        rows: const <ParentCompetencyRow>[],
        weekly: WeeklyLearningSummary(
          learned: 0,
          retained: 0,
          needsSupport: 0,
          suggestedFiveMinuteActivity:
              'Choose one familiar skill and explain it together.',
          evidenceWindowStartIso:
              now.subtract(const Duration(days: 7)).toIso8601String(),
          evidenceWindowEndIso: now.toIso8601String(),
        ),
        projectEvidence: const <ProjectEvidence>[],
      );
    }

    final rows = <ParentCompetencyRow>[];
    for (final competency in classPack.competencies) {
      final mastery = learning.skillMastery[competency.id] ??
          SkillMastery(competencyId: competency.id);
      final longTerm = const MissionMasteryIntelligence().forCompetency(
        learningState: learning,
        classNumber: classNumber,
        competencyId: competency.id,
        now: now,
      );
      rows.add(
        ParentCompetencyRow(
          competencyId: competency.id,
          subject: competency.subject,
          unitId: competency.unitId,
          title: competency.title,
          state: mastery.state,
          longTermStatus: longTerm.status,
          longTermLabel: longTerm.label,
          longTermReason: longTerm.reason,
          longTermConfidence: longTerm.confidence,
          evidenceCount: mastery.evidenceCount,
          lastPracticeIso: mastery.lastEvidenceIso,
          nextReviewIso: mastery.nextReviewIso,
          parentNote:
              '${_parentNote(mastery)} Long-term signal: ${longTerm.label}.',
        ),
      );
    }

    final weekStart = now.subtract(const Duration(days: 7));
    final weekEvidence = learning.attemptEvidence.where((item) {
      final date = DateTime.tryParse(item.recordedAtIso);
      return date != null && !date.isBefore(weekStart) && !date.isAfter(now);
    }).toList();
    final learnedSkills = weekEvidence.map((item) => item.competencyId).toSet();
    final retained = rows
        .where((row) => row.longTermStatus == LongTermMasteryStatus.secure)
        .length;
    final support = rows
        .where(
            (row) => row.longTermStatus == LongTermMasteryStatus.needsPractice)
        .length;
    final weakest = rows
        .where(
            (row) => row.longTermStatus == LongTermMasteryStatus.needsPractice)
        .toList();
    final suggestion = weakest.isEmpty
        ? 'Spend five minutes asking the child to teach you one recently learned idea using their own example.'
        : 'Spend five minutes on “${weakest.first.title}”: use one concrete example, ask for the child’s reasoning, and stop before it feels like a test.';

    return ParentLearningReport(
      classNumber: classNumber,
      rows: List<ParentCompetencyRow>.unmodifiable(rows),
      weekly: WeeklyLearningSummary(
        learned: learnedSkills.length,
        retained: retained,
        needsSupport: support,
        suggestedFiveMinuteActivity: suggestion,
        evidenceWindowStartIso: weekStart.toIso8601String(),
        evidenceWindowEndIso: now.toIso8601String(),
      ),
      projectEvidence: List<ProjectEvidence>.unmodifiable(
        learning.projectEvidence
            .where((item) => item.classNumber == classNumber),
      ),
    );
  }

  String _parentNote(SkillMastery skill) {
    if (skill.evidenceCount == 0) {
      return 'No learning evidence yet. BrightQuest will not infer ability from missing data.';
    }
    final repeatedMisconception = _topMisconception(skill.misconceptionCounts);
    final detail = repeatedMisconception == null
        ? ''
        : ' A repeated mix-up is ${_plainMisconception(repeatedMisconception)}.';
    return switch (skill.state) {
      LearningEvidenceState.notStarted => 'Not started yet.$detail',
      LearningEvidenceState.introduced =>
        'Introduced; more guided evidence is needed.$detail',
      LearningEvidenceState.practising =>
        'Learning in progress; independence is still developing.$detail',
      LearningEvidenceState.masteredNow =>
        'Demonstrated independently now; delayed review is still needed.$detail',
      LearningEvidenceState.reviewDue => 'A retention review is due.$detail',
      LearningEvidenceState.secure =>
        'Shown independently, transferred, and retained after a delay.$detail',
      LearningEvidenceState.needsSupport =>
        'Several pieces of evidence suggest a calmer reteach will help.$detail',
    };
  }

  String? _topMisconception(Map<String, int> values) {
    if (values.isEmpty) return null;
    final entries = values.entries.toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        return count != 0 ? count : a.key.compareTo(b.key);
      });
    return entries.first.value >= 2 ? entries.first.key : null;
  }

  String _plainMisconception(String id) {
    if (id.contains('arithmetic'))
      return 'an operation or place-value calculation error';
    if (id.contains('fraction'))
      return 'confusing the whole with equal fractional parts';
    if (id.contains('direction'))
      return 'using direction from the wrong starting orientation';
    if (id.contains('grammar'))
      return 'confusing the job a word performs in context';
    return 'a recurring interpretation of this type of task';
  }
}

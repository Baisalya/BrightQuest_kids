import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/learning/learning_models.dart';
import '../../core/learning/parent_report_engine.dart';

class ParentLearningReportScreen extends StatelessWidget {
  const ParentLearningReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final repository = BrightQuestScope.contentOf(context);
    final report = const ParentReportEngine().build(
      curriculum: repository.curriculum,
      learning: controller.learningState,
      classNumber: controller.selectedClass,
      now: DateTime.now(),
    );
    final bySubject = <String, List<ParentCompetencyRow>>{};
    for (final row in report.rows) {
      bySubject
          .putIfAbsent(row.subject, () => <ParentCompetencyRow>[])
          .add(row);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Learning evidence')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This week',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                          label: Text(
                              '${report.weekly.learned} skills practised')),
                      Chip(label: Text('${report.weekly.retained} secure')),
                      Chip(
                          label: Text(
                              '${report.weekly.needsSupport} need support')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(report.weekly.suggestedFiveMinuteActivity),
                  const SizedBox(height: 8),
                  const Text(
                    'Activity time is shown separately from demonstrated learning. BrightQuest does not rank siblings or compare children.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final entry in bySubject.entries) ...[
            Text(
              _subjectTitle(entry.key),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final row in entry.value)
              Card(
                child: ExpansionTile(
                  leading: Icon(_stateIcon(row.state)),
                  title: Text(row.title),
                  subtitle: Text(
                    '${_stateLabel(row.state)} • ${row.evidenceCount} evidence item${row.evidenceCount == 1 ? '' : 's'}',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(row.parentNote),
                    ),
                    if (row.lastPracticeIso != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            'Last evidence: ${_date(row.lastPracticeIso!)}'),
                      ),
                    if (row.nextReviewIso != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child:
                            Text('Next review: ${_date(row.nextReviewIso!)}'),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
          ],
          if (report.projectEvidence.isNotEmpty) ...[
            Text('Applied missions',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final evidence in report.projectEvidence)
              Card(
                child: ListTile(
                  title: Text(evidence.missionId),
                  subtitle: Text(
                    '${evidence.adultVerified ? 'Adult-verified evidence' : 'Child reflection — not mastery evidence'} • Correctness ${(evidence.correctness * 100).round()}% • Strategy ${(evidence.strategy * 100).round()}% • Independence ${(evidence.independence * 100).round()}% • Explanation ${(evidence.explanation * 100).round()}%',
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'PDF/print export remains disabled until its layout and privacy review is signed off. This prevents hidden identifiers or purchase information from leaking into a report.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _subjectTitle(String value) => switch (value) {
        'maths' => 'Maths',
        'english' => 'English',
        'science' => 'Science',
        'evs' => 'EVS',
        'social' => 'Social & maps',
        'coding' => 'Coding',
        _ => value,
      };

  static String _stateLabel(LearningEvidenceState state) => switch (state) {
        LearningEvidenceState.notStarted => 'Not started',
        LearningEvidenceState.introduced => 'Introduced',
        LearningEvidenceState.practising => 'Learning',
        LearningEvidenceState.masteredNow => 'Mastered now',
        LearningEvidenceState.reviewDue => 'Review due',
        LearningEvidenceState.secure => 'Secure',
        LearningEvidenceState.needsSupport => 'Needs support',
      };

  static IconData _stateIcon(LearningEvidenceState state) => switch (state) {
        LearningEvidenceState.notStarted =>
          Icons.radio_button_unchecked_rounded,
        LearningEvidenceState.introduced => Icons.lightbulb_outline_rounded,
        LearningEvidenceState.practising => Icons.school_rounded,
        LearningEvidenceState.masteredNow => Icons.star_rounded,
        LearningEvidenceState.reviewDue => Icons.update_rounded,
        LearningEvidenceState.secure => Icons.verified_rounded,
        LearningEvidenceState.needsSupport => Icons.volunteer_activism_rounded,
      };

  static String _date(String iso) {
    final value = DateTime.tryParse(iso);
    if (value == null) return iso;
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

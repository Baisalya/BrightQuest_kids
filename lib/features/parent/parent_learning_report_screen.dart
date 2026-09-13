import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/models/game_models.dart';
import '../../core/learning/learning_models.dart';
import '../../core/learning/parent_report_engine.dart';

class ParentLearningReportScreen extends StatelessWidget {
  const ParentLearningReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    if (controller.isNurseryLearner) {
      return const _NurseryLearningReport();
    }
    return const _SchoolLearningReport();
  }
}

class _SchoolLearningReport extends StatelessWidget {
  const _SchoolLearningReport();

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
        key: const Key('parent_school_learning_report'),
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
                        label:
                            Text('${report.weekly.learned} skills practised'),
                      ),
                      Chip(
                        label: Text('${report.weekly.retained} secure'),
                      ),
                      Chip(
                        label: Text(
                          '${report.weekly.needsSupport} need support',
                        ),
                      ),
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
          Text(
            'Adventure diagnostics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Parent-only signals from the learning games. Adaptive level is an internal challenge setting, not a grade or label for the child.',
          ),
          const SizedBox(height: 10),
          for (final game in games.where((game) => game.id != 'rewards_room'))
            _AdventureDiagnosticCard(game: game),
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
                    '${row.longTermLabel} • ${row.evidenceCount} evidence item${row.evidenceCount == 1 ? '' : 's'}',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(row.parentNote),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Evidence confidence ${(row.longTermConfidence * 100).round()}% • ${row.longTermReason}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (row.lastPracticeIso != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Last evidence: ${_date(row.lastPracticeIso!)}',
                        ),
                      ),
                    if (row.nextReviewIso != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Next review: ${_date(row.nextReviewIso!)}',
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
          ],
          if (report.projectEvidence.isNotEmpty) ...[
            Text(
              'Applied missions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
}

class _AdventureDiagnosticCard extends StatelessWidget {
  const _AdventureDiagnosticCard({required this.game});

  final AdventureGame game;

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final stats = controller.statsFor(game.id);
    final difficulty = controller.recommendedDifficulty(game.id);
    final weakTopics = stats.topicProgress.entries
        .where((entry) => entry.value.attempts >= 2)
        .toList()
      ..sort(
        (a, b) => a.value.accuracy.compareTo(b.value.accuracy),
      );
    final focusTopics = weakTopics
        .take(2)
        .map((entry) => _prettyTopic(entry.key))
        .toList(growable: false);

    return Card(
      child: ExpansionTile(
        key: Key('parent_adventure_diagnostic_${game.id}'),
        leading: CircleAvatar(
          backgroundColor: game.color.withValues(alpha: .12),
          child: Icon(game.icon, color: game.color),
        ),
        title: Text(
          game.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${(stats.mastery * 100).round()}% mastery • ${(stats.accuracy * 100).round()}% accuracy',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${stats.correctAnswers}/${stats.attempts} correct • ${stats.hintsUsed} hints • adaptive level $difficulty',
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              focusTopics.isEmpty
                  ? 'Focus next: more play evidence needed'
                  : 'Focus next: ${focusTopics.join(' • ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _NurseryLearningReport extends StatelessWidget {
  const _NurseryLearningReport();

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final repository = BrightQuestScope.contentOf(context);
    final nursery = repository.nurseryPack;

    return Scaffold(
      appBar: AppBar(title: const Text('Nursery learning evidence')),
      body: ListView(
        key: const Key('parent_nursery_learning_report'),
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nursery overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          '${controller.nurseryAttemptEvidence.length} activities recorded',
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${controller.dueNurseryReviewTasks(limit: 50).length} review ready',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nursery evidence stays separate from School Class 3–5 records. Passive teaching screens and tracing do not establish mastery.',
                  ),
                ],
              ),
            ),
          ),
          if (nursery == null) ...[
            const SizedBox(height: 14),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Nursery content is unavailable in this build.',
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 18),
            for (final domain in nursery.domains) ...[
              Text(
                domain.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              for (final skill in nursery.skillsForDomain(domain.id))
                Builder(
                  builder: (context) {
                    final mastery = controller.nurseryMasteryFor(skill.id);
                    return Card(
                      child: ListTile(
                        leading: Icon(_stateIcon(mastery.state)),
                        title: Text(skill.title),
                        subtitle: Text(
                          '${_stateLabel(mastery.state)} • ${mastery.scorableEvidenceCount} scorable evidence item${mastery.scorableEvidenceCount == 1 ? '' : 's'} • ${mastery.cleanIndependentCorrectCount}/2 clean independent • ${mastery.cleanTransferCorrectCount}/1 transfer${mastery.nextReviewIso == null ? '' : ' • review ${_date(mastery.nextReviewIso!)}'}',
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

String _prettyTopic(String value) => value
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _subjectTitle(String value) => switch (value) {
      'maths' => 'Maths',
      'english' => 'English',
      'science' => 'Science',
      'evs' => 'EVS',
      'social' => 'Social & maps',
      'coding' => 'Coding',
      _ => value,
    };

String _stateLabel(LearningEvidenceState state) => switch (state) {
      LearningEvidenceState.notStarted => 'Not started',
      LearningEvidenceState.introduced => 'Introduced',
      LearningEvidenceState.practising => 'Learning',
      LearningEvidenceState.masteredNow => 'Mastered now',
      LearningEvidenceState.reviewDue => 'Review due',
      LearningEvidenceState.secure => 'Secure',
      LearningEvidenceState.needsSupport => 'Needs support',
    };

IconData _stateIcon(LearningEvidenceState state) => switch (state) {
      LearningEvidenceState.notStarted => Icons.radio_button_unchecked_rounded,
      LearningEvidenceState.introduced => Icons.lightbulb_outline_rounded,
      LearningEvidenceState.practising => Icons.school_rounded,
      LearningEvidenceState.masteredNow => Icons.star_rounded,
      LearningEvidenceState.reviewDue => Icons.update_rounded,
      LearningEvidenceState.secure => Icons.verified_rounded,
      LearningEvidenceState.needsSupport => Icons.volunteer_activism_rounded,
    };

String _date(String iso) {
  final value = DateTime.tryParse(iso);
  if (value == null) return iso;
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/content/content_activity.dart';
import '../../core/curriculum/content_contract.dart';
import 'lesson_flow_screen.dart';

/// A competency-first entry point for the Class 3–5 curriculum.
///
/// Skill Studio deliberately stays separate from the eight legacy game
/// formats. It lets BrightQuest teach and assess competencies that do not fit
/// those games without pretending that every skill is the same interaction.
class ClassSkillStudioScreen extends StatelessWidget {
  const ClassSkillStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final repository = BrightQuestScope.contentOf(context);
    final classNumber = controller.selectedClass;
    final contract = repository.curriculum.classPack(classNumber);

    if (contract == null) {
      return const Scaffold(
        body: Center(child: Text('This class does not have a Skill Studio.')),
      );
    }

    final bySubject = <String, List<CompetencyContract>>{};
    for (final competency in contract.competencies) {
      bySubject.putIfAbsent(competency.subject, () => <CompetencyContract>[])
        ..add(competency);
    }
    final subjects = bySubject.keys.toList()..sort(_subjectOrder);

    return Scaffold(
      appBar: AppBar(title: Text('Class $classNumber Skill Studio')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose a skill to learn',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Each path teaches the idea, gives a worked example, then checks it with guided, independent and transfer practice. Content remains under teacher review.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final subject in subjects) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                    child: Text(
                      _subjectLabel(subject),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  for (final competency in bySubject[subject]!)
                    _CompetencyCard(
                      classNumber: classNumber,
                      competency: competency,
                      activities: repository
                          .activitiesForCompetency(classNumber, competency.id)
                          .where((activity) => activity.gameId == 'skill_studio')
                          .toList(growable: false),
                      extendedPractice: repository
                          .supportsGeneratedSkillStudioPractice(
                        classNumber,
                        competency.id,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static int _subjectOrder(String left, String right) {
    const order = <String>[
      'maths',
      'english',
      'science',
      'evs',
      'social',
      'coding',
    ];
    final a = order.indexOf(left);
    final b = order.indexOf(right);
    if (a == b) return left.compareTo(right);
    if (a < 0) return 1;
    if (b < 0) return -1;
    return a.compareTo(b);
  }

  static String _subjectLabel(String subject) => switch (subject) {
        'maths' => 'Maths',
        'english' => 'English',
        'science' => 'Science',
        'evs' => 'EVS',
        'social' => 'Social Studies',
        'coding' => 'Computational Thinking',
        _ => subject,
      };
}

class _CompetencyCard extends StatelessWidget {
  const _CompetencyCard({
    required this.classNumber,
    required this.competency,
    required this.activities,
    required this.extendedPractice,
  });

  final int classNumber;
  final CompetencyContract competency;
  final List<ContentActivity> activities;
  final bool extendedPractice;

  @override
  Widget build(BuildContext context) {
    final masteryEligible = activities
        .where((activity) => activity.payload['masteryEligible'] != false)
        .length;
    final practiceOnly = activities.isNotEmpty && masteryEligible == 0;
    final studioLabel = activities.isEmpty
        ? 'Legacy path'
        : practiceOnly
            ? '${activities.length} activities · Practice only'
            : '${activities.length} activities · $masteryEligible mastery-eligible';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: '${competency.title}. $studioLabel${extendedPractice ? '. Extended fresh practice available.' : ''}',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LessonFlowScreen.forCompetency(
                classNumber: classNumber,
                competencyId: competency.id,
                title: competency.title,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  child: Icon(
                    practiceOnly
                        ? Icons.edit_note_rounded
                        : Icons.school_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        competency.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(competency.objective),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Chip(
                            avatar: Icon(
                              practiceOnly
                                  ? Icons.edit_note_rounded
                                  : Icons.task_alt_rounded,
                              size: 18,
                            ),
                            label: Text(studioLabel),
                          ),
                          if (extendedPractice)
                            const Chip(
                              avatar: Icon(Icons.all_inclusive_rounded, size: 18),
                              label: Text('Extended fresh practice'),
                            ),
                          if (competency.review.status !=
                              ContentReviewState.approved)
                            const Chip(
                              avatar: Icon(Icons.rate_review_rounded, size: 18),
                              label: Text('Teacher review pending'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

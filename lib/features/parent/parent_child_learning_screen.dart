import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/capabilities/learner_capability_boundary.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/models/game_models.dart';
import '../../core/models/learner_stage.dart';
import '../../core/models/progress_models.dart';
import '../../core/state/game_controller.dart';
import 'class_pack_screen.dart';
import 'parent_learning_report_screen.dart';
import 'parent_section_scaffold.dart';

class ParentChildLearningScreen extends StatelessWidget {
  const ParentChildLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final accuracy = (controller.accuracy * 100).round();
    final dailyAccuracy = (controller.dailyAccuracy * 100).round();
    final weakest = controller.weakestGameIds();

    return ParentSectionScaffold(
      title: 'Child & learning',
      subtitle:
          'Manage child profiles, class placement, learning progress, reports and class packs without mixing them with device settings.',
      icon: Icons.school_rounded,
      children: [
        _ProfileManager(controller: controller),
        const SizedBox(height: 14),
        ParentSectionCard(
          title:
              '${controller.activeProfileAvatar} ${controller.activeProfileName}',
          subtitle: controller.isNurseryLearner
              ? 'Nursery learner profile'
              : 'School learner • Class ${controller.selectedClass}',
          icon: Icons.person_rounded,
          child: Column(
            children: [
              DropdownButtonFormField<LearnerStage>(
                key: ValueKey<String>('stage-${controller.activeProfileId}'),
                initialValue: controller.learnerStage,
                decoration: const InputDecoration(labelText: 'Learning stage'),
                items: const [
                  DropdownMenuItem<LearnerStage>(
                    value: LearnerStage.nursery,
                    child: Text('Nursery'),
                  ),
                  DropdownMenuItem<LearnerStage>(
                    value: LearnerStage.school,
                    child: Text('School'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) controller.setLearnerStage(value);
                },
              ),
              if (!controller.isNurseryLearner) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  key: ValueKey<String>('class-${controller.activeProfileId}'),
                  initialValue: controller.selectedClass,
                  decoration: const InputDecoration(labelText: 'School class'),
                  items: LearnerCapabilityBoundary.supportedSchoolClasses
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('Class $value'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) controller.setClass(value);
                  },
                ),
              ],
              const SizedBox(height: 12),
              if (controller.isNurseryLearner) ...[
                _SummaryRow(
                  label: 'Nursery activities recorded',
                  value: '${controller.nurseryAttemptEvidence.length}',
                ),
                _SummaryRow(
                  label: 'Review ready',
                  value: '${controller.dueNurseryReviewTasks(limit: 50).length}',
                ),
              ] else ...[
                _SummaryRow(
                  label: 'Level / XP',
                  value: 'Lv ${controller.level} • ${controller.xp} XP',
                ),
                _SummaryRow(label: 'All-time accuracy', value: '$accuracy%'),
                _SummaryRow(
                  label: 'Today',
                  value:
                      '${controller.correctToday}/${controller.answersToday} correct ($dailyAccuracy%)',
                ),
                _SummaryRow(
                  label: 'Learning streak',
                  value: '${controller.streak} days',
                ),
                _SummaryRow(
                  label: 'Study time today',
                  value: '${controller.studyMinutesToday.floor()} min',
                ),
              ],
            ],
          ),
        ),
        if (!controller.isNurseryLearner) ...[
          const SizedBox(height: 14),
          Card(
            margin: EdgeInsets.zero,
            child: ExpansionTile(
              key: const Key('parent_adventure_progress_section'),
              leading: const Icon(Icons.map_rounded),
              title: const Text(
                'Class adventure progress',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '${controller.completedLearningLevels}/${controller.totalLearningLevels} levels cleared • ⭐ ${controller.learningPathStars}',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                LinearProgressIndicator(
                  value: controller.learningPathProgress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: 10),
                ...learningWorlds.map((world) {
                  final completed =
                      controller.completedLevelsForSubject(world.subject);
                  final total = controller.totalLevelsForSubject(world.subject);
                  final stars = controller.starsForSubject(world.subject);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Text(world.emoji,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(
                      world.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: LinearProgressIndicator(
                      value: total == 0 ? 0 : completed / total,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    trailing: Text('$completed/$total • ⭐ $stars'),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            margin: EdgeInsets.zero,
            child: ExpansionTile(
              key: const Key('parent_focus_areas_section'),
              leading: const Icon(Icons.track_changes_rounded),
              title: const Text(
                'Focus areas',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                weakest.isEmpty
                    ? 'More play is needed before focus areas are ranked.'
                    : '${weakest.length} areas need the most practice.',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (weakest.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Play a few adventures first. BrightQuest will then surface the lowest-mastery areas here.',
                      style: TextStyle(color: Colors.black54, height: 1.4),
                    ),
                  )
                else
                  ...weakest.map((gameId) {
                    final game = games.firstWhere((item) => item.id == gameId);
                    final stats = controller.statsFor(gameId);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: game.color.withValues(alpha: 0.12),
                        child: Icon(game.icon, color: game.color),
                      ),
                      title: Text(
                        game.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${(stats.mastery * 100).round()}% mastery • ${(stats.accuracy * 100).round()}% accuracy',
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ParentSectionCard(
            title: 'Reports & class packs',
            subtitle: 'Detailed evidence and parent-only class-pack controls.',
            icon: Icons.insights_rounded,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.insights_rounded),
                  title: const Text('Learning evidence report'),
                  subtitle: const Text(
                    'Competency evidence, review due dates, misconceptions and supervised project evidence.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ParentLearningReportScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.school_rounded),
                  title: const Text('Class packs & restore'),
                  subtitle: const Text(
                    'Parent-only purchase area. Packs remain fail-closed until review and store verification are complete.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ClassPackScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DailyChallengeOverview(controller: controller),
        ],
      ],
    );
  }
}

class _ProfileManager extends StatelessWidget {
  const _ProfileManager({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final List<ChildProfileSnapshot> profiles = controller.profiles;
    return ParentSectionCard(
      title: 'Child profiles',
      subtitle: 'Switch the active learner or add another child.',
      icon: Icons.people_alt_rounded,
      trailing: FilledButton.tonalIcon(
        onPressed: () => _showAddProfileDialog(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add'),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: profiles.map((profile) {
          final active = profile.id == controller.activeProfileId;
          return InputChip(
            selected: active,
            avatar: Text(profile.avatarEmoji),
            label: Text(
              profile.learnerStage == LearnerStage.nursery
                  ? '${profile.name} • Nursery'
                  : '${profile.name} • C${profile.selectedClass}',
            ),
            onSelected: (_) {
              if (!active) controller.switchProfile(profile.id);
            },
            onDeleted: profiles.length <= 1 || !active
                ? null
                : () => _confirmDeleteProfile(context, profile),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showAddProfileDialog(BuildContext context) async {
    final nameController = TextEditingController();
    var learnerStage = LearnerStage.school;
    var classNumber = 3;
    var avatar = '🧒';
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add child profile'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  maxLength: 24,
                  decoration: const InputDecoration(
                    labelText: 'Child name or nickname',
                  ),
                ),
                DropdownButtonFormField<LearnerStage>(
                  initialValue: learnerStage,
                  decoration: const InputDecoration(labelText: 'Learning stage'),
                  items: const [
                    DropdownMenuItem<LearnerStage>(
                      value: LearnerStage.nursery,
                      child: Text('Nursery'),
                    ),
                    DropdownMenuItem<LearnerStage>(
                      value: LearnerStage.school,
                      child: Text('School'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => learnerStage = value);
                    }
                  },
                ),
                if (learnerStage == LearnerStage.school) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: classNumber,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: LearnerCapabilityBoundary.supportedSchoolClasses
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text('Class $value'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => classNumber = value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: ['🧒', '👧', '👦', '🧑']
                      .map(
                        (value) => ChoiceChip(
                          label: Text(
                            value,
                            style: const TextStyle(fontSize: 24),
                          ),
                          selected: avatar == value,
                          onSelected: (_) =>
                              setDialogState(() => avatar = value),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (created == true && context.mounted) {
      final id = controller.createProfile(
        name: nameController.text,
        classNumber: classNumber,
        learnerStage: learnerStage,
        avatarEmoji: avatar,
      );
      if (id.isEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a child name first.')),
        );
      }
    }
    nameController.dispose();
  }

  Future<void> _confirmDeleteProfile(
    BuildContext context,
    ChildProfileSnapshot profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${profile.name}?'),
        content: const Text(
          'This permanently removes this child’s local learning progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) controller.deleteProfile(profile.id);
  }
}

class _DailyChallengeOverview extends StatelessWidget {
  const _DailyChallengeOverview({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: ExpansionTile(
          key: const Key('parent_daily_quests_section'),
          leading: const Icon(Icons.flag_rounded),
          title: const Text(
            'Today’s learning quests',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text('${controller.dailyChallenges.length} quests'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: controller.dailyChallenges.map<Widget>((challenge) {
            final value = controller.dailyChallengeValue(challenge);
            final claimed = controller.isDailyChallengeClaimed(challenge.id);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                claimed ? Icons.check_circle_rounded : Icons.flag_rounded,
              ),
              title: Text(challenge.title),
              subtitle: LinearProgressIndicator(
                value: (value / challenge.target).clamp(0.0, 1.0).toDouble(),
              ),
              trailing: Text(
                '${value.clamp(0, challenge.target)}/${challenge.target}',
              ),
            );
          }).toList(),
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}

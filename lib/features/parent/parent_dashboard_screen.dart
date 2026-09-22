import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/services/bright_audio_service.dart';
import '../../widgets/bright_widgets.dart';
import 'parent_accessibility_screen.dart';
import 'parent_about_app_screen.dart';
import 'parent_audio_settings_screen.dart';
import 'parent_child_learning_screen.dart';
import 'parent_data_security_screen.dart';
import 'parent_healthy_play_screen.dart';
import 'parent_section_scaffold.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final accuracy = (controller.accuracy * 100).round();
    final dailyAccuracy = (controller.dailyAccuracy * 100).round();

    return Column(
      children: [
        BrightHeader(
          title: 'Parent Center',
          trailing: Tooltip(
            message: 'Lock parent area',
            child: IconButton(
              key: const Key('parent_center_lock_button'),
              onPressed: controller.lockParentArea,
              icon: const Icon(Icons.lock_rounded),
            ),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFFF6F8FB),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ActiveChildCard(
                          name: controller.activeProfileName,
                          avatar: controller.activeProfileAvatar,
                          stageLabel: controller.isNurseryLearner
                              ? 'Nursery'
                              : 'Class ${controller.selectedClass}',
                          onManage: () => _open(
                            context,
                            const ParentChildLearningScreen(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (controller.isNurseryLearner)
                          _NurserySnapshot(
                            activities: controller.nurseryAttemptEvidence.length,
                            reviewReady: controller
                                .dueNurseryReviewTasks(limit: 50)
                                .length,
                          )
                        else
                          _SchoolSnapshot(
                            level: controller.level,
                            xp: controller.xp,
                            accuracy: accuracy,
                            correctToday: controller.correctToday,
                            answersToday: controller.answersToday,
                            dailyAccuracy: dailyAccuracy,
                            streak: controller.streak,
                            studyMinutes:
                                controller.studyMinutesToday.floor(),
                            completedLevels:
                                controller.completedLearningLevels,
                            totalLevels: controller.totalLearningLevels,
                            progress: controller.learningPathProgress,
                            stars: controller.learningPathStars,
                          ),
                        const SizedBox(height: 20),
                        const Text(
                          'Manage',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Open only the settings you need instead of scrolling through one long parent page.',
                          style: TextStyle(color: Colors.black54, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 900
                                ? 3
                                : constraints.maxWidth >= 400
                                    ? 2
                                    : 1;
                            const gap = 12.0;
                            final tileWidth = (constraints.maxWidth -
                                    (columns - 1) * gap) /
                                columns;
                            final audio = BrightAudioService.instance;
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                  width: tileWidth,
                                  child: ParentManagementTile(
                                    key: const Key(
                                        'parent_manage_child_learning'),
                                    icon: Icons.school_rounded,
                                    title: 'Child & learning',
                                    subtitle:
                                        'Profiles, class, progress, reports and class packs.',
                                    status: controller.isNurseryLearner
                                        ? 'Nursery profile active'
                                        : '${controller.completedLearningLevels}/${controller.totalLearningLevels} levels cleared',
                                    onTap: () => _open(
                                      context,
                                      const ParentChildLearningScreen(),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: ParentManagementTile(
                                    key: const Key('parent_manage_healthy_play'),
                                    icon: Icons.health_and_safety_rounded,
                                    title: 'Healthy play',
                                    subtitle:
                                        'Daily limit, learning goal and reminders.',
                                    status: controller.timeLimitEnabled
                                        ? '${controller.dailyTimeLimitMinutes} min daily limit'
                                        : 'No daily time limit',
                                    onTap: () => _open(
                                      context,
                                      const ParentHealthyPlayScreen(),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: ParentManagementTile(
                                    key: const Key('parent_manage_audio'),
                                    icon: Icons.volume_up_rounded,
                                    title: 'Audio & narration',
                                    subtitle:
                                        'BGM, game sounds, narrator and volumes.',
                                    status: audio.appAudioEnabled
                                        ? 'App-wide audio on'
                                        : 'App-wide audio muted',
                                    onTap: () => _open(
                                      context,
                                      const ParentAudioSettingsScreen(),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: ParentManagementTile(
                                    key: const Key(
                                        'parent_manage_accessibility'),
                                    icon: Icons.visibility_rounded,
                                    title: 'Reading & accessibility',
                                    subtitle:
                                        'Spacing, reading focus, captions and language.',
                                    status: controller.captionsEnabled
                                        ? 'Captions on'
                                        : 'Captions off',
                                    onTap: () => _open(
                                      context,
                                      const ParentAccessibilityScreen(),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: ParentManagementTile(
                                    key: const Key(
                                        'parent_manage_data_security'),
                                    icon: Icons.admin_panel_settings_rounded,
                                    title: 'Data & parent lock',
                                    subtitle:
                                        'Recovery code, parent lock and progress reset.',
                                    status: 'Local & offline-first',
                                    onTap: () => _open(
                                      context,
                                      const ParentDataSecurityScreen(),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: ParentManagementTile(
                                    key: const Key('parent_manage_about_updates'),
                                    icon: Icons.info_outline_rounded,
                                    title: 'About us & updates',
                                    subtitle:
                                        'Developer, support, website, version and Store status.',
                                    status: 'Version 0.6.0+26',
                                    onTap: () => _open(
                                      context,
                                      const ParentAboutAppScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.offline_bolt_rounded,
                              size: 19,
                              color: Color(0xFF415F8F),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Offline-first parent controls. No ads, chat or social feeds are enabled.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}

class _ActiveChildCard extends StatelessWidget {
  const _ActiveChildCard({
    required this.name,
    required this.avatar,
    required this.stageLabel,
    required this.onManage,
  });

  final String name;
  final String avatar;
  final String stageLabel;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEAF0F8),
                child: Text(avatar, style: const TextStyle(fontSize: 27)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active child',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(stageLabel),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onManage,
                child: const Text('Manage'),
              ),
            ],
          ),
        ),
      );
}

class _NurserySnapshot extends StatelessWidget {
  const _NurserySnapshot({required this.activities, required this.reviewReady});

  final int activities;
  final int reviewReady;

  @override
  Widget build(BuildContext context) => _SnapshotCard(
        items: [
          _SnapshotValue('Activities', '$activities'),
          _SnapshotValue('Review ready', '$reviewReady'),
        ],
      );
}

class _SchoolSnapshot extends StatelessWidget {
  const _SchoolSnapshot({
    required this.level,
    required this.xp,
    required this.accuracy,
    required this.correctToday,
    required this.answersToday,
    required this.dailyAccuracy,
    required this.streak,
    required this.studyMinutes,
    required this.completedLevels,
    required this.totalLevels,
    required this.progress,
    required this.stars,
  });

  final int level;
  final int xp;
  final int accuracy;
  final int correctToday;
  final int answersToday;
  final int dailyAccuracy;
  final int streak;
  final int studyMinutes;
  final int completedLevels;
  final int totalLevels;
  final double progress;
  final int stars;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _SnapshotCard(
                embedded: true,
                items: [
                  _SnapshotValue('Level / XP', 'Lv $level • $xp XP'),
                  _SnapshotValue('Accuracy', '$accuracy%'),
                  _SnapshotValue(
                    'Today',
                    '$correctToday/$answersToday • $dailyAccuracy%',
                  ),
                  _SnapshotValue('Streak', '$streak days'),
                  _SnapshotValue('Study today', '$studyMinutes min'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$completedLevels/$totalLevels learning levels',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text('⭐ $stars'),
                ],
              ),
              const SizedBox(height: 7),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
              ),
            ],
          ),
        ),
      );
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.items, this.embedded = false});

  final List<_SnapshotValue> items;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth >= 480
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.value,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
    if (embedded) return content;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }
}

class _SnapshotValue {
  const _SnapshotValue(this.label, this.value);

  final String label;
  final String value;
}

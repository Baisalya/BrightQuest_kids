import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/curriculum/curriculum_catalog.dart';
import '../../core/models/game_models.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/bright_audio_service.dart';
import '../../core/state/game_controller.dart';
import '../../widgets/bright_widgets.dart';
import 'class_pack_screen.dart';
import 'parent_learning_report_screen.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final accuracy = (controller.accuracy * 100).round();
    final dailyAccuracy = (controller.dailyAccuracy * 100).round();
    final weakest = controller.weakestGameIds();

    return Column(
      children: [
        BrightHeader(
          title: 'Parent Dashboard',
          trailing: IconButton(
            tooltip: 'Lock parent area',
            onPressed: controller.lockParentArea,
            icon: const Icon(Icons.lock_rounded),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _ProfileManager(controller: controller),
              const SizedBox(height: 18),
              Text(
                '${controller.activeProfileAvatar} ${controller.activeProfileName} • Class ${controller.selectedClass}',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        key: ValueKey<String>(
                            'class-${controller.activeProfileId}'),
                        initialValue: controller.selectedClass,
                        decoration:
                            const InputDecoration(labelText: 'School class'),
                        items: const [3, 4, 5]
                            .map((value) => DropdownMenuItem<int>(
                                value: value, child: Text('Class $value')))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) controller.setClass(value);
                        },
                      ),
                      const SizedBox(height: 10),
                      _Row(
                          label: 'Level / XP',
                          value:
                              'Lv ${controller.level} • ${controller.xp} XP'),
                      _Row(label: 'All-time accuracy', value: '$accuracy%'),
                      _Row(
                        label: 'Today',
                        value:
                            '${controller.correctToday}/${controller.answersToday} correct ($dailyAccuracy%)',
                      ),
                      _Row(
                          label: 'Learning streak',
                          value: '${controller.streak} days'),
                      _Row(
                        label: 'Study time today',
                        value: '${controller.studyMinutesToday.floor()} min',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Class adventure map',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${controller.completedLearningLevels}/${controller.totalLearningLevels} levels cleared',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Text(
                            '⭐ ${controller.learningPathStars}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: controller.learningPathProgress,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      const SizedBox(height: 12),
                      ...learningWorlds.map((world) {
                        final completed =
                            controller.completedLevelsForSubject(world.subject);
                        final total =
                            controller.totalLevelsForSubject(world.subject);
                        final stars = controller.starsForSubject(world.subject);
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Text(world.emoji,
                              style: const TextStyle(fontSize: 25)),
                          title: Text(world.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
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
              ),
              const SizedBox(height: 18),
              const Text(
                'Focus areas',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: weakest.isEmpty
                      ? const Text(
                          'Play a few adventures first. BrightQuest will then surface the lowest-mastery areas here.',
                          style: TextStyle(color: Colors.black54, height: 1.4),
                        )
                      : Column(
                          children: weakest.map((gameId) {
                            final game =
                                games.firstWhere((item) => item.id == gameId);
                            final stats = controller.statsFor(gameId);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor:
                                    game.color.withValues(alpha: 0.12),
                                child: Icon(game.icon, color: game.color),
                              ),
                              title: Text(game.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              subtitle: Text(
                                '${(stats.mastery * 100).round()}% mastery • ${(stats.accuracy * 100).round()}% accuracy',
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Learning evidence & class packs',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.insights_rounded),
                      title: const Text('Learning evidence report'),
                      subtitle: const Text(
                        'See competency evidence, review due dates, misconceptions and supervised project evidence.',
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
                        'Parent-only purchase area. Packs stay locked for sale until review and store verification are complete.',
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
              const SizedBox(height: 18),
              const Text(
                'Reading & accessibility',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Dyslexia-friendly spacing'),
                      subtitle: const Text(
                        'Adds breathing room between letters and lines. This is a reading preference, not a medical treatment.',
                      ),
                      value: controller.dyslexiaFriendlySpacing,
                      onChanged: controller.setDyslexiaFriendlySpacing,
                    ),
                    SwitchListTile(
                      title: const Text('Reading focus'),
                      subtitle: const Text(
                        'Highlights the current learning text and narration transcript with extra spacing and contrast.',
                      ),
                      value: controller.readingFocusEnabled,
                      onChanged: controller.setReadingFocusEnabled,
                    ),
                    SwitchListTile(
                      title: const Text('Captions / visible audio meaning'),
                      subtitle: const Text(
                        'Shows the current narration transcript and choices even when speech is muted or unavailable.',
                      ),
                      value: controller.captionsEnabled,
                      onChanged: controller.setCaptionsEnabled,
                    ),
                    const ListTile(
                      title: Text('Learning language'),
                      subtitle: Text(
                        'English (India). Hindi remains unavailable until a reviewed translation pack exists; answers are never mixed across locales.',
                      ),
                      trailing: Text('en-IN'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Healthy play controls',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Daily time limit'),
                        subtitle: Text(
                          controller.timeLimitEnabled
                              ? 'Games pause after ${controller.dailyTimeLimitMinutes} minutes of active learning-game time.'
                              : 'Off. Learning games are not time-blocked.',
                        ),
                        value: controller.timeLimitEnabled,
                        onChanged: controller.setTimeLimitEnabled,
                      ),
                      if (controller.timeLimitEnabled) ...[
                        ListTile(
                          title: Text(
                              'Limit: ${controller.dailyTimeLimitMinutes} min'),
                          subtitle: Text(
                              '${controller.studyMinutesToday.floor()} min used today'),
                        ),
                        Slider(
                          value: controller.dailyTimeLimitMinutes.toDouble(),
                          min: 15,
                          max: 180,
                          divisions: 11,
                          label: '${controller.dailyTimeLimitMinutes} min',
                          onChanged: (value) => controller
                              .setDailyTimeLimitMinutes(value.round()),
                        ),
                      ],
                      ListTile(
                          title: Text(
                              'Daily learning goal: ${controller.dailyMinutesGoal} min')),
                      Slider(
                        value: controller.dailyMinutesGoal.toDouble(),
                        min: 10,
                        max: 60,
                        divisions: 10,
                        label: '${controller.dailyMinutesGoal} min',
                        onChanged: (value) =>
                            controller.setDailyMinutesGoal(value.round()),
                      ),
                      SwitchListTile(
                        title:
                            Text('Audio for ${controller.activeProfileName}'),
                        subtitle: const Text(
                            'Master switch for music, guide voice and sound effects.'),
                        value: controller.soundEnabled,
                        onChanged: (value) {
                          controller.setSoundEnabled(value);
                          unawaited(BrightAudioService.instance
                              .setSessionEnabled(value));
                        },
                      ),
                      AnimatedBuilder(
                        animation: BrightAudioService.instance,
                        builder: (context, _) {
                          final audio = BrightAudioService.instance;
                          return Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Background music'),
                                subtitle: const Text(
                                    'Gentle looping music changes with each adventure.'),
                                value: audio.musicEnabled,
                                onChanged: controller.soundEnabled
                                    ? audio.setMusicEnabled
                                    : null,
                              ),
                              SwitchListTile(
                                title: const Text('Gentle guide voice'),
                                subtitle: Text(
                                  audio.voiceAvailable
                                      ? 'Smart read speaks questions, choices, and answer feedback.'
                                      : 'Install a Windows speech voice to enable narration.',
                                ),
                                value:
                                    audio.voiceAvailable && audio.voiceEnabled,
                                onChanged: controller.soundEnabled &&
                                        audio.voiceAvailable
                                    ? audio.setVoiceEnabled
                                    : null,
                              ),
                              if (audio.availableVoices.isNotEmpty)
                                ListTile(
                                  title: const Text('Narration voice'),
                                  subtitle: DropdownButton<String>(
                                    key: const Key('guide_voice_selector'),
                                    isExpanded: true,
                                    value: audio.selectedVoiceId,
                                    hint: const Text('Choose a voice'),
                                    items: [
                                      for (final voice in audio.availableVoices)
                                        DropdownMenuItem<String>(
                                          value: voice.id,
                                          child: Text(
                                            voice.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                    onChanged: controller.soundEnabled &&
                                            audio.voiceEnabled
                                        ? (value) {
                                            if (value != null) {
                                              unawaited(audio.setVoice(value));
                                            }
                                          }
                                        : null,
                                  ),
                                  trailing:
                                      audio.selectedVoice?.isFemale == true
                                          ? const Tooltip(
                                              message:
                                                  'Female voice selected by default',
                                              child: Icon(
                                                Icons.woman_2_rounded,
                                                color: Color(0xFFF0549B),
                                              ),
                                            )
                                          : null,
                                ),
                              SwitchListTile(
                                title:
                                    const Text('Automatic learning narration'),
                                subtitle: const Text(
                                    'Reads lesson steps automatically and keeps game introductions spoken. Read-aloud buttons always remain manual.'),
                                value: audio.autoNarrationEnabled,
                                onChanged: controller.soundEnabled &&
                                        audio.voiceAvailable &&
                                        audio.voiceEnabled
                                    ? audio.setAutoNarrationEnabled
                                    : null,
                              ),
                              SwitchListTile(
                                title: const Text('Cheerful voice feedback'),
                                subtitle: const Text(
                                    'Short praise and encouragement after answers.'),
                                value: audio.voiceFeedbackEnabled,
                                onChanged: controller.soundEnabled &&
                                        audio.voiceAvailable &&
                                        audio.voiceEnabled
                                    ? audio.setVoiceFeedbackEnabled
                                    : null,
                              ),
                              SwitchListTile(
                                title: const Text('Sound effects'),
                                subtitle: const Text(
                                    'Tap, hint, correct, star, unlock and completion sounds.'),
                                value: audio.sfxEnabled,
                                onChanged: controller.soundEnabled
                                    ? audio.setSfxEnabled
                                    : null,
                              ),
                              ListTile(
                                title: Text(
                                    'BGM music volume ${(audio.musicVolume * 100).round()}%'),
                                subtitle: Slider(
                                  value: audio.musicVolume,
                                  min: 0,
                                  max: 0.55,
                                  onChanged: controller.soundEnabled &&
                                          audio.musicEnabled
                                      ? audio.setMusicVolume
                                      : null,
                                ),
                              ),
                              ListTile(
                                title: Text(
                                    'Game sound effects volume ${(audio.sfxVolume * 100).round()}%'),
                                subtitle: Slider(
                                  value: audio.sfxVolume,
                                  min: 0.15,
                                  max: 1,
                                  onChanged: controller.soundEnabled &&
                                          audio.sfxEnabled
                                      ? audio.setSfxVolume
                                      : null,
                                ),
                              ),
                              ListTile(
                                title: Text(
                                    'Speech narration volume ${(audio.voiceVolume * 100).round()}%'),
                                subtitle: Slider(
                                  value: audio.voiceVolume,
                                  min: 0.2,
                                  max: 1,
                                  onChanged: controller.soundEnabled &&
                                          audio.voiceAvailable &&
                                          audio.voiceEnabled
                                      ? audio.setVoiceVolume
                                      : null,
                                ),
                                trailing: IconButton(
                                  tooltip: 'Test guide voice',
                                  onPressed: controller.soundEnabled &&
                                          audio.voiceAvailable &&
                                          audio.voiceEnabled
                                      ? audio.testVoice
                                      : null,
                                  icon: const Icon(
                                      Icons.record_voice_over_rounded),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                    'Guide speed ${(audio.voiceRate * 100).round()}%'),
                                subtitle: Slider(
                                  value: audio.voiceRate,
                                  min: 0.30,
                                  max: 0.62,
                                  divisions: 8,
                                  onChanged: controller.soundEnabled &&
                                          audio.voiceAvailable &&
                                          audio.voiceEnabled
                                      ? audio.setVoiceRate
                                      : null,
                                ),
                              ),
                              ListTile(
                                title: Text(audio.voicePitchAvailable
                                    ? 'Guide tone ${(audio.voicePitch * 100).round()}%'
                                    : 'Guide tone (Android only)'),
                                subtitle: Slider(
                                  value: audio.voicePitch,
                                  min: 0.80,
                                  max: 1.30,
                                  divisions: 10,
                                  onChanged: controller.soundEnabled &&
                                          audio.voiceAvailable &&
                                          audio.voiceEnabled &&
                                          audio.voicePitchAvailable
                                      ? audio.setVoicePitch
                                      : null,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Learning reminders'),
                        subtitle: const Text(
                            'Saved preference; OS notification scheduling is not enabled yet.'),
                        value: controller.remindersEnabled,
                        onChanged: controller.setRemindersEnabled,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _DailyChallengeOverview(controller: controller),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Local data controls',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Reset clears learning progress only for the active child. Other child profiles and the parent PIN are preserved.',
                        style: TextStyle(color: Colors.black54, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _confirmReset(context),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Reset active child progress'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Offline-first: profiles, progress and controls are stored locally. No ads, chat, purchases or social feeds are enabled.',
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final controller = BrightQuestScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reset ${controller.activeProfileName} progress?'),
        content: const Text(
            'Coins, stars, XP, answers, mastery, Learning World levels, achievements and cosmetic unlocks for this child will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await controller.resetProgress();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Active child progress reset.')),
        );
      }
    }
  }
}

class _ProfileManager extends StatelessWidget {
  const _ProfileManager({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final List<ChildProfileSnapshot> profiles = controller.profiles;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Child profiles',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _showAddProfileDialog(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profiles.map((profile) {
                final active = profile.id == controller.activeProfileId;
                return InputChip(
                  selected: active,
                  avatar: Text(profile.avatarEmoji),
                  label: Text('${profile.name} • C${profile.selectedClass}'),
                  onSelected: (_) {
                    if (!active) controller.switchProfile(profile.id);
                  },
                  onDeleted: profiles.length <= 1 || !active
                      ? null
                      : () => _confirmDeleteProfile(context, profile),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddProfileDialog(BuildContext context) async {
    final nameController = TextEditingController();
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
                      labelText: 'Child name or nickname'),
                ),
                DropdownButtonFormField<int>(
                  initialValue: classNumber,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: const [3, 4, 5]
                      .map((value) => DropdownMenuItem(
                          value: value, child: Text('Class $value')))
                      .toList(),
                  onChanged: (value) {
                    if (value != null)
                      setDialogState(() => classNumber = value);
                  },
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: ['🧒', '👧', '👦', '🧑']
                      .map(
                        (value) => ChoiceChip(
                          label:
                              Text(value, style: const TextStyle(fontSize: 24)),
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
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Create')),
          ],
        ),
      ),
    );
    if (created == true && context.mounted) {
      final id = controller.createProfile(
          name: nameController.text,
          classNumber: classNumber,
          avatarEmoji: avatar);
      if (id.isEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a child name first.')));
      }
    }
    nameController.dispose();
  }

  Future<void> _confirmDeleteProfile(
      BuildContext context, ChildProfileSnapshot profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${profile.name}?'),
        content: const Text(
            'This permanently removes this child’s local learning progress.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete')),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Today’s learning quests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...controller.dailyChallenges
                  .map<Widget>((DailyChallenge challenge) {
                final value = controller.dailyChallengeValue(challenge);
                final claimed =
                    controller.isDailyChallengeClaimed(challenge.id);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(claimed
                      ? Icons.check_circle_rounded
                      : Icons.flag_rounded),
                  title: Text(challenge.title),
                  subtitle: LinearProgressIndicator(
                    value:
                        (value / challenge.target).clamp(0.0, 1.0).toDouble(),
                  ),
                  trailing: Text(
                      '${value.clamp(0, challenge.target)}/${challenge.target}'),
                );
              }),
            ],
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
                child:
                    Text(label, style: const TextStyle(color: Colors.black54))),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
}

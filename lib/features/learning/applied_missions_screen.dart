import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/learning/applied_mission_catalog.dart';
import '../../core/learning/learning_models.dart';

class AppliedMissionsScreen extends StatelessWidget {
  const AppliedMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final repository = BrightQuestScope.contentOf(context);
    final missions = const AppliedMissionCatalog().forClass(
      repository.curriculum,
      controller.selectedClass,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Applied Missions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'These missions combine two or more skills. They use only local, safe scenarios—no child uploads, chat, or public sharing.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final mission in missions)
            Card(
              child: ListTile(
                title: Text(mission.title),
                subtitle: Text(mission.brief, maxLines: 4),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _MissionReflectionScreen(mission: mission),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MissionReflectionScreen extends StatefulWidget {
  const _MissionReflectionScreen({required this.mission});
  final AppliedMissionDefinition mission;

  @override
  State<_MissionReflectionScreen> createState() =>
      _MissionReflectionScreenState();
}

class _MissionReflectionScreenState extends State<_MissionReflectionScreen> {
  double correctness = 0.5;
  double strategy = 0.5;
  double independence = 0.5;
  double explanation = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mission.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.mission.brief),
                  const SizedBox(height: 14),
                  Text(
                    'Reflection',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(widget.mission.reflection),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mission reflection (not mastery evidence)',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'A child may reflect here, but these ratings stay unverified and never create secure mastery. A parent or teacher can discuss the mission later.',
          ),
          _ScoreSlider(
            label: 'Correctness',
            value: correctness,
            onChanged: (value) => setState(() => correctness = value),
          ),
          _ScoreSlider(
            label: 'Strategy',
            value: strategy,
            onChanged: (value) => setState(() => strategy = value),
          ),
          _ScoreSlider(
            label: 'Independence',
            value: independence,
            onChanged: (value) => setState(() => independence = value),
          ),
          _ScoreSlider(
            label: 'Explanation',
            value: explanation,
            onChanged: (value) => setState(() => explanation = value),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final controller = BrightQuestScope.of(context);
              final now = DateTime.now();
              controller.recordProjectEvidence(
                ProjectEvidence(
                  id: 'project:${controller.activeProfileId}:${now.microsecondsSinceEpoch}',
                  missionId: widget.mission.id,
                  classNumber: widget.mission.classNumber,
                  competencyIds: widget.mission.competencyIds,
                  correctness: correctness,
                  strategy: strategy,
                  independence: independence,
                  explanation: explanation,
                  completedAtIso: now.toIso8601String(),
                  adultVerified: false,
                ),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Save mission reflection'),
          ),
        ],
      ),
    );
  }
}

class _ScoreSlider extends StatelessWidget {
  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('$label ${(value * 100).round()}%'),
        subtitle: Slider(
          value: value,
          divisions: 4,
          onChanged: onChanged,
        ),
      );
}

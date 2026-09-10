import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/nursery/nursery_content.dart';
import '../../core/nursery/nursery_visuals.dart';
import '../../core/services/bright_audio_service.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_motion.dart';
import '../../widgets/bright_widgets.dart';
import 'nursery_home_plan.dart';
import 'nursery_lesson_screen.dart';
import 'nursery_domain_presentation.dart';
import 'nursery_visual.dart';
import 'nursery_world_screen.dart';

class NurseryHomeScreen extends StatelessWidget {
  const NurseryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = BrightQuestScope.contentOf(context);
    final pack = repository.nurseryPack;
    final controller = BrightQuestScope.of(context);
    if (pack == null) {
      return const Scaffold(
        body: Center(child: Text('Nursery Learning Garden is unavailable.')),
      );
    }

    final due = controller.dueNurseryReviewTasks(limit: 10);
    final plan = NurseryHomePlanner.build(
      pack: pack,
      dueTasks: due,
      masteryFor: controller.nurseryMasteryFor,
    );
    return Scaffold(
      body: BrightPageBackground(
        primary: const Color(0xFFF4FFF7),
        secondary: const Color(0xFFFFFAE8),
        child: Column(
          children: [
            BrightHeader(
              showBack: true,
              title: 'Nursery Learning Garden',
              trailing: IconButton(
                tooltip: 'Hear welcome',
                onPressed: () => unawaited(
                  BrightAudioService.instance.speak(
                    'Welcome to Nursery Play. Tap the big play button, or choose a world.',
                    manual: true,
                  ),
                ),
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ),
            Expanded(
              child: ListView(
                key: const PageStorageKey<String>('nursery-calm-home'),
                padding: EdgeInsets.zero,
                children: [
                  BrightResponsive(
                    maxWidth: 980,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    builder: (context, _) => _NextPlayCard(plan: plan),
                  ),
                  BrightResponsive(
                    maxWidth: 980,
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                    builder: (context, _) => _WorldPicker(
                      pack: pack,
                      plan: plan,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextPlayCard extends StatelessWidget {
  const _NextPlayCard({required this.plan});

  final NurseryHomePlan plan;

  @override
  Widget build(BuildContext context) {
    final action = plan.primaryAction;
    final color = nurseryDomainColor(action.skill.domainId);
    return BrightReveal(
      duration: const Duration(milliseconds: 280),
      beginScale: .99,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: .18),
              Colors.white,
              const Color(0xFFFFFCF1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: .16), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .09),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 620;
            final visual = Container(
              width: horizontal ? 116 : 92,
              height: horizontal ? 116 : 92,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: NurseryVisual(
                spec: NurseryVisualResolver.forSkill(action.skill),
                size: horizontal ? 78 : 62,
                decorative: true,
              ),
            );
            final message = Column(
              crossAxisAlignment:
                  horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Text(
                  'Ready to play?',
                  textAlign: horizontal ? TextAlign.left : TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  action.subtitle,
                  textAlign: horizontal ? TextAlign.left : TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  button: true,
                  label: '${action.title}. ${action.skill.title}.',
                  child: FilledButton.icon(
                    key: const Key('nursery-primary-action'),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(176, 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NurseryLessonScreen(
                          skillId: action.skill.id,
                          reviewMode: action.reviewMode,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      action.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
              ],
            );

            if (!horizontal) {
              return Column(
                children: [
                  visual,
                  const SizedBox(height: 12),
                  message,
                ],
              );
            }
            return Row(
              children: [
                visual,
                const SizedBox(width: 22),
                Expanded(child: message),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WorldPicker extends StatelessWidget {
  const _WorldPicker({required this.pack, required this.plan});

  final NurseryContentPack pack;
  final NurseryHomePlan plan;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose a world',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            'Four big places to learn and play',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: .68),
                ),
          ),
          const SizedBox(height: 14),
          BrightAdaptiveGrid(
            minChildWidth: 145,
            maxColumns: 4,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final domain in pack.domains)
                _WorldCard(
                  pack: pack,
                  domain: domain,
                  progress: plan.progressFor(domain.id),
                ),
            ],
          ),
        ],
      );
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.pack,
    required this.domain,
    required this.progress,
  });

  final NurseryContentPack pack;
  final NurseryDomain domain;
  final NurseryDomainProgress progress;

  @override
  Widget build(BuildContext context) {
    final color = nurseryDomainColor(domain.id);
    final status = _domainProgressLabel(progress);
    return Semantics(
      button: true,
      label: '${nurseryDomainTitle(domain)}. ${nurseryDomainSubtitle(domain.id)}. '
          '${progress.startedSkills} of ${progress.totalSkills} activities started. Tap to open.',
      child: BrightPressableScale(
        hoverScale: 1.012,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('nursery-world-${domain.id}'),
            borderRadius: BorderRadius.circular(26),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NurseryWorldScreen(
                  pack: pack,
                  domain: domain,
                ),
              ),
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 154),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .90),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: color.withValues(alpha: .17)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .06),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 190;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: compact ? 64 : 72,
                        height: compact ? 64 : 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: NurseryVisual(
                          spec: NurseryVisualResolver.forDomain(domain),
                          size: compact ? 48 : 54,
                          decorative: true,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        nurseryDomainTitle(domain),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          nurseryDomainSubtitle(domain.id),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress.progress,
                          minHeight: 6,
                          backgroundColor: color.withValues(alpha: .10),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _domainProgressLabel(NurseryDomainProgress progress) {
  if (progress.totalSkills > 0 && progress.secureSkills == progress.totalSkills) {
    return 'All explored';
  }
  if (progress.startedSkills > 0) return 'Keep going';
  return 'New';
}

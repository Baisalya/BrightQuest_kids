import 'package:flutter/material.dart';

import '../../../../core/learning/gameplay_activity_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/bright_motion.dart';
import '../activity_game_contract.dart';

/// A single-answer mechanic that still feels native to the selected world.
/// The authored choices are rendered as market stalls, story steps, lab
/// samples, expedition markers, or robot modules without changing their value.
class ThemedChoiceActivity extends StatefulWidget {
  const ThemedChoiceActivity({
    required this.values,
    required this.presentation,
    required this.locked,
    required this.onResponseChanged,
    super.key,
  });

  final List<Object?> values;
  final LearningGameChoicePresentation presentation;
  final bool locked;
  final GameActivityResponseChanged onResponseChanged;

  @override
  State<ThemedChoiceActivity> createState() => _ThemedChoiceActivityState();
}

class _ThemedChoiceActivityState extends State<ThemedChoiceActivity> {
  Object? _selected;

  void _select(Object? value) {
    if (widget.locked) return;
    setState(() => _selected = value);
    widget.onResponseChanged(
      GameActivityResponseSnapshot(value: value, ready: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final descriptor = _descriptor(widget.presentation);
    final compactHeight = MediaQuery.sizeOf(context).height < 820;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compactHeight) ...[
          _ChoiceMissionHeader(descriptor: descriptor),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 620
                ? 2
                : constraints.maxWidth >= 390
                    ? 2
                    : 1;
            final width = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var index = 0; index < widget.values.length; index += 1)
                  SizedBox(
                    width: width,
                    child: _WorldChoiceTile(
                      value: widget.values[index],
                      number: index + 1,
                      selected: _sameValue(_selected, widget.values[index]),
                      enabled: !widget.locked,
                      descriptor: descriptor,
                      compact: compactHeight,
                      onTap: () => _select(widget.values[index]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  static bool _sameValue(Object? left, Object? right) {
    if (left is num && right is num) {
      return left.toDouble() == right.toDouble();
    }
    return left == right;
  }
}

class _ChoiceMissionHeader extends StatelessWidget {
  const _ChoiceMissionHeader({required this.descriptor});

  final _ChoiceDescriptor descriptor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              descriptor.soft,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: descriptor.accent.withValues(alpha: .20)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: descriptor.accent.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  Text(descriptor.emoji, style: const TextStyle(fontSize: 23)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descriptor.title,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descriptor.instruction,
                    style: const TextStyle(
                      color: AppTheme.inkMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _WorldChoiceTile extends StatelessWidget {
  const _WorldChoiceTile({
    required this.value,
    required this.number,
    required this.selected,
    required this.enabled,
    required this.descriptor,
    required this.compact,
    required this.onTap,
  });

  final Object? value;
  final int number;
  final bool selected;
  final bool enabled;
  final _ChoiceDescriptor descriptor;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BrightPressableScale(
        child: Semantics(
          selected: selected,
          button: true,
          label: 'Answer $number: $value',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(19),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOutCubic,
                constraints: BoxConstraints(minHeight: compact ? 60 : 78),
                padding: EdgeInsets.all(compact ? 8 : 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: selected
                        ? [
                            descriptor.accent.withValues(alpha: .20),
                            descriptor.soft,
                          ]
                        : [
                            Colors.white,
                            descriptor.soft.withValues(alpha: .45),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: selected
                        ? descriptor.accent
                        : descriptor.accent.withValues(alpha: .25),
                    width: selected ? 2.2 : 1.2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: descriptor.accent.withValues(alpha: .16),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : const [],
                ),
                child: Row(
                  children: [
                    _ChoiceMarker(
                      number: number,
                      selected: selected,
                      descriptor: descriptor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            descriptor.optionLabel(number),
                            style: TextStyle(
                              color: descriptor.accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 9.5,
                              letterSpacing: .35,
                            ),
                          ),
                          SizedBox(height: compact ? 1 : 3),
                          Text(
                            '$value',
                            style: const TextStyle(
                              color: AppTheme.navy,
                              fontWeight: FontWeight.w900,
                              height: 1.22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      selected ? Icons.stars_rounded : descriptor.icon,
                      color: selected ? descriptor.accent : AppTheme.inkMuted,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _ChoiceMarker extends StatelessWidget {
  const _ChoiceMarker({
    required this.number,
    required this.selected,
    required this.descriptor,
  });

  final int number;
  final bool selected;
  final _ChoiceDescriptor descriptor;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? descriptor.accent : Colors.white,
          borderRadius: BorderRadius.circular(
            descriptor.roundMarker ? 99 : 12,
          ),
          border: Border.all(
            color: descriptor.accent.withValues(alpha: selected ? 1 : .35),
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : Text(
                descriptor.markerText(number),
                style: TextStyle(
                  color: descriptor.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
      );
}

class _ChoiceDescriptor {
  const _ChoiceDescriptor({
    required this.emoji,
    required this.title,
    required this.instruction,
    required this.optionPrefix,
    required this.markerPrefix,
    required this.accent,
    required this.soft,
    required this.icon,
    this.roundMarker = false,
  });

  final String emoji;
  final String title;
  final String instruction;
  final String optionPrefix;
  final String markerPrefix;
  final Color accent;
  final Color soft;
  final IconData icon;
  final bool roundMarker;

  String optionLabel(int number) => '$optionPrefix $number'.toUpperCase();
  String markerText(int number) =>
      markerPrefix.isEmpty ? '$number' : '$markerPrefix$number';
}

_ChoiceDescriptor _descriptor(LearningGameChoicePresentation presentation) =>
    switch (presentation) {
      LearningGameChoicePresentation.marketStalls => const _ChoiceDescriptor(
          emoji: '🛒',
          title: 'Market mission',
          instruction:
              'Inspect the stalls and load the answer that solves the mission.',
          optionPrefix: 'Stall',
          markerPrefix: '₹',
          accent: Color(0xFF2385D7),
          soft: Color(0xFFE9F6FF),
          icon: Icons.storefront_rounded,
        ),
      LearningGameChoicePresentation.storyTrail => const _ChoiceDescriptor(
          emoji: '📖',
          title: 'Story trail',
          instruction:
              'Choose the story step that keeps the idea on the right path.',
          optionPrefix: 'Trail',
          markerPrefix: '',
          accent: Color(0xFF268D70),
          soft: Color(0xFFEAF9F3),
          icon: Icons.auto_stories_rounded,
          roundMarker: true,
        ),
      LearningGameChoicePresentation.labScanner => const _ChoiceDescriptor(
          emoji: '🔬',
          title: 'Lab scanner',
          instruction:
              'Scan each sample and select the result that matches the evidence.',
          optionPrefix: 'Sample',
          markerPrefix: 'S',
          accent: Color(0xFF6A4BD2),
          soft: Color(0xFFF1EDFF),
          icon: Icons.biotech_rounded,
        ),
      LearningGameChoicePresentation.ecoTrail => const _ChoiceDescriptor(
          emoji: '🌱',
          title: 'Green mission',
          instruction:
              'Pick the action or idea that helps complete this eco challenge.',
          optionPrefix: 'Path',
          markerPrefix: '',
          accent: Color(0xFF3F9B4C),
          soft: Color(0xFFECF9EE),
          icon: Icons.eco_rounded,
          roundMarker: true,
        ),
      LearningGameChoicePresentation.mapExpedition => const _ChoiceDescriptor(
          emoji: '🧭',
          title: 'Explorer checkpoint',
          instruction:
              'Study the clue and choose the destination marker that fits it.',
          optionPrefix: 'Marker',
          markerPrefix: '',
          accent: Color(0xFFD97922),
          soft: Color(0xFFFFF3E7),
          icon: Icons.location_on_rounded,
          roundMarker: true,
        ),
      LearningGameChoicePresentation.robotConsole => const _ChoiceDescriptor(
          emoji: '🤖',
          title: 'Robot console',
          instruction:
              'Choose the module that gives the robot the correct instruction.',
          optionPrefix: 'Module',
          markerPrefix: 'C',
          accent: Color(0xFF574FC4),
          soft: Color(0xFFF0EFFF),
          icon: Icons.memory_rounded,
        ),
      LearningGameChoicePresentation.questCards => const _ChoiceDescriptor(
          emoji: '⭐',
          title: 'Quest choice',
          instruction:
              'Choose the answer that completes this learning mission.',
          optionPrefix: 'Choice',
          markerPrefix: '',
          accent: AppTheme.purple,
          soft: AppTheme.surfaceLavender,
          icon: Icons.auto_awesome_rounded,
          roundMarker: true,
        ),
    };

import 'package:flutter/material.dart';

import '../../../../core/content/content_activity.dart';
import '../../../../core/theme/app_theme.dart';
import '../activity_game_contract.dart';

class GrammarSortActivity extends StatefulWidget {
  const GrammarSortActivity({
    required this.activity,
    required this.locked,
    required this.onResponseChanged,
    super.key,
  });

  final ContentActivity activity;
  final bool locked;
  final GameActivityResponseChanged onResponseChanged;

  @override
  State<GrammarSortActivity> createState() => _GrammarSortActivityState();
}

class _GrammarSortActivityState extends State<GrammarSortActivity> {
  final Map<String, String> _roles = <String, String>{};
  String _activeRole = 'noun';

  void _assign(String role, String word) {
    if (widget.locked) return;
    setState(() {
      _roles[role] = word;
      _activeRole = role;
    });
    widget.onResponseChanged(
      GameActivityResponseSnapshot(
        value: Map<String, String>.from(_roles),
        ready: _roles.length == 3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentence = '${widget.activity.payload['sentence']}';
    final words = RegExp(r"[A-Za-z']+")
        .allMatches(sentence)
        .map((match) => match.group(0)!)
        .toSet()
        .toList(growable: false);
    const parts = <String>['noun', 'verb', 'adjective'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF2FA), Color(0xFFF1FFF8)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🧙', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 7),
                  Text(
                    'Power the sentence',
                    style: TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                sentence,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 470;
            final width = compact
                ? constraints.maxWidth
                : (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final part in parts)
                  SizedBox(
                    width: width,
                    child: _GrammarBucket(
                      part: part,
                      value: _roles[part],
                      active: _activeRole == part,
                      enabled: !widget.locked,
                      onActivate: () => setState(() => _activeRole = part),
                      onAccept: (word) => _assign(part, word),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Choose a word for the ${_activeRole.toUpperCase()} portal',
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final word in words)
              LongPressDraggable<String>(
                data: word,
                feedback: Material(
                  color: Colors.transparent,
                  child: _GrammarWordTile(word: word, onTap: () {}),
                ),
                childWhenDragging: Opacity(
                  opacity: .3,
                  child: _GrammarWordTile(word: word, onTap: () {}),
                ),
                child: _GrammarWordTile(
                  word: word,
                  onTap:
                      widget.locked ? null : () => _assign(_activeRole, word),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GrammarBucket extends StatelessWidget {
  const _GrammarBucket({
    required this.part,
    required this.value,
    required this.active,
    required this.enabled,
    required this.onActivate,
    required this.onAccept,
  });

  final String part;
  final String? value;
  final bool active;
  final bool enabled;
  final VoidCallback onActivate;
  final ValueChanged<String> onAccept;

  @override
  Widget build(BuildContext context) {
    final descriptor = _roleDescriptor(part);
    return DragTarget<String>(
      onAcceptWithDetails: enabled ? (details) => onAccept(details.data) : null,
      builder: (context, candidates, rejected) => InkWell(
        onTap: enabled ? onActivate : null,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 102),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                descriptor.color.withValues(
                  alpha: active || candidates.isNotEmpty ? .22 : .10,
                ),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: descriptor.color,
              width: active || candidates.isNotEmpty ? 2 : 1.1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(descriptor.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 5),
              Text(
                part.toUpperCase(),
                style: TextStyle(
                  color: Color.lerp(descriptor.color, Colors.black, .24),
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value ?? 'Drop word here',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrammarWordTile extends StatelessWidget {
  const _GrammarWordTile({required this.word, required this.onTap});

  final String word;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: const Icon(Icons.drag_indicator_rounded, size: 16),
        label: Text(word),
        onPressed: onTap,
      );
}

class _RoleDescriptor {
  const _RoleDescriptor(this.color, this.emoji);

  final Color color;
  final String emoji;
}

_RoleDescriptor _roleDescriptor(String role) => switch (role) {
      'noun' => const _RoleDescriptor(Color(0xFF42A5F5), '🏷️'),
      'verb' => const _RoleDescriptor(Color(0xFF58BE68), '⚡'),
      _ => const _RoleDescriptor(Color(0xFFFFA92F), '✨'),
    };

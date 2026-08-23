import 'package:flutter/material.dart';

import '../../../../core/content/content_activity.dart';
import '../../../../core/theme/app_theme.dart';
import '../activity_game_contract.dart';

class RecyclingSortActivity extends StatefulWidget {
  const RecyclingSortActivity({
    required this.activity,
    required this.choices,
    required this.locked,
    required this.onResponseChanged,
    super.key,
  });

  final ContentActivity activity;
  final List<Object?> choices;
  final bool locked;
  final GameActivityResponseChanged onResponseChanged;

  @override
  State<RecyclingSortActivity> createState() => _RecyclingSortActivityState();
}

class _RecyclingSortActivityState extends State<RecyclingSortActivity> {
  Object? _selectedBin;

  void _select(Object? value) {
    if (widget.locked) return;
    setState(() => _selectedBin = value);
    widget.onResponseChanged(
      GameActivityResponseSnapshot(value: value, ready: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emoji = '${widget.activity.payload['emoji']}';
    final name = '${widget.activity.payload['name']}';

    final objectCard = _WasteObjectCard(
      emoji: emoji,
      name: name,
      compact: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEFAF0),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Row(
            children: [
              Text('🌍', style: TextStyle(fontSize: 25)),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Clean-up mission — drag the item to a bin, or tap the bin.',
                  style: TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Center(
          child: widget.locked
              ? objectCard
              : LongPressDraggable<_WastePayload>(
                  data: _WastePayload(emoji, name),
                  feedback: Material(
                    color: Colors.transparent,
                    child: _WasteObjectCard(
                      emoji: emoji,
                      name: name,
                      compact: true,
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: .28, child: objectCard),
                  child: objectCard,
                ),
        ),
        const SizedBox(height: 12),
        Text(
          _selectedBin == null
              ? 'Where should $name go?'
              : '$name is waiting in the ${_selectedBin!} bin.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 500 ? 3 : 2;
            final width =
                (constraints.maxWidth - ((columns - 1) * 8)) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var index = 0; index < widget.choices.length; index += 1)
                  SizedBox(
                    width: width,
                    child: _BinDropZone(
                      label: '${widget.choices[index]}',
                      index: index,
                      selected: _sameValue(_selectedBin, widget.choices[index]),
                      enabled: !widget.locked,
                      onTap: () => _select(widget.choices[index]),
                      onAccept: (_) => _select(widget.choices[index]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  static bool _sameValue(Object? left, Object? right) => left == right;
}

class _WasteObjectCard extends StatelessWidget {
  const _WasteObjectCard({
    required this.emoji,
    required this.name,
    required this.compact,
  });

  final String emoji;
  final String name;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(maxWidth: compact ? 170 : 240),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 10 : 13,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB9DDBD), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x180B5B23),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: compact ? 32 : 42)),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (!compact)
                    const Text(
                      'hold & drag',
                      style: TextStyle(
                        color: AppTheme.inkMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _BinDropZone extends StatelessWidget {
  const _BinDropZone({
    required this.label,
    required this.index,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.onAccept,
  });

  final String label;
  final int index;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final ValueChanged<_WastePayload> onAccept;

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      const Color(0xFF2F86CA),
      const Color(0xFF4FAF55),
      const Color(0xFFE2A329),
      const Color(0xFF8A65D1),
    ];
    final color = colors[index % colors.length];
    return DragTarget<_WastePayload>(
      onAcceptWithDetails: enabled ? (details) => onAccept(details.data) : null,
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        return Semantics(
          button: true,
          selected: selected,
          label: '$label recycling bin',
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(17),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minHeight: 108),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? color
                    : color.withValues(alpha: hovering ? .22 : .11),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: color,
                  width: selected || hovering ? 2.6 : 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected
                        ? Icons.recycling_rounded
                        : Icons.delete_outline_rounded,
                    color: selected ? Colors.white : color,
                    size: 32,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : AppTheme.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                  if (hovering && !selected)
                    Text(
                      'DROP HERE',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 8.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WastePayload {
  const _WastePayload(this.emoji, this.name);

  final String emoji;
  final String name;
}

import 'package:flutter/material.dart';

import '../../../../core/content/content_activity.dart';
import '../../../../core/theme/app_theme.dart';
import '../activity_game_contract.dart';

class SentenceBuilderActivity extends StatefulWidget {
  const SentenceBuilderActivity({
    required this.activity,
    required this.locked,
    required this.onResponseChanged,
    super.key,
  });

  final ContentActivity activity;
  final bool locked;
  final GameActivityResponseChanged onResponseChanged;

  @override
  State<SentenceBuilderActivity> createState() =>
      _SentenceBuilderActivityState();
}

class _SentenceBuilderActivityState extends State<SentenceBuilderActivity> {
  final List<_WordToken> _selected = <_WordToken>[];
  late List<_WordToken> _available;

  @override
  void initState() {
    super.initState();
    _available = _initialTokens();
  }

  List<_WordToken> _initialTokens() {
    final raw = widget.activity.payload['words'] as List;
    final tokens = <_WordToken>[
      for (var index = 0; index < raw.length; index += 1)
        _WordToken(index, '${raw[index]}'),
    ];
    return _stableShuffle(tokens, widget.activity.id);
  }

  void _add(_WordToken token) {
    if (widget.locked || !_available.contains(token)) return;
    setState(() {
      _available.remove(token);
      _selected.add(token);
    });
    _emit();
  }

  void _remove(_WordToken token) {
    if (widget.locked) return;
    setState(() {
      _selected.remove(token);
      _available.add(token);
    });
    _emit();
  }

  void _emit() {
    widget.onResponseChanged(
      GameActivityResponseSnapshot(
        value: _selected.map((token) => token.word).toList(growable: false),
        ready: _available.isEmpty && _selected.isNotEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _selected.length + _available.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StoryProgress(current: _selected.length, total: total),
        const SizedBox(height: 12),
        DragTarget<_WordToken>(
          onAcceptWithDetails:
              widget.locked ? null : (details) => _add(details.data),
          builder: (context, candidates, rejected) => AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: candidates.isNotEmpty
                    ? const [Color(0xFFDDF8EE), Color(0xFFF4FFFB)]
                    : const [Color(0xFFF3FBF7), Color(0xFFFFFFFF)],
              ),
              border: Border.all(
                color: candidates.isNotEmpty
                    ? const Color(0xFF3BA887)
                    : const Color(0xFFB9DDCF),
                width: candidates.isNotEmpty ? 2 : 1.3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.route_rounded,
                        color: Color(0xFF268D70), size: 19),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _selected.isEmpty
                            ? 'Build the story trail from left to right'
                            : '${_selected.length} of $total story steps placed',
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (var index = 0;
                        index < _selected.length;
                        index += 1) ...[
                      _BuiltWordTile(
                        number: index + 1,
                        word: _selected[index].word,
                        enabled: !widget.locked,
                        onRemove: () => _remove(_selected[index]),
                      ),
                      if (index < total - 1)
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF7DB8A3),
                          size: 18,
                        ),
                    ],
                    if (_selected.length < total)
                      _EmptyStoryStep(number: _selected.length + 1),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 13),
        const Text(
          'Word cards — tap or drag a card',
          style: TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final token in _available)
              LongPressDraggable<_WordToken>(
                data: token,
                feedback: Material(
                  color: Colors.transparent,
                  child: _WordBankTile(
                    word: token.word,
                    enabled: false,
                    onTap: () {},
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: .28,
                  child: _WordBankTile(
                    word: token.word,
                    enabled: false,
                    onTap: () {},
                  ),
                ),
                child: _WordBankTile(
                  word: token.word,
                  enabled: !widget.locked,
                  onTap: () => _add(token),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static List<_WordToken> _stableShuffle(
    List<_WordToken> values,
    String seed,
  ) {
    if (seed.isEmpty) return List<_WordToken>.from(values);
    final result = List<_WordToken>.from(values)
      ..sort((a, b) {
        final aScore =
            (seed.codeUnitAt(a.id % seed.length) * 31 + a.id * 17) % 101;
        final bScore =
            (seed.codeUnitAt(b.id % seed.length) * 31 + b.id * 17) % 101;
        final score = aScore.compareTo(bScore);
        return score != 0 ? score : a.id.compareTo(b.id);
      });
    if (result.length > 1 &&
        result.asMap().entries.every((entry) => entry.value.id == entry.key)) {
      result.add(result.removeAt(0));
    }
    return result;
  }
}

class _StoryProgress extends StatelessWidget {
  const _StoryProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F8F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('📖', style: TextStyle(fontSize: 23)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Restore the story path',
                  style: TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: total == 0 ? 0 : current / total,
                    backgroundColor: const Color(0xFFE3EEE9),
                    color: const Color(0xFF3BA887),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$current/$total',
            style: const TextStyle(
              color: Color(0xFF268D70),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
}

class _EmptyStoryStep extends StatelessWidget {
  const _EmptyStoryStep({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF9DCDBB),
            style: BorderStyle.solid,
          ),
        ),
        child: Text(
          'Step $number…',
          style: const TextStyle(
            color: AppTheme.inkMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _WordBankTile extends StatelessWidget {
  const _WordBankTile({
    required this.word,
    required this.enabled,
    required this.onTap,
  });

  final String word;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFB8DCCA)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140C3356),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              word,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      );
}

class _BuiltWordTile extends StatelessWidget {
  const _BuiltWordTile({
    required this.number,
    required this.word,
    required this.enabled,
    required this.onRemove,
  });

  final int number;
  final String word;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => InputChip(
        avatar: CircleAvatar(
          radius: 10,
          backgroundColor: const Color(0xFF268D70),
          child: Text(
            '$number',
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
        label: Text(word),
        onDeleted: enabled ? onRemove : null,
      );
}

class _WordToken {
  const _WordToken(this.id, this.word);

  final int id;
  final String word;
}

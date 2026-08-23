import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../activity_game_contract.dart';

class ExperimentMixerActivity extends StatefulWidget {
  const ExperimentMixerActivity({
    required this.choices,
    required this.locked,
    required this.onResponseChanged,
    super.key,
  });

  final List<String> choices;
  final bool locked;
  final GameActivityResponseChanged onResponseChanged;

  @override
  State<ExperimentMixerActivity> createState() =>
      _ExperimentMixerActivityState();
}

class _ExperimentMixerActivityState extends State<ExperimentMixerActivity> {
  final Set<String> _selected = <String>{};

  void _toggle(String ingredient) {
    if (widget.locked) return;
    setState(() {
      if (_selected.contains(ingredient)) {
        _selected.remove(ingredient);
      } else {
        _selected.add(ingredient);
      }
    });
    _emit();
  }

  void _add(String ingredient) {
    if (widget.locked || _selected.contains(ingredient)) return;
    setState(() => _selected.add(ingredient));
    _emit();
  }

  void _emit() {
    final response = _selected.toList()..sort();
    widget.onResponseChanged(
      GameActivityResponseSnapshot(
        value: response,
        ready: response.isNotEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DragTarget<String>(
            onAcceptWithDetails:
                widget.locked ? null : (details) => _add(details.data),
            builder: (context, candidates, rejected) => AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: candidates.isNotEmpty
                      ? const [Color(0xFFE0F8FF), Color(0xFFF2EDFF)]
                      : const [Color(0xFFF3EEFF), Color(0xFFEAFBFF)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: candidates.isNotEmpty
                      ? const Color(0xFF6A4BD2)
                      : const Color(0xFFDAD0FF),
                  width: candidates.isNotEmpty ? 2 : 1.2,
                ),
              ),
              child: Row(
                children: [
                  _FlaskVisual(
                    filled: _selected.isNotEmpty,
                    highlighted: candidates.isNotEmpty,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Experiment flask',
                          style: TextStyle(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selected.isEmpty
                              ? 'Drag ingredients into the flask or tap them below.'
                              : 'Mixture: ${(_selected.toList()..sort()).join(' + ')}',
                          style: const TextStyle(
                            color: AppTheme.inkMuted,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        if (_selected.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final ingredient
                                  in (_selected.toList()..sort()))
                                InputChip(
                                  label: Text(ingredient),
                                  avatar: const Icon(
                                    Icons.bubble_chart_rounded,
                                    size: 16,
                                  ),
                                  onDeleted: widget.locked
                                      ? null
                                      : () => _toggle(ingredient),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ingredient shelf',
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
              for (final ingredient in widget.choices)
                LongPressDraggable<String>(
                  data: ingredient,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _IngredientTile(
                      ingredient: ingredient,
                      selected: _selected.contains(ingredient),
                      enabled: false,
                      onTap: () {},
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: .3,
                    child: _IngredientTile(
                      ingredient: ingredient,
                      selected: _selected.contains(ingredient),
                      enabled: false,
                      onTap: () {},
                    ),
                  ),
                  child: _IngredientTile(
                    ingredient: ingredient,
                    selected: _selected.contains(ingredient),
                    enabled: !widget.locked,
                    onTap: () => _toggle(ingredient),
                  ),
                ),
            ],
          ),
        ],
      );
}

class _FlaskVisual extends StatelessWidget {
  const _FlaskVisual({required this.filled, required this.highlighted});

  final bool filled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        width: 76,
        height: 92,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0xFFDDF8FF)
              : Colors.white.withValues(alpha: .75),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF7B61D8),
            width: highlighted ? 2.5 : 1.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(filled ? '🧪' : '⚗️', style: const TextStyle(fontSize: 48)),
            if (filled)
              const Positioned(
                right: 5,
                top: 7,
                child: Text('✨', style: TextStyle(fontSize: 17)),
              ),
          ],
        ),
      );
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({
    required this.ingredient,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String ingredient;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilterChip(
        avatar: Icon(
          selected ? Icons.science_rounded : Icons.add_circle_outline_rounded,
          size: 18,
        ),
        label: Text(ingredient),
        selected: selected,
        onSelected: enabled ? (_) => onTap() : null,
      );
}

import 'package:flutter/material.dart';

import '../../core/nursery/nursery_spoken_labels.dart';
import '../../core/nursery/nursery_visuals.dart';
import 'nursery_motion.dart';
import 'nursery_visual.dart';

/// Picture-first rendering for an authored Nursery answer or matching value.
///
/// The authored [value] is never rewritten. It is still the value submitted to
/// the evaluator; this widget only decides how that value should look to a
/// child. Known words use bundled illustrations, colour/shape values use
/// painted vectors, and letters/numbers remain crisp typography.
class NurseryGameValue extends StatelessWidget {
  const NurseryGameValue({
    required this.value,
    this.skillId,
    this.prompt,
    this.visualSize = 66,
    this.showLabel = true,
    this.reducedMotion = true,
    this.textStyle,
    super.key,
  });

  final String value;
  final String? skillId;
  final String? prompt;
  final double visualSize;
  final bool showLabel;
  final bool reducedMotion;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final trimmed = value.trim();
    final spoken = nurserySpokenLabel(trimmed);
    final pieces = _pieces(trimmed);
    final textOnly = pieces.length == 1 && _isLongTextOnly(pieces.single.spec);

    if (textOnly) {
      return Text(
        trimmed,
        textAlign: TextAlign.center,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: textStyle ??
            Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
      );
    }

    final multiple = pieces.length > 1;
    final size = multiple ? visualSize * .78 : visualSize;
    final visualRow = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: [
        for (var index = 0; index < pieces.length; index += 1) ...[
          if (index > 0 && pieces[index].connector == _Connector.plus)
            Icon(
              Icons.add_rounded,
              size: size * .48,
              semanticLabel: 'plus',
            ),
          NurseryVisual(
            spec: pieces[index].spec,
            size: size,
            reducedMotion: reducedMotion,
            animateAsset: false,
            decorative: true,
          ),
        ],
      ],
    );

    final shouldShowLabel = showLabel &&
        spoken.isNotEmpty &&
        !_labelWouldDuplicateTypography(pieces, spoken);
    if (!shouldShowLabel) return visualRow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        visualRow,
        const SizedBox(height: 6),
        Text(
          spoken,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }

  List<_VisualPiece> _pieces(String trimmed) {
    if (trimmed.contains(' & ')) {
      final parts = trimmed
          .split(RegExp(r'\s*&\s*'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(growable: false);
      if (parts.length > 1) {
        return <_VisualPiece>[
          for (final part in parts)
            _VisualPiece(
              spec: NurseryVisualResolver.forInteractionValue(
                part,
                skillId: skillId,
                prompt: prompt,
              ),
              connector: _Connector.none,
            ),
        ];
      }
    }

    if (trimmed.contains(' + ')) {
      final parts = trimmed
          .split(RegExp(r'\s*\+\s*'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(growable: false);
      if (parts.length > 1) {
        return <_VisualPiece>[
          for (var index = 0; index < parts.length; index += 1)
            _VisualPiece(
              spec: NurseryVisualResolver.forInteractionValue(
                parts[index],
                skillId: skillId,
                prompt: prompt,
              ),
              connector: index == 0 ? _Connector.none : _Connector.plus,
            ),
        ];
      }
    }

    final rawVisuals = nurseryVisualTokensInText(trimmed);
    if (rawVisuals.length > 1) {
      return <_VisualPiece>[
        for (final token in rawVisuals)
          _VisualPiece(
            spec: NurseryVisualResolver.fromLegacyToken(token),
            connector: _Connector.none,
          ),
      ];
    }

    return <_VisualPiece>[
      _VisualPiece(
        spec: NurseryVisualResolver.forInteractionValue(
          trimmed,
          skillId: skillId,
          prompt: prompt,
        ),
        connector: _Connector.none,
      ),
    ];
  }

  static bool _isLongTextOnly(NurseryVisualSpec spec) =>
      spec.source == NurseryVisualSource.typography &&
      spec.concept == NurseryVisualConcept.text &&
      (spec.text?.trim().length ?? 0) > 8;

  static bool _labelWouldDuplicateTypography(
    List<_VisualPiece> pieces,
    String spoken,
  ) {
    if (pieces.length != 1) return false;
    final spec = pieces.single.spec;
    if (spec.source != NurseryVisualSource.typography) return false;
    final text = spec.text?.trim();
    return text != null && text.toLowerCase() == spoken.trim().toLowerCase();
  }
}

/// Reusable large answer card used by authored and generated Nursery games.
/// Its semantics deliberately preserve the existing `Answer ...` contract.
class NurseryGameAnswerCard extends StatelessWidget {
  const NurseryGameAnswerCard({
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.index,
    required this.reducedMotion,
    this.skillId,
    this.prompt,
    this.minHeight = 118,
    super.key,
  });

  final String value;
  final bool enabled;
  final VoidCallback onTap;
  final int index;
  final bool reducedMotion;
  final String? skillId;
  final String? prompt;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spoken = nurserySpokenLabel(value);
    final child = Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      enabled: enabled,
      label: 'Answer $spoken',
      child: Material(
        color: enabled
            ? scheme.tertiaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Center(
                child: NurseryGameValue(
                  value: value,
                  skillId: skillId,
                  prompt: prompt,
                  visualSize: 70,
                  reducedMotion: reducedMotion,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return NurseryMotionReveal(
      reducedMotion: reducedMotion,
      duration: Duration(milliseconds: 240 + index * 55),
      beginScale: .94,
      verticalOffset: 3,
      curve: Curves.easeOutBack,
      child: child,
    );
  }
}

enum _Connector { none, plus }

class _VisualPiece {
  const _VisualPiece({required this.spec, required this.connector});

  final NurseryVisualSpec spec;
  final _Connector connector;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/nursery/nursery_spoken_labels.dart';
import '../../core/nursery/nursery_visuals.dart';
import 'nursery_asset_reaction.dart';

/// The single presentation boundary for Nursery semantic visuals.
///
/// UI code should render [NurseryVisualSpec] through this widget rather than
/// directly displaying emoji/pictogram strings. Bundled images are preferred
/// when a spec supplies an asset; other concepts are drawn with scalable
/// Flutter vectors so they remain crisp on Android, tablets and Windows.
class NurseryVisual extends StatelessWidget {
  const NurseryVisual({
    required this.spec,
    this.size = 56,
    this.reducedMotion = true,
    this.animateAsset = false,
    this.decorative = false,
    super.key,
  });

  final NurseryVisualSpec spec;
  final double size;
  final bool reducedMotion;
  final bool animateAsset;
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    final visual = SizedBox.square(
      dimension: size,
      child: switch (spec.source) {
        NurseryVisualSource.localAsset => _assetVisual(context),
        NurseryVisualSource.typography => _TypographyVisual(spec: spec),
        NurseryVisualSource.painted => CustomPaint(
            painter: NurseryVisualPainter(
              concept: spec.concept,
              brightness: Theme.of(context).brightness,
              variant: spec.variant,
              count: spec.count,
            ),
          ),
      },
    );

    if (decorative) return ExcludeSemantics(child: visual);
    return Semantics(
      image: true,
      label: spec.semanticLabel,
      child: ExcludeSemantics(child: visual),
    );
  }

  Widget _assetVisual(BuildContext context) {
    final fallback = _AssetFallback(spec: spec);
    if (!spec.usesLocalAsset) return fallback;
    final safeCount = spec.count.clamp(1, 10).toInt();
    if (safeCount > 1) {
      return _RepeatedAssetVisual(
        assetPath: spec.assetPath!,
        count: safeCount,
        fallback: fallback,
      );
    }
    if (animateAsset) {
      return NurseryAnimatedAsset(
        assetPath: spec.assetPath!,
        word: _animationWord(spec.semanticLabel),
        reducedMotion: reducedMotion,
        fallback: fallback,
      );
    }
    return Image.asset(
      spec.assetPath!,
      fit: BoxFit.cover,
      cacheWidth: 128,
      cacheHeight: 128,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  static String _animationWord(String semanticLabel) {
    final normalized = semanticLabel.trim();
    final pictureIndex = normalized.toLowerCase().indexOf(' picture');
    return pictureIndex <= 0 ? normalized : normalized.substring(0, pictureIndex);
  }
}

class NurseryVisualToken extends StatelessWidget {
  const NurseryVisualToken({
    required this.value,
    this.size = 58,
    this.showLabel = false,
    this.reducedMotion = true,
    super.key,
  });

  final String value;
  final double size;
  final bool showLabel;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final spoken = nurserySpokenLabel(value);
    final spec = NurseryVisualResolver.fromLegacyToken(
      value,
      semanticHint: spoken,
    );
    final effectiveSize = spec.count > 4 ? math.max(size, 72.0) : size;
    final visual = NurseryVisual(
      spec: spec,
      size: effectiveSize,
      reducedMotion: reducedMotion,
      animateAsset: false,
      decorative: true,
    );
    if (!showLabel) {
      return Semantics(
        image: true,
        label: spoken,
        child: ExcludeSemantics(child: visual),
      );
    }
    return Semantics(
      image: true,
      label: spoken,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            visual,
            const SizedBox(height: 5),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: effectiveSize * 1.8),
              child: Text(
                spoken,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NurseryPromptVisuals extends StatelessWidget {
  const NurseryPromptVisuals({
    required this.text,
    this.tokens = const <String>[],
    this.size = 64,
    super.key,
  });

  final String text;
  final List<String> tokens;
  final double size;

  @override
  Widget build(BuildContext context) {
    final rawTokens = tokens.isNotEmpty
        ? NurseryVisualResolver.compactVisualTokens(tokens)
        : nurseryVisualTokensInText(text);
    if (rawTokens.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (final raw in rawTokens) {
      final token = raw.trim();
      if (token.isEmpty) continue;
      if (token == '+') {
        children.add(
          Icon(
            Icons.add_rounded,
            size: size * .55,
            semanticLabel: 'plus',
          ),
        );
        continue;
      }
      if (token == '=') {
        children.add(
          Text(
            '=',
            style: TextStyle(
              fontSize: size * .48,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
        continue;
      }
      children.add(
        NurseryVisualToken(
          value: token,
          size: size,
          reducedMotion: true,
        ),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: children,
    );
  }
}

class _RepeatedAssetVisual extends StatelessWidget {
  const _RepeatedAssetVisual({
    required this.assetPath,
    required this.count,
    required this.fallback,
  });

  final String assetPath;
  final int count;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final columns = count <= 4 ? 2 : count <= 9 ? 3 : 4;
    return GridView.count(
      crossAxisCount: columns,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(3),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: [
        for (var index = 0; index < count; index += 1)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              cacheWidth: 128,
              cacheHeight: 128,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
          ),
      ],
    );
  }
}

class NurseryProgressStars extends StatelessWidget {
  const NurseryProgressStars({
    required this.filled,
    this.total = 3,
    this.size = 20,
    super.key,
  });

  final int filled;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total.clamp(0, 20).toInt();
    final safeFilled = filled.clamp(0, safeTotal).toInt();
    final color = Theme.of(context).colorScheme.tertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < safeTotal; index += 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Icon(
              index < safeFilled ? Icons.star_rounded : Icons.star_border_rounded,
              size: size,
              color: color,
            ),
          ),
      ],
    );
  }
}

class _AssetFallback extends StatelessWidget {
  const _AssetFallback({required this.spec});

  final NurseryVisualSpec spec;

  @override
  Widget build(BuildContext context) {
    final fallbackText = spec.text?.trim();
    if (fallbackText != null && fallbackText.isNotEmpty) {
      return _TypographyVisual(
        spec: NurseryVisualSpec(
          key: '${spec.key}:typography-fallback',
          concept: NurseryVisualConcept.letter,
          source: NurseryVisualSource.typography,
          semanticLabel: spec.semanticLabel,
          text: fallbackText,
        ),
      );
    }
    return CustomPaint(
      painter: NurseryVisualPainter(
        concept: NurseryVisualConcept.pictureWords,
        brightness: Theme.of(context).brightness,
        variant: spec.variant,
        count: spec.count,
      ),
    );
  }
}

class _TypographyVisual extends StatelessWidget {
  const _TypographyVisual({required this.spec});

  final NurseryVisualSpec spec;

  @override
  Widget build(BuildContext context) {
    final text = spec.text?.trim();
    if (text == null || text.isEmpty) {
      return CustomPaint(
        painter: NurseryVisualPainter(
          concept: NurseryVisualConcept.play,
          brightness: Theme.of(context).brightness,
        ),
      );
    }
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
              fontSize: 30,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight vector renderer for semantic Nursery visuals.
///
/// The shapes intentionally use simple geometry so the visuals scale without
/// an extra SVG dependency and remain deterministic in widget/golden tests.
class NurseryVisualPainter extends CustomPainter {
  NurseryVisualPainter({
    required this.concept,
    required this.brightness,
    this.variant,
    this.count = 1,
  });

  final NurseryVisualConcept concept;
  final Brightness brightness;
  final String? variant;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= 0) return;
    final scale = side / 100;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(scale, scale);

    final dark = brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF7F8FF) : const Color(0xFF293451);
    const purple = Color(0xFF7768E8);
    const blue = Color(0xFF45A8E8);
    const green = Color(0xFF56BF76);
    const orange = Color(0xFFFFA446);
    const pink = Color(0xFFF47DB0);
    const yellow = Color(0xFFFFD85A);
    final soft = dark ? const Color(0xFF39445F) : const Color(0xFFF7FAFF);

    void circle(Offset center, double radius, Color color) {
      canvas.drawCircle(center, radius, Paint()..color = color);
    }

    void rounded(Rect rect, double radius, Color color) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()..color = color,
      );
    }

    void strokePath(Path path, Color color, double width) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    void text(String value, Offset center, double fontSize, Color color) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        center - Offset(painter.width / 2, painter.height / 2),
      );
    }

    void star(Offset center, double outerRadius, Color color) {
      final path = Path();
      for (var i = 0; i < 10; i += 1) {
        final radius = i.isEven ? outerRadius : outerRadius * .45;
        final angle = -math.pi / 2 + (math.pi * i / 5);
        final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    void playTriangle({Offset center = const Offset(52, 50), double radius = 25}) {
      final path = Path()
        ..moveTo(center.dx - radius * .55, center.dy - radius)
        ..lineTo(center.dx + radius, center.dy)
        ..lineTo(center.dx - radius * .55, center.dy + radius)
        ..close();
      canvas.drawPath(path, Paint()..color = purple);
    }

    switch (concept) {
      case NurseryVisualConcept.garden:
        circle(const Offset(79, 23), 12, yellow);
        strokePath(
          Path()
            ..moveTo(8, 78)
            ..quadraticBezierTo(28, 58, 50, 78)
            ..quadraticBezierTo(72, 56, 94, 78),
          green,
          9,
        );
        strokePath(
          Path()
            ..moveTo(50, 77)
            ..lineTo(50, 48),
          green,
          6,
        );
        circle(const Offset(40, 44), 13, pink);
        circle(const Offset(60, 44), 13, blue);
        circle(const Offset(50, 34), 13, orange);
        circle(const Offset(50, 51), 8, yellow);
        break;
      case NurseryVisualConcept.alphabet:
      case NurseryVisualConcept.letter:
        rounded(const Rect.fromLTWH(8, 22, 29, 56), 9, purple);
        rounded(const Rect.fromLTWH(36, 12, 29, 66), 9, blue);
        rounded(const Rect.fromLTWH(64, 26, 28, 52), 9, green);
        text('A', const Offset(22.5, 50), 28, Colors.white);
        text('b', const Offset(50.5, 45), 28, Colors.white);
        text('C', const Offset(78, 52), 26, Colors.white);
        break;
      case NurseryVisualConcept.maths:
      case NurseryVisualConcept.number:
        circle(const Offset(24, 30), 16, purple);
        circle(const Offset(50, 62), 17, blue);
        circle(const Offset(78, 31), 16, orange);
        text('1', const Offset(24, 30), 19, Colors.white);
        text('2', const Offset(50, 62), 20, Colors.white);
        text('3', const Offset(78, 31), 19, Colors.white);
        break;
      case NurseryVisualConcept.world:
        circle(const Offset(50, 50), 35, blue);
        final land = Path()
          ..moveTo(28, 35)
          ..quadraticBezierTo(40, 26, 48, 34)
          ..quadraticBezierTo(56, 41, 65, 35)
          ..quadraticBezierTo(76, 40, 71, 51)
          ..quadraticBezierTo(65, 59, 58, 56)
          ..quadraticBezierTo(48, 52, 44, 64)
          ..quadraticBezierTo(35, 67, 29, 56)
          ..close();
        canvas.drawPath(land, Paint()..color = green);
        break;
      case NurseryVisualConcept.thinking:
      case NurseryVisualConcept.matching:
        rounded(const Rect.fromLTWH(12, 20, 32, 29), 8, purple);
        rounded(const Rect.fromLTWH(56, 20, 32, 29), 8, purple);
        rounded(const Rect.fromLTWH(12, 57, 32, 23), 8, orange);
        rounded(const Rect.fromLTWH(56, 57, 32, 23), 8, orange);
        strokePath(
          Path()
            ..moveTo(44, 34)
            ..lineTo(56, 34)
            ..moveTo(44, 68)
            ..lineTo(56, 68),
          ink,
          4,
        );
        circle(const Offset(28, 34), 5, Colors.white);
        circle(const Offset(72, 34), 5, Colors.white);
        break;
      case NurseryVisualConcept.listening:
        circle(const Offset(33, 50), 17, purple);
        final speaker = Path()
          ..moveTo(25, 43)
          ..lineTo(33, 43)
          ..lineTo(44, 34)
          ..lineTo(44, 66)
          ..lineTo(33, 57)
          ..lineTo(25, 57)
          ..close();
        canvas.drawPath(speaker, Paint()..color = Colors.white);
        strokePath(
          Path()
            ..moveTo(55, 39)
            ..quadraticBezierTo(67, 50, 55, 61)
            ..moveTo(65, 31)
            ..quadraticBezierTo(84, 50, 65, 69),
          blue,
          6,
        );
        break;
      case NurseryVisualConcept.tracing:
        for (var i = 0; i < 6; i += 1) {
          circle(Offset(14 + i * 14, 72 - math.sin(i * .9) * 28), 3.5, blue);
        }
        canvas.save();
        canvas.translate(64, 31);
        canvas.rotate(-.65);
        rounded(const Rect.fromLTWH(-7, -22, 14, 44), 5, orange);
        final tip = Path()
          ..moveTo(-7, 22)
          ..lineTo(7, 22)
          ..lineTo(0, 34)
          ..close();
        canvas.drawPath(tip, Paint()..color = yellow);
        canvas.restore();
        break;
      case NurseryVisualConcept.sorting:
        rounded(const Rect.fromLTWH(10, 54, 34, 29), 8, purple);
        rounded(const Rect.fromLTWH(56, 54, 34, 29), 8, green);
        circle(const Offset(27, 29), 10, pink);
        final triangle = Path()
          ..moveTo(73, 17)
          ..lineTo(84, 38)
          ..lineTo(62, 38)
          ..close();
        canvas.drawPath(triangle, Paint()..color = orange);
        strokePath(Path()..moveTo(27, 40)..lineTo(27, 52), pink, 3);
        strokePath(Path()..moveTo(73, 40)..lineTo(73, 52), orange, 3);
        break;
      case NurseryVisualConcept.pictureWords:
      case NurseryVisualConcept.localPicture:
        rounded(const Rect.fromLTWH(10, 18, 80, 64), 12, soft);
        circle(const Offset(68, 36), 8, yellow);
        final hills = Path()
          ..moveTo(17, 71)
          ..lineTo(38, 48)
          ..lineTo(50, 60)
          ..lineTo(63, 45)
          ..lineTo(84, 71)
          ..close();
        canvas.drawPath(hills, Paint()..color = green);
        break;
      case NurseryVisualConcept.counting:
        final safeCount = count.clamp(1, 10).toInt();
        final columns = safeCount <= 4 ? 2 : safeCount <= 9 ? 3 : 4;
        final rows = (safeCount / columns).ceil();
        final cellWidth = 72 / columns;
        final cellHeight = 68 / rows;
        for (var i = 0; i < safeCount; i += 1) {
          final row = i ~/ columns;
          final column = i % columns;
          final point = Offset(
            14 + cellWidth * (column + .5),
            16 + cellHeight * (row + .5),
          );
          if (variant == 'star') {
            star(point, math.min(cellWidth, cellHeight) * .30, yellow);
          } else {
            circle(
              point,
              math.min(cellWidth, cellHeight) * .24,
              i.isEven ? purple : blue,
            );
          }
        }
        break;
      case NurseryVisualConcept.addition:
        circle(const Offset(25, 50), 13, purple);
        circle(const Offset(75, 50), 13, green);
        rounded(const Rect.fromLTWH(46, 32, 8, 36), 4, orange);
        rounded(const Rect.fromLTWH(32, 46, 36, 8), 4, orange);
        break;
      case NurseryVisualConcept.colours:
        final colour = switch (variant) {
          'red' => const Color(0xFFEF5350),
          'blue' => blue,
          'green' => green,
          'yellow' => yellow,
          'orange' => orange,
          'purple' => purple,
          _ => null,
        };
        if (colour != null) {
          circle(const Offset(50, 50), 31, colour);
          circle(const Offset(39, 39), 8, Colors.white.withValues(alpha: .28));
        } else {
          circle(const Offset(30, 32), 15, pink);
          circle(const Offset(66, 28), 14, blue);
          circle(const Offset(72, 65), 15, green);
          circle(const Offset(34, 68), 14, yellow);
        }
        break;
      case NurseryVisualConcept.shapes:
        if (variant == 'circle') {
          circle(const Offset(50, 50), 30, blue);
        } else if (variant == 'square') {
          rounded(const Rect.fromLTWH(22, 22, 56, 56), 7, purple);
        } else if (variant == 'rectangle') {
          rounded(const Rect.fromLTWH(14, 31, 72, 38), 7, green);
        } else if (variant == 'triangle') {
          final triangle = Path()
            ..moveTo(50, 17)
            ..lineTo(84, 78)
            ..lineTo(16, 78)
            ..close();
          canvas.drawPath(triangle, Paint()..color = orange);
        } else {
          circle(const Offset(25, 31), 14, blue);
          rounded(const Rect.fromLTWH(57, 17, 27, 27), 4, purple);
          final triangle = Path()
            ..moveTo(32, 55)
            ..lineTo(48, 82)
            ..lineTo(16, 82)
            ..close();
          canvas.drawPath(triangle, Paint()..color = orange);
          final diamond = Path()
            ..moveTo(70, 53)
            ..lineTo(86, 68)
            ..lineTo(70, 83)
            ..lineTo(54, 68)
            ..close();
          canvas.drawPath(diamond, Paint()..color = green);
        }
        break;
      case NurseryVisualConcept.animals:
        circle(const Offset(50, 54), 27, orange);
        final leftEar = Path()
          ..moveTo(28, 36)
          ..lineTo(31, 17)
          ..lineTo(44, 31)
          ..close();
        final rightEar = Path()
          ..moveTo(56, 31)
          ..lineTo(69, 17)
          ..lineTo(72, 36)
          ..close();
        canvas.drawPath(leftEar, Paint()..color = orange);
        canvas.drawPath(rightEar, Paint()..color = orange);
        circle(const Offset(40, 51), 3.5, ink);
        circle(const Offset(60, 51), 3.5, ink);
        circle(const Offset(50, 61), 4, pink);
        strokePath(Path()..moveTo(50, 65)..quadraticBezierTo(45, 71, 40, 67), ink, 2.5);
        strokePath(Path()..moveTo(50, 65)..quadraticBezierTo(55, 71, 60, 67), ink, 2.5);
        break;
      case NurseryVisualConcept.food:
        circle(const Offset(46, 55), 26, pink);
        circle(const Offset(59, 55), 26, pink);
        strokePath(Path()..moveTo(53, 31)..quadraticBezierTo(55, 18, 63, 14), green, 6);
        final leaf = Path()
          ..moveTo(60, 21)
          ..quadraticBezierTo(76, 13, 78, 28)
          ..quadraticBezierTo(68, 30, 60, 21)
          ..close();
        canvas.drawPath(leaf, Paint()..color = green);
        break;
      case NurseryVisualConcept.objects:
        rounded(const Rect.fromLTWH(15, 50, 31, 31), 7, purple);
        text('A', const Offset(30.5, 65.5), 18, Colors.white);
        circle(const Offset(70, 61), 20, blue);
        strokePath(Path()..moveTo(52, 61)..quadraticBezierTo(70, 43, 88, 61), Colors.white, 3);
        break;
      case NurseryVisualConcept.body:
        circle(const Offset(50, 27), 13, orange);
        strokePath(Path()..moveTo(50, 42)..lineTo(50, 68), purple, 8);
        strokePath(Path()..moveTo(50, 49)..lineTo(30, 58), purple, 7);
        strokePath(Path()..moveTo(50, 49)..lineTo(70, 58), purple, 7);
        strokePath(Path()..moveTo(50, 66)..lineTo(36, 84), purple, 7);
        strokePath(Path()..moveTo(50, 66)..lineTo(64, 84), purple, 7);
        break;
      case NurseryVisualConcept.routines:
        circle(const Offset(33, 34), 17, yellow);
        for (var i = 0; i < 8; i += 1) {
          final angle = i * math.pi / 4;
          strokePath(
            Path()
              ..moveTo(33 + math.cos(angle) * 23, 34 + math.sin(angle) * 23)
              ..lineTo(33 + math.cos(angle) * 29, 34 + math.sin(angle) * 29),
            orange,
            3,
          );
        }
        circle(const Offset(67, 65), 23, soft);
        strokePath(Path()..moveTo(67, 65)..lineTo(67, 51), purple, 4);
        strokePath(Path()..moveTo(67, 65)..lineTo(77, 70), purple, 4);
        break;
      case NurseryVisualConcept.patterns:
        circle(const Offset(18, 50), 8, purple);
        rounded(
          Rect.fromCenter(
            center: const Offset(40, 50),
            width: 16,
            height: 16,
          ),
          4,
          orange,
        );
        circle(const Offset(62, 50), 8, purple);
        rounded(
          Rect.fromCenter(
            center: const Offset(84, 50),
            width: 16,
            height: 16,
          ),
          4,
          orange,
        );
        break;
      case NurseryVisualConcept.observation:
        final eye = Path()
          ..moveTo(10, 50)
          ..quadraticBezierTo(50, 15, 90, 50)
          ..quadraticBezierTo(50, 85, 10, 50)
          ..close();
        canvas.drawPath(eye, Paint()..color = soft);
        circle(const Offset(50, 50), 18, blue);
        circle(const Offset(50, 50), 8, ink);
        circle(const Offset(44, 44), 3, Colors.white);
        break;
      case NurseryVisualConcept.celebration:
        star(const Offset(50, 49), 31, yellow);
        star(const Offset(19, 24), 9, pink);
        star(const Offset(82, 22), 8, blue);
        star(const Offset(80, 78), 7, green);
        break;
      case NurseryVisualConcept.review:
        strokePath(
          Path()
            ..moveTo(73, 31)
            ..quadraticBezierTo(48, 10, 25, 32)
            ..quadraticBezierTo(8, 50, 25, 70)
            ..quadraticBezierTo(48, 90, 70, 69),
          orange,
          9,
        );
        final arrow = Path()
          ..moveTo(66, 19)
          ..lineTo(84, 25)
          ..lineTo(73, 42)
          ..close();
        canvas.drawPath(arrow, Paint()..color = orange);
        playTriangle(center: const Offset(50, 50), radius: 13);
        break;
      case NurseryVisualConcept.play:
      case NurseryVisualConcept.text:
        circle(const Offset(50, 50), 37, soft);
        playTriangle();
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant NurseryVisualPainter oldDelegate) =>
      oldDelegate.concept != concept ||
      oldDelegate.brightness != brightness ||
      oldDelegate.variant != variant ||
      oldDelegate.count != count;
}

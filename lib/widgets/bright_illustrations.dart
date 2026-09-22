import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/presentation/game_feel_models.dart';
import 'bright_motion.dart';

class BrightQuestAppIcon extends StatelessWidget {
  const BrightQuestAppIcon({
    this.size = 52,
    this.semanticLabel = true,
    super.key,
  });

  final double size;
  final bool semanticLabel;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * .24),
        child: Image.asset(
          'assets/branding/brightquest_app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          semanticLabel: semanticLabel ? 'BrightQuest Kids app icon' : null,
          excludeFromSemantics: !semanticLabel,
        ),
      );
}

class BrightQuestLogo extends StatelessWidget {
  const BrightQuestLogo({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final top = compact ? 25.0 : 37.0;
    final bottom = compact ? 22.0 : 34.0;
    final markSize = compact ? 36.0 : 52.0;
    final wordmarkWidth = compact ? 90.0 : 160.0;

    final wordmark = FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'BrightQuest',
                style: TextStyle(
                  fontSize: top,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = compact ? 5 : 7
                    ..color = const Color(0xFF123A72),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Bright',
                      style: TextStyle(
                        color: const Color(0xFFFFBD22),
                        fontSize: top,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                    TextSpan(
                      text: 'Quest',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: top,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(
                  shadows: [
                    Shadow(
                      color: Color(0x44000000),
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: compact ? -1 : -3,
                left: compact ? 52 : 76,
                child: Text(
                  '★',
                  style: TextStyle(
                    color: const Color(0xFFFFD12A),
                    fontSize: compact ? 13 : 18,
                  ),
                ),
              ),
            ],
          ),
          Transform.translate(
            offset: Offset(0, compact ? -5 : -8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Kids',
                  style: TextStyle(
                    fontSize: bottom,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = compact ? 5 : 7
                      ..color = Colors.white,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [
                      Color(0xFF54C43D),
                      Color(0xFF3CB6FF),
                      Color(0xFF8A54E8),
                      Color(0xFFFF6B32),
                    ],
                  ).createShader(rect),
                  child: Text(
                    'Kids',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: bottom,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'BrightQuest Kids',
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 132 : 220),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrightQuestAppIcon(size: markSize, semanticLabel: false),
              SizedBox(width: compact ? 5 : 8),
              SizedBox(width: wordmarkWidth, child: wordmark),
            ],
          ),
        ),
      ),
    );
  }
}

class BrightLionMascot extends StatelessWidget {
  const BrightLionMascot({
    this.size = 150,
    this.scientist = false,
    this.mood = BrightMascotMood.cheerful,
    this.animated = true,
    this.scientistCoatColor,
    this.scientistGoggleColor,
    super.key,
  });

  final double size;
  final bool scientist;
  final BrightMascotMood mood;
  final bool animated;
  final Color? scientistCoatColor;
  final Color? scientistGoggleColor;

  @override
  Widget build(BuildContext context) {
    final mascot = SizedBox(
      width: size,
      height: size * 1.08,
      child: CustomPaint(
        painter: _LionPainter(
          scientist: scientist,
          mood: mood,
          scientistCoatColor: scientistCoatColor,
          scientistGoggleColor: scientistGoggleColor,
        ),
      ),
    );
    if (!animated) return mascot;
    return BrightMomentReaction(
      trigger: mood,
      kind: _momentKindForMascotMood(mood),
      child: mascot,
    );
  }
}

BrightMomentKind _momentKindForMascotMood(BrightMascotMood mood) =>
    switch (mood) {
      BrightMascotMood.focused => BrightMomentKind.focus,
      BrightMascotMood.thinking => BrightMomentKind.retry,
      BrightMascotMood.encouraging => BrightMomentKind.hint,
      BrightMascotMood.celebrating => BrightMomentKind.success,
      BrightMascotMood.heroic => BrightMomentKind.bossClear,
      BrightMascotMood.cheerful => BrightMomentKind.calm,
    };

class _LionPainter extends CustomPainter {
  const _LionPainter({
    required this.scientist,
    required this.mood,
    required this.scientistCoatColor,
    required this.scientistGoggleColor,
  });
  final bool scientist;
  final BrightMascotMood mood;
  final Color? scientistCoatColor;
  final Color? scientistGoggleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 150;
    final sy = size.height / 162;
    canvas.save();
    canvas.scale(sx, sy);

    final mane = Paint()..color = const Color(0xFF9C4A18);
    final maneDark = Paint()..color = const Color(0xFF74320E);
    final fur = Paint()..color = const Color(0xFFF3A23A);
    final light = Paint()..color = const Color(0xFFFFD18B);
    final navy = Paint()..color = const Color(0xFF1F4D8F);
    final white = Paint()..color = Colors.white;
    final scientistCoat = Paint()..color = scientistCoatColor ?? Colors.white;
    final black = Paint()..color = const Color(0xFF2B1B15);

    // tail
    canvas.drawPath(
      Path()
        ..moveTo(34, 118)
        ..cubicTo(5, 116, 7, 86, 27, 89),
      Paint()
        ..color = const Color(0xFFF3A23A)
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(const Offset(18, 88), 8, maneDark);

    // body/jacket
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(43, 95, 70, 58), const Radius.circular(24)),
        scientist ? scientistCoat : navy);
    if (scientist) {
      canvas.drawRect(const Rect.fromLTWH(72, 101, 3, 48),
          Paint()..color = const Color(0xFFBED5EA));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(52, 108, 15, 20), const Radius.circular(4)),
          Paint()..color = const Color(0xFFE3EDF7));
    } else {
      canvas.drawPath(
          Path()
            ..moveTo(72, 99)
            ..lineTo(72, 153),
          Paint()
            ..color = const Color(0xFF113A72)
            ..strokeWidth = 3);
      canvas.drawCircle(
          const Offset(91, 117), 3, Paint()..color = const Color(0xFFFFC42A));
    }

    // arm wave
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(105, 92, 24, 47), const Radius.circular(12)),
        fur);
    canvas.drawCircle(const Offset(126, 86), 14, fur);
    for (final offset in const [
      Offset(117, 75),
      Offset(125, 72),
      Offset(133, 76)
    ]) {
      canvas.drawCircle(offset, 4.5, fur);
    }
    // other arm
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(30, 103, 25, 40), const Radius.circular(12)),
        fur);

    // mane blobs
    const center = Offset(73, 62);
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi * 2 / 14;
      canvas.drawCircle(
          Offset(center.dx + math.cos(a) * 40, center.dy + math.sin(a) * 39),
          18,
          mane);
    }
    canvas.drawCircle(center, 42, mane);
    canvas.drawCircle(center, 34, fur);
    if (mood == BrightMascotMood.heroic) {
      final crown = Path()
        ..moveTo(49, 24)
        ..lineTo(53, 8)
        ..lineTo(64, 18)
        ..lineTo(73, 4)
        ..lineTo(82, 18)
        ..lineTo(94, 8)
        ..lineTo(97, 25)
        ..close();
      canvas.drawPath(crown, Paint()..color = const Color(0xFFFFC928));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(49, 22, 48, 9),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFE59B17),
      );
    }
    // ears
    canvas.drawCircle(const Offset(45, 37), 13, mane);
    canvas.drawCircle(const Offset(101, 37), 13, mane);
    canvas.drawCircle(const Offset(45, 37), 7, light);
    canvas.drawCircle(const Offset(101, 37), 7, light);
    // muzzle
    canvas.drawOval(const Rect.fromLTWH(49, 59, 48, 29), light);
    // eyes + expression
    if (mood == BrightMascotMood.celebrating ||
        mood == BrightMascotMood.heroic) {
      final happyEye = Paint()
        ..color = black.color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        const Rect.fromLTWH(53, 51, 13, 9),
        math.pi,
        math.pi,
        false,
        happyEye,
      );
      canvas.drawArc(
        const Rect.fromLTWH(80, 51, 13, 9),
        math.pi,
        math.pi,
        false,
        happyEye,
      );
    } else {
      canvas.drawOval(const Rect.fromLTWH(53, 46, 13, 17), white);
      canvas.drawOval(const Rect.fromLTWH(80, 46, 13, 17), white);
      final pupilShift = mood == BrightMascotMood.thinking
          ? const Offset(1.5, -2.0)
          : Offset.zero;
      canvas.drawCircle(const Offset(61, 55) + pupilShift, 4.5, black);
      canvas.drawCircle(const Offset(85, 55) + pupilShift, 4.5, black);
      canvas.drawCircle(const Offset(59.5, 53.5) + pupilShift, 1.4, white);
      canvas.drawCircle(const Offset(83.5, 53.5) + pupilShift, 1.4, white);
      if (mood == BrightMascotMood.focused) {
        final brow = Paint()
          ..color = maneDark.color
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(53, 44), const Offset(65, 42), brow);
        canvas.drawLine(const Offset(81, 42), const Offset(93, 44), brow);
      }
    }
    // nose and mouth
    canvas.drawPath(
        Path()
          ..moveTo(68, 66)
          ..lineTo(78, 66)
          ..lineTo(73, 72)
          ..close(),
        black);
    final smilePaint = Paint()
      ..color = black.color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (mood == BrightMascotMood.thinking) {
      canvas.drawArc(
        const Rect.fromLTWH(66, 73, 16, 9),
        math.pi * .10,
        math.pi * .80,
        false,
        smilePaint,
      );
    } else {
      canvas.drawArc(const Rect.fromLTWH(61, 69, 24, 18), 0.05, math.pi - 0.1,
          false, smilePaint);
      canvas.drawOval(const Rect.fromLTWH(68, 78, 12, 7),
          Paint()..color = const Color(0xFFE95F5C));
    }
    if (mood == BrightMascotMood.celebrating ||
        mood == BrightMascotMood.heroic) {
      canvas.drawCircle(
        const Offset(92, 116),
        8,
        Paint()..color = const Color(0xFFFFC928),
      );
      canvas.drawCircle(
        const Offset(92, 116),
        3,
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }

    if (scientist) {
      // goggles
      final goggle = Paint()
        ..color = scientistGoggleColor ?? const Color(0xFF36B7F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(const Offset(59, 49), 10, goggle);
      canvas.drawCircle(const Offset(87, 49), 10, goggle);
      canvas.drawLine(const Offset(69, 49), const Offset(77, 49), goggle);
      canvas.drawLine(const Offset(48, 45), const Offset(37, 39), goggle);
      canvas.drawLine(const Offset(98, 45), const Offset(109, 39), goggle);
      // tiny tube
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(119, 115, 10, 31), const Radius.circular(4)),
          Paint()..color = const Color(0xFFDDF8FF));
      canvas.drawRect(const Rect.fromLTWH(120, 132, 8, 12),
          Paint()..color = const Color(0xFF8C59E8));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LionPainter oldDelegate) =>
      oldDelegate.scientist != scientist ||
      oldDelegate.mood != mood ||
      oldDelegate.scientistCoatColor != scientistCoatColor ||
      oldDelegate.scientistGoggleColor != scientistGoggleColor;
}

class BrightAdventureLandscape extends StatelessWidget {
  const BrightAdventureLandscape(
      {required this.child, this.market = false, super.key});

  final Widget child;
  final bool market;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: CustomPaint(
          painter: _AdventureLandscapePainter(market: market),
          child: child,
        ),
      );
}

class _AdventureLandscapePainter extends CustomPainter {
  const _AdventureLandscapePainter({required this.market});
  final bool market;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
              colors: [Color(0xFF41A8F5), Color(0xFF94E4FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)
          .createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    void cloud(double x, double y, double s) {
      final p = Paint()..color = Colors.white.withValues(alpha: 0.82);
      canvas.drawCircle(Offset(x, y), 20 * s, p);
      canvas.drawCircle(Offset(x + 20 * s, y - 7 * s), 27 * s, p);
      canvas.drawCircle(Offset(x + 48 * s, y), 20 * s, p);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x - 5 * s, y, 62 * s, 20 * s),
              Radius.circular(10 * s)),
          p);
    }

    cloud(size.width * .08, size.height * .16, .65);
    cloud(size.width * .74, size.height * .13, .5);

    // distant hills
    final hillBack = Paint()..color = const Color(0xFF83D187);
    final hillFront = Paint()..color = const Color(0xFF4EB66C);
    final path = Path()
      ..moveTo(0, size.height * .72)
      ..quadraticBezierTo(size.width * .18, size.height * .55, size.width * .38,
          size.height * .71)
      ..quadraticBezierTo(
          size.width * .62, size.height * .49, size.width, size.height * .68)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, hillBack);
    final front = Path()
      ..moveTo(0, size.height * .83)
      ..quadraticBezierTo(size.width * .22, size.height * .66, size.width * .46,
          size.height * .83)
      ..quadraticBezierTo(
          size.width * .72, size.height * .66, size.width, size.height * .80)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(front, hillFront);

    // castle / market silhouettes
    if (!market) {
      final castle = Paint()..color = const Color(0xFFD9D8EE);
      final roof = Paint()..color = const Color(0xFF7357D9);
      final baseX = size.width * .42;
      final baseY = size.height * .53;
      canvas.drawRect(
          Rect.fromLTWH(baseX, baseY, size.width * .18, size.height * .18),
          castle);
      for (final dx in [0.0, size.width * .07, size.width * .14]) {
        canvas.drawRect(
            Rect.fromLTWH(baseX + dx, baseY - size.height * .08,
                size.width * .045, size.height * .14),
            castle);
        final towerRoof = Path()
          ..moveTo(baseX + dx - 2, baseY - size.height * .08)
          ..lineTo(baseX + dx + size.width * .0225, baseY - size.height * .14)
          ..lineTo(baseX + dx + size.width * .047, baseY - size.height * .08)
          ..close();
        canvas.drawPath(towerRoof, roof);
      }
      canvas.drawOval(
          Rect.fromLTWH(baseX + size.width * .07, baseY + size.height * .09,
              size.width * .04, size.height * .09),
          Paint()..color = const Color(0xFF776F9E));
    } else {
      final wood = Paint()..color = const Color(0xFFB96A28);
      final awningRed = Paint()..color = const Color(0xFFE85038);
      final awningWhite = Paint()..color = const Color(0xFFFFF1D8);
      final y = size.height * .60;
      canvas.drawRect(
          Rect.fromLTWH(
              size.width * .36, y, size.width * .32, size.height * .18),
          wood);
      final stripW = size.width * .045;
      for (var i = 0; i < 7; i++) {
        canvas.drawRect(
            Rect.fromLTWH(size.width * .35 + i * stripW, y - size.height * .05,
                stripW, size.height * .055),
            i.isEven ? awningRed : awningWhite);
      }
      for (var i = 0; i < 9; i++) {
        canvas.drawCircle(
            Offset(size.width * (.38 + i * .03),
                y + size.height * (.05 + (i % 2) * .025)),
            size.shortestSide * .014,
            Paint()
              ..color = i % 3 == 0
                  ? const Color(0xFFE74335)
                  : i % 3 == 1
                      ? const Color(0xFFFFC629)
                      : const Color(0xFF4FAE4B));
      }
    }

    // winding path
    final road = Paint()
      ..color = const Color(0xFFF4D79F)
      ..strokeWidth = size.width * .055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final roadPath = Path()
      ..moveTo(size.width * .52, size.height)
      ..quadraticBezierTo(size.width * .43, size.height * .82, size.width * .52,
          size.height * .70);
    canvas.drawPath(roadPath, road);
  }

  @override
  bool shouldRepaint(covariant _AdventureLandscapePainter oldDelegate) =>
      oldDelegate.market != market;
}

class BrightWoodenSign extends StatelessWidget {
  const BrightWoodenSign(
      {required this.title, this.subtitle, this.compact = false, super.key});

  final String title;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        width: compact ? double.infinity : null,
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 22, vertical: compact ? 12 : 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Color(0xFFFFE0A5),
            Color(0xFFF7C980),
            Color(0xFFFFE7B8)
          ]),
          borderRadius: BorderRadius.circular(compact ? 20 : 28),
          border: Border.all(
              color: const Color(0xFFA96528), width: compact ? 3 : 4),
          boxShadow: const [
            BoxShadow(
                color: Color(0x440F3751), blurRadius: 16, offset: Offset(0, 8))
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(compact ? 16 : 22),
                child: const BrightGlint(color: Color(0xFFFFF4D1)),
              ),
            ),
            Positioned(left: -9, top: -9, child: _Nail(size: compact ? 9 : 11)),
            Positioned(
                right: -9, top: -9, child: _Nail(size: compact ? 9 : 11)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: const Color(0xFF6B2F17),
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 20 : 30,
                        height: 1.05)),
                if (subtitle != null) ...[
                  SizedBox(height: compact ? 4 : 7),
                  Text(subtitle!,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: const Color(0xFF633D25),
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 10 : 14)),
                ],
              ],
            ),
          ],
        ),
      );
}

class _Nail extends StatelessWidget {
  const _Nail({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          color: Color(0xFF865426), shape: BoxShape.circle));
}

class BrightGameScene extends StatelessWidget {
  const BrightGameScene(
      {required this.gameId, this.compact = false, super.key});

  final String gameId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 88.0 : 112.0;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _GameScenePainter(gameId)),
    );
  }
}

class _GameScenePainter extends CustomPainter {
  const _GameScenePainter(this.gameId);
  final String gameId;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final palette = _scenePalette(gameId);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(24)),
        Paint()
          ..shader = LinearGradient(
                  colors: palette,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              .createShader(rect));

    final whiteSoft = Paint()..color = Colors.white.withValues(alpha: .78);
    final dark = Paint()..color = const Color(0xFF173558).withValues(alpha: .9);
    final w = size.width;
    final h = size.height;

    switch (gameId) {
      case 'math_market':
        final wood = Paint()..color = const Color(0xFFB4672B);
        canvas.drawRect(
            Rect.fromLTWH(w * .08, h * .43, w * .34, h * .40), wood);
        for (var i = 0; i < 6; i++) {
          canvas.drawRect(
              Rect.fromLTWH(w * (.065 + i * .062), h * .34, w * .062, h * .13),
              Paint()
                ..color = i.isEven
                    ? const Color(0xFFE94E3B)
                    : const Color(0xFFFFEDD2));
        }
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * .48, h * .23, w * .42, h * .49),
                const Radius.circular(10)),
            Paint()..color = const Color(0xFF174C3D));
        _drawText(canvas, '24 ÷ 6 = ?', Offset(w * .55, h * .39), w * .047,
            Colors.white);
        for (var i = 0; i < 8; i++) {
          canvas.drawCircle(
              Offset(w * (.13 + (i % 4) * .06), h * (.60 + (i ~/ 4) * .10)),
              h * .045,
              Paint()
                ..color = [
                  const Color(0xFFE54835),
                  const Color(0xFFFFC830),
                  const Color(0xFF58B34E)
                ][i % 3]);
        }
        break;
      case 'fraction_pizza':
        final center = Offset(w * .50, h * .52);
        canvas.drawCircle(
            center, h * .33, Paint()..color = const Color(0xFFF7C35E));
        canvas.drawCircle(
            center, h * .27, Paint()..color = const Color(0xFFFFE09A));
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
              center,
              Offset(center.dx + math.cos(a) * h * .28,
                  center.dy + math.sin(a) * h * .28),
              Paint()
                ..color = const Color(0xFFB56C2B)
                ..strokeWidth = 2);
          if (i.isEven)
            canvas.drawCircle(
                Offset(center.dx + math.cos(a + .35) * h * .16,
                    center.dy + math.sin(a + .35) * h * .16),
                h * .035,
                Paint()..color = const Color(0xFFD74733));
        }
        _drawText(canvas, '¼', Offset(w * .76, h * .28), h * .20,
            const Color(0xFF5A2B16));
        break;
      case 'science_lab':
        _drawFlask(
            canvas, Offset(w * .32, h * .36), h * .58, const Color(0xFFE04F45));
        _drawFlask(
            canvas, Offset(w * .57, h * .24), h * .72, const Color(0xFF52D6D8));
        _drawFlask(
            canvas, Offset(w * .77, h * .43), h * .48, const Color(0xFF7B58EA));
        canvas.drawCircle(Offset(w * .61, h * .17), h * .035, whiteSoft);
        canvas.drawCircle(Offset(w * .68, h * .24), h * .022, whiteSoft);
        break;
      case 'story_builder':
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * .10, h * .48, w * .48, h * .30),
                const Radius.circular(9)),
            Paint()..color = const Color(0xFFFFF3D2));
        canvas.drawLine(
            Offset(w * .34, h * .50),
            Offset(w * .34, h * .78),
            Paint()
              ..color = const Color(0xFFB77F4C)
              ..strokeWidth = 2);
        _drawCastle(canvas, Offset(w * .55, h * .18), w * .26, h * .52);
        canvas.drawCircle(Offset(w * .78, h * .54), h * .14,
            Paint()..color = const Color(0xFF8256CF));
        canvas.drawCircle(Offset(w * .82, h * .51), h * .023, whiteSoft);
        break;
      case 'grammar_puzzle':
        _drawPuzzle(canvas, Rect.fromLTWH(w * .10, h * .25, w * .29, h * .40),
            const Color(0xFF39A9F4), 'NOUN');
        _drawPuzzle(canvas, Rect.fromLTWH(w * .36, h * .18, w * .29, h * .40),
            const Color(0xFF54C45E), 'VERB');
        _drawPuzzle(canvas, Rect.fromLTWH(w * .58, h * .42, w * .31, h * .38),
            const Color(0xFFFFB02D), 'ADJ');
        break;
      case 'map_quest':
        final map = Path()
          ..moveTo(w * .12, h * .65)
          ..lineTo(w * .25, h * .22)
          ..lineTo(w * .48, h * .30)
          ..lineTo(w * .62, h * .16)
          ..lineTo(w * .87, h * .47)
          ..lineTo(w * .72, h * .78)
          ..lineTo(w * .46, h * .68)
          ..lineTo(w * .30, h * .83)
          ..close();
        canvas.drawPath(map, Paint()..color = const Color(0xFF9DD47A));
        canvas.drawPath(
            map,
            Paint()
              ..color = const Color(0xFF488C54)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        canvas.drawCircle(Offset(w * .56, h * .45), h * .09,
            Paint()..color = const Color(0xFFE94C42));
        canvas.drawCircle(
            Offset(w * .56, h * .45), h * .035, Paint()..color = Colors.white);
        canvas.drawPath(
            Path()
              ..moveTo(w * .52, h * .51)
              ..lineTo(w * .56, h * .68)
              ..lineTo(w * .60, h * .51)
              ..close(),
            Paint()..color = const Color(0xFFE94C42));
        _drawCompass(canvas, Offset(w * .80, h * .28), h * .14);
        break;
      case 'coding_maze':
        _drawRobot(canvas, Offset(w * .27, h * .50), h * .28);
        final colors = [
          const Color(0xFFE75A63),
          const Color(0xFF4D8EEA),
          const Color(0xFF5DBD6A)
        ];
        for (var i = 0; i < 3; i++) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(w * .47, h * (.22 + i * .20), w * .37, h * .14),
                  const Radius.circular(7)),
              Paint()..color = colors[i]);
          _drawText(canvas, ['move', 'turn', 'repeat'][i],
              Offset(w * .52, h * (.255 + i * .20)), h * .11, Colors.white);
        }
        break;
      case 'recycling_challenge':
        for (var i = 0; i < 3; i++) {
          final x = w * (.14 + i * .28);
          final color = [
            const Color(0xFF2D83C7),
            const Color(0xFF4EAF4F),
            const Color(0xFFE3A424)
          ][i];
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(x, h * .35, w * .20, h * .45),
                  const Radius.circular(8)),
              Paint()..color = color);
          canvas.drawRect(Rect.fromLTWH(x - w * .01, h * .28, w * .22, h * .09),
              Paint()..color = Color.lerp(color, Colors.black, .12)!);
          _drawText(
              canvas, '♻', Offset(x + w * .05, h * .48), h * .22, Colors.white);
        }
        break;
      case 'rewards_room':
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * .28, h * .48, w * .44, h * .29),
                const Radius.circular(9)),
            Paint()..color = const Color(0xFFB66824));
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * .30, h * .35, w * .40, h * .24),
                const Radius.circular(26)),
            Paint()..color = const Color(0xFFD8832D));
        canvas.drawRect(Rect.fromLTWH(w * .48, h * .48, w * .06, h * .20),
            Paint()..color = const Color(0xFFFFD044));
        for (final p in [
          Offset(w * .18, h * .30),
          Offset(w * .80, h * .30),
          Offset(w * .70, h * .14),
          Offset(w * .34, h * .17)
        ]) {
          _drawStar(canvas, p, h * .08, const Color(0xFFFFD32A));
        }
        break;
      default:
        canvas.drawCircle(Offset(w * .5, h * .5), h * .25, whiteSoft);
        canvas.drawCircle(Offset(w * .5, h * .5), h * .12, dark);
    }
  }

  List<Color> _scenePalette(String id) => switch (id) {
        'math_market' => const [
            Color(0xFF69C8FF),
            Color(0xFFB6EDFF),
            Color(0xFF6DC57A)
          ],
        'fraction_pizza' => const [
            Color(0xFF4C674C),
            Color(0xFF213D2D),
            Color(0xFFF59F25)
          ],
        'science_lab' => const [
            Color(0xFF422793),
            Color(0xFF7E4DE8),
            Color(0xFF2A174F)
          ],
        'story_builder' => const [
            Color(0xFF59CFE7),
            Color(0xFF73D79E),
            Color(0xFF6940AF)
          ],
        'grammar_puzzle' => const [
            Color(0xFFFF75B3),
            Color(0xFFEE4F9F),
            Color(0xFF8B3473)
          ],
        'map_quest' => const [
            Color(0xFF66C8FF),
            Color(0xFF7DD2C2),
            Color(0xFF2C8ACC)
          ],
        'coding_maze' => const [
            Color(0xFF4635A5),
            Color(0xFF6B5DE0),
            Color(0xFF262452)
          ],
        'recycling_challenge' => const [
            Color(0xFF6BC866),
            Color(0xFFB6E978),
            Color(0xFF3A9843)
          ],
        'rewards_room' => const [
            Color(0xFFFFB51F),
            Color(0xFFFFD95C),
            Color(0xFFEA7B13)
          ],
        _ => const [Color(0xFF4CB7FF), Color(0xFF86DFFF)],
      };

  void _drawFlask(Canvas canvas, Offset origin, double size, Color liquid) {
    final glass = Paint()
      ..color = Colors.white.withValues(alpha: .86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path()
      ..moveTo(origin.dx + size * .39, origin.dy)
      ..lineTo(origin.dx + size * .39, origin.dy + size * .25)
      ..lineTo(origin.dx + size * .18, origin.dy + size * .74)
      ..quadraticBezierTo(origin.dx + size * .10, origin.dy + size * .94,
          origin.dx + size * .32, origin.dy + size)
      ..lineTo(origin.dx + size * .68, origin.dy + size)
      ..quadraticBezierTo(origin.dx + size * .90, origin.dy + size * .94,
          origin.dx + size * .82, origin.dy + size * .74)
      ..lineTo(origin.dx + size * .61, origin.dy + size * .25)
      ..lineTo(origin.dx + size * .61, origin.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: .22));
    canvas.drawPath(path, glass);
    final liquidPath = Path()
      ..moveTo(origin.dx + size * .22, origin.dy + size * .72)
      ..quadraticBezierTo(origin.dx + size * .50, origin.dy + size * .65,
          origin.dx + size * .78, origin.dy + size * .72)
      ..lineTo(origin.dx + size * .68, origin.dy + size * .92)
      ..quadraticBezierTo(origin.dx + size * .50, origin.dy + size,
          origin.dx + size * .32, origin.dy + size * .92)
      ..close();
    canvas.drawPath(liquidPath, Paint()..color = liquid.withValues(alpha: .88));
    canvas.drawLine(Offset(origin.dx + size * .34, origin.dy),
        Offset(origin.dx + size * .66, origin.dy), glass);
  }

  void _drawCastle(Canvas canvas, Offset origin, double width, double height) {
    final base = Paint()..color = const Color(0xFFE8E1D1);
    final roof = Paint()..color = const Color(0xFFB74B3D);
    canvas.drawRect(
        Rect.fromLTWH(origin.dx + width * .15, origin.dy + height * .35,
            width * .7, height * .5),
        base);
    for (final x in [0.12, 0.43, 0.74]) {
      canvas.drawRect(
          Rect.fromLTWH(origin.dx + width * x, origin.dy + height * .18,
              width * .14, height * .35),
          base);
      canvas.drawPath(
          Path()
            ..moveTo(origin.dx + width * (x - .02), origin.dy + height * .18)
            ..lineTo(origin.dx + width * (x + .07), origin.dy)
            ..lineTo(origin.dx + width * (x + .16), origin.dy + height * .18)
            ..close(),
          roof);
    }
  }

  void _drawPuzzle(Canvas canvas, Rect rect, Color color, String text) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()..color = color);
    canvas.drawCircle(Offset(rect.right, rect.center.dy), rect.height * .11,
        Paint()..color = color);
    canvas.drawCircle(Offset(rect.left, rect.center.dy), rect.height * .10,
        Paint()..color = Colors.white.withValues(alpha: .22));
    _drawText(
        canvas,
        text,
        Offset(rect.left + rect.width * .14, rect.top + rect.height * .34),
        rect.height * .18,
        Colors.white);
  }

  void _drawCompass(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFFF5E9C5));
    canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = const Color(0xFF6B4E29)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy - r * .75)
          ..lineTo(center.dx + r * .28, center.dy + r * .30)
          ..lineTo(center.dx, center.dy + r * .10)
          ..lineTo(center.dx - r * .28, center.dy + r * .30)
          ..close(),
        Paint()..color = const Color(0xFFE64C3C));
  }

  void _drawRobot(Canvas canvas, Offset center, double r) {
    final body = Paint()..color = const Color(0xFF79B9E9);
    final deep = Paint()..color = const Color(0xFF17456E);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: r * 1.7, height: r * 1.4),
            Radius.circular(r * .32)),
        body);
    canvas.drawCircle(Offset(center.dx - r * .34, center.dy), r * .16,
        Paint()..color = const Color(0xFF75E7FF));
    canvas.drawCircle(Offset(center.dx + r * .34, center.dy), r * .16,
        Paint()..color = const Color(0xFF75E7FF));
    canvas.drawCircle(Offset(center.dx - r * .34, center.dy), r * .06, deep);
    canvas.drawCircle(Offset(center.dx + r * .34, center.dy), r * .06, deep);
    final antennaPaint = Paint()
      ..color = deep.color
      ..strokeWidth = 3;
    canvas.drawLine(Offset(center.dx, center.dy - r * .72),
        Offset(center.dx, center.dy - r * 1.05), antennaPaint);
    canvas.drawCircle(Offset(center.dx, center.dy - r * 1.12), r * .11,
        Paint()..color = const Color(0xFFFFD229));
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius : radius * .45;
      final p =
          Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
      if (i == 0)
        path.moveTo(p.dx, p.dy);
      else
        path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawText(
      Canvas canvas, String text, Offset offset, double fontSize, Color color) {
    final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color, fontSize: fontSize, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _GameScenePainter oldDelegate) =>
      oldDelegate.gameId != gameId;
}

class BrightSparkles extends StatelessWidget {
  const BrightSparkles({this.color = const Color(0xFFFFD22A), super.key});
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: BrightReveal(
          duration: const Duration(milliseconds: 620),
          beginScale: 0.72,
          offset: const Offset(0.025, -0.02),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: 86,
            height: 64,
            child: Stack(
              children: [
                Positioned(
                    left: 8,
                    top: 4,
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 18, color: color)),
                Positioned(
                    right: 10,
                    top: 18,
                    child: Icon(Icons.star_rounded,
                        size: 13, color: color.withValues(alpha: .9))),
                Positioned(
                    right: 28,
                    bottom: 7,
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 14, color: color.withValues(alpha: .75))),
              ],
            ),
          ),
        ),
      );
}

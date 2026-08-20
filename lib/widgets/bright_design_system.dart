import 'package:flutter/material.dart';

import '../core/models/game_models.dart';
import '../core/theme/app_theme.dart';
import 'bright_motion.dart';

enum BrightBreakpoint { compact, medium, expanded, large }

BrightBreakpoint brightBreakpointFor(double width) {
  if (width < 600) return BrightBreakpoint.compact;
  if (width < 900) return BrightBreakpoint.medium;
  if (width < 1200) return BrightBreakpoint.expanded;
  return BrightBreakpoint.large;
}

class BrightResponsive extends StatelessWidget {
  const BrightResponsive({
    required this.builder,
    this.maxWidth = 1320,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    super.key,
  });

  final Widget Function(BuildContext context, BrightBreakpoint breakpoint)
      builder;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = brightBreakpointFor(constraints.maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding,
              child: builder(context, breakpoint),
            ),
          ),
        );
      },
    );
  }
}

class BrightPageBackground extends StatelessWidget {
  const BrightPageBackground({
    required this.child,
    this.primary = const Color(0xFFECF8FF),
    this.secondary = const Color(0xFFFFFAEB),
    super.key,
  });

  final Widget child;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, secondary, const Color(0xFFF7F1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
              top: 90,
              right: -28,
              child: _Bubble(size: 130, color: Color(0x224CB7FF))),
          const Positioned(
              top: 360,
              left: -35,
              child: _Bubble(size: 105, color: Color(0x22FFD54F))),
          const Positioned(
              bottom: 90,
              right: 40,
              child: _Bubble(size: 70, color: Color(0x226D4BE8))),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}

class BrightSurface extends StatelessWidget {
  const BrightSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.radius = 26,
    this.shadow = true,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x140C3356),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: color ?? Colors.white.withValues(alpha: 0.94),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: borderColor ?? Colors.white, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class BrightSectionTitle extends StatelessWidget {
  const BrightSectionTitle({
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    Widget titleRow({bool includeTrailing = true}) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.purple, size: 21),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.inkMuted, height: 1.3)),
                  ],
                ],
              ),
            ),
            if (includeTrailing && trailing != null) ...[
              const SizedBox(width: 12),
              Flexible(child: trailing!)
            ],
          ],
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (trailing != null && constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleRow(includeTrailing: false),
              const SizedBox(height: 8),
              trailing!,
            ],
          );
        }
        return titleRow();
      },
    );
  }
}

class BrightMascotBubble extends StatelessWidget {
  const BrightMascotBubble({
    required this.message,
    this.emoji = '🦁',
    this.compact = false,
    super.key,
  });

  final String message;
  final String emoji;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mascotSize = compact ? 48.0 : 62.0;
    return BrightReveal(
      duration: const Duration(milliseconds: 320),
      beginScale: 0.96,
      offset: const Offset(0.015, 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: mascotSize,
            height: mascotSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFFE28A), Color(0xFFFFB95A)]),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 12,
                    offset: Offset(0, 5))
              ],
            ),
            child: Text(emoji, style: TextStyle(fontSize: compact ? 28 : 36)),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 15, vertical: compact ? 9 : 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(5),
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x15000000),
                      blurRadius: 14,
                      offset: Offset(0, 5))
                ],
              ),
              child: Text(message,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 12 : 14,
                      color: AppTheme.navy)),
            ),
          ),
        ],
      ),
    );
  }
}

class BrightPill extends StatelessWidget {
  const BrightPill({
    required this.icon,
    required this.label,
    this.color = AppTheme.purple,
    this.background,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: background ?? color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ],
        ),
      );
}

class BrightWorldPalette {
  const BrightWorldPalette(this.primary, this.secondary, this.deep, this.emoji);
  final Color primary;
  final Color secondary;
  final Color deep;
  final String emoji;
}

BrightWorldPalette paletteForSubject(SubjectWorld subject) => switch (subject) {
      SubjectWorld.maths => const BrightWorldPalette(
          Color(0xFF49A5FF), Color(0xFF9EE7FF), Color(0xFF155BB8), '🏰'),
      SubjectWorld.english => const BrightWorldPalette(
          Color(0xFF55CDAE), Color(0xFFB9F2D6), Color(0xFF147963), '📚'),
      SubjectWorld.science => const BrightWorldPalette(
          Color(0xFF8D69F7), Color(0xFFD7C8FF), Color(0xFF4A2BB4), '🧪'),
      SubjectWorld.evs => const BrightWorldPalette(
          Color(0xFF62C86A), Color(0xFFC6F2A8), Color(0xFF2C7D36), '🌿'),
      SubjectWorld.social => const BrightWorldPalette(
          Color(0xFFFFA34D), Color(0xFFFFD9A7), Color(0xFFB85B11), '🗺️'),
      SubjectWorld.coding => const BrightWorldPalette(
          Color(0xFF6C63E8), Color(0xFFBFC4FF), Color(0xFF3B36A1), '🤖'),
      SubjectWorld.art => const BrightWorldPalette(
          Color(0xFFFF72B5), Color(0xFFFFC5E4), Color(0xFFB43878), '🎨'),
    };

class BrightWorldBackdrop extends StatelessWidget {
  const BrightWorldBackdrop(
      {required this.palette, required this.child, super.key});
  final BrightWorldPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.primary, palette.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: palette.primary.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(
          children: [
            const Positioned.fill(
                child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    child: BrightGlint())),
            Positioned(
                right: -8,
                top: -16,
                child:
                    Text(palette.emoji, style: const TextStyle(fontSize: 92))),
            const Positioned(
                right: 88,
                bottom: 16,
                child: Text('✨', style: TextStyle(fontSize: 22))),
            Positioned.fill(child: child),
          ],
        ),
      );
}

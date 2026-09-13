import 'package:flutter/material.dart';

import '../core/models/game_models.dart';
import '../core/presentation/game_feel_models.dart';
import '../core/theme/app_theme.dart';
import 'bright_adaptive.dart';
import 'bright_illustrations.dart';
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
    this.maxWidth,
    this.padding,
    super.key,
  });

  final Widget Function(BuildContext context, BrightBreakpoint breakpoint)
      builder;
  final double? maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final global = BrightLayout.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = brightBreakpointFor(constraints.maxWidth);
        final resolvedPadding = padding ??
            EdgeInsets.symmetric(
              horizontal: global.gutter,
            );
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? global.contentMaxWidth,
            ),
            child: Padding(
              padding: resolvedPadding,
              child: builder(context, breakpoint),
            ),
          ),
        );
      },
    );
  }
}

/// Responsive grid that uses a minimum child width instead of hard-coded
/// breakpoint-specific column counts. This keeps Android free-form windows
/// stable while allowing Windows to use its extra horizontal space.
class BrightAdaptiveGrid extends StatelessWidget {
  const BrightAdaptiveGrid({
    required this.children,
    this.minChildWidth = 250,
    this.maxColumns = 5,
    this.spacing = 14,
    this.runSpacing = 14,
    super.key,
  });

  final List<Widget> children;
  final double minChildWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.of(context).textScaler.scale(1);
        final readableMinChildWidth = brightReadableMinTileWidth(
          baseMinWidth: minChildWidth,
          textScale: textScale,
        );
        final possible = ((constraints.maxWidth + spacing) /
                (readableMinChildWidth + spacing))
            .floor();
        final columns = possible.clamp(1, maxColumns).toInt();
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child)
          ],
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
    this.showDecorations = true,
    super.key,
  });

  final Widget child;
  final Color primary;
  final Color secondary;
  final bool showDecorations;

  @override
  Widget build(BuildContext context) {
    final layout = BrightLayout.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            Color.lerp(primary, secondary, .45)!,
            const Color(0xFFF7F1FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          if (showDecorations) ...[
            Positioned(
              top: layout.shortViewport ? 44 : 82,
              right: -34,
              child: const _Bubble(size: 142, color: Color(0x244CB7FF)),
            ),
            const Positioned(
              top: 340,
              left: -44,
              child: _Bubble(size: 118, color: Color(0x25FFD54F)),
            ),
            const Positioned(
              bottom: 72,
              right: 34,
              child: _Bubble(size: 76, color: Color(0x226D4BE8)),
            ),
            Positioned(
              top: layout.isDesktop ? 148 : 210,
              left: layout.isDesktop ? 42 : -20,
              child: const _StarCluster(),
            ),
          ],
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .35)),
          ),
        ),
      );
}

class _StarCluster extends StatelessWidget {
  const _StarCluster();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Opacity(
          opacity: .34,
          child: Transform.rotate(
            angle: -.22,
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 22, color: AppTheme.purple),
                SizedBox(width: 10),
                Icon(Icons.star_rounded, size: 13, color: AppTheme.orange),
              ],
            ),
          ),
        ),
      );
}

class BrightSurface extends StatelessWidget {
  const BrightSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.radius = AppTheme.radiusLarge,
    this.shadow = true,
    this.tint,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool shadow;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final baseColor = color ?? Colors.white.withValues(alpha: 0.94);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: (tint ?? AppTheme.navy).withValues(alpha: .08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: baseColor,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color: borderColor ?? Colors.white.withValues(alpha: .92),
            width: 1.4,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [
            if (tint != null)
              Positioned(
                right: -32,
                top: -42,
                child: IgnorePointer(
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tint!.withValues(alpha: .08),
                    ),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
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
    this.accent = AppTheme.purple,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    Widget titleRow({bool includeTrailing = true}) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: .16),
                      accent.withValues(alpha: .07),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 11),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.inkMuted,
                            height: 1.3,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (includeTrailing && trailing != null) ...[
              const SizedBox(width: 12),
              Flexible(child: trailing!),
            ],
          ],
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (trailing != null && constraints.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleRow(includeTrailing: false),
              const SizedBox(height: 9),
              trailing!,
            ],
          );
        }
        return titleRow();
      },
    );
  }
}

class BrightLeoMoment extends StatelessWidget {
  const BrightLeoMoment({
    required this.message,
    required this.moment,
    this.trigger,
    this.compact = false,
    super.key,
  });

  final String message;
  final BrightGameFeelMoment moment;
  final Object? trigger;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = switch (moment.kind) {
      BrightMomentKind.success ||
      BrightMomentKind.unlock ||
      BrightMomentKind.bossClear ||
      BrightMomentKind.worldClear =>
        const Color(0xFF17824A),
      BrightMomentKind.retry => const Color(0xFFB36A00),
      BrightMomentKind.powerUp ||
      BrightMomentKind.hint =>
        const Color(0xFF6D4BE8),
      _ => const Color(0xFF1F6FAF),
    };
    final mascotSize = compact ? 54.0 : 68.0;

    return Semantics(
      container: true,
      excludeSemantics: true,
      liveRegion: moment.kind == BrightMomentKind.success ||
          moment.kind == BrightMomentKind.retry ||
          moment.kind == BrightMomentKind.powerUp,
      label: '${moment.semanticLabel}. $message',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: mascotSize,
            child: BrightMomentReaction(
              trigger: trigger ?? '${moment.kind.name}:${moment.mood.name}',
              kind: moment.kind,
              child: BrightLionMascot(
                size: mascotSize,
                mood: moment.mood,
                animated: false,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: BrightMomentReaction(
              trigger: trigger ?? '${moment.kind.name}:${moment.mood.name}',
              kind: moment.kind,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 11 : 14,
                  vertical: compact ? 9 : 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .94),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    bottomLeft: Radius.circular(5),
                  ),
                  border: Border.all(color: accent.withValues(alpha: .18)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: .10),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moment.emoji,
                        style: TextStyle(fontSize: compact ? 18 : 21)),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          fontSize: compact ? 11.5 : 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
                colors: [Color(0xFFFFE28A), Color(0xFFFFB95A)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Text(emoji, style: TextStyle(fontSize: compact ? 28 : 36)),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 15,
                vertical: compact ? 9 : 12,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 12 : 14,
                  color: AppTheme.navy,
                ),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: background ?? color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .08)),
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
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
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
  const BrightWorldBackdrop({
    required this.palette,
    required this.child,
    super.key,
  });
  final BrightWorldPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.primary, palette.deep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.24),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -22,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.secondary.withValues(alpha: .25),
                ),
              ),
            ),
            const Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                child: BrightGlint(),
              ),
            ),
            Positioned(
              right: -8,
              top: -16,
              child: Text(palette.emoji, style: const TextStyle(fontSize: 92)),
            ),
            const Positioned(
              right: 88,
              bottom: 16,
              child: Text('✨', style: TextStyle(fontSize: 22)),
            ),
            Positioned.fill(child: child),
          ],
        ),
      );
}

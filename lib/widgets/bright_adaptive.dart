import 'package:flutter/material.dart';

/// Resolves BrightQuest's in-app reading-size preference without suppressing
/// the operating system accessibility scale. The larger request wins and is
/// capped at 2x so Android large-text users remain respected while the app
/// keeps a tested upper layout bound for kid-facing surfaces.
double brightEffectiveTextScale({
  required double systemTextScale,
  required double appTextScale,
}) {
  final system = systemTextScale.clamp(0.8, 3.0).toDouble();
  final app = appTextScale.clamp(0.9, 1.3).toDouble();
  return (system > app ? system : app).clamp(0.9, 2.0).toDouble();
}

/// High-level viewport intent. This is deliberately based on the usable Flutter
/// surface rather than an OS check so Android free-form windows behave like the
/// space they actually have.
enum BrightWindowClass { phone, tablet, freeform, desktop }

@immutable
class BrightLayoutMetrics {
  const BrightLayoutMetrics({
    required this.size,
    required this.windowClass,
    required this.shortViewport,
    required this.gutter,
    required this.sectionGap,
    required this.contentMaxWidth,
    required this.minimumTapTarget,
    required this.navigationWidth,
  });

  factory BrightLayoutMetrics.fromSize(Size size) {
    final width = size.width;
    final height = size.height;
    final windowClass = width < 600
        ? BrightWindowClass.phone
        : width < 900
            ? BrightWindowClass.tablet
            : width < 1280
                ? BrightWindowClass.freeform
                : BrightWindowClass.desktop;
    final shortViewport = height < 700;

    return BrightLayoutMetrics(
      size: size,
      windowClass: windowClass,
      shortViewport: shortViewport,
      gutter: switch (windowClass) {
        BrightWindowClass.phone => 14,
        BrightWindowClass.tablet => 18,
        BrightWindowClass.freeform => 20,
        BrightWindowClass.desktop => 24,
      },
      sectionGap: shortViewport ? 12 : 16,
      contentMaxWidth: windowClass == BrightWindowClass.desktop ? 1480 : 1320,
      minimumTapTarget: windowClass == BrightWindowClass.phone ? 48 : 44,
      navigationWidth: switch (windowClass) {
        BrightWindowClass.phone => 0,
        BrightWindowClass.tablet => 78,
        BrightWindowClass.freeform => 88,
        BrightWindowClass.desktop => 236,
      },
    );
  }

  final Size size;
  final BrightWindowClass windowClass;
  final bool shortViewport;
  final double gutter;
  final double sectionGap;
  final double contentMaxWidth;
  final double minimumTapTarget;
  final double navigationWidth;

  bool get isPhone => windowClass == BrightWindowClass.phone;
  bool get isTablet => windowClass == BrightWindowClass.tablet;
  bool get isFreeform => windowClass == BrightWindowClass.freeform;
  bool get isDesktop => windowClass == BrightWindowClass.desktop;
  bool get usesBottomNavigation => isPhone;
  bool get usesNavigationRail => isTablet || isFreeform;
  bool get usesExpandedNavigation => isDesktop;
  bool get isWide => isFreeform || isDesktop;

  int gridColumns({
    double minTileWidth = 250,
    int minColumns = 1,
    int maxColumns = 5,
    double spacing = 14,
  }) {
    final usable = size.width - gutter * 2;
    final estimated = ((usable + spacing) / (minTileWidth + spacing)).floor();
    return estimated.clamp(minColumns, maxColumns).toInt();
  }
}

class BrightLayoutHost extends StatelessWidget {
  const BrightLayoutHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : mediaSize.width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : mediaSize.height;
        final metrics = BrightLayoutMetrics.fromSize(Size(width, height));
        return _BrightLayoutScope(metrics: metrics, child: child);
      },
    );
  }
}

class BrightLayout {
  const BrightLayout._();

  static BrightLayoutMetrics of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_BrightLayoutScope>();
    return scope?.metrics ??
        BrightLayoutMetrics.fromSize(MediaQuery.sizeOf(context));
  }
}

class _BrightLayoutScope extends InheritedWidget {
  const _BrightLayoutScope({required this.metrics, required super.child});

  final BrightLayoutMetrics metrics;

  @override
  bool updateShouldNotify(_BrightLayoutScope oldWidget) =>
      oldWidget.metrics.size != metrics.size ||
      oldWidget.metrics.windowClass != metrics.windowClass ||
      oldWidget.metrics.shortViewport != metrics.shortViewport;
}

class BrightAdaptivePadding extends StatelessWidget {
  const BrightAdaptivePadding({
    required this.child,
    this.top = 0,
    this.bottom = 0,
    super.key,
  });

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final layout = BrightLayout.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(layout.gutter, top, layout.gutter, bottom),
      child: child,
    );
  }
}

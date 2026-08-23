import 'dart:async';

import 'package:flutter/material.dart';

import '../core/content/content_repository.dart';
import '../core/entitlements/entitlement_service.dart';
import '../core/services/bright_audio_service.dart';
import '../core/state/game_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/adventures/adventures_screen.dart';
import '../features/home/home_screen.dart';
import '../features/parent/parent_gate_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/progress/progress_screen.dart';
import '../widgets/bright_adaptive.dart';
import 'app_persistence_boundary.dart';
import 'brightquest_scope.dart';

class BrightQuestApp extends StatelessWidget {
  BrightQuestApp({
    required this.controller,
    required this.contentRepository,
    EntitlementService? entitlementService,
    super.key,
  }) : entitlementService = entitlementService ?? EntitlementService();

  final GameController controller;
  final ContentRepository contentRepository;
  final EntitlementService entitlementService;

  @override
  Widget build(BuildContext context) {
    return BrightQuestScope(
      controller: controller,
      contentRepository: contentRepository,
      entitlementService: entitlementService,
      child: AppPersistenceBoundary(
        controller: controller,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'BrightQuest Kids',
              theme: AppTheme.light(
                highContrast: controller.highContrastEnabled,
                dyslexiaFriendlySpacing: controller.dyslexiaFriendlySpacing,
              ),
              builder: (context, child) {
                final media = MediaQuery.of(context);
                final systemTextScale = media.textScaler.scale(1);
                final effectiveTextScale = brightEffectiveTextScale(
                  systemTextScale: systemTextScale,
                  appTextScale: controller.textScale,
                );
                return MediaQuery(
                  data: media.copyWith(
                    textScaler: TextScaler.linear(effectiveTextScale),
                  ),
                  child: BrightLayoutHost(
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              home: const MainShell(),
            );
          },
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  bool? _lastAudioEnabled;

  final Map<int, Widget> _mountedPages = <int, Widget>{};

  Widget _pageFor(int pageIndex) => _mountedPages.putIfAbsent(
        pageIndex,
        () => switch (pageIndex) {
          0 => const HomeScreen(),
          1 => const AdventuresScreen(),
          2 => const ProgressScreen(),
          3 => const ParentGateScreen(),
          4 => const ProfileScreen(),
          _ => const HomeScreen(),
        },
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = BrightQuestScope.of(context).soundEnabled;
    if (_lastAudioEnabled == enabled) return;
    _lastAudioEnabled = enabled;
    unawaited(BrightAudioService.instance.setSessionEnabled(enabled));
    if (enabled) {
      unawaited(BrightAudioService.instance.playMenuMusic());
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = BrightLayout.of(context);
    // Keep only the active destination in the widget tree. This preserves the
    // Windows crash-isolation contract by avoiding offstage page semantics
    // while the shell's own State keeps the selected destination stable
    // across free-form window resizing.
    final page = _pageFor(index);

    if (layout.usesBottomNavigation) {
      return Scaffold(
        body: page,
        bottomNavigationBar: _BrightBottomNavigation(
          selectedIndex: index,
          onSelected: (value) => setState(() => index = value),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _BrightSideNavigation(
            selectedIndex: index,
            expanded: layout.usesExpandedNavigation,
            width: layout.navigationWidth,
            compactHeight: layout.shortViewport,
            onSelected: (value) => setState(() => index = value),
          ),
          Expanded(child: page),
        ],
      ),
    );
  }
}

class _ShellItem {
  const _ShellItem(this.icon, this.label, this.emoji);
  final IconData icon;
  final String label;
  final String emoji;
}

const _shellItems = <_ShellItem>[
  _ShellItem(Icons.home_rounded, 'Home', '🏡'),
  _ShellItem(Icons.explore_rounded, 'Worlds', '🗺️'),
  _ShellItem(Icons.auto_graph_rounded, 'Progress', '⭐'),
  _ShellItem(Icons.family_restroom_rounded, 'Parents', '👨‍👩‍👧'),
  _ShellItem(Icons.face_rounded, 'Profile', '🦁'),
];

class _BrightSideNavigation extends StatelessWidget {
  const _BrightSideNavigation({
    required this.selectedIndex,
    required this.expanded,
    required this.width,
    required this.compactHeight,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool expanded;
  final double width;
  final bool compactHeight;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF314FD0),
            Color(0xFF6D4BE8),
            Color(0xFF4C8FE9),
            Color(0xFF45B5EC),
          ],
          stops: [0, .42, .73, 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x260C3356),
            blurRadius: 30,
            offset: Offset(8, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 84,
            right: -26,
            child:
                Icon(Icons.cloud_rounded, size: 90, color: Color(0x16FFFFFF)),
          ),
          const Positioned(
            bottom: 120,
            left: -20,
            child: Icon(Icons.auto_awesome_rounded,
                size: 62, color: Color(0x14FFE36F)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Android free-form and desktop windows can become extremely
                // short. Preserve the five navigation targets first and drop
                // only decorative/profile chrome when vertical space is tight.
                final severelyShort = constraints.maxHeight < 460;
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: expanded ? 14 : 9,
                    vertical: compactHeight ? 10 : 16,
                  ),
                  child: Column(
                    children: [
                      if (!severelyShort) ...[
                        _BrandMark(
                          expanded: expanded,
                          compact: compactHeight,
                        ),
                        SizedBox(height: compactHeight ? 10 : 18),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children:
                              List.generate(_shellItems.length, (itemIndex) {
                            final item = _shellItems[itemIndex];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: compactHeight ? 5 : 8,
                              ),
                              child: _SideNavDestination(
                                item: item,
                                selected: selectedIndex == itemIndex,
                                expanded: expanded,
                                compactHeight: compactHeight,
                                onTap: () {
                                  unawaited(BrightAudioService.instance
                                      .playSfx(BrightSfx.tap));
                                  onSelected(itemIndex);
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                      if (!severelyShort)
                        _ExplorerDock(
                          expanded: expanded,
                          compactHeight: compactHeight,
                          avatar: controller.activeProfileAvatar,
                          name: controller.activeProfileName,
                          classNumber: controller.selectedClass,
                          level: controller.level,
                          stars: controller.learningPathStars,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNavDestination extends StatefulWidget {
  const _SideNavDestination({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.compactHeight,
    required this.onTap,
  });

  final _ShellItem item;
  final bool selected;
  final bool expanded;
  final bool compactHeight;
  final VoidCallback onTap;

  @override
  State<_SideNavDestination> createState() => _SideNavDestinationState();
}

class _SideNavDestinationState extends State<_SideNavDestination> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Semantics(
        container: true,
        excludeSemantics: true,
        selected: selected,
        button: true,
        label: widget.item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: widget.compactHeight ? 48 : 54,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: widget.expanded ? 10 : 0,
                vertical: widget.compactHeight ? 7 : 9,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white
                    : hovered
                        ? Colors.white.withValues(alpha: .16)
                        : Colors.white.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: hovered ? .18 : .06),
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x260F2D60),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: widget.expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.purple.withValues(alpha: .10)
                          : Colors.white.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      widget.item.icon,
                      color: selected ? AppTheme.purpleDeep : Colors.white,
                      size: 21,
                    ),
                  ),
                  if (widget.expanded) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.item.label,
                        style: TextStyle(
                          color: selected ? AppTheme.navy : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: selected ? AppTheme.purple : Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplorerDock extends StatelessWidget {
  const _ExplorerDock({
    required this.expanded,
    required this.compactHeight,
    required this.avatar,
    required this.name,
    required this.classNumber,
    required this.level,
    required this.stars,
  });

  final bool expanded;
  final bool compactHeight;
  final String avatar;
  final String name;
  final int classNumber;
  final int level;
  final int stars;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return Tooltip(
        message: '$name • Class $classNumber',
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: .16)),
          ),
          child: Text(avatar, style: const TextStyle(fontSize: 29)),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(compactHeight ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compactHeight ? 38 : 44,
                height: compactHeight ? 38 : 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(avatar,
                    style: TextStyle(fontSize: compactHeight ? 22 : 26)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Class $classNumber • Level $level',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!compactHeight) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '⭐ $stars path stars',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.expanded, required this.compact});
  final bool expanded;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment:
            expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: compact ? 42 : 48,
            height: compact ? 42 : 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFFFF1B7)],
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x28000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Text('🦁', style: TextStyle(fontSize: compact ? 25 : 29)),
          ),
          if (expanded) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BrightQuest',
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'KIDS • ADVENTURE LEARNING',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFFFE36F),
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
}

class _BrightBottomNavigation extends StatelessWidget {
  const _BrightBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 6),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .97),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2A0C3356),
                blurRadius: 26,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_shellItems.length, (itemIndex) {
              final item = _shellItems[itemIndex];
              final selected = itemIndex == selectedIndex;
              return Expanded(
                child: Semantics(
                  container: true,
                  excludeSemantics: true,
                  selected: selected,
                  button: true,
                  label: item.label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      unawaited(
                          BrightAudioService.instance.playSfx(BrightSfx.tap));
                      onSelected(itemIndex);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? const LinearGradient(
                                colors: [Color(0xFFEDE7FF), Color(0xFFEAF6FF)],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 31,
                            height: 29,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.purple.withValues(alpha: .12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.icon,
                              color: selected
                                  ? AppTheme.purpleDeep
                                  : AppTheme.inkMuted,
                              size: 21,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? AppTheme.purpleDeep
                                  : AppTheme.inkMuted,
                              fontWeight:
                                  selected ? FontWeight.w900 : FontWeight.w700,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
}

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
import '../widgets/bright_design_system.dart';
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
              return MediaQuery(
                data: media.copyWith(
                    textScaler: TextScaler.linear(controller.textScale)),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const MainShell(),
          );
        },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = brightBreakpointFor(constraints.maxWidth);
        final useSideNav = breakpoint != BrightBreakpoint.compact;
        final expandedSideNav = breakpoint == BrightBreakpoint.large;

        if (useSideNav) {
          return Scaffold(
            body: Row(
              children: [
                _BrightSideNavigation(
                  selectedIndex: index,
                  expanded: expandedSideNav,
                  onSelected: (value) => setState(() => index = value),
                ),
                Expanded(child: _pageFor(index)),
              ],
            ),
          );
        }

        return Scaffold(
          body: _pageFor(index),
          bottomNavigationBar: _BrightBottomNavigation(
            selectedIndex: index,
            onSelected: (value) => setState(() => index = value),
          ),
        );
      },
    );
  }
}

class _ShellItem {
  const _ShellItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _shellItems = <_ShellItem>[
  _ShellItem(Icons.home_rounded, 'Home'),
  _ShellItem(Icons.explore_rounded, 'Worlds'),
  _ShellItem(Icons.auto_graph_rounded, 'Progress'),
  _ShellItem(Icons.family_restroom_rounded, 'Parents'),
  _ShellItem(Icons.face_rounded, 'Profile'),
];

class _BrightSideNavigation extends StatelessWidget {
  const _BrightSideNavigation({
    required this.selectedIndex,
    required this.expanded,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool expanded;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final width = expanded ? 220.0 : 86.0;
    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF355BC9), Color(0xFF6D4BE8), Color(0xFF4BA9F2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x240C3356), blurRadius: 24, offset: Offset(8, 0))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: expanded ? 14 : 9, vertical: 16),
          child: Column(
            children: [
              _BrandMark(expanded: expanded),
              const SizedBox(height: 22),
              ...List.generate(_shellItems.length, (itemIndex) {
                final item = _shellItems[itemIndex];
                final selected = selectedIndex == itemIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: expanded ? 13 : 0, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: expanded
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Icon(item.icon,
                                color: selected
                                    ? AppTheme.purpleDeep
                                    : Colors.white,
                                size: 24),
                            if (expanded) ...[
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    color:
                                        selected ? AppTheme.navy : Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              Container(
                padding: EdgeInsets.all(expanded ? 12 : 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: expanded
                    ? Row(
                        children: [
                          Text(controller.activeProfileAvatar,
                              style: const TextStyle(fontSize: 30)),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(controller.activeProfileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900)),
                                Text('Class ${controller.selectedClass}',
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.82),
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Text(controller.activeProfileAvatar,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 30)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.expanded});
  final bool expanded;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment:
            expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x28000000),
                    blurRadius: 12,
                    offset: Offset(0, 5))
              ],
            ),
            child: const Text('🦁', style: TextStyle(fontSize: 28)),
          ),
          if (expanded) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BrightQuest',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                  Text('KIDS',
                      style: TextStyle(
                          color: Color(0xFFFFE36F),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 10)),
                ],
              ),
            ),
          ],
        ],
      );
}

class _BrightBottomNavigation extends StatelessWidget {
  const _BrightBottomNavigation(
      {required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x220C3356),
                  blurRadius: 24,
                  offset: Offset(0, 8))
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.purple.withValues(alpha: 0.11)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon,
                              color: selected
                                  ? AppTheme.purpleDeep
                                  : AppTheme.inkMuted,
                              size: 23),
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
                              fontSize: 10,
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

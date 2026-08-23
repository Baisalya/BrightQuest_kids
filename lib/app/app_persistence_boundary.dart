import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/state/game_controller.dart';

/// Root-level durability boundary for progress and resumable mission state.
///
/// Individual games still checkpoint eagerly, but production lifecycle events
/// can happen while the child is on Home, Nursery, Progress or a parent page.
/// Keeping this observer above the whole app ensures both authoritative
/// progress and the separate resumable-session store are flushed whenever the
/// process is backgrounded, hidden, detached or under memory pressure.
class AppPersistenceBoundary extends StatefulWidget {
  const AppPersistenceBoundary({
    required this.controller,
    required this.child,
    super.key,
  });

  final GameController controller;
  final Widget child;

  @override
  State<AppPersistenceBoundary> createState() => _AppPersistenceBoundaryState();
}

class _AppPersistenceBoundaryState extends State<AppPersistenceBoundary>
    with WidgetsBindingObserver {
  Future<void> _flushTail = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(AppPersistenceBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _queueFlush(oldWidget.controller);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _queueFlush(widget.controller);
  }

  @override
  void didHaveMemoryPressure() {
    _queueFlush(widget.controller);
  }

  void _queueFlush(GameController controller) {
    _flushTail = _flushTail
        .catchError((Object _, StackTrace __) {})
        .then((_) => controller.flushAll());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _queueFlush(widget.controller);
    unawaited(_flushTail);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

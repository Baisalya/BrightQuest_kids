import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/state/game_controller.dart';

class StudySessionTracker extends StatefulWidget {
  const StudySessionTracker({
    required this.controller,
    required this.child,
    this.onLimitReached,
    super.key,
  });

  final GameController controller;
  final Widget child;
  final VoidCallback? onLimitReached;

  @override
  State<StudySessionTracker> createState() => _StudySessionTrackerState();
}

class _StudySessionTrackerState extends State<StudySessionTracker>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _active = true;
  bool _limitReported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_active) {
        widget.controller.addStudySeconds(30);
        if (!_limitReported && widget.controller.dailyTimeLimitReached) {
          _limitReported = true;
          widget.onLimitReached?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

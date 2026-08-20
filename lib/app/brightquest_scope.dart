import 'package:flutter/widgets.dart';

import '../core/state/game_controller.dart';

class BrightQuestScope extends InheritedNotifier<GameController> {
  const BrightQuestScope({
    required GameController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static GameController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BrightQuestScope>();
    assert(scope != null, 'BrightQuestScope not found');
    return scope!.notifier!;
  }

  static GameController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BrightQuestScope>()?.notifier;
  }
}

import 'package:flutter/widgets.dart';

import '../core/content/content_repository.dart';
import '../core/entitlements/entitlement_service.dart';
import '../core/state/game_controller.dart';

class BrightQuestScope extends InheritedNotifier<GameController> {
  BrightQuestScope({
    required GameController controller,
    required this.contentRepository,
    EntitlementService? entitlementService,
    required super.child,
    super.key,
  })  : entitlementService = entitlementService ?? EntitlementService(),
        super(notifier: controller);

  final ContentRepository contentRepository;
  final EntitlementService entitlementService;

  static GameController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BrightQuestScope>();
    assert(scope != null, 'BrightQuestScope not found');
    return scope!.notifier!;
  }

  static GameController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BrightQuestScope>()
        ?.notifier;
  }

  static ContentRepository contentOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BrightQuestScope>();
    assert(scope != null, 'BrightQuestScope not found');
    return scope!.contentRepository;
  }

  static EntitlementService entitlementsOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BrightQuestScope>();
    assert(scope != null, 'BrightQuestScope not found');
    return scope!.entitlementService;
  }
}

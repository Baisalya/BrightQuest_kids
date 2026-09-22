import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 11+12 codifies shipped capability and accessibility boundaries',
      () {
    final capability = File(
      'lib/core/capabilities/learner_capability_boundary.dart',
    ).readAsStringSync();
    final shell = File('lib/app/learner_shell_policy.dart').readAsStringSync();
    final controller =
        File('lib/core/state/game_controller.dart').readAsStringSync();
    final parentLearning = File(
      'lib/features/parent/parent_child_learning_screen.dart',
    ).readAsStringSync();
    final classPacks =
        File('lib/features/parent/class_pack_screen.dart').readAsStringSync();
    final entitlements = File('lib/core/entitlements/entitlement_service.dart')
        .readAsStringSync();
    final adaptive =
        File('lib/widgets/bright_adaptive.dart').readAsStringSync();
    final design =
        File('lib/widgets/bright_design_system.dart').readAsStringSync();
    final widgets = File('lib/widgets/bright_widgets.dart').readAsStringSync();
    final narration = File('lib/widgets/learning_accessibility_widgets.dart')
        .readAsStringSync();

    expect(capability, contains('recognizedLearnerSpan'));
    expect(capability, contains('availableLearnerOptions'));
    expect(capability, contains('supportedSchoolClasses'));
    expect(capability, contains('unavailableSchoolClasses'));
    expect(capability, contains('<int>[1, 2, 6]'));
    expect(capability, contains('<int>[3, 4, 5]'));

    expect(shell, contains('requireSupportedSchoolClass(classNumber)'));
    expect(shell, isNot(contains('_defensiveFallback')));

    expect(
      controller,
      contains('LearnerCapabilityBoundary.isSupportedSchoolClass(value)'),
    );
    expect(
      controller,
      contains('LearnerCapabilityBoundary.isSupportedSchoolClass(classNumber)'),
    );
    expect(
      controller,
      contains('LearnerCapabilityBoundary.isSupportedSchoolClass('),
    );

    expect(
      parentLearning,
      contains('LearnerCapabilityBoundary.supportedSchoolClasses'),
    );
    expect(
      classPacks,
      contains('LearnerCapabilityBoundary.supportedSchoolClasses'),
    );
    expect(
      entitlements,
      contains('requireSupportedSchoolClass(classNumber)'),
    );

    expect(adaptive, contains('minimumTapTarget: 48'));
    expect(adaptive, contains('brightShouldStackForReadability'));
    expect(adaptive, contains('brightReadableMinTileWidth'));
    expect(design, contains('readableMinChildWidth'));
    expect(widgets, contains("label: 'Back'"));
    expect(widgets, contains('width: 48'));
    expect(narration, contains('width: 48, height: 48'));
    expect(narration, contains('minWidth: 48'));
    expect(narration, contains('minHeight: 48'));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Parent Center is a compact hub instead of one long settings page', () {
    final dashboard = File('lib/features/parent/parent_dashboard_screen.dart')
        .readAsStringSync();

    expect(dashboard.split('\n').length, lessThan(500));
    expect(dashboard, contains("title: 'Parent Center'"));
    expect(dashboard, contains('ParentManagementTile('));
    expect(dashboard, contains('ParentChildLearningScreen()'));
    expect(dashboard, contains('ParentHealthyPlayScreen()'));
    expect(dashboard, contains('ParentAudioSettingsScreen()'));
    expect(dashboard, contains('ParentAccessibilityScreen()'));
    expect(dashboard, contains('ParentDataSecurityScreen()'));
    expect(dashboard, contains('ParentAboutAppScreen()'));
    expect(dashboard, isNot(contains('SwitchListTile(')));
    expect(dashboard, isNot(contains('Slider(')));
  });

  test('Parent management responsibilities are separated by concern', () {
    final child = File(
      'lib/features/parent/parent_child_learning_screen.dart',
    ).readAsStringSync();
    final healthy = File(
      'lib/features/parent/parent_healthy_play_screen.dart',
    ).readAsStringSync();
    final audio = File(
      'lib/features/parent/parent_audio_settings_screen.dart',
    ).readAsStringSync();
    final accessibility = File(
      'lib/features/parent/parent_accessibility_screen.dart',
    ).readAsStringSync();
    final security = File(
      'lib/features/parent/parent_data_security_screen.dart',
    ).readAsStringSync();
    final about = File(
      'lib/features/parent/parent_about_app_screen.dart',
    ).readAsStringSync();

    expect(child, contains('Child profiles'));
    expect(child, contains('Learning stage'));
    expect(child, contains('Class adventure progress'));
    expect(child, contains('Learning evidence report'));

    expect(healthy, contains('Daily time limit'));
    expect(healthy, contains('Daily learning goal'));
    expect(healthy, contains('Learning reminders'));

    expect(audio, contains("Key('app_audio_master')"));
    expect(audio, contains("Key('app_bgm_volume')"));
    expect(audio, contains("Key('app_sfx_volume')"));
    expect(audio, contains("Key('app_narrator_volume')"));
    expect(audio, contains('_AudioExpansionCard('));

    expect(accessibility, contains('Dyslexia-friendly spacing'));
    expect(accessibility, contains('Reading focus'));
    expect(accessibility, contains('Captions / visible audio meaning'));

    expect(security, contains('Parent area lock'));
    expect(security, contains('View recovery code'));
    expect(security, contains('Reset active child progress'));

    expect(about, contains('Developer'));
    expect(about, contains('Support independent development'));
    expect(about, contains('Version & updates'));
    expect(about, contains('Rate & Store availability'));
  });

  test('Parent section pages share one consistent management scaffold', () {
    const sectionFiles = <String>[
      'lib/features/parent/parent_child_learning_screen.dart',
      'lib/features/parent/parent_healthy_play_screen.dart',
      'lib/features/parent/parent_audio_settings_screen.dart',
      'lib/features/parent/parent_accessibility_screen.dart',
      'lib/features/parent/parent_data_security_screen.dart',
      'lib/features/parent/parent_about_app_screen.dart',
    ];

    for (final file in sectionFiles) {
      final source = File(file).readAsStringSync();
      expect(source, contains('ParentSectionScaffold('), reason: file);
    }

    final scaffold = File(
      'lib/features/parent/parent_section_scaffold.dart',
    ).readAsStringSync();
    expect(scaffold, contains('BrightHeader(title: title, showBack: true)'));
    expect(scaffold, contains('_SectionContextBanner('));
    expect(scaffold, isNot(contains('fontSize: 23')));
    expect(scaffold, isNot(contains('class _SectionIntro')));
    expect(scaffold, contains('maxWidth'));
    expect(scaffold, contains('ParentManagementTile'));
  });
}

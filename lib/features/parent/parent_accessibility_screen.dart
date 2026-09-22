import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import 'parent_section_scaffold.dart';

class ParentAccessibilityScreen extends StatelessWidget {
  const ParentAccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);

    return ParentSectionScaffold(
      title: 'Reading & accessibility',
      subtitle:
          'Adjust reading presentation and visible narration support for the active child without changing lesson content.',
      icon: Icons.visibility_rounded,
      children: [
        ParentSectionCard(
          title: 'Reading presentation',
          subtitle: 'Visual preferences for easier reading and focus.',
          icon: Icons.chrome_reader_mode_rounded,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            children: [
              SwitchListTile(
                key: const Key('parent_dyslexia_spacing_switch'),
                title: const Text('Dyslexia-friendly spacing'),
                subtitle: const Text(
                  'Adds breathing room between letters and lines. This is a reading preference, not a medical treatment.',
                ),
                value: controller.dyslexiaFriendlySpacing,
                onChanged: controller.setDyslexiaFriendlySpacing,
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const Key('parent_reading_focus_switch'),
                title: const Text('Reading focus'),
                subtitle: const Text(
                  'Highlights the current learning text and narration transcript with extra spacing and contrast.',
                ),
                value: controller.readingFocusEnabled,
                onChanged: controller.setReadingFocusEnabled,
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const Key('parent_captions_switch'),
                title: const Text('Captions / visible audio meaning'),
                subtitle: const Text(
                  'Shows the current narration transcript and choices even when speech is muted or unavailable.',
                ),
                value: controller.captionsEnabled,
                onChanged: controller.setCaptionsEnabled,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const ParentSectionCard(
          title: 'Learning language',
          subtitle:
              'Language packs remain review-gated so questions and answers are never mixed across locales.',
          icon: Icons.language_rounded,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('English (India)'),
            subtitle: Text(
              'Hindi remains unavailable until a reviewed translation pack exists.',
            ),
            trailing: Text(
              'en-IN',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/nursery/nursery_content.dart';
import '../../core/theme/app_theme.dart';

String nurseryDomainTitle(NurseryDomain domain) => switch (domain.id) {
      'alphabet' => 'ABC & Sounds',
      'math' => 'Numbers',
      'knowledge' => 'My World',
      'thinking' => 'Match & Think',
      _ => domain.title,
    };

String nurseryDomainSubtitle(String id) => switch (id) {
      'alphabet' => 'Letters, sounds and picture words',
      'math' => 'Count, match and easy sums',
      'knowledge' => 'Colours, shapes, animals and everyday things',
      'thinking' => 'Match, sort and spot patterns',
      _ => 'Tap a picture to play',
    };

Color nurseryDomainColor(String id) => switch (id) {
      'alphabet' => const Color(0xFF6B63E8),
      'math' => const Color(0xFF2E9EEB),
      'knowledge' => const Color(0xFF46B86B),
      'thinking' => const Color(0xFFF29B32),
      _ => AppTheme.purple,
    };

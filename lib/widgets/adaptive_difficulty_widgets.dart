import 'package:flutter/material.dart';

import '../core/curriculum/curriculum_models.dart';
import '../core/learning/adaptive_difficulty_models.dart';
import '../core/theme/app_theme.dart';

class AdaptiveDifficultyBanner extends StatelessWidget {
  const AdaptiveDifficultyBanner({
    required this.policy,
    this.compact = false,
    super.key,
  });

  final AdaptiveMissionPolicy policy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = switch (policy.levelType) {
      LearningLevelType.practice => const Color(0xFF6D4BE8),
      LearningLevelType.challenge => const Color(0xFF176D7A),
      LearningLevelType.mastery => const Color(0xFF9B5D00),
    };
    final icon = switch (policy.levelType) {
      LearningLevelType.practice => Icons.school_rounded,
      LearningLevelType.challenge => Icons.flag_rounded,
      LearningLevelType.mastery => Icons.workspace_premium_rounded,
    };

    return Semantics(
      container: true,
      label: policy.semanticLabel,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 13,
          vertical: compact ? 8 : 11,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(compact ? 13 : 17),
          border: Border.all(color: accent.withValues(alpha: .22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: compact ? 18 : 22),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        policy.badgeLabel,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 9.5 : 10.5,
                          letterSpacing: .55,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .82),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          policy.readinessLabel,
                          style: const TextStyle(
                            color: AppTheme.inkMuted,
                            fontWeight: FontWeight.w800,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 5),
                    Text(
                      policy.message,
                      style: const TextStyle(
                        color: AppTheme.inkMuted,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

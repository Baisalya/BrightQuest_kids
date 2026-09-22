import 'package:flutter/material.dart';

import '../core/services/app_distribution_info.dart';

/// Shared What's New surface used by the automatic post-update notice and the
/// manual Parent Center action. Only the automatic variant exposes the
/// version-scoped suppression action.
Future<bool?> showBrightQuestWhatsNewDialog(
  BuildContext context, {
  required bool automatic,
}) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: !automatic,
      builder: (dialogContext) => AlertDialog(
        key: const Key('whats_new_dialog'),
        title: Row(
          children: [
            const Icon(Icons.new_releases_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                automatic ? 'BrightQuest Kids updated' : "What's new",
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Version ${AppDistributionInfo.version}',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                if (automatic) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Here are the main changes in this update.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 12),
                for (final item in AppDistributionInfo.currentHighlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Color(0xFF2B7A52),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: automatic
            ? [
                TextButton(
                  key: const Key('whats_new_show_next_launch'),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Show next time'),
                ),
                FilledButton(
                  key: const Key('whats_new_suppress_this_version'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text("Don't show this update again"),
                ),
              ]
            : [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Done'),
                ),
              ],
      ),
    );

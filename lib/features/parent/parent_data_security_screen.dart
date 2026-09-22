import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/brightquest_scope.dart';
import 'parent_section_scaffold.dart';

class ParentDataSecurityScreen extends StatelessWidget {
  const ParentDataSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);

    return ParentSectionScaffold(
      title: 'Data & parent lock',
      subtitle:
          'Manage the parent gate, recovery code and local child-progress reset separately from everyday learning controls.',
      icon: Icons.admin_panel_settings_rounded,
      children: [
        ParentSectionCard(
          title: 'Parent area lock',
          subtitle:
              'Lock the parent area when you are finished so child-facing screens cannot open these controls.',
          icon: Icons.lock_rounded,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const Key('parent_lock_now_button'),
              onPressed: () {
                controller.lockParentArea();
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.lock_rounded),
              label: const Text('Lock parent area now'),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ParentSectionCard(
          title: 'PIN recovery',
          subtitle:
              'The recovery code resets a forgotten parent PIN without deleting child profiles or learning progress.',
          icon: Icons.key_rounded,
          child: ListTile(
            key: const Key('parent_recovery_code_tile'),
            contentPadding: EdgeInsets.zero,
            title: const Text('View recovery code'),
            subtitle: const Text('Keep the code somewhere outside the app.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showRecoveryCode(context),
          ),
        ),
        const SizedBox(height: 14),
        ParentSectionCard(
          title: 'Local learning data',
          subtitle:
              'Reset affects only the active child. Other profiles and the parent PIN are preserved.',
          icon: Icons.storage_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Active child: ${controller.activeProfileAvatar} ${controller.activeProfileName}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('parent_reset_active_child_button'),
                  onPressed: () => _confirmReset(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Reset active child progress'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.offline_bolt_rounded, color: Color(0xFF415F8F)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Offline-first: profiles, progress and parent controls are stored locally. The parent PIN is a child-facing gate and does not replace operating-system security.',
                    style: TextStyle(color: Colors.black54, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showRecoveryCode(BuildContext context) async {
    final controller = BrightQuestScope.of(context);
    final code = controller.parentRecoveryCodeForUnlockedSession;
    if (code == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Parent recovery code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Keep this code outside the app. It resets the parent PIN without deleting child progress.',
            ),
            const SizedBox(height: 14),
            SelectableText(
              code,
              key: const Key('parent_recovery_code'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Recovery code copied.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final controller = BrightQuestScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reset ${controller.activeProfileName} progress?'),
        content: const Text(
          'Coins, stars, XP, answers, mastery, Learning World levels, achievements and cosmetic unlocks for this child will be cleared. Other child profiles, the parent PIN and device-wide settings are preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await controller.resetProgress();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Active child progress reset.')),
        );
      }
    }
  }
}

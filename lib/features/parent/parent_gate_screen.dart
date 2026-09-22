import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/brightquest_scope.dart';
import '../../core/state/game_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/bright_design_system.dart';
import '../../widgets/bright_widgets.dart';
import 'parent_dashboard_screen.dart';

class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({super.key});

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  String? _error;
  String? _recoveryDisclosure;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _submit() {
    final controller = BrightQuestScope.of(context);
    final code = _pinController.text;
    final hadRecoveryCode = controller.hasParentRecoveryCode;

    if (!controller.hasParentPin && code != _confirmPinController.text) {
      setState(() => _error = 'Enter the same 4-digit PIN twice.');
      return;
    }

    final ok = controller.hasParentPin
        ? controller.verifyParentPin(code)
        : controller.setParentPin(code);
    if (!ok) {
      setState(() => _error = 'Enter a valid 4-digit parent PIN.');
      return;
    }

    final shouldShowRecovery =
        !hadRecoveryCode && controller.parentRecoveryCodeForUnlockedSession != null;
    setState(() {
      _error = null;
      _pinController.clear();
      _confirmPinController.clear();
      if (shouldShowRecovery) {
        _recoveryDisclosure = controller.parentRecoveryCodeForUnlockedSession;
      }
    });
  }

  Future<void> _openRecovery() async {
    final recoveryCode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ParentPinRecoverySheet(),
    );
    if (!mounted || recoveryCode == null) return;
    setState(() => _recoveryDisclosure = recoveryCode);
  }

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final recoveryDisclosure = _recoveryDisclosure;
    if (recoveryDisclosure != null) {
      return _RecoveryCodeDisclosure(
        code: recoveryDisclosure,
        onDone: () => setState(() => _recoveryDisclosure = null),
      );
    }
    if (controller.isParentSessionUnlocked) {
      return const ParentDashboardScreen();
    }

    final creatingPin = !controller.hasParentPin;
    return BrightPageBackground(
      primary: const Color(0xFFF3F7FA),
      secondary: const Color(0xFFF7F4ED),
      child: Column(
        children: [
          BrightHeader(
            title: 'Parents',
            showBack: Navigator.of(context).canPop(),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: BrightSurface(
                    padding: const EdgeInsets.all(24),
                    color: const Color(0xFFFCFEFF),
                    borderColor: const Color(0xFFE0E7EF),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF415F8F), Color(0xFF6A7FA3)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          creatingPin
                              ? 'Create a parent PIN'
                              : 'Parent area locked',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.navy,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          creatingPin
                              ? 'Choose and confirm a 4-digit PIN. A recovery code will be created so a forgotten PIN does not erase child progress.'
                              : 'Enter the 4-digit PIN to manage child profiles, learning goals and healthy-play controls.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.inkMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _PinField(
                          key: const Key('parent_pin_input'),
                          controller: _pinController,
                          label: '4-digit PIN',
                          errorText: _error,
                          onSubmitted: (_) => _submit(),
                        ),
                        if (creatingPin) ...[
                          const SizedBox(height: 10),
                          _PinField(
                            key: const Key('parent_pin_confirm_input'),
                            controller: _confirmPinController,
                            label: 'Confirm PIN',
                            onSubmitted: (_) => _submit(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _submit,
                            icon: Icon(
                              creatingPin
                                  ? Icons.shield_rounded
                                  : Icons.lock_open_rounded,
                            ),
                            label: Text(
                              creatingPin
                                  ? 'Create parent PIN'
                                  : 'Unlock parent area',
                            ),
                          ),
                        ),
                        if (!creatingPin) ...[
                          const SizedBox(height: 6),
                          TextButton.icon(
                            key: const Key('parent_forgot_pin_button'),
                            onPressed: _openRecovery,
                            icon: const Icon(Icons.key_rounded),
                            label: const Text('Forgot PIN?'),
                          ),
                          if (controller.parentPinResetPending) ...[
                            const SizedBox(height: 6),
                            Text(
                              'A delayed reset is pending. Entering the correct PIN cancels that reset automatically.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.inkMuted,
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 10),
                        const Text(
                          'Parent mode uses a local child-facing gate. Recovery is designed to preserve learning progress, but this PIN is not a substitute for operating-system security.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.inkMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    this.errorText,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 8,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          counterText: '',
        ),
        onSubmitted: onSubmitted,
      );
}

class _RecoveryCodeDisclosure extends StatelessWidget {
  const _RecoveryCodeDisclosure({required this.code, required this.onDone});

  final String code;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: BrightPageBackground(
          primary: const Color(0xFFF3F7FA),
          secondary: const Color(0xFFF7F4ED),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: BrightSurface(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.key_rounded,
                          size: 54,
                          color: AppTheme.navy,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Save your recovery code',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Keep this code outside the app. It can reset a forgotten parent PIN without deleting child profiles or learning progress.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.inkMuted, height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        SelectableText(
                          code,
                          key: const Key('parent_recovery_code'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: code));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Recovery code copied.')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy recovery code'),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const Key('parent_recovery_saved_button'),
                            onPressed: onDone,
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text('I saved this code'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _ParentPinRecoverySheet extends StatefulWidget {
  const _ParentPinRecoverySheet();

  @override
  State<_ParentPinRecoverySheet> createState() => _ParentPinRecoverySheetState();
}

class _ParentPinRecoverySheetState extends State<_ParentPinRecoverySheet> {
  final TextEditingController _recoveryController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _delayedPinController = TextEditingController();
  final TextEditingController _delayedConfirmPinController =
      TextEditingController();
  String? _error;

  @override
  void dispose() {
    _recoveryController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _delayedPinController.dispose();
    _delayedConfirmPinController.dispose();
    super.dispose();
  }

  void _resetWithRecoveryCode(GameController controller) {
    if (_newPinController.text != _confirmPinController.text) {
      setState(() => _error = 'The new PIN entries do not match.');
      return;
    }
    final ok = controller.resetParentPinWithRecoveryCode(
      recoveryCode: _recoveryController.text,
      newPin: _newPinController.text,
    );
    if (!ok) {
      setState(() => _error = 'Check the recovery code and new 4-digit PIN.');
      return;
    }
    Navigator.of(context).pop(controller.parentRecoveryCodeForUnlockedSession);
  }

  void _completeDelayedReset(GameController controller) {
    if (_delayedPinController.text != _delayedConfirmPinController.text) {
      setState(() => _error = 'The new PIN entries do not match.');
      return;
    }
    final ok = controller.completeDelayedParentPinReset(_delayedPinController.text);
    if (!ok) {
      setState(() => _error = 'The delayed reset is not ready yet.');
      return;
    }
    Navigator.of(context).pop(controller.parentRecoveryCodeForUnlockedSession);
  }

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final readyAt = controller.parentPinResetReadyAt;
    final delayedReady = controller.canCompleteDelayedParentPinReset();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Recover parent access',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Recovery never clears child profiles, scores or learning progress.',
                style: TextStyle(color: AppTheme.inkMuted, height: 1.4),
              ),
              if (controller.hasParentRecoveryCode) ...[
                const SizedBox(height: 18),
                const Text(
                  'Use saved recovery code',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('parent_recovery_input'),
                  controller: _recoveryController,
                  keyboardType: TextInputType.number,
                  maxLength: 14,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                    LengthLimitingTextInputFormatter(14),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Recovery code',
                    hintText: '0000-0000-0000',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                _PinField(
                  key: const Key('parent_recovery_new_pin'),
                  controller: _newPinController,
                  label: 'New 4-digit PIN',
                  errorText: _error,
                ),
                const SizedBox(height: 8),
                _PinField(
                  key: const Key('parent_recovery_confirm_pin'),
                  controller: _confirmPinController,
                  label: 'Confirm new PIN',
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const Key('parent_recovery_reset_button'),
                  onPressed: () => _resetWithRecoveryCode(controller),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset PIN with recovery code'),
                ),
              ],
              const SizedBox(height: 22),
              const Divider(),
              const SizedBox(height: 14),
              const Text(
                'No recovery code?',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Because BrightQuest is offline and has no parent account to verify, an immediate code-free reset would let a child bypass the gate. The safe fallback is a 24-hour delayed reset. Entering the correct PIN during that window cancels the request.',
                style: TextStyle(color: AppTheme.inkMuted, height: 1.4),
              ),
              const SizedBox(height: 12),
              if (!controller.parentPinResetPending)
                OutlinedButton.icon(
                  key: const Key('parent_delayed_reset_request_button'),
                  onPressed: () {
                    controller.requestParentPinReset();
                    setState(() => _error = null);
                  },
                  icon: const Icon(Icons.schedule_rounded),
                  label: const Text('Start 24-hour reset'),
                )
              else if (!delayedReady)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Reset requested. New PIN setup becomes available after ${_formatLocalDateTime(readyAt)}.',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                )
              else ...[
                const Text(
                  'The waiting period is complete. Create a new PIN now.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _PinField(
                  key: const Key('parent_delayed_new_pin'),
                  controller: _delayedPinController,
                  label: 'New 4-digit PIN',
                  errorText: _error,
                ),
                const SizedBox(height: 8),
                _PinField(
                  key: const Key('parent_delayed_confirm_pin'),
                  controller: _delayedConfirmPinController,
                  label: 'Confirm new PIN',
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const Key('parent_delayed_reset_complete_button'),
                  onPressed: () => _completeDelayedReset(controller),
                  icon: const Icon(Icons.lock_reset_rounded),
                  label: const Text('Create new parent PIN'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatLocalDateTime(DateTime? value) {
  if (value == null) return 'the scheduled time';
  final local = value.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day}/${local.month}/${local.year} at $hour12:$minute $period';
}

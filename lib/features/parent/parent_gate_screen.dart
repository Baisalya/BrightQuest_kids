import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/brightquest_scope.dart';
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
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    final controller = BrightQuestScope.of(context);
    final code = _pinController.text;
    final ok = controller.hasParentPin
        ? controller.verifyParentPin(code)
        : controller.setParentPin(code);
    setState(() {
      _error = ok ? null : 'Enter a valid 4-digit parent PIN.';
      if (ok) _pinController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    if (controller.isParentSessionUnlocked)
      return const ParentDashboardScreen();

    return BrightPageBackground(
      primary: const Color(0xFFF3F7FA),
      secondary: const Color(0xFFF7F4ED),
      child: Column(
        children: [
          const BrightHeader(title: 'Parents'),
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
                                colors: [Color(0xFF415F8F), Color(0xFF6A7FA3)]),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded,
                              color: Colors.white, size: 38),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.hasParentPin
                              ? 'Parent area locked'
                              : 'Create a parent PIN',
                          style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.navy),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.hasParentPin
                              ? 'Enter the 4-digit PIN to manage child profiles, learning goals and healthy-play controls.'
                              : 'Set a 4-digit local gate before opening parent controls.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.inkMuted, height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4)
                          ],
                          decoration: InputDecoration(
                              labelText: '4-digit PIN',
                              errorText: _error,
                              counterText: ''),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _submit,
                            icon: Icon(controller.hasParentPin
                                ? Icons.lock_open_rounded
                                : Icons.shield_rounded),
                            label: Text(controller.hasParentPin
                                ? 'Unlock parent area'
                                : 'Create parent PIN'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Parent mode uses a calmer interface. This PIN is a local child-facing gate, not a substitute for operating-system security.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.inkMuted,
                              height: 1.35),
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

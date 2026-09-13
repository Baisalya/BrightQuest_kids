# Phase 11+12 Journey 2x Text Hotfix

The Phase 11+12 accessibility test correctly found a real 2x-text overflow in
`_JourneyChip`.

Root cause:
- the chip was inside a width-bounded `Wrap`;
- its internal `Row(mainAxisSize: min)` contained a non-flexible `Text`;
- at 2x text the label kept its natural width and overflowed the available
  phone-width chip by 135–267 pixels.

Fix:
- keep the icon fixed;
- wrap the label in `Flexible`;
- allow normal multi-line wrapping.

No learning, progress, reward, capability, persistence, or navigation logic is
changed.

## Apply from repo root

```powershell
dart run .\tool\phase11_12_journey_2x_text_hotfix.dart
dart format lib\features\progress\progress_screen.dart
flutter analyze
flutter test test\phase11_12_accessibility_ui_test.dart
```

If that passes, rerun the already-installed semantic gate:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\phase11_12_release_gate_v3.ps1
```

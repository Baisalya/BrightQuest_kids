import 'dart:convert';
import 'dart:io';

class _Patch {
  const _Patch({
    required this.path,
    required this.label,
    required this.oldBase64,
    required this.newBase64,
    required this.expectedCount,
  });

  final String path;
  final String label;
  final String oldBase64;
  final String newBase64;
  final int expectedCount;

  String get oldText => utf8.decode(base64.decode(oldBase64));
  String get newText => utf8.decode(base64.decode(newBase64));
}

String _normalize(String value) =>
    value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

int _count(String source, String pattern) {
  if (pattern.isEmpty) return 0;
  var result = 0;
  var offset = 0;
  while (true) {
    final index = source.indexOf(pattern, offset);
    if (index < 0) return result;
    result += 1;
    offset = index + pattern.length;
  }
}

void main() {
  final root = Directory.current;
  final staged = <String, String>{};

  for (final patch in _patches) {
    final relative = patch.path.replaceAll('/', Platform.pathSeparator);
    final file = File('${root.path}${Platform.pathSeparator}$relative');
    if (!file.existsSync()) {
      stderr.writeln('Missing required file: ${patch.path}');
      exitCode = 2;
      return;
    }

    var text = staged[patch.path] ??
        _normalize(file.readAsStringSync(encoding: utf8));
    final oldText = _normalize(patch.oldText);
    final newText = _normalize(patch.newText);

    final newCount = _count(text, newText);
    if (newCount == patch.expectedCount) {
      stdout.writeln('Already applied: ${patch.label}');
      staged[patch.path] = text;
      continue;
    }
    if (newCount != 0) {
      stderr.writeln(
        "Cannot apply '${patch.label}': partially-applied new block count "
        '$newCount. Expected 0 or ${patch.expectedCount}. No files written.',
      );
      exitCode = 3;
      return;
    }

    final oldCount = _count(text, oldText);
    if (oldCount != patch.expectedCount) {
      stderr.writeln(
        "Cannot apply '${patch.label}': old block count $oldCount, expected "
        '${patch.expectedCount}. No files written.',
      );
      exitCode = 4;
      return;
    }

    for (var i = 0; i < patch.expectedCount; i++) {
      text = text.replaceFirst(oldText, newText);
    }
    staged[patch.path] = text;
    stdout.writeln('Prepared: ${patch.label}');
  }

  // Atomic-at-contract level: no source file is written until every patch above
  // has validated and staged successfully.
  for (final entry in staged.entries) {
    final relative = entry.key.replaceAll('/', Platform.pathSeparator);
    File('${root.path}${Platform.pathSeparator}$relative')
        .writeAsStringSync(entry.value, encoding: utf8, flush: true);
  }

  stdout.writeln('');
  stdout.writeln('Phase 11+12 in-place hardening applied successfully.');
  stdout.writeln('Patched source files: ${staged.length}');
}

const _patches = <_Patch>[
  _Patch(
    path: "lib/core/state/game_controller.dart",
    label: "GameController capability import",
    oldBase64: "aW1wb3J0ICdwYWNrYWdlOmZsdXR0ZXIvZm91bmRhdGlvbi5kYXJ0JzsKCmltcG9ydCAnLi4vY29udGVudC9hY2hpZXZlbWVudF9jYXRhbG9nLmRhcnQnOw==",
    newBase64: "aW1wb3J0ICdwYWNrYWdlOmZsdXR0ZXIvZm91bmRhdGlvbi5kYXJ0JzsKCmltcG9ydCAnLi4vY2FwYWJpbGl0aWVzL2xlYXJuZXJfY2FwYWJpbGl0eV9ib3VuZGFyeS5kYXJ0JzsKaW1wb3J0ICcuLi9jb250ZW50L2FjaGlldmVtZW50X2NhdGFsb2cuZGFydCc7",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/core/state/game_controller.dart",
    label: "Ignore unsupported entitlement cache entries",
    oldBase64: "ICB2b2lkIGNhY2hlRW50aXRsZW1lbnQoQ2xhc3NFbnRpdGxlbWVudCBlbnRpdGxlbWVudCkgewogICAgX3NuYXBzaG90LmVudGl0bGVtZW50Q2FjaGVbZW50aXRsZW1lbnQuY2xhc3NOdW1iZXJdID0gZW50aXRsZW1lbnQ7CiAgICBfY2hhbmdlZCgpOwogIH0=",
    newBase64: "ICB2b2lkIGNhY2hlRW50aXRsZW1lbnQoQ2xhc3NFbnRpdGxlbWVudCBlbnRpdGxlbWVudCkgewogICAgaWYgKCFMZWFybmVyQ2FwYWJpbGl0eUJvdW5kYXJ5LmlzU3VwcG9ydGVkU2Nob29sQ2xhc3MoCiAgICAgIGVudGl0bGVtZW50LmNsYXNzTnVtYmVyLAogICAgKSkgewogICAgICByZXR1cm47CiAgICB9CiAgICBfc25hcHNob3QuZW50aXRsZW1lbnRDYWNoZVtlbnRpdGxlbWVudC5jbGFzc051bWJlcl0gPSBlbnRpdGxlbWVudDsKICAgIF9jaGFuZ2VkKCk7CiAgfQ==",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/core/state/game_controller.dart",
    label: "School class mutation uses capability boundary",
    oldBase64: "ICB2b2lkIHNldENsYXNzKGludCB2YWx1ZSkgewogICAgaWYgKHZhbHVlIDwgMyB8fCB2YWx1ZSA+IDUgfHwgdmFsdWUgPT0gX3Byb2ZpbGUuc2VsZWN0ZWRDbGFzcykgcmV0dXJuOwogICAgX2ZvcmVncm91bmRTZXNzaW9uS2V5cy5yZW1vdmUoYWN0aXZlUHJvZmlsZUlkKTsKICAgIF9wcm9maWxlLnNlbGVjdGVkQ2xhc3MgPSB2YWx1ZTsKICAgIF9jaGFuZ2VkKCk7CiAgfQ==",
    newBase64: "ICB2b2lkIHNldENsYXNzKGludCB2YWx1ZSkgewogICAgaWYgKCFMZWFybmVyQ2FwYWJpbGl0eUJvdW5kYXJ5LmlzU3VwcG9ydGVkU2Nob29sQ2xhc3ModmFsdWUpIHx8CiAgICAgICAgdmFsdWUgPT0gX3Byb2ZpbGUuc2VsZWN0ZWRDbGFzcykgewogICAgICByZXR1cm47CiAgICB9CiAgICBfZm9yZWdyb3VuZFNlc3Npb25LZXlzLnJlbW92ZShhY3RpdmVQcm9maWxlSWQpOwogICAgX3Byb2ZpbGUuc2VsZWN0ZWRDbGFzcyA9IHZhbHVlOwogICAgX2NoYW5nZWQoKTsKICB9",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/core/state/game_controller.dart",
    label: "Profile creation fails closed for unsupported classes",
    oldBase64: "ICAgIGZpbmFsIHRyaW1tZWQgPSBuYW1lLnRyaW0oKTsKICAgIGlmICh0cmltbWVkLmlzRW1wdHkpIHJldHVybiAnJzsKICAgIGZpbmFsIG5vcm1hbGl6ZWRDbGFzcyA9IGNsYXNzTnVtYmVyLmNsYW1wKDMsIDUpLnRvSW50KCk7CiAgICBmaW5hbCBpZCA9ICdjaGlsZC0ke0RhdGVUaW1lLm5vdygpLm1pY3Jvc2Vjb25kc1NpbmNlRXBvY2h9Jzs=",
    newBase64: "ICAgIGZpbmFsIHRyaW1tZWQgPSBuYW1lLnRyaW0oKTsKICAgIGlmICh0cmltbWVkLmlzRW1wdHkgfHwKICAgICAgICAhTGVhcm5lckNhcGFiaWxpdHlCb3VuZGFyeS5pc1N1cHBvcnRlZFNjaG9vbENsYXNzKGNsYXNzTnVtYmVyKSkgewogICAgICByZXR1cm4gJyc7CiAgICB9CiAgICBmaW5hbCBub3JtYWxpemVkQ2xhc3MgPSBjbGFzc051bWJlcjsKICAgIGZpbmFsIGlkID0gJ2NoaWxkLSR7RGF0ZVRpbWUubm93KCkubWljcm9zZWNvbmRzU2luY2VFcG9jaH0nOw==",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/core/state/game_controller.dart",
    label: "Invalid unsupported-class sessions are discarded",
    oldBase64: "ICAgICAgdmFyIGludmFsaWQgPSBzbG90S2V5ICE9IGNoZWNrcG9pbnQuc2xvdEtleSB8fAogICAgICAgICAgIWNoZWNrcG9pbnQuaXNSZXN1bWFibGUgfHwKICAgICAgICAgICFrbm93bkdhbWVJZHMuY29udGFpbnMoY2hlY2twb2ludC5nYW1lSWQpOw==",
    newBase64: "ICAgICAgdmFyIGludmFsaWQgPSBzbG90S2V5ICE9IGNoZWNrcG9pbnQuc2xvdEtleSB8fAogICAgICAgICAgIWNoZWNrcG9pbnQuaXNSZXN1bWFibGUgfHwKICAgICAgICAgICFrbm93bkdhbWVJZHMuY29udGFpbnMoY2hlY2twb2ludC5nYW1lSWQpIHx8CiAgICAgICAgICAhTGVhcm5lckNhcGFiaWxpdHlCb3VuZGFyeS5pc1N1cHBvcnRlZFNjaG9vbENsYXNzKAogICAgICAgICAgICBjaGVja3BvaW50LmNsYXNzTnVtYmVyLAogICAgICAgICAgKTs=",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/features/parent/parent_dashboard_screen.dart",
    label: "Parent dashboard capability import",
    oldBase64: "aW1wb3J0ICcuLi8uLi9hcHAvYnJpZ2h0cXVlc3Rfc2NvcGUuZGFydCc7CmltcG9ydCAnLi4vLi4vY29yZS9jdXJyaWN1bHVtL2N1cnJpY3VsdW1fY2F0YWxvZy5kYXJ0Jzs=",
    newBase64: "aW1wb3J0ICcuLi8uLi9hcHAvYnJpZ2h0cXVlc3Rfc2NvcGUuZGFydCc7CmltcG9ydCAnLi4vLi4vY29yZS9jYXBhYmlsaXRpZXMvbGVhcm5lcl9jYXBhYmlsaXR5X2JvdW5kYXJ5LmRhcnQnOwppbXBvcnQgJy4uLy4uL2NvcmUvY3VycmljdWx1bS9jdXJyaWN1bHVtX2NhdGFsb2cuZGFydCc7",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/features/parent/parent_dashboard_screen.dart",
    label: "Parent class selectors use supported class registry",
    oldBase64: "aXRlbXM6IGNvbnN0IFszLCA0LCA1XQ==",
    newBase64: "aXRlbXM6IExlYXJuZXJDYXBhYmlsaXR5Qm91bmRhcnkuc3VwcG9ydGVkU2Nob29sQ2xhc3Nlcw==",
    expectedCount: 2,
  ),
  _Patch(
    path: "lib/features/parent/class_pack_screen.dart",
    label: "Class pack capability import",
    oldBase64: "aW1wb3J0ICcuLi8uLi9hcHAvYnJpZ2h0cXVlc3Rfc2NvcGUuZGFydCc7CmltcG9ydCAnLi4vLi4vY29yZS9jb250ZW50L2NvbnRlbnRfcmVwb3NpdG9yeS5kYXJ0Jzs=",
    newBase64: "aW1wb3J0ICcuLi8uLi9hcHAvYnJpZ2h0cXVlc3Rfc2NvcGUuZGFydCc7CmltcG9ydCAnLi4vLi4vY29yZS9jYXBhYmlsaXRpZXMvbGVhcm5lcl9jYXBhYmlsaXR5X2JvdW5kYXJ5LmRhcnQnOwppbXBvcnQgJy4uLy4uL2NvcmUvY29udGVudC9jb250ZW50X3JlcG9zaXRvcnkuZGFydCc7",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/features/parent/class_pack_screen.dart",
    label: "Class pack list uses supported class registry",
    oldBase64: "Zm9yIChmaW5hbCBjbGFzc051bWJlciBpbiBjb25zdCA8aW50PlszLCA0LCA1XSk=",
    newBase64: "Zm9yIChmaW5hbCBjbGFzc051bWJlciBpbiBMZWFybmVyQ2FwYWJpbGl0eUJvdW5kYXJ5LnN1cHBvcnRlZFNjaG9vbENsYXNzZXMp",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/core/entitlements/entitlement_service.dart",
    label: "Entitlement capability import",
    oldBase64: "aW1wb3J0ICdlbnRpdGxlbWVudF9tb2RlbHMuZGFydCc7CmltcG9ydCAnc3RvcmVfYmlsbGluZ19nYXRld2F5LmRhcnQnOw==",
    newBase64: "aW1wb3J0ICcuLi9jYXBhYmlsaXRpZXMvbGVhcm5lcl9jYXBhYmlsaXR5X2JvdW5kYXJ5LmRhcnQnOwppbXBvcnQgJ2VudGl0bGVtZW50X21vZGVscy5kYXJ0JzsKaW1wb3J0ICdzdG9yZV9iaWxsaW5nX2dhdGV3YXkuZGFydCc7",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/core/entitlements/entitlement_service.dart",
    label: "Entitlement purchase fails closed outside shipped classes",
    oldBase64: "ICBGdXR1cmU8Q2xhc3NFbnRpdGxlbWVudD4gcHVyY2hhc2VDbGFzcyhpbnQgY2xhc3NOdW1iZXIpIGFzeW5jIHsKICAgIGZpbmFsIHByb2R1Y3RJZCA9IGNsYXNzUGFja1Byb2R1Y3RJZHNbY2xhc3NOdW1iZXJdOwogICAgaWYgKHByb2R1Y3RJZCA9PSBudWxsKSB7CiAgICAgIHRocm93IEFyZ3VtZW50RXJyb3IudmFsdWUoCiAgICAgICAgICBjbGFzc051bWJlciwgJ2NsYXNzTnVtYmVyJywgJ011c3QgYmUgMywgNCBvciA1Jyk7CiAgICB9",
    newBase64: "ICBGdXR1cmU8Q2xhc3NFbnRpdGxlbWVudD4gcHVyY2hhc2VDbGFzcyhpbnQgY2xhc3NOdW1iZXIpIGFzeW5jIHsKICAgIExlYXJuZXJDYXBhYmlsaXR5Qm91bmRhcnkucmVxdWlyZVN1cHBvcnRlZFNjaG9vbENsYXNzKGNsYXNzTnVtYmVyKTsKICAgIGZpbmFsIHByb2R1Y3RJZCA9IGNsYXNzUGFja1Byb2R1Y3RJZHNbY2xhc3NOdW1iZXJdOwogICAgaWYgKHByb2R1Y3RJZCA9PSBudWxsKSB7CiAgICAgIHRocm93IFN0YXRlRXJyb3IoCiAgICAgICAgJ01pc3NpbmcgcHJvZHVjdCBJRCBmb3Igc3VwcG9ydGVkIENsYXNzICRjbGFzc051bWJlci4nLAogICAgICApOwogICAgfQ==",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/core/content/content_repository.dart",
    label: "Content repository capability import",
    oldBase64: "aW1wb3J0ICdkYXJ0OmNvbnZlcnQnOwoKaW1wb3J0ICcuLi9jdXJyaWN1bHVtL2NvbnRlbnRfY29udHJhY3QuZGFydCc7",
    newBase64: "aW1wb3J0ICdkYXJ0OmNvbnZlcnQnOwoKaW1wb3J0ICcuLi9jYXBhYmlsaXRpZXMvbGVhcm5lcl9jYXBhYmlsaXR5X2JvdW5kYXJ5LmRhcnQnOwppbXBvcnQgJy4uL2N1cnJpY3VsdW0vY29udGVudF9jb250cmFjdC5kYXJ0Jzs=",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/core/content/content_repository.dart",
    label: "Development pack lock parser uses capability boundary",
    oldBase64: "LndoZXJlKCh2YWx1ZSkgPT4gdmFsdWUgPj0gMyAmJiB2YWx1ZSA8PSA1KQ==",
    newBase64: "LndoZXJlKExlYXJuZXJDYXBhYmlsaXR5Qm91bmRhcnkuaXNTdXBwb3J0ZWRTY2hvb2xDbGFzcyk=",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/widgets/bright_widgets.dart",
    label: "BrightHeader stacks for large text",
    oldBase64: "ZmluYWwgdXNlU3RhY2tlZEhlYWRlciA9IGhlYWRlckNvbnN0cmFpbnRzLm1heFdpZHRoIDwgNDIwOw==",
    newBase64: "ZmluYWwgdXNlU3RhY2tlZEhlYWRlciA9IGJyaWdodFNob3VsZFN0YWNrRm9yUmVhZGFiaWxpdHkoCiAgICAgICAgICAgICAgICAgICAgY29udGV4dDogY29udGV4dCwKICAgICAgICAgICAgICAgICAgICBhdmFpbGFibGVXaWR0aDogaGVhZGVyQ29uc3RyYWludHMubWF4V2lkdGgsCiAgICAgICAgICAgICAgICAgICAgY29tcGFjdFdpZHRoOiA1MjAsCiAgICAgICAgICAgICAgICAgICk7",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/widgets/bright_widgets.dart",
    label: "Header back action is semantic and 48dp",
    oldBase64: "ICBAb3ZlcnJpZGUKICBXaWRnZXQgYnVpbGQoQnVpbGRDb250ZXh0IGNvbnRleHQpID0+IE1hdGVyaWFsKAogICAgICAgIGNvbG9yOiBDb2xvcnMud2hpdGUud2l0aFZhbHVlcyhhbHBoYTogMC45MiksCiAgICAgICAgYm9yZGVyUmFkaXVzOiBCb3JkZXJSYWRpdXMuY2lyY3VsYXIoMTYpLAogICAgICAgIGNoaWxkOiBJbmtXZWxsKAogICAgICAgICAgYm9yZGVyUmFkaXVzOiBCb3JkZXJSYWRpdXMuY2lyY3VsYXIoMTYpLAogICAgICAgICAgb25UYXA6IG9uVGFwLAogICAgICAgICAgY2hpbGQ6IFNpemVkQm94KAogICAgICAgICAgICAgIHdpZHRoOiA0NCwgaGVpZ2h0OiA0NCwgY2hpbGQ6IEljb24oaWNvbiwgY29sb3I6IEFwcFRoZW1lLm5hdnkpKSwKICAgICAgICApLAogICAgICApOw==",
    newBase64: "ICBAb3ZlcnJpZGUKICBXaWRnZXQgYnVpbGQoQnVpbGRDb250ZXh0IGNvbnRleHQpID0+IFNlbWFudGljcygKICAgICAgICBidXR0b246IHRydWUsCiAgICAgICAgbGFiZWw6ICdCYWNrJywKICAgICAgICBjaGlsZDogVG9vbHRpcCgKICAgICAgICAgIG1lc3NhZ2U6ICdCYWNrJywKICAgICAgICAgIGNoaWxkOiBNYXRlcmlhbCgKICAgICAgICAgICAgY29sb3I6IENvbG9ycy53aGl0ZS53aXRoVmFsdWVzKGFscGhhOiAwLjkyKSwKICAgICAgICAgICAgYm9yZGVyUmFkaXVzOiBCb3JkZXJSYWRpdXMuY2lyY3VsYXIoMTYpLAogICAgICAgICAgICBjaGlsZDogSW5rV2VsbCgKICAgICAgICAgICAgICBib3JkZXJSYWRpdXM6IEJvcmRlclJhZGl1cy5jaXJjdWxhcigxNiksCiAgICAgICAgICAgICAgb25UYXA6IG9uVGFwLAogICAgICAgICAgICAgIGNoaWxkOiBTaXplZEJveCgKICAgICAgICAgICAgICAgIHdpZHRoOiA0OCwKICAgICAgICAgICAgICAgIGhlaWdodDogNDgsCiAgICAgICAgICAgICAgICBjaGlsZDogSWNvbihpY29uLCBjb2xvcjogQXBwVGhlbWUubmF2eSksCiAgICAgICAgICAgICAgKSwKICAgICAgICAgICAgKSwKICAgICAgICAgICksCiAgICAgICAgKSwKICAgICAgKTs=",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/widgets/bright_design_system.dart",
    label: "Adaptive grids reserve readable width at large text",
    oldBase64: "ICAgICAgYnVpbGRlcjogKGNvbnRleHQsIGNvbnN0cmFpbnRzKSB7CiAgICAgICAgZmluYWwgcG9zc2libGUgPQogICAgICAgICAgICAoKGNvbnN0cmFpbnRzLm1heFdpZHRoICsgc3BhY2luZykgLyAobWluQ2hpbGRXaWR0aCArIHNwYWNpbmcpKQogICAgICAgICAgICAgICAgLmZsb29yKCk7CiAgICAgICAgZmluYWwgY29sdW1ucyA9IHBvc3NpYmxlLmNsYW1wKDEsIG1heENvbHVtbnMpLnRvSW50KCk7CiAgICAgICAgZmluYWwgd2lkdGggPQogICAgICAgICAgICAoY29uc3RyYWludHMubWF4V2lkdGggLSBzcGFjaW5nICogKGNvbHVtbnMgLSAxKSkgLyBjb2x1bW5zOw==",
    newBase64: "ICAgICAgYnVpbGRlcjogKGNvbnRleHQsIGNvbnN0cmFpbnRzKSB7CiAgICAgICAgZmluYWwgdGV4dFNjYWxlID0gTWVkaWFRdWVyeS5vZihjb250ZXh0KS50ZXh0U2NhbGVyLnNjYWxlKDEpOwogICAgICAgIGZpbmFsIHJlYWRhYmxlTWluQ2hpbGRXaWR0aCA9IGJyaWdodFJlYWRhYmxlTWluVGlsZVdpZHRoKAogICAgICAgICAgYmFzZU1pbldpZHRoOiBtaW5DaGlsZFdpZHRoLAogICAgICAgICAgdGV4dFNjYWxlOiB0ZXh0U2NhbGUsCiAgICAgICAgKTsKICAgICAgICBmaW5hbCBwb3NzaWJsZSA9ICgoY29uc3RyYWludHMubWF4V2lkdGggKyBzcGFjaW5nKSAvCiAgICAgICAgICAgICAgICAocmVhZGFibGVNaW5DaGlsZFdpZHRoICsgc3BhY2luZykpCiAgICAgICAgICAgIC5mbG9vcigpOwogICAgICAgIGZpbmFsIGNvbHVtbnMgPSBwb3NzaWJsZS5jbGFtcCgxLCBtYXhDb2x1bW5zKS50b0ludCgpOwogICAgICAgIGZpbmFsIHdpZHRoID0KICAgICAgICAgICAgKGNvbnN0cmFpbnRzLm1heFdpZHRoIC0gc3BhY2luZyAqIChjb2x1bW5zIC0gMSkpIC8gY29sdW1uczs=",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/widgets/learning_accessibility_widgets.dart",
    label: "Standard read-aloud target is 48dp",
    oldBase64: "ICAgICAgICAgICAgICAgICAgdmlzdWFsRGVuc2l0eTogVmlzdWFsRGVuc2l0eS5jb21wYWN0LAogICAgICAgICAgICAgICAgKSw=",
    newBase64: "ICAgICAgICAgICAgICAgICAgdmlzdWFsRGVuc2l0eTogVmlzdWFsRGVuc2l0eS5jb21wYWN0LAogICAgICAgICAgICAgICAgICBjb25zdHJhaW50czogY29uc3QgQm94Q29uc3RyYWludHMoCiAgICAgICAgICAgICAgICAgICAgbWluV2lkdGg6IDQ4LAogICAgICAgICAgICAgICAgICAgIG1pbkhlaWdodDogNDgsCiAgICAgICAgICAgICAgICAgICksCiAgICAgICAgICAgICAgICApLA==",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/widgets/learning_accessibility_widgets.dart",
    label: "Standard stop-narration target is 48dp",
    oldBase64: "ICAgICAgICAgICAgICAgICAgICBpY29uOiBjb25zdCBJY29uKEljb25zLnN0b3BfY2lyY2xlX291dGxpbmVkKSwKICAgICAgICAgICAgICAgICAgICB2aXN1YWxEZW5zaXR5OiBWaXN1YWxEZW5zaXR5LmNvbXBhY3QsCiAgICAgICAgICAgICAgICAgICks",
    newBase64: "ICAgICAgICAgICAgICAgICAgICBpY29uOiBjb25zdCBJY29uKEljb25zLnN0b3BfY2lyY2xlX291dGxpbmVkKSwKICAgICAgICAgICAgICAgICAgICB2aXN1YWxEZW5zaXR5OiBWaXN1YWxEZW5zaXR5LmNvbXBhY3QsCiAgICAgICAgICAgICAgICAgICAgY29uc3RyYWludHM6IGNvbnN0IEJveENvbnN0cmFpbnRzKAogICAgICAgICAgICAgICAgICAgICAgbWluV2lkdGg6IDQ4LAogICAgICAgICAgICAgICAgICAgICAgbWluSGVpZ2h0OiA0OCwKICAgICAgICAgICAgICAgICAgICApLAogICAgICAgICAgICAgICAgICApLA==",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/widgets/learning_accessibility_widgets.dart",
    label: "Dense read-aloud target is 48dp",
    oldBase64: "Y29uc3RyYWludHM6IGNvbnN0IEJveENvbnN0cmFpbnRzLnRpZ2h0Rm9yKHdpZHRoOiAzNCwgaGVpZ2h0OiAzNCks",
    newBase64: "Y29uc3RyYWludHM6IGNvbnN0IEJveENvbnN0cmFpbnRzLnRpZ2h0Rm9yKHdpZHRoOiA0OCwgaGVpZ2h0OiA0OCks",
    expectedCount: 1,
  ),
  _Patch(
    path: "lib/widgets/learning_accessibility_widgets.dart",
    label: "Dense stop-narration target is 48dp",
    oldBase64: "ICAgICAgICAgICAgICAgIGNvbnN0cmFpbnRzOgogICAgICAgICAgICAgICAgICAgIGNvbnN0IEJveENvbnN0cmFpbnRzLnRpZ2h0Rm9yKHdpZHRoOiAzNCwgaGVpZ2h0OiAzNCks",
    newBase64: "ICAgICAgICAgICAgICAgIGNvbnN0cmFpbnRzOgogICAgICAgICAgICAgICAgICAgIGNvbnN0IEJveENvbnN0cmFpbnRzLnRpZ2h0Rm9yKHdpZHRoOiA0OCwgaGVpZ2h0OiA0OCks",
    expectedCount: 1,
  ),
];

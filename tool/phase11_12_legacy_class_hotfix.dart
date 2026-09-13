import 'dart:convert';
import 'dart:io';

class _Patch {
  const _Patch({
    required this.path,
    required this.label,
    required this.oldBase64,
    required this.newBase64,
  });

  final String path;
  final String label;
  final String oldBase64;
  final String newBase64;

  String get oldText => utf8.decode(base64.decode(oldBase64));
  String get newText => utf8.decode(base64.decode(newBase64));
}

String _normalize(String value) =>
    value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

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

    if (text.contains(newText)) {
      stdout.writeln('Already applied: ${patch.label}');
      staged[patch.path] = text;
      continue;
    }

    final first = text.indexOf(oldText);
    final second =
        first < 0 ? -1 : text.indexOf(oldText, first + oldText.length);
    if (first < 0 || second >= 0) {
      stderr.writeln(
        "Cannot apply '${patch.label}': expected old block exactly once. "
        'No production files were written.',
      );
      exitCode = 3;
      return;
    }

    text = text.replaceFirst(oldText, newText);
    staged[patch.path] = text;
    stdout.writeln('Prepared: ${patch.label}');
  }

  for (final entry in staged.entries) {
    final relative = entry.key.replaceAll('/', Platform.pathSeparator);
    File('${root.path}${Platform.pathSeparator}$relative')
        .writeAsStringSync(entry.value, encoding: utf8, flush: true);
  }

  stdout.writeln('');
  stdout.writeln('Phase 11+12 legacy-class migration hotfix applied.');
  stdout.writeln('Persisted unsupported classes now fall back to Class 4.');
}

const _patches = <_Patch>[
  _Patch(
    path: "lib/core/models/progress_models.dart",
    label: "Capability boundary import",
    oldBase64: "aW1wb3J0ICcuLi9lbnRpdGxlbWVudHMvZW50aXRsZW1lbnRfbW9kZWxzLmRhcnQnOw==",
    newBase64: "aW1wb3J0ICcuLi9jYXBhYmlsaXRpZXMvbGVhcm5lcl9jYXBhYmlsaXR5X2JvdW5kYXJ5LmRhcnQnOwppbXBvcnQgJy4uL2VudGl0bGVtZW50cy9lbnRpdGxlbWVudF9tb2RlbHMuZGFydCc7",
  ),
  _Patch(
    path: "lib/core/models/progress_models.dart",
    label: "Normalize persisted unsupported school class",
    oldBase64: "ICAgICAgc2VsZWN0ZWRDbGFzczogKGpzb25bJ3NlbGVjdGVkQ2xhc3MnXSBhcyBudW0/KT8udG9JbnQoKSA/PyA0LA==",
    newBase64: "ICAgICAgc2VsZWN0ZWRDbGFzczogX3N1cHBvcnRlZENsYXNzRnJvbVN0b3JhZ2UoanNvblsnc2VsZWN0ZWRDbGFzcyddKSw=",
  ),
  _Patch(
    path: "lib/core/models/progress_models.dart",
    label: "Persisted class normalization helper",
    oldBase64: "ICBmYWN0b3J5IENoaWxkUHJvZmlsZVNuYXBzaG90LmZyb21MZWdhY3lKc29uKE1hcDxTdHJpbmcsIE9iamVjdD8+IGpzb24pIHsKICAgIGZpbmFsIGNvcHkgPSBNYXA8U3RyaW5nLCBPYmplY3Q/Pi5mcm9tKGpzb24pCiAgICAgIC4uWydpZCddID0gJ2NoaWxkLTEnCiAgICAgIC4uWyduYW1lJ10gPSAnRXhwbG9yZXInCiAgICAgIC4uWydhdmF0YXJFbW9qaSddID0gJ/Cfp5InOwogICAgcmV0dXJuIENoaWxkUHJvZmlsZVNuYXBzaG90LmZyb21Kc29uKGNvcHkpOwogIH0KCiAgc3RhdGljIFNldDxTdHJpbmc+IF9zdHJpbmdTZXQoT2JqZWN0PyB2YWx1ZSkgew==",
    newBase64: "ICBmYWN0b3J5IENoaWxkUHJvZmlsZVNuYXBzaG90LmZyb21MZWdhY3lKc29uKE1hcDxTdHJpbmcsIE9iamVjdD8+IGpzb24pIHsKICAgIGZpbmFsIGNvcHkgPSBNYXA8U3RyaW5nLCBPYmplY3Q/Pi5mcm9tKGpzb24pCiAgICAgIC4uWydpZCddID0gJ2NoaWxkLTEnCiAgICAgIC4uWyduYW1lJ10gPSAnRXhwbG9yZXInCiAgICAgIC4uWydhdmF0YXJFbW9qaSddID0gJ/Cfp5InOwogICAgcmV0dXJuIENoaWxkUHJvZmlsZVNuYXBzaG90LmZyb21Kc29uKGNvcHkpOwogIH0KCiAgc3RhdGljIGludCBfc3VwcG9ydGVkQ2xhc3NGcm9tU3RvcmFnZShPYmplY3Q/IHZhbHVlKSB7CiAgICBmaW5hbCBjbGFzc051bWJlciA9ICh2YWx1ZSBhcyBudW0/KT8udG9JbnQoKSA/PyA0OwogICAgcmV0dXJuIExlYXJuZXJDYXBhYmlsaXR5Qm91bmRhcnkuaXNTdXBwb3J0ZWRTY2hvb2xDbGFzcyhjbGFzc051bWJlcikKICAgICAgICA/IGNsYXNzTnVtYmVyCiAgICAgICAgOiA0OwogIH0KCiAgc3RhdGljIFNldDxTdHJpbmc+IF9zdHJpbmdTZXQoT2JqZWN0PyB2YWx1ZSkgew==",
  ),
];

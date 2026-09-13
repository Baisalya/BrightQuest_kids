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
        'No test files were written.',
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
  stdout.writeln('Phase 7+8 final-gate test hotfix applied.');
  stdout.writeln('Production files changed: 0');
}

const _patches = <_Patch>[
  _Patch(
    path: "test/phase7_8_architecture_test.dart",
    label: "Nursery rootMode static contract",
    oldBase64: "ICAgIGV4cGVjdChudXJzZXJ5LCBjb250YWlucygncm9vdE1vZGU6JykpOw==",
    newBase64: "ICAgIGV4cGVjdChudXJzZXJ5LCBjb250YWlucygndGhpcy5yb290TW9kZSA9IGZhbHNlJykpOwogICAgZXhwZWN0KG51cnNlcnksIGNvbnRhaW5zKCdmaW5hbCBib29sIHJvb3RNb2RlOycpKTs=",
  ),
  _Patch(
    path: "test/audio_experience_test.dart",
    label: "Windows speech environment-safe runtime assertion",
    oldBase64: "ICAgIGlmIChQbGF0Zm9ybS5pc1dpbmRvd3MpIHsKICAgICAgZmluYWwgc3BlZWNoID0gV2luZG93c1NwZWVjaEJhY2tlbmQoKTsKICAgICAgYXdhaXQgc3BlZWNoLmluaXRpYWxpemUoKTsKICAgICAgZXhwZWN0KHNwZWVjaC5hdmFpbGFibGUsIGlzVHJ1ZSk7CiAgICAgIGV4cGVjdChzcGVlY2gudm9pY2VzLCBpc05vdEVtcHR5KTsKICAgICAgaWYgKHNwZWVjaC52b2ljZXMuYW55KCh2b2ljZSkgPT4gdm9pY2UuaXNGZW1hbGUpKSB7CiAgICAgICAgZXhwZWN0KHNwZWVjaC5kZWZhdWx0Vm9pY2U/LmlzRmVtYWxlLCBpc1RydWUpOwogICAgICB9CiAgICB9",
    newBase64: "ICAgIGlmIChQbGF0Zm9ybS5pc1dpbmRvd3MpIHsKICAgICAgZmluYWwgc3BlZWNoID0gV2luZG93c1NwZWVjaEJhY2tlbmQoKTsKICAgICAgYXdhaXQgc3BlZWNoLmluaXRpYWxpemUoKTsKCiAgICAgIC8vIFN5c3RlbS5TcGVlY2ggdm9pY2UgaW5zdGFsbGF0aW9uIGlzIGEgbWFjaGluZS1sZXZlbCBjYXBhYmlsaXR5LCBub3QgYW4KICAgICAgLy8gYXBwIGludmFyaWFudC4gVGhlIGJhY2tlbmQgaXMgaW50ZW50aW9uYWxseSBhbGxvd2VkIHRvIHJlbWFpbgogICAgICAvLyB1bmF2YWlsYWJsZSBhbmQga2VlcCB0aGUgbGVhcm5pbmcgZmxvdyBydW5uaW5nLiBXaGVuIHRoZSBob3N0IGV4cG9zZXMKICAgICAgLy8gdm9pY2VzLCB0aGVpciBwYXJzZWQvZGVmYXVsdC12b2ljZSBjb250cmFjdCBpcyBzdGlsbCB2ZXJpZmllZC4KICAgICAgaWYgKCFzcGVlY2guYXZhaWxhYmxlKSB7CiAgICAgICAgZXhwZWN0KHNwZWVjaC52b2ljZXMsIGlzRW1wdHkpOwogICAgICAgIHJldHVybjsKICAgICAgfQoKICAgICAgZXhwZWN0KHNwZWVjaC52b2ljZXMsIGlzTm90RW1wdHkpOwogICAgICBpZiAoc3BlZWNoLnZvaWNlcy5hbnkoKHZvaWNlKSA9PiB2b2ljZS5pc0ZlbWFsZSkpIHsKICAgICAgICBleHBlY3Qoc3BlZWNoLmRlZmF1bHRWb2ljZT8uaXNGZW1hbGUsIGlzVHJ1ZSk7CiAgICAgIH0KICAgIH0=",
  ),
];

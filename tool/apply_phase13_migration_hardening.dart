import 'dart:convert';
import 'dart:io';

String _normalize(String value) =>
    value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

String _decode(String value) => utf8.decode(base64.decode(value));

void main() {
  final file = File(
    'lib${Platform.pathSeparator}core${Platform.pathSeparator}models'
    '${Platform.pathSeparator}progress_models.dart',
  );
  if (!file.existsSync()) {
    stderr.writeln('Missing lib/core/models/progress_models.dart');
    exitCode = 2;
    return;
  }

  var text = _normalize(file.readAsStringSync(encoding: utf8));
  var changed = false;

  if (text.contains('profile.id = profileId;') &&
      text.contains('profiles[profileId] = profile;')) {
    stdout.writeln('Already applied: profile identity normalization');
  } else {
    final oldText = _decode(
        "ICAgICAgICAgIGZpbmFsIHByb2ZpbGUgPSBDaGlsZFByb2ZpbGVTbmFwc2hvdC5mcm9tSnNvbigKICAgICAgICAgICAgTWFwPFN0cmluZywgT2JqZWN0Pz4uZnJvbShlbnRyeS52YWx1ZSBhcyBNYXApLAogICAgICAgICAgKTsKICAgICAgICAgIHByb2ZpbGVzW2VudHJ5LmtleSBhcyBTdHJpbmddID0gcHJvZmlsZTs=");
    final newText = _decode(
        "ICAgICAgICAgIGZpbmFsIHByb2ZpbGUgPSBDaGlsZFByb2ZpbGVTbmFwc2hvdC5mcm9tSnNvbigKICAgICAgICAgICAgTWFwPFN0cmluZywgT2JqZWN0Pz4uZnJvbShlbnRyeS52YWx1ZSBhcyBNYXApLAogICAgICAgICAgKTsKICAgICAgICAgIGZpbmFsIHByb2ZpbGVJZCA9IGVudHJ5LmtleSBhcyBTdHJpbmc7CiAgICAgICAgICBwcm9maWxlLmlkID0gcHJvZmlsZUlkOwogICAgICAgICAgcHJvZmlsZXNbcHJvZmlsZUlkXSA9IHByb2ZpbGU7");
    final first = text.indexOf(oldText);
    final second =
        first < 0 ? -1 : text.indexOf(oldText, first + oldText.length);
    if (first < 0 || second >= 0) {
      stderr.writeln(
        'Cannot apply profile identity normalization exactly once. '
        'No production file was written.',
      );
      exitCode = 3;
      return;
    }
    text = text.replaceFirst(oldText, newText);
    changed = true;
    stdout.writeln('Prepared: profile identity normalization');
  }

  if (text.contains('entitlement.classNumber == classNumber') &&
      text.contains(
        'LearnerCapabilityBoundary.isSupportedSchoolClass(classNumber)',
      )) {
    stdout.writeln('Already applied: entitlement cache identity validation');
  } else {
    final oldText = _decode(
        "ICAgICAgICAgIGlmIChjbGFzc051bWJlciAhPSBudWxsICYmIGVudHJ5LnZhbHVlIGlzIE1hcCkgewogICAgICAgICAgICBlbnRpdGxlbWVudHNbY2xhc3NOdW1iZXJdID0gQ2xhc3NFbnRpdGxlbWVudC5mcm9tSnNvbigKICAgICAgICAgICAgICBNYXA8U3RyaW5nLCBPYmplY3Q/Pi5mcm9tKGVudHJ5LnZhbHVlIGFzIE1hcCksCiAgICAgICAgICAgICk7CiAgICAgICAgICB9");
    final newText = _decode(
        "ICAgICAgICAgIGlmIChjbGFzc051bWJlciAhPSBudWxsICYmCiAgICAgICAgICAgICAgTGVhcm5lckNhcGFiaWxpdHlCb3VuZGFyeS5pc1N1cHBvcnRlZFNjaG9vbENsYXNzKGNsYXNzTnVtYmVyKSAmJgogICAgICAgICAgICAgIGVudHJ5LnZhbHVlIGlzIE1hcCkgewogICAgICAgICAgICBmaW5hbCBlbnRpdGxlbWVudCA9IENsYXNzRW50aXRsZW1lbnQuZnJvbUpzb24oCiAgICAgICAgICAgICAgTWFwPFN0cmluZywgT2JqZWN0Pz4uZnJvbShlbnRyeS52YWx1ZSBhcyBNYXApLAogICAgICAgICAgICApOwogICAgICAgICAgICBpZiAoZW50aXRsZW1lbnQuY2xhc3NOdW1iZXIgPT0gY2xhc3NOdW1iZXIpIHsKICAgICAgICAgICAgICBlbnRpdGxlbWVudHNbY2xhc3NOdW1iZXJdID0gZW50aXRsZW1lbnQ7CiAgICAgICAgICAgIH0KICAgICAgICAgIH0=");
    final first = text.indexOf(oldText);
    final second =
        first < 0 ? -1 : text.indexOf(oldText, first + oldText.length);
    if (first < 0 || second >= 0) {
      stderr.writeln(
        'Cannot apply entitlement cache identity validation exactly once. '
        'No production file was written.',
      );
      exitCode = 4;
      return;
    }
    text = text.replaceFirst(oldText, newText);
    changed = true;
    stdout.writeln('Prepared: entitlement cache identity validation');
  }

  if (changed) {
    file.writeAsStringSync(text, encoding: utf8, flush: true);
  }

  stdout.writeln('');
  stdout.writeln('Phase 13 migration hardening ready.');
  stdout.writeln('Production file changed this run: $changed');
}

import 'dart:convert';
import 'dart:io';

String _normalize(String value) =>
    value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

void main() {
  final file = File(
    'lib${Platform.pathSeparator}features${Platform.pathSeparator}'
    'progress${Platform.pathSeparator}progress_screen.dart',
  );

  if (!file.existsSync()) {
    stderr.writeln('Missing progress_screen.dart');
    exitCode = 2;
    return;
  }

  var text = _normalize(file.readAsStringSync(encoding: utf8));
  final oldText = utf8.decode(base64.decode("ICAgICAgICBjaGlsZDogUm93KAogICAgICAgICAgbWFpbkF4aXNTaXplOiBNYWluQXhpc1NpemUubWluLAogICAgICAgICAgY2hpbGRyZW46IFsKICAgICAgICAgICAgSWNvbihpY29uLCBjb2xvcjogY29uc3QgQ29sb3IoMHhGRkZGRTM2RiksIHNpemU6IDE4KSwKICAgICAgICAgICAgY29uc3QgU2l6ZWRCb3god2lkdGg6IDUpLAogICAgICAgICAgICBUZXh0KAogICAgICAgICAgICAgIGxhYmVsLAogICAgICAgICAgICAgIHN0eWxlOiBjb25zdCBUZXh0U3R5bGUoCiAgICAgICAgICAgICAgICBjb2xvcjogQ29sb3JzLndoaXRlLAogICAgICAgICAgICAgICAgZm9udFdlaWdodDogRm9udFdlaWdodC53OTAwLAogICAgICAgICAgICAgICAgZm9udFNpemU6IDExLAogICAgICAgICAgICAgICksCiAgICAgICAgICAgICksCiAgICAgICAgICBdLAogICAgICAgICks"));
  final newText = utf8.decode(base64.decode("ICAgICAgICBjaGlsZDogUm93KAogICAgICAgICAgbWFpbkF4aXNTaXplOiBNYWluQXhpc1NpemUubWluLAogICAgICAgICAgY2hpbGRyZW46IFsKICAgICAgICAgICAgSWNvbihpY29uLCBjb2xvcjogY29uc3QgQ29sb3IoMHhGRkZGRTM2RiksIHNpemU6IDE4KSwKICAgICAgICAgICAgY29uc3QgU2l6ZWRCb3god2lkdGg6IDUpLAogICAgICAgICAgICBGbGV4aWJsZSgKICAgICAgICAgICAgICBjaGlsZDogVGV4dCgKICAgICAgICAgICAgICAgIGxhYmVsLAogICAgICAgICAgICAgICAgc29mdFdyYXA6IHRydWUsCiAgICAgICAgICAgICAgICBzdHlsZTogY29uc3QgVGV4dFN0eWxlKAogICAgICAgICAgICAgICAgICBjb2xvcjogQ29sb3JzLndoaXRlLAogICAgICAgICAgICAgICAgICBmb250V2VpZ2h0OiBGb250V2VpZ2h0Lnc5MDAsCiAgICAgICAgICAgICAgICAgIGZvbnRTaXplOiAxMSwKICAgICAgICAgICAgICAgICksCiAgICAgICAgICAgICAgKSwKICAgICAgICAgICAgKSwKICAgICAgICAgIF0sCiAgICAgICAgKSw="));

  if (text.contains(newText)) {
    stdout.writeln('Already applied: Journey chip 2x-text wrapping');
    return;
  }

  final first = text.indexOf(oldText);
  final second = first < 0 ? -1 : text.indexOf(oldText, first + oldText.length);
  if (first < 0 || second >= 0) {
    stderr.writeln(
      'Cannot apply Journey 2x-text hotfix: expected source block exactly once. '
      'No production file was written.',
    );
    exitCode = 3;
    return;
  }

  text = text.replaceFirst(oldText, newText);
  file.writeAsStringSync(text, encoding: utf8, flush: true);

  stdout.writeln('Applied: Journey chip 2x-text wrapping');
  stdout.writeln('Production files changed: 1');
}

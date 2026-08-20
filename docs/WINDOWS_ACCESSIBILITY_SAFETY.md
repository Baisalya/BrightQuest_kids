# Windows Accessibility and Narration Safety

BrightQuest currently preserves the crash-isolated Windows narration implementation and does not restore the previously unsafe Flutter TTS DLL path. Windows Flutter semantics remain isolated/disabled where the project already uses that workaround.

Do not restore `flutter_tts_plugin.dll`, generated Flutter TTS registration or Windows semantics merely to satisfy an automated accessibility checklist. Restoration requires native crash reproduction testing, repeated narration/resize/sleep-resume soak and confirmation that the relevant Flutter engine/plugin combination is stable.

Meanwhile, learning meaning must remain available visually: questions, choices, hints, explanations, correct/wrong feedback and meaningful audio equivalents are represented as text. Android semantics/keyboard/focus improvements can continue independently from the Windows native crash boundary.

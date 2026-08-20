# Windows Accessibility and Narration Safety

BrightQuest preserves the crash-isolated Windows narration implementation and does not restore the previously unsafe Flutter TTS DLL path. The main shell now mounts only its active page instead of keeping five dense pages in an eager `IndexedStack`, reducing accessibility-tree churn at the source.

Do not restore `flutter_tts_plugin.dll`, generated Flutter TTS registration or Windows semantics merely to satisfy an automated accessibility checklist. Restoration requires native crash reproduction testing, repeated narration/resize/sleep-resume soak and confirmation that the relevant Flutter engine/plugin combination is stable.

Windows Flutter semantics remain disabled in normal builds until real-device qualification is complete. A dedicated canary is available for that qualification run:

```powershell
flutter run -d windows --dart-define=BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY=true
```

Run the canary with Narrator enabled. Exercise every main destination and game, repeatedly resize/minimise/restore the window, trigger narration and correct/wrong feedback, then sleep/resume Windows. Record OS build, Flutter version, device, duration and any native crash. Do not ship the canary flag after a single clean run; require the matrix in `docs/RELEASE_QA_CHECKLIST.md` to pass.

Meanwhile, learning meaning remains available visually: questions, choices, hints, explanations, correct/wrong feedback and meaningful audio equivalents are represented as text. Android semantics/keyboard/focus improvements can continue independently from the Windows native crash boundary.

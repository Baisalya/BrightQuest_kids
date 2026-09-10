# Step 23 / Nursery Step 9 — Kid-friendly Motion, Feedback & Celebration Polish QA

## Scope

This step standardizes Nursery motion and result feedback without changing learning content, answer evaluation, activity IDs, evidence/mastery behavior, save data, review scheduling, or the Step 7 Study → Guided Play → Independent Game sequence.

The product rules are intentionally conservative:

- motion is finite and one-shot;
- no repeating/reversing animation loops or periodic timers;
- app reduced-motion and operating-system `disableAnimations` are both respected;
- Windows avoids geometry-changing Nursery reactions and uses opacity-only polish where motion remains enabled;
- success, retry, hint, selection, and entrance reactions stay short and calm;
- semantics/live-region feedback remains present when visual motion is disabled.

## Motion architecture

`lib/features/nursery/nursery_motion.dart` is the shared presentation boundary.

- `NurseryMotionPolicy` resolves app/OS motion preferences and Windows geometry safety.
- `NurseryMotionReaction` plays one finite cue when a result/selection trigger changes.
- `NurseryMotionReveal` provides one-shot entrance polish with an immediate static reduced-motion path.
- all defined motion durations are at most 560 ms by default; custom Nursery reveal durations remain bounded below one second.

No progress, persistence, content-generation, or evaluator dependency is allowed in the motion boundary.

## Feedback polish

- Correct answers receive a finite success reaction plus the existing visual cheer.
- Incorrect answers use a small finite retry reaction rather than an aggressive failure animation.
- Hints get a small one-shot emphasis cue.
- Match/sort selection cards react when selected and when a placement becomes complete.
- Tracing progress gets a small one-shot cue as each guide dot is reached, with a finite success cue at completion.
- Answer-card and scene-banner entrance motion now share the central policy.
- Memory Game no longer hardcodes `reducedMotion: true`; it follows the same resolved accessibility preference as normal lessons and uses the same feedback/cheer components.

## Accessibility and Windows safety

The lesson screen combines the app preference with `MediaQuery.disableAnimations` before passing motion state into presentation stages. Motion widgets independently guard the OS preference as a second safety boundary.

On Windows, Nursery motion keeps semantics geometry stable by suppressing transform-based reactions; opacity-only finite feedback is used instead. This follows the existing Windows accessibility isolation strategy without restoring Windows TTS/semantics plugins.

## Baseline

Step 9 starts from the user-qualified Step 8 QAFix baseline (`+412 ~2: All other tests passed`).

## Static release checks

- No `.repeat(` animation calls in the Nursery motion boundary.
- No `Timer.periodic` in the Nursery motion boundary.
- No new package dependency.
- Nursery content pack/schema unchanged from the QA-passed Step 8 baseline.
- Nursery response evaluator, progress engine, learning models and practice generator unchanged.
- No activity/skill/save/mastery migration.
- New motion/feedback presentation remains local to Nursery UI.
- Cumulative Step 9 modified/new file count: 16.

## Flutter qualification

The archive preparation environment does not contain Flutter/Dart tooling. Run locally:

```powershell
flutter analyze
flutter test test/nursery_motion_feedback_polish_test.dart
flutter test test/nursery_asset_reaction_test.dart
flutter test test/nursery_lesson_architecture_test.dart
flutter test test/nursery_picture_first_games_test.dart
flutter test test/nursery_study_guided_independent_flow_test.dart
flutter test test/nursery_simple_game_flow_test.dart
flutter test test/nursery_layout_test.dart
flutter test
```

# Nursery Upgrade — Interaction, Animation and Audio Plan

## Child journey

Nursery appears on Home as a dedicated “Nursery Learning Garden” entry rather than changing the active Class 3/4/5 selector. Opening it shows large domain cards and a simple skill path with visible progress states. A skill launch follows one reusable flow:

1. **Objective** — one sentence plus friendly visual; optional auto narration.
2. **Animated explanation** — finite purposeful movement (for example objects joining a group or a letter appearing) with visible text.
3. **Worked visual example** — answer is shown and explained; no mastery evidence recorded.
4. **Guided try** — child answers; hints allowed; evidence recorded as guided only.
5. **Independent A** — scorable, no automatic hint before first response.
6. **Independent B** — different authored or deterministic variant.
7. **Transfer** — different wording/object/context; no mastery hint.
8. **Completion** — progress explains “practising”, “remember later” or equivalent; it never declares secure mastery before delayed review.
9. **Delayed review** — due skill appears in a review section after the configured interval; successful independent review advances retention state.

A wrong answer keeps the child in the activity, gives a gentle explanation/hint, and allows another attempt. Retries can earn learning progress but do not count as first-try independent mastery evidence.

## Interaction patterns

| Pattern | Touch | Mouse | Keyboard | Feedback | Accessibility |
| --- | --- | --- | --- | --- | --- |
| Large choice | tap 56px+ target | click/hover | Tab + Enter/Space | selected state + text + SFX/narration | `Semantics` label includes choice text; no colour-only status |
| Pair match | tap left then right | click pair | focus buttons in reading order | completed pair locks and shows text check | full pair labels; unmatched state not colour-only |
| Sort buckets | tap item then bucket | click item/bucket | focus item then destination button | placed item shown under bucket | button alternative means no drag-only requirement |
| Trace path | drag finger through broad checkpoints | hold/click-drag pointer | not required for mastery; recognition alternative remains keyboard operable | checkpoint glow + completion message | explicit label “guided tracing practice”; no handwriting correctness claim |
| Memory/observation | tap “I’m ready” after study | click | Enter/Space | study→answer transition | static content available long enough; no forced timer |
| Read aloud | tap speaker | click | focus + Enter | existing speech with BGM ducking | visible text always present |

## Animation inventory

| Moment | Learning purpose | Motion | Duration | Reduced-motion behaviour | Performance budget |
| --- | --- | --- | --- | --- | --- |
| Letter reveal | focus attention on target symbol | one fade/scale entrance | 180–280 ms | instant static letter | finite implicit animation only |
| Object counting | support one-to-one/grouping | objects appear/move once in sequence/group | ≤600 ms total | all objects shown statically | no repeating controller/ticker |
| Addition | show two groups combining | left/right groups translate to shared group once | ≤650 ms | static `group + group = total` | finite `TweenAnimationBuilder`/implicit motion |
| Matching success | show relation formed | short scale/check transition | 160–220 ms | static check and text | no particles loop |
| Tracing guidance | show next checkpoint | next-point pulse/guide transition | ≤250 ms per child action | static numbered/checkpoint guide | motion only after input; no scheduled loop |
| Correct answer | reinforce success | one finite card/check transition | ≤250 ms | static success card | never blocks next button |
| Hint | draw attention to useful feature | one finite emphasis | ≤220 ms | text emphasis only | no flashing |

Animation requirements are implemented through finite Flutter implicit/tween animations only. No `AnimationController.repeat`, periodic timer or infinite scheduled frame loop is permitted in Nursery.

## Character and object states

Nursery uses the existing BrightQuest visual language and lion guide but keeps the screen less dense than Classes 3–5. Visual objects are represented by large shapes, letters, numerals, colour swatches and familiar emoji/pictograms with adjacent text labels when meaning matters.

Interaction states are explicit: `ready`, `selected`, `correct`, `tryAgain`, `hintShown`, `completed`. Correct/wrong meaning is always communicated by icon/text in addition to colour/audio.

## Smart-read and voice behaviour

Nursery reuses `BrightAudioService` without introducing another TTS package.

- Auto narration speaks the objective/instruction when each lesson stage first appears if the existing preference is enabled.
- “Read aloud” always remains available and calls `speakPrompt`, including readable choices when applicable.
- Letter examples use child-safe narration strings already stored in content; no runtime phoneme synthesis API is assumed.
- Correct responses call `speakCorrect` with answer/detail.
- Wrong responses call `speakWrong` with child-visible guidance and do not automatically reveal the answer on the first incorrect attempt.
- Installed voice discovery/selection, female-first preference, voice rate/volume and Android `flutter_tts` behavior remain unchanged.
- Windows continues to use the existing hidden child-process `System.Speech` backend. Nursery does not restore `flutter_tts_plugin.dll`.

## Music, speech and sound controls

The existing controls remain authoritative:

- BGM: `musicEnabled` / `musicVolume`;
- effects: `sfxEnabled` / `sfxVolume`;
- narration: `voiceEnabled` / `voiceVolume` / selected installed voice;
- auto narration and spoken feedback toggles;
- existing BGM ducking while narration is active.

Nursery uses existing tap/correct/wrong/hint/complete SFX. No new package or platform channel is required. Meaningful sound always has visible text feedback.

## Correct, incorrect, hint and completion feedback

- **Correct:** cheerful but brief; show why the answer works, not only a check mark.
- **Incorrect first try:** “Good try” style message + conceptual cue; answer remains enabled for another attempt.
- **Repeated incorrect:** offer the authored stronger hint/worked cue. Retry evidence is marked non-independent.
- **Hint:** never deducts existing rewards or progress; it simply prevents that attempt from counting as independent mastery evidence.
- **Completion:** distinguish “You practised this” from “You remembered this later.” Secure state requires delayed review.
- No public scores, ranking, shame, failure animation or streak pressure.

## Android and Windows responsive layouts

Nursery uses width-driven Flutter layout only, consistent with `BrightResponsive`/existing breakpoints:

- **Compact Android (~360×640):** one-column skill cards, full-width choices, no horizontally clipped instruction/feedback text, tracing canvas constrained to viewport.
- **Tablet / Android free-form:** two-column skill grid where space permits; worked example and interaction can sit side-by-side only when both retain large targets.
- **Windows free-form / desktop:** centred max-width learning panel, optional two-column explanation/interaction, mouse hover/focus visible, no assumption of maximized window.
- Text scale up to the existing 1.3 setting must not cause fixed-height overflow; Nursery content uses scrollable vertical surfaces rather than height-constrained stacks.

## Accessibility and Windows crash-safety boundary

- Standard Flutter buttons/cards/focus order and meaningful `Semantics` labels are used for Android accessibility.
- Large text, high contrast and the existing dyslexia-spacing/reading-focus preferences remain available through the shared theme/controller.
- Reduced motion is read from `GameController.reducedMotionEnabled`; Nursery animation becomes static/instant when enabled.
- Actions never rely only on colour, sound or drag. Matching/sorting have button flows and text equivalents.
- Windows normal builds remain wrapped by the existing fail-closed `ExcludeSemantics` path in `main.dart`.
- Nursery must not change `BRIGHTQUEST_WINDOWS_SEMANTICS_CANARY`, plugin registration or `third_party/flutter_tts_android`.
- The semantics canary is built/tested separately and cannot become production-default based on widget tests alone.

## Asset requirements

Nursery v1 deliberately avoids a new third-party asset dependency. It uses:

- Flutter/material icons and shape drawing;
- Unicode letter/numeral text;
- familiar emoji/pictograms with visible word labels where semantic ambiguity could matter;
- current BrightQuest music/SFX and dynamic installed-device narration.

A later art pass may replace pictograms with reviewed local illustrations, but must preserve stable content IDs, visible text and accessibility labels. No remote image/network dependency is required for learning.

## Picture-word discovery cards

Alphabet worked-example screens include a discovery card with three child actions: **Hear it**, **Another word**, and **Next letter**. Changing the word/letter uses a short one-shot fade/scale transition; reduced-motion changes are instantaneous. The Nursery hub A–Z Letter Garden also cycles to another authored picture word when a card is tapped, so repeated exploration reveals new content instead of replaying the same association forever. Discovery is always teaching-only and never marks mastery.

The pack bundles at least 200 local `assets/nursery/letter_cards/*.png` picture cards so Android and Windows do not depend on platform emoji rendering for the main visual. Each card also retains a Unicode picture fallback plus Flutter text/narration, preserving a visible/accessible equivalent if an asset fails to decode. Correct answers receive a finite one-shot star/celebration entrance; there are no repeating animation controllers or background frame loops.

## Global Play-Board Navigation Pass

Nursery skill lessons no longer depend on a forced `Next → Next → Next` page chain. Every Nursery domain now opens through the same child-first play-board shell. The board presents a `Discover Zone` plus themed mini-game portals derived from the authored activity type and domain: skill-accurate alphabet portals (`Letter Hunt` / `Letter Challenge`, `Sound Safari` / `Sound Challenge`, `Sound Starter` / `Beginning-Sound Quest`, `Listen & Find`, and `Picture Pairs` / `Picture Challenge`), `Number Hunt` / `Math Mission` for maths, `Picture Hunt` / `World Quest` for My World, `Puzzle Pop` / `Brain Boost` for thinking skills, and interaction-specific `Match Magic`, `Sort Safari`, and `Trace Trail` portals.

The child chooses a portal, completes the interaction, and returns to the play board rather than being automatically pushed into the next form-like page. Correct activity completion is reflected on the board as `Played`; this is UI completion only and does not change mastery rules. The underlying evidence engine still requires clean independent evidence, transfer evidence, and later due review. Discovery remains teaching-only.

The discovery area also avoids linear navigation. `Mission`, `Magic clue`, and `Show me` are selectable discovery cards, and the child may switch among them directly. The worked example remains animated with the existing reduced-motion fallback. Game-portal and answer-card entrance animations are finite one-shot animations only; reduced motion suppresses the portal/answer entrance motion.

Matching and sorting interactions now submit automatically when the final partner/item is placed, removing an unnecessary form-style `Check` button. Tracing was already auto-submitted when the ordered guide path completes. Choice activities use large tappable answer bubbles rather than compact form buttons. All game portals and answer targets remain standard Flutter semantic buttons with keyboard/mouse/touch activation support.

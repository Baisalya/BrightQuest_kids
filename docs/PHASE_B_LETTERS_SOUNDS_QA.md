# BrightQuest Phase B — Letters & Sounds QA

## Purpose

Phase B deepens the verified Phase A framework for Nursery alphabet and phonics. It treats the 208 picture-word cards as two different teaching resources:

1. **Letter/vocabulary discovery** — broad A–Z examples may be shown, narrated and animated.
2. **Simple phonics evidence** — only clear, developmentally appropriate sound-letter examples may contribute to letter-sound or beginning-sound practice and mastery.

A discovery word being spelled with a letter does **not** automatically make it a safe simple-phonics example.

## Phase B corrections

The content pack now keeps irregular, advanced, accent-sensitive and cluster examples out of simple phonics evidence while retaining them for vocabulary discovery. Examples include:

- `E`: Eye, Eagle, Earth, Ear and accent-sensitive Envelope.
- `I`: Ice Cream, Island, Ice Cube and Ivy.
- `O`: Owl, Onion, Ocean, Orange and Olive.
- `U`: Unicorn, Uniform, Utensils, Urn and Ukulele.
- consonant clusters such as Drum, Frog, Flag, Grapes, Star, Spoon, Tree and Train.
- `S + H`: Ship is not treated as the simple `/s/` example.
- `Q`: Q/U words remain discovery vocabulary rather than a single simple-consonant mastery claim.
- `X`: X-ray, Xylophone and medial/final X examples remain discovery content; they do not enter simple beginning-sound mastery.

The resulting Phase B simple-phonics pool contains **157 curated examples** while all **208 cards remain available for A–Z discovery**.

## Narration policy

For a simple phonics example, the child is asked to listen to the actual familiar word and notice its first sound. The app does not depend on system TTS correctly producing an isolated phoneme from a single typed letter. This avoids accidentally teaching letter names such as “bee” as if they were pure consonant sounds.

Irregular/advanced cards use an explanatory listening cue rather than pretending they share the simple sound. These cards remain teaching-only for that phonics relation.

## Picture-word integrity

Phase B also replaces obvious emoji-to-word mismatches with dedicated bundled illustrations. The corrected cards are Igloo, Jug, Lamp, Ostrich, Quilt, Quail, Quiver, Ukulele, Vacuum, Vulture, Wagon, Yak and Zeppelin. Their main PNG now depicts the labelled object rather than a misleading substitute such as an ice cube for Igloo or a broom for Vacuum. Their fallback `picture` value is the exact word label, so an asset decode failure degrades to correct text instead of a wrong picture.

## Game-board alignment

Alphabet portals now describe the actual learning task:

- uppercase/lowercase/visual recognition → **Letter Hunt / Letter Challenge**
- letter sounds → **Sound Safari / Sound Challenge**
- beginning sounds → **Sound Starter / Beginning-Sound Quest**
- listen-and-select → **Listen & Find**
- word-picture association → **Picture Pairs / Picture Challenge**
- pair matching → **Match Magic**
- tracing → **Trace Trail**

A letter-recognition question is no longer labelled as a sound game simply because it is a transfer activity.

## Automated gates

`NurseryPhonicsAudit` independently checks the authored JSON flags against a curated QA reference rather than trusting the content flags themselves. It verifies:

- all 26 letters and 208 discovery cards remain present;
- sound and beginning-sound eligibility exactly match the Phase B reference;
- advanced/irregular words cannot enter simple phonics mastery;
- Q and X stay out of simple onset mastery;
- generated sound practice never selects a non-approved example;
- deterministic generators cover the complete 157-example simple pool;
- child-facing generated text does not expose implementation jargon such as “sound cue”.

Widget tests cover all ten alphabet skill boards at phone, tablet and Windows/free-form sizes and verify skill-appropriate portal labels and accessible animated picture semantics.

Pixel-golden tests are included as an opt-in harness because real Flutter rendering is required to create trustworthy baselines. On the Windows qualification machine, run `./tool/qa/capture_phase_b_goldens.ps1` (PowerShell: `.\tool\qa\capture_phase_b_goldens.ps1`) to create/update `test/goldens/phase_b/`. The default test suite keeps these tests skipped until the explicit `BRIGHTQUEST_PHASE_B_GOLDENS` define is enabled, so missing baselines are never silently fabricated.

## Run on Windows

```powershell
dart format lib test tool
flutter analyze
flutter test
.\tool\qa\run_phase_b.ps1
```

The Phase B runner first re-runs the fail-fast Phase A baseline, then the focused phonics audit, focused unit/widget regressions and static analysis. It prints `Phase B completed successfully` only if all steps exit successfully.

## Human gates

Automated Phase B success does not equal teacher approval or commercial readiness. The following remain external evidence gates and must not be invented:

- qualified early-years/phonics review of the exact content revision;
- supervised child observation/pilot results;
- real-device narration review for installed Android and Windows voices;
- Android accessibility/device qualification;
- Windows safe-default and Narrator canary qualification;
- production billing/store configuration.

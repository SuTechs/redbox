# Red Box

Status: Pocket toy design approved on 2 October 2026. The first Flutter version is implemented. See DESIGN.md and design/pocket-toy.html for the locked design guide.

## The idea

Red Box is a cute, calming memory game for a small everyday break. Watch a few square boxes glow red, remember their positions, then tap every box that did **not** glow red.

Correctly tapped boxes also turn red. That is the playful twist: the player remembers what happened earlier instead of relying on the colors currently on screen.

## How a round works

1. A beautiful arrangement of square boxes appears. The opening levels use 6, 8, 10, 12, and 9 boxes in different silhouettes.
2. One or more boxes gently glow red for a few seconds. The first level shows one red box.
3. Those boxes return to their normal appearance. Every box now looks the same.
4. The player taps all the boxes that stayed normal during the preview, in any order.
5. Each correct tap turns that box red and gives a soft, satisfying response.
6. When every safe box has been tapped, the round is complete. A small celebration leads to the next level.

Example: if one box glows red in a six-box round, leave it alone and tap the other five. At the end, the five tapped boxes are red and the original red box is normal.

The red boxes are a set of positions to remember, not a sequence to repeat. All marked boxes glow together in the initial version.

## Rules

- Taps are enabled only after the preview finishes and its red color has fully faded.
- A box that glowed during the preview must never be tapped, even when it looks normal again.
- A correctly selected box stays red and cannot count twice. Repeated taps on it do nothing.
- The boxes keep the same positions throughout the round.
- Winning means selecting every safe box, with no forbidden selections.
- Every arrangement contains at least one forbidden box and at least one safe box.
- Progress shows safe boxes selected, such as “2 of 3”. It does not reveal which boxes are safe.

## Keeping it relaxing

Defaults for the first version:

- No timer during the tapping phase, lives, streak pressure, or score penalties.
- A mistake pauses the round, gently reveals the remembered boxes, and says “Let's try that again”. Retry starts a fresh random pattern at the same level, without losing progress.
- Start with a three-second preview. Offer a slower five-second preview in settings.
- Let the player pause, resume, or leave whenever they like. Resuming or returning from the background replays the preview and clears that round's selections.
- Use soft optional sounds and light optional haptics. Avoid loud alarms, rapid flashes, and screen shakes.
- Make success feel like a small reward: a friendly phrase, a little bounce, and a clear “Next level” button.

“Stress relief” describes the intended mood and experience; the game does not make health claims.

## Levels and arrangements

The pleasure comes from tapping the boxes. Easy means a small memory load, not a small or repetitive board. Beautiful patterns with 6–16 square boxes appear from the beginning, independently of the red-box count.

`patternForLevel(level, seed: seed)` is a pure Dart function. The same seed and level always return the same shape. It selects from 22 connected silhouettes, alternates box counts, and varies reflections and rotations. Families include leaves, stepping stones, clovers, rings, wings, crowns, ribbons, and frames. Consecutive levels use different families. Boards use at most five rows/columns, preserve square tiles, and fit the screen with touch targets of at least 48 logical pixels.

| Levels | Boxes | Red boxes to remember |
| --- | --- | --- |
| 1–50 | Varied 6–16 | 1 |
| 51–150 | Varied 6–16 | 1–2 |
| 151 onward | Varied 6–16 | 1–3 |

One easy moment in each five-level block after 50 reduces the red-box count to one; it keeps the seeded silhouette and plenty of satisfying taps. At later levels, the other rounds mix two and three red boxes. There is no escalating board-size pressure.

Shapes are deterministic; red positions are chosen separately at random for each attempt. A retry keeps the level's shape and changes its red set. The pattern sampler in `design/patterns.html` and `design/pattern-samples.png` shows exact seed-20261002 outputs for levels 1, 2, 3, 4, 5, 50, 70, 100, and 1000. Regenerate it with `dart run tools/preview_patterns.dart 20261002`.

Levels continue indefinitely: no final level, reset at a level cap, or wraparound. After the early progression, vary comfortable layouts and red-box counts without continually increasing difficulty. Every fresh round chooses red boxes at random, including level 1. Avoid repeating the same red set on recent retries/replays; pause/resume preserves the current pattern.

The level page shows 50 levels per chapter with friendly pace labels, completed/open/locked square buttons, chapter navigation, and a number picker for reaching any unlocked level. Completing an earlier level never lowers saved progress. The furthest unlocked level remains the home Continue destination.

## Screens and UI

- **Home:** Red Box name, a friendly red square character, one clear play button, and small How to play and Settings actions. Offer Continue when a saved level exists.
- **Levels:** a Pocket toy chapter browser, square level buttons, difficulty labels, and replay access to every unlocked level.
- **How to play:** a short visual explanation: watch the red boxes → let them fade → tap the others. Explain that correct taps turn red too.
- **Game:** level number, pause control, generous space around the boxes, a clear “Watch” / “Tap the others” instruction, and subtle progress.
- **Round complete:** warm feedback and a Next level button. Keep the board visible where possible.
- **Retry:** kind feedback, remembered boxes revealed, and a Try again button.
- **Pause / Settings:** resume, return home, sound, haptics, slower preview, and reduced motion. No navigation underneath active boxes.

## Look and feel

Cute, simple, tactile, and uncluttered. Red is the central gameplay color; other colors should support it. Rounded square corners are welcome, but the boxes stay visibly square. Give the mascot personality while keeping gameplay tiles simple and equally recognizable.

The approved direction is **Pocket toy**: warm cream, coral red, soft depth, Fredoka titles, Nunito body text, and a friendly square mascot. Preserve the approved HTML guide in the Flutter project.

Bundle relaxing sounds for correct taps, level completion, play/continue/next/retry, and mistakes. Use gentle plucks and rounded chimes, with a separate mute setting. Mistakes get a soft low note rather than an alarm.

Background music offers two original, bundled ambient loops: Cloud drift and Warm keys. Start music on the player's first interaction, keep it quiet beneath tap sounds, fade track changes, and pause when backgrounded. Save the selected track and separate music/tap-sound mute preferences. Include a Mute all audio action and access to music settings from the pause sheet. All audio must work offline.

Accessibility: comfortable text contrast, touch targets of at least 48 logical pixels, phase announcements, and a reduced-motion preview that holds red without pulsing. Offer a non-color cue, such as the same symbol on previewed and correctly selected boxes, so the memory challenge remains intact. Audio is optional and must not be necessary to understand the game.

## First Flutter version

Build for Android and iOS, portrait-first and offline. Include the core loop, gentle progression, curated layouts, tutorial, pause, retry, settings, and local storage for the current level and preferences. Exclude accounts, ads, purchases, leaderboards, and online features from the first version.

Keep the originally red box IDs separate from the tapped box IDs. Determine correctness from the original set, never from a tile's visible color. Use explicit round states: ready → preview → fade → input → complete or retry.

## Delivery order

1. Save and lock the approved Pocket toy design guide. Complete.
2. Implement the full Flutter UI, randomized endless rounds, and relaxing sound cues.
3. Verify the rules, lifecycle behavior, local progress, responsive layouts, and build.
4. Playtest the pace, sound balance, and difficulty on a phone.

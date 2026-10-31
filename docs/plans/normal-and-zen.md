# Normal progression and Zen mode

## Intent

Keep Red Box's Pocket toy identity and satisfying taps. Add a Normal mode that
becomes a real memory challenge; preserve the shipped game as Zen. This PR
prepares the next app version and does not submit a store release.

## Modes and progress

- New installs start in Normal. Home offers Normal / Zen, and Settings has a
  Zen mode switch. The current mode is visible on Home, Levels, and the board.
- Each mode has its own unlocked level. Existing v1 `level` migrates to Zen;
  Normal starts at level 1. Audio and comfort preferences survive migration.
- The mode is fixed during a round; change it from Home or Levels. A paused
  game's audio/comfort settings cannot silently change its progression track.
- Zen retains existing seeded shapes (6–16 boxes), one to three red boxes,
  breather levels, 3/5-second previews, and no shuffling.

## Normal difficulty

| Levels | Board sizes | Red boxes | Preview | Sequential pair swaps |
| --- | --- | --- | --- | --- |
| 1 | 8 | 1 | 3s | 0 |
| 2–4 | 10–12 | 2 | 3s | 0 |
| 5–9 | 12–16 | 3 | 2.6s | 0 |
| 10–19 | 16–18 | 4 | 2.4s | 1 |
| 20–29 | 18–22 | 5 | 2.2s | 2 |
| 30–39 | 20–24 | 6 | 2s | 2 |
| 40–59 | 22–26 | 6 | 2s | 3 |
| 60–79 | 24–28 | 7 | 1.8s | 4 |
| 80–99 | 26–28 | 8 | 1.6s | 4 |
| 100–149 | 26–30 | 8 | 1.6s | 5 |
| 150+ | 26–30 | 10 | 1.4s | 6 |

Level numbers remain endless. The curve caps to keep targets tappable and
previews usable; seeded silhouettes/orientations and random remembered boxes
keep later levels varied. There is no input countdown, life system, or paywall.
The longer-preview preference adds time in Normal too.

## Fair shuffling

Preview → fade → optional shuffle → input → complete/retry. Red color and symbol
cues fade before movement. Each swap exchanges one remembered and one safe tile;
identities carry the remembered state to their new positions. Use separate arcs
so the two neutral tiles do not collide along an indistinguishable straight path.
Swaps are sequential, with input locked until every animation and settling gap
ends. Instructions announce the number of reds, preview duration, and swaps.

Retry generates fresh red positions and a new swap plan. Pause cancels timers;
resume replays the same round from its original layout, including its same swap
plan. Pausing a completed/failed round preserves that result. Reduced motion
(including the OS preference) disables shuffles instead of teleporting hidden
tiles. No rankings are added, so accessibility options do not affect fairness
between players.

## Architecture

- A pure difficulty policy owns Normal counts, timing, and swap limits.
- A separate seeded Normal pattern function keeps Zen's pattern API unchanged.
- A generated round contains immutable mode, red identities, and swap pairs.
- The controller owns phase timers and tile-to-slot mappings, independent of UI.
- The board animates the controller's mapping using stable tile identities.
- Progress updates explicitly target the completed round's mode.
- Layouts stay at most five columns and six rows in portrait with 48px square touch targets.
  Short screens and large text can scroll vertically; previews jump the whole
  board into view before play. Large text uses natural scrolling rather than
  intrinsic flex layout. Tall boards transpose in landscape; rotating during an
  active round replays the same preview. Progress dots wrap.

## Verification

- Pure tests: tier boundaries, seeded layout reproducibility, connectivity,
  unique IDs, board size bounds, red selection, fresh retries, disjoint swaps.
- Controller tests: no input during preview/fade/shuffle, correct tracking after
  swaps, safe completion, wrong taps, pause/resume in every timed phase, disposal,
  and reduced motion with no hidden jumps.
- Persistence tests: legacy migration, independent progress, mode restoration,
  rapid writes, corrupt values, and audio/comfort retention.
- Widget tests: both mode entry points, level-page updates, immutable in-round
  mode, correct progress unlocks, square targets on small/large-text screens,
  and visible shuffle instructions and input locking.
- Run formatter, analyzer, full tests, and release web/Android builds. Capture
  mode, difficulty and shuffle examples for PR review. Review changes before
  opening the PR; no automatic merge or store submission.

## Verification results — 31 October 2026

- All 68 Flutter tests pass, including legacy Zen regressions and Normal mode,
  migration, shuffled identities, mid-shuffle reduced motion, rotation,
  320×568 previews with safe-area padding, 568×320 landscape, and system text
  scales 1.2, 1.4, 1.8 and 2.0.
- Formatter is clean and `flutter analyze` reports no issues.
- Release web build, signed Android App Bundle, and iOS simulator debug build pass.
- Real Flutter PNGs and timed shuffle frames were exported with the capture test.
- Independent source review is complete. Its landscape visibility finding was
  resolved and regression-tested; no outstanding actionable findings remain.
- Physical-device playtesting and store upload remain part of the release process
  after reviewing this PR.

# Normal progression and Zen mode

## Intent

Keep Red Box's Pocket toy identity and satisfying taps. Add a Normal mode that
becomes a real memory challenge; preserve the shipped game as Zen. This PR
prepares the next app version and does not submit a store release.

## Modes and progress

- The main Play action opens Normal. A lotus icon beside Settings on Home
  launches Zen directly; Home has no text mode selector. Zen keeps the warm cream
  background, with sage accents and a lotus badge. The level browser follows the last-played track,
  with a Zen mode switch in its Settings. The active track is visible on Levels
  and the board.
- Each mode has its own unlocked level. Existing v1 `level` migrates to Zen;
  Normal starts at level 1. Audio and comfort preferences survive migration.
- The mode is fixed during a round; change it from Home or Levels. A paused
  game's audio/comfort settings cannot silently change its progression track.
- Zen retains existing seeded shapes (6–16 boxes), one to three red boxes,
  breather levels, 3/5-second previews, and no shuffling.

## Normal difficulty

| Levels | Board sizes | Red boxes | Preview | Sequential pair swaps |
| --- | --- | --- | --- | --- |
| 1 | 4 | 1 | 3s | 0 |
| 2 | 5 | 1 | 3s | 0 |
| 3–4 | 6 | 2 | 3s | 0 |
| 5 | 7 | 2 | 3s | 0 |
| 6–7 | 8 | 3 | 3s | 0 |
| 8–9 | 9 | 3 | 3s | 0 |
| 10 | 10 | 4 | 3s | 0 |
| 11–19 | 10–12 | 4 | 3s | 0 |
| 20–29 | 12 | 4 | 3s | 1 |
| 30–39 | 12–14 | 5 | 2.8s | 1 |
| 40–49 | 14 | 5 | 2.8s | 2 |
| 50–69 | 14–16 | 6 | 2.6s | 2 |
| 70–89 | 16–18 | 7 | 2.6s | 2 |
| 90–119 | 18 | 7 | 2.4s | 3 |
| 120–159 | 18–20 | 8 | 2.4s | 3 |
| 160–219 | 20 | 8 | 2.2s | 4 |
| 220–299 | 20–22 | 9 | 2.2s | 4 |
| 300–399 | 22 | 9 | 2s | 5 |
| 400+ | 22–24 | 10 | 1.8s | 5 |

### Rebalance rationale

Normal teaches with a four-box round, then grows memory density before adding
movement. Only the first two rounds have one red. Every round has at least 20%
reds and no more than 14 safe taps. The first shuffle keeps the familiar four
reds and three-second preview; later tiers alternate practice, extra memory,
and movement. Small board-size variations give the curve a rhythm rather than
making every next level strictly larger.

This is a design hypothesis informed by competence and autonomy in
[game-engagement research](https://selfdeterminationtheory.org/SDT/documents/2010_PrzybylskiRigbyRyan_ROGP.pdf),
not a validated psychological outcome. No failure penalties or tapping timer;
Extra time, reduced motion and Zen remain player choices. Playtest the opening,
first shuffle and late tiers with new and experienced players before release.

### Level identity

A level number and seed determine its silhouette and difficulty. Retrying changes
red positions and the legal shuffle plan, never the silhouette. A seeded family
deck avoids adjacent repeats; silhouette previews and red counts appear on each
level card without revealing the upcoming red positions. The chapter summary
shows its current (or nearest boundary) level's actual shape and challenge, replacing the
repeated “A growing challenge” copy. Shape names also appear above Normal play.

Endless levels cannot have infinitely unique silhouettes within a finite phone
grid: families recur, with stable orientations and changing rules. We promise
recognizable, reproducible levels and variety, not mathematical global uniqueness.

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

- The initial 69 Flutter tests passed, including legacy Zen regressions and Normal mode,
  migration, shuffled identities, mid-shuffle reduced motion, rotation,
  320×568 previews with safe-area padding, 568×320 landscape, and system text
  scales 1.2, 1.4, 1.8 and 2.0. Real-font small-phone tests also verify that
  the Home play action is visible without scrolling in either mode.
- Formatter is clean and `flutter analyze` reports no issues.
- Release web build, signed Android App Bundle, and iOS simulator debug build pass.
- Real Flutter PNGs and timed shuffle frames were exported with the capture test.
- Independent source review is complete. Its landscape visibility finding was
  resolved and regression-tested; no outstanding actionable findings remain.
- Physical-device playtesting and store upload remain part of the release process
  after reviewing this PR.

### Follow-up review

The October 31 feedback changes the opening to 4–10 boxes, defers shuffling to
20, and restores cream behind Zen's lotus/sage accents. Added checks cover the
opening sequence, safe-tap budget, memory density, adjacent silhouettes across
4,000 seeded levels, and accurate chapter guidance at small-screen/large-text sizes.
New captures include the actual level browser and the first four-box round.

Visual review also found that a shuffle arc could leave the screen at the right
edge. Both paths now receive the same inward translation, preserving their
separation while keeping their tile faces inside the board. A frame-by-frame
small-phone widget test covers this case.

Final follow-up verification: all 72 Flutter tests pass; formatter and analyzer
are clean. Release web, signed Android App Bundle, and iOS simulator builds pass.
The real-widget capture test passes, and refreshed PNGs plus the regenerated
shuffle GIF show the final curve, level cards, warm Zen palette and edge fix.

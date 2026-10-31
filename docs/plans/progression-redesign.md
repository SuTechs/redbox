# Red Box progression redesign — proposal

Status: approved by the user and implemented, 31 October 2026. This supersedes
the earlier Normal/Zen proposal. The audit below records the pre-change build
(475489e); the illustrative board study is a planning artifact, not a capture.
The final user clarification also requires beautiful Zen silhouettes: the Zen
deck excludes solid square and rectangular boards.

## Audit before implementation

Audited the current round generator at the default seed, rather than inferring
behavior from the level labels. Preview below means the standard setting.

| Current level | Normal: total / red / safe taps | Normal preview / pair swaps | Current Zen: total / red |
| --- | --- | --- | --- |
| 1 | 4 / 1 / 3 | 3s / 0 | 6 / 1 |
| 300 | 22 / 9 / 13 | 2s / 5 | 13 / 3 |
| 500 | 23 / 10 / 13 | 1.8s / 5 | 16 / 3 |
| 600 | 24 / 10 / 14 | 1.8s / 5 | 13 / 3 |
| 1,296 | 24 / 10 / 14 | 1.8s / 5 | 12 / 2 |
| 1,300 | 22 / 10 / 12 | 1.8s / 5 | 8 / 3 |

The reported two reds at 1,296 exactly match the current Zen policy. The current
code alone cannot prove which route was used in that particular play session.
Normal also has a real design problem: it reaches its final tier at 400 and then
stays at ten reds. The last-played mode also controls the level browser, which
makes those two ladders easy to confuse.

## Product decisions

1. **Normal is the numbered game.** Continue resumes its unlocked level. Its
   remembered-red count rises through the long-term curve. Replaying a level
   keeps its board and rules; the red positions are fresh.
2. **Zen has no levels.** Play Zen starts an easy random board. Another board
   starts another. No numbered ladder, unlocked levels, chapter labels or saved
   Zen level is shown. There is no Zen on/off setting.
3. **Home gives both activities direct entry.** Primary Continue (Let's play on
   a new install), then a secondary lotus action labelled **Play Zen**. Settings
   stays at the upper right; a small **Levels** icon sits directly beneath it.
   Remove the header's Zen icon and the large Levels button below Continue.
4. **Levels always means Normal levels.** Return to clear numbered buttons with
   completed/current/locked states. Remove shape thumbnails and per-cell red
   counts. A concise chapter heading explains its current skill, not the same
   generic sentence on every page. The actual round explains what to remember.
5. Keep the approved Pocket toy cream/coral style. Zen retains a sage lotus and
   clear **Zen** badge. Music and comfort controls stay available from pause;
   they are settings, while Normal and Zen are separate entry points.

Home hierarchy (structure, not final pixel spacing):

```text
Red Box                                      Settings
                                             Levels
                  Pocket toy hero

                 Continue · Level N
                 [lotus] Play Zen
                    How to play
```

Both play actions must fit on a 320×568 phone without scrolling at default text
size. Use a compact hero arrangement where needed. Large text can scroll. Both
header icons retain at least 48×48 touch areas and clear accessibility labels.

## Proposed Normal curve

The numbers below are difficulty bands, not an assertion that every next board
must be larger. Small size variations make space for different silhouettes;
**the red count never drops between later Normal bands**. Early teaching levels
use these exact total counts: **4, 5, 6, 6, 7, 7, 8, 8, 9, 10**. Red counts for
those ten levels: **1, 1, 2, 2, 2, 2, 3, 3, 3, 3**.

| Levels | Total boxes | Red boxes to remember | Safe taps |
| --- | --- | --- | --- |
| 1 | 4 | 1 | 3 |
| 2 | 5 | 1 | 4 |
| 3–6 | 6–7 | 2 | 4–5 |
| 7–14 | 8–10 | 3 | 5–7 |
| 15–24 | 10–12 | 4 | 6–8 |
| 25–39 | 12–14 | 5 | 7–9 |
| 40–59 | 14–16 | 6 | 8–10 |
| 60–89 | 16–18 | 7 | 9–11 |
| 90–139 | 18–20 | 8 | 10–12 |
| 140–219 | 20–22 | 9 | 11–13 |
| 220–349 | 22–24 | 10 | 12–14 |
| 350–499 | 24–26 | 11 | 13–15 |
| 500–599 | 28–30 | 12 | 16–18 |
| 600–749 | 30–32 | 13 | 17–19 |
| 750–899 | 32–34 | 14 | 18–20 |
| 900–999 | 34–36 | 15 | 19–21 |
| 1,000–1,099 | 36–38 | 16 | 20–22 |
| 1,100–1,199 | 38–40 | 17 | 21–23 |
| 1,200–1,499 | 40 | 18 | 22 |
| 1,500–1,999 | 40 | 19 | 21 |
| 2,000 onward | 40 | 20 | 20 |

After the first ten levels, a deterministic count cycle stays inside that band's
range. Never change count or shape on retry. At high levels the challenge comes
from remembering roughly 40–50% of a substantial board; it cannot fall back to
two or three reds. The previous 14-safe-tap cap is removed: the new budget is at
most 23 taps, alongside a much larger remembered set.

There is an intentional physical ceiling: 40 squares and 20 reds. Levels continue
past 2,000 with fresh red sets and varied layouts/paths at expert difficulty.
This is a longer progression followed by endless expert play, not unlimited
increases in tile count. Keeping visible 48px touch targets is the reason for
that ceiling. There is no lives system or tapping countdown.

### Viewing time and gradual speed

A growing memory set needs a readable exposure. Shrinking the entire preview
monotonically while increasing reds would turn late levels into guesswork.
Use a memory-sized time budget, then introduce a small speed increase while the
player practices the same red count.

- Baseline preview: `max(3.0, 2.0 + 0.2 × redCount)` seconds.
- Before level 100: use that baseline.
- After 100: reduce by 0.1s for each completed 25-level practice block within the
  current red-count band, up to a 0.4s reduction. Start that practice clock at the
  later of level 100 and the current band's first level.
- A new red-count band restores its baseline. Extra time multiplies the resulting
  duration by 5/3, as in the existing preference. No hidden per-player adjustment.

Thus eighteen reds get roughly five seconds; this is a much greater memory load
than one red for three seconds. The exact time budget remains a playtest target.

### Movement, introduced separately

- Levels 1–49: stationary memory puzzles.
- 50–174: one pair swap.
- 175–549: two pair swaps.
- 550–849: three pair swaps.
- 850 onward: four pair swaps maximum.

A pair exchanges one red identity and one safe identity. The pairs are disjoint,
visible, sequential and input-locked. Early pairs are neighboring tiles. Start
movement at 900ms per pair, with a 180ms settling gap. Shorten movement by 50ms
at levels 100, 275, 675, 975 and 1,350, reaching a 650ms floor. These milestones
are separate from red-count increases. Reduce motion disables swaps, preserving
the same memory count and the extra-time choice.

Four pairs cap the moving portion at eight tiles. Moving the whole forty-box
board would obscure identities and add a lengthy waiting phase. No invisible
teleports, simultaneous crossing groups, fake-out flashes or input timer are
part of this proposal.

### Requested examples

These are concrete sample boards within the proposed size bands, illustrated in
[the board study](progression-study.png). Shape masks and red locations here are
planning examples, not captured gameplay or finalized output of a new generator.

| Level | Sample total | Red | Safe | Standard preview | Pair swaps |
| --- | --- | --- | --- | --- | --- |
| 1 | 4 | 1 | 3 | 3.0s | 0 |
| 300 | 22 | 10 | 12 | 3.7s | 2 |
| 500 | 28 | 12 | 16 | 4.4s | 2 |
| 600 | 30 | 13 | 17 | 4.6s | 3 |
| 1,296 | 40 | 18 | 22 | 5.3s | 4 |
| 1,300 | 40 | 18 | 22 | 5.2s | 4 |

Progress need not add a red every single level. Levels 1,296 and 1,300 keep the
same eighteen-red load while practicing different stable boards and slightly
quicker reading. The next memory increase is nineteen reds at 1,500.

## Zen, without a ladder

- Play Zen starts immediately, with an explicit Zen label and lotus.
- Choose a fresh, connected 6–16-box silhouette independently each round. Favor
  6–12 boxes; larger silhouettes are occasional tapping treats, not milestones.
- One red most of the time; occasionally two on boards of ten or more. Cap at
  two forever. No shuffle, speed ramp or performance-based difficulty change.
- Preview three seconds, or five with the longer-preview comfort preference.
- Completion says **Lovely** and offers **Another board**. No next-level wording,
  chapter, stars, rank, streak, score, unlock or displayed round counter.
- A mistaken tap softly reveals the reds and offers another look at that same
  board. No failure penalty; offer a new board from pause if desired.
- Persist audio/comfort preferences and Normal progress. Zen needs no saved level
  or saved random-session seed. Old Zen/legacy level values can remain archived
  in storage during migration, but do not drive any play route or UI.

## Critique pass 1 — challenge and enjoyment

| Weakness found in the first draft | Revision in this proposal |
| --- | --- |
| Adding reds while forcing shorter global previews makes late boards unreadable. | Memory-sized baseline, with small within-band speed changes and a recovery when the remembered set grows. |
| Raising reds, speed and shuffle count at the same milestone creates abrupt difficulty jumps. | Separate red-count and swap-count schedules; movement speed has its own spaced milestones. |
| The earlier 14-tap cap keeps boards small even at four-digit levels. | Allow boards up to 40 and safe taps up to 23; raise red density rather than filling late boards with easy tapping. |
| Too many sequential swaps turn the game into waiting. | Limit movement to four pairs, rather than growing it alongside every red-count increase. |
| Zen with levels and a Settings toggle looks like a second campaign. | A direct Play Zen action, no ladder, random independent boards and no mode setting. |
| Shape previews crowd an infrequently visited screen and add UI the player did not request. | Numbered level buttons, state icons and useful chapter copy only. |

## Critique pass 2 — feasibility and edge cases

### Dense boards must fit before this curve ships

The current five-column layout and large instruction header are insufficient for
forty boxes. This proposal therefore includes a compact play layout, rather than
assuming that changing difficulty numbers is enough.

- Small portrait feasibility: a 6-column × 8-row envelope at 48px targets and 4px
  gaps is **308×412px**. On 320×568, this leaves 156px vertically for safe areas,
  compact controls and progress. Forty occupied cells leave eight spaces for
  shaped silhouettes. Keep dense horizontal margins at 6px, not the current 24px.
- Small landscape feasibility: a 9-column × 5-row envelope at 48px targets and
  2px gaps is **448×248px**. With a 48px side control rail and 12px separation,
  it is **508×248px**. That fits inside 568×320 even with a combined 40px of
  horizontal and vertical safe-area deductions. Use the side rail, not the tall
  portrait heading/footer stack.
- These are space calculations, not a completed responsive-UI test. Real fonts,
  safe areas, text scales, tile depth, pressed state and shuffle arcs must pass
  actual rendered checks. Reserve/clamp moving paths within the board envelope.
  If targets cannot fit, revise the layout or curve; never hide part of a timed
  board in a scroll view or silently shrink touch targets.
- Use stable layout variants per aspect profile. Rotation replays a full visible
  preview; it must never reflow hidden red positions while input stays live.

### Determinism, identity and correctness

- Plan a pure `normalLevelSpec(level, seed, layoutProfile)` with count, red count,
  shape, preview and swap limits. A separate attempt seed chooses reds and swap
  pairs. Retry keeps the level spec; pause/resume keeps the attempt too.
- A seed should reproduce a level's arrangement for the same layout profile.
  Portrait and landscape can use different fitted variants of its shape family;
  a rotation starts the preview again. All tiles keep stable identities and
  swapping carries remembered identity, not a coordinate's old color.
- Connected shapes, bounded dimensions and deterministic ordering are hard
  constraints. Avoid adjacent identical silhouettes. Curated shape families may
  recur; do not promise infinitely unique shapes on a finite grid.
- Normal and Zen must be explicit session types at route entry. Remove the
  last-played-mode dependency from Levels. No default-to-Zen generator call may
  accidentally create a Normal round. Persist only Normal's active ladder.
- Retain saved Normal unlocks and comfort preferences. Do not copy a high legacy
  Zen number into Normal: a casual player must not land directly in an
  eighteen-red challenge after updating. Do not reset existing Normal progress.
- Random red selection is without replacement and avoids the last same-board
  set. Do not reveal future red positions on Home or Levels.

### What this review still cannot prove

Arithmetic and a plan do not establish that eighteen reds feels enjoyable, or
that forty tactile tiles remain comfortable on a physical phone. Start with the
specified numbers, then use real-device playtesting at 1, 10, 50, 300, 600 and
1,300 with beginners and experienced players. Check understanding, guesswork,
fatigue, accidental taps and whether players choose another round. Tune preview
budgets and band spacing from that feedback without undoing the rising red-count
floor. These are release validation tasks, not claims of completed testing.

## Implementation sequence, after planning

1. Build/review the pure Normal level specification and a deterministic sampler.
   Inspect samples for 1–10, all tier boundaries, 50, 70, 100, 300, 500, 600,
   1,000, 1,296, 1,300, 2,000 and 10,000 before wiring the UI.
2. Prove the dense-board layout with rendered portrait/landscape studies, including
   every shuffle frame and large text, before adopting the forty-box bands.
3. Separate Normal progression and random Zen session state; preserve preferences
   and existing Normal unlocks. Remove Zen's level counter and Settings toggle.
4. Apply the Home hierarchy and simplify the Normal-only level browser. Use
   chapter-specific skill summaries without shape previews or per-level metrics.
5. Connect the curve, motion schedule and Zen loop. Verify retry, pause,
   backgrounding, rotation, wrong taps, wins and both mode entry points.
6. Capture the real implementation, inspect it against this study, run meaningful
   tests/builds and playtest on devices. Only then update the implementation PR's
   claims and screenshots. No implementation or store submission is part of this
   planning pass.


## Implementation record

- Normal's red-count, preview and movement schedules are implemented as above.
  Count choices cycle within each band; the level and seed determine the shape.
- Zen uses a curated shuffled deck, including hearts, lotus flowers, bows, clouds,
  arches, leaves and ribbons. Solid rectangles/squares and the heavier dome,
  picture-frame, cup and bridge families are excluded from Zen. It has no level
  UI, saved active ladder, mode toggle or progression side effects.
- Dense boards have fitted portrait/landscape variants. Every tile remains
  visible and at least 48px on the tested 320×568 and 568×320 viewports, including
  safe areas and text scales 1 and 2. Rotation preserves remembered identities
  and restarts the full preview. Zen rotation across layout types is covered too.
- Integer shape weights and Park–Miller variations keep seeded geometry portable.
  A Dart VM / compiled-JavaScript comparison covers 12,600 level specifications.
  Late-level variety is checked across 1,000 forty-box boards in each profile,
  avoiding the short family-only cycle found during source review.
- Current automated coverage replaces the superseded numbered-Zen contract with
  tests for level-free random sessions, beautiful connected silhouettes, Normal
  migration, the new curve, fitted geometry and identity-preserving movement.
- Real Flutter capture tools export the requested Normal milestones and eight
  Zen boards. Physical-device playtesting remains part of release validation.

The portability check is reproducible with
`dart tools/check_pattern_portability.dart` and
`dart compile js -o /tmp/redbox-pattern-check.js tools/check_pattern_portability.dart`,
then `node -e 'global.self=globalThis; require("/tmp/redbox-pattern-check.js")'`.
Both outputs must match. The current 12,600-specification hash is **588015108**.

Final implementation validation: **48 Flutter tests pass**, with clean formatting
and analysis. Both real-widget capture tools pass. Release web, signed Android
App Bundle and iOS simulator builds pass. All source and rendered reviews for
this implementation are complete; physical-device playtesting remains before
store submission.

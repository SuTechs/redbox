# Red Box

A tactile memory game in the approved Pocket toy style: warm cream, coral square
boxes, friendly typography, original quiet sounds, and optional ambient music.

## Normal

Continue resumes a numbered, seeded memory challenge. Start with four boxes and
one red; the first ten total counts are 4, 5, 6, 6, 7, 7, 8, 8, 9, 10. Red counts
rise to twelve at 500, eighteen at 1,300 and twenty at 2,000. Boards grow to forty
boxes. Viewing time scales with memory load and shortens slightly within practice
bands. Shuffling starts at 50, reaches four sequential pairs, and gradually
speeds up from 900ms to 650ms per pair. The full policy and its review are in the
[approved plan](docs/plans/progression-redesign.md).

Watch the reds, let them fade, follow any moving pairs, then tap every safe box.
Correct taps also turn red. Tile identity carries remembered state through a
swap. Input is locked during preview, fading and movement. Wrong taps offer a
fresh attempt at the same level and shape, with fresh reds. Completion unlocks
the next level. Replays never reduce the furthest unlock.

The curve caps at forty boxes and twenty reds; numbered play continues with fresh
sets and varied seeded layouts. No lives, score, input timer or paywall.

## Zen

Play Zen starts an independent, random easy board. Zen has no level numbers,
chapters, progression, score or Settings toggle. Its curated shuffled shape deck
contains connected petals, leaves, rings, ribbons, wings, arches and similar
silhouettes. Solid rectangular and square boards are excluded. Families do not
repeat consecutively. Shapes contain 6–16 boxes, remembering one red most of the
time, occasionally two on boards of ten or more. Difficulty never increases.

Preview for three seconds, or five with Extra time. No shuffles. Completion
shows Lovely and Another board. A mistake softly reveals the reds and offers
Another look at the same board, without a penalty. A New board action is also
available in pause. Random Zen play never changes Normal progress.

## Navigation and appearance

Home: primary Continue (Let's play for a new player), then Play Zen. Settings is
at the top right, with the less prominent Levels icon directly below. The level
browser is Normal-only: chapter guidance and numbered completed/current/locked
buttons, with no pattern thumbnails or per-cell red counts. A level picker can
replay any unlocked number. Gameplay and level browsing retain the Pocket toy
palette; Zen adds a sage lotus and Zen label.

Regular phones keep spacious tactile boards. Dense boards, short viewports,
landscape and large text use a board-first arrangement. All active tiles remain
square and at least 48 logical pixels; timed boards are fully visible. Landscape
uses a fitted shape variant and side controls. Rotation restarts the same
remembered identities with a full preview; no hidden reflow while input is live.

## Comfort and persistence

Music offers Cloud drift and Warm keys, with separate sound/music controls, a
track picker and Mute all audio. Bundle original sounds and fonts. Pause music
when backgrounded; pause/resume replays the same round. Extra time, optional
haptics, symbol cues and reduced motion remain available. Reduced motion removes
swaps instead of concealing a teleport. Pause preserves completed and retry states.

Persist Normal's furthest level and audio/comfort choices. Retain old Zen/legacy
level values as inert migration data, without showing a Zen ladder or using them
to unlock Normal. Normal unlocks survive the update.

No accounts, ads, analytics, tracking, in-app purchases or data collection.
Native apps work offline; the web version loads bundled assets over the network.
Package/bundle ID: com.sutechs.redbox. Support: redbox@sutechs.com.
Privacy: https://sutechs.com/privacy. Terms: https://sutechs.com/terms.

# Red Box — Pocket toy

Approved by the user on 2 October 2026. Pocket toy is the locked visual direction for the Flutter app.

## Reference

- [Interactive HTML guide](design/pocket-toy.html)
- [Editable guide source](design/pocket-toy.source.html)
- [Home reference](design/pocket-toy-home.png)
- [Game reference](design/pocket-toy-play.png)
- [Flutter level page](design/flutter-levels.png)
- [Flutter music settings](design/flutter-music.png)
- [Seeded pattern sampler](design/patterns.html)
- [Requested level patterns](design/pattern-samples.png)

The HTML preserves the approved design exploration, with three sample rounds. Its sample-round limit is not a game requirement. The Flutter game continues indefinitely.

## Visual system

| Token | Value | Use |
| --- | --- | --- |
| Cream | `#FFF8ED` | Main background |
| Ink | `#40342E` | Titles and primary text |
| Warm muted ink | `#806D5C` | Supporting text |
| Coral red | `#ED6258` | Red boxes and primary actions |
| Red depth | `#C6413A` | Red tile and button underside |
| Tile cream | `#F0E6D6` | Neutral boxes |
| Tile depth | `#DDCEBA` | Neutral tile underside |
| Button cream | `#FFFAF4` | Large primary button labels |

- Display: **Fredoka**, medium weight. Home title 48; game headings 29.
- Body and controls: **Nunito**, regular through extra bold. Body 14–16; primary actions 20 bold for readable contrast.
- Bundle both fonts locally; keep their SIL Open Font License files.
- Use 24 logical pixels of page padding, 8-pixel spacing increments, and generous empty space.
- Tiles stay square, with an 18-pixel corner radius, scaled down on larger boards. Neutral and red tiles share the same geometry.
- Tiles have a solid underside, a tiny highlight, and a gentle pressed movement. Preserve the square identity.
- Primary buttons have a 17-pixel radius and a 4-pixel solid underside. Icon actions have at least 48 × 48 touch targets.
- On a real phone, the cream surface fills the screen. The reference's phone-shaped frame is presentation chrome, not app UI.

## Character and motion

A coral square mascot, slightly tilted, with two small dark eyes, a smile, cheeks, and a short top highlight. Small neutral squares support the home illustration. Keep faces out of gameplay tiles.

The red preview gently glows; it never flashes rapidly. Fade back to neutral over about 260 ms and enable input only afterward. Correct taps depress the tile and turn it red. A subtle bounce celebrates completion. Honor both the device's reduced-motion setting and the game's reduced-motion preference.

## Screens

Home: small Red Box wordmark, settings action, mascot, Red Box title, “A tiny game. A little reset.”, primary play/continue button, and How to play.

Levels: “Little steps” beside a small square mascot, a tactile chapter card with a pace label, and 50 square level buttons at a time. Completed levels show a small check, the furthest unlocked level is coral, and future levels show a lock. Browse chapters or open the range label to play any unlocked level by number. Keep a Play current level button visible at the bottom. Replays preserve the furthest unlocked level.

Game: back action, level number, pause action, “Watch the red box(es)” then “Tap the others”, centered board, small progress dots and count, and “A little focus. No hurry.” Success and retry replace the instruction and footer while keeping the board visible.

Tutorial, settings, and pause use cream bottom sheets with rounded upper corners and the same typography. Settings include sound, haptics, Zen's 3/5-second preview or Normal's Extra time option, reduced motion, and a symbol cue for players who need a cue beyond color.

## Sound

Bundle original, quiet WAV cues for taps, continuing, completion, and mistakes. Background music offers two original 64-second looping compositions: Cloud drift (slow ambient chords) and Warm keys (sparse soft notes). Keep music quieter than taps, fade starts and changes, and pause it in the background. Separate music and tap-sound switches, a track picker, and Mute all audio are available in settings. Music & sound is also accessible from the game's pause sheet. Haptics can be disabled separately.

## Normal and Zen

Home keeps Normal's primary Continue action, then a secondary **Play Zen** action
with a sage lotus. Settings stays at the upper right; a Levels icon sits directly
below it. There is no header Zen shortcut, mode selector or Zen Settings toggle.
Levels is a Normal-only numbered browser without shape previews or per-cell
red counts. Use useful chapter skill summaries and clear completed/current/locked
states. Both Home play actions stay visible on a 320×568 phone at default text.

Zen has no level counter. It uses the warm cream background, sage accents
(`#E8EBDD`) and dark sage ink (`#506950`), with a visible Zen/lotus identity. Its
shuffled deck excludes all solid rectangles and squares: choose shaped petals,
leaves, rings, ribbons, arches and wings. Avoid consecutive family repeats.
Completion says Another board; mistakes offer Another look, replaying that board.

Normal uses the [approved curve](docs/plans/progression-redesign.md). The red
count rises to eighteen on forty-box boards at 1,300. The shape and timing are
stable per level; retry changes reds and movement plans. Small, spaced movement
milestones follow memory growth. Opposite arcs and shared edge corrections keep
both moving tiles visible. Draw moving boxes above stationary tiles; lock input
until their movement and settling gap end.

Regular phones retain the spacious layout. Dense, short, landscape and large-text
screens use board-first controls, with a side rail in landscape. Fit variants
within six columns/eight rows in portrait or nine columns/five rows in landscape.
All active tiles are square, at least 48px, and fully visible; never put part of a
timed board out of view. Reserve tile-depth space. Rotation replays remembered
identities in the new fitted variant. Reduced motion disables shuffles.

Maintain separate Normal progression and temporary Zen sessions. Keep saved
Normal unlocks and comfort preferences; old Zen counters are inert migration data.

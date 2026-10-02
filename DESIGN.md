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

Tutorial, settings, and pause use cream bottom sheets with rounded upper corners and the same typography. Settings include sound, haptics, 3/5-second preview, reduced motion, and a symbol cue for players who need a cue beyond color.

## Sound

Bundle original, quiet WAV cues for taps, continuing, completion, and mistakes. Background music offers two original 64-second looping compositions: Cloud drift (slow ambient chords) and Warm keys (sparse soft notes). Keep music quieter than taps, fade starts and changes, and pause it in the background. Separate music and tap-sound switches, a track picker, and Mute all audio are available in settings. Music & sound is also accessible from the game's pause sheet. Haptics can be disabled separately.

## Gameplay commitments

Fresh rounds randomize red positions, including level 1. Retry regenerates the red set; recent same-level repetitions are avoided. Pause/resume keeps the current pattern. Levels never wrap back to 1. Shapes with 6–16 boxes vary from the beginning; the first 50 levels stay easy by previewing just one red box. Later levels mix one, two, and three red boxes. Easy moments keep the varied silhouette and reduce memory load. Tapping remains the main pleasure. Pattern families are connected, with seeded rotations/reflections, alternating sizes, and no consecutive family repeats. Fit both tall and wide patterns to the screen while retaining 48-pixel touch targets. Pace labels stay friendly: Easy, Gentle, Steady, Playful, Curious, Endless. Do not determine correctness from the current tile color.

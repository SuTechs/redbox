// Compare this output on Dart VM and compiled JavaScript; no Flutter engine is needed.
import 'package:redbox/game/round.dart';

void main() {
  var hash = 0;
  var count = 0;
  for (final seed in [-17, 42, 20261002]) {
    for (final p in LayoutProfile.values) {
      for (var level = 1; level <= 2100; level++) {
        final d = NormalDifficulty.forLevel(level);
        final b = normalPatternForLevel(
          level,
          boxCount: d.boxCountForLevel(level),
          seed: seed,
          profile: p,
        );
        for (final unit
            in '${b.columns}:${b.mask.join('/')}:${d.redCount}:${d.previewMilliseconds}'
                .codeUnits) {
          hash = (hash * 31 + unit) & 0x7fffffff;
        }
        count++;
      }
    }
  }
  // This cross-runtime CLI writes one comparable line in both VM and JS.
  // ignore: avoid_print
  print('$count seeded specifications: $hash');
}

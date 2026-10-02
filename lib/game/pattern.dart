const defaultPatternSeed = 20261002;

class BoardLayout {
  const BoardLayout(this.name, this.columns, this.slots);
  final String name;
  final int columns;
  final List<int?> slots;
  int get boxCount => slots.whereType<int>().length;
  int get rows => (slots.length / columns).ceil();

  List<String> get mask => List.generate(
    rows,
    (row) => List.generate(
      columns,
      (column) => slots[row * columns + column] == null ? '.' : '#',
    ).join(),
  );
}

/// Pure and portable: identical level + seed always returns the same shape.
/// The shape is independent of how many red boxes need to be remembered.
BoardLayout patternForLevel(int level, {int seed = defaultPatternSeed}) {
  if (level < 1) throw ArgumentError.value(level, 'level', 'Must be positive');
  final order = List.generate(_patterns.length, (index) => index);
  final deck = _PatternRandom(seed);
  for (var index = order.length - 1; index > 0; index--) {
    final other = deck.nextInt(index + 1);
    final swap = order[index];
    order[index] = order[other];
    order[other] = swap;
  }
  // Alternate sizes so a shuffled seed cannot bunch several similar-sized
  // boards together. The opening offers 6, 8, 10, 12 and 9 satisfying boxes.
  final remaining = List.of(order);
  order.clear();
  while (remaining.isNotEmpty) {
    final before = remaining.length;
    for (final count in [6, 8, 10, 12, 9, 13, 11, 16, 14]) {
      final index = remaining.indexWhere(
        (id) => _patterns[id].boxCount == count,
      );
      if (index >= 0) order.add(remaining.removeAt(index));
    }
    if (remaining.length == before) {
      order.addAll(remaining);
      break;
    }
  }
  // A shuffled deck avoids repeating a family on consecutive levels. Later
  // visits vary orientation while the level number continues indefinitely.
  final template = _patterns[order[(level - 1) % order.length]];
  final variation = _PatternRandom(seed + level * 97);
  var mask = template.mask.toList();
  if (variation.nextInt(2) == 1) {
    mask = mask.map((row) => row.split('').reversed.join()).toList();
  }
  final turns = variation.nextInt(4);
  for (var turn = 0; turn < turns; turn++) {
    mask = List.generate(
      mask.first.length,
      (column) => List.generate(
        mask.length,
        (row) => mask[mask.length - row - 1][column],
      ).join(),
    );
  }
  var id = 0;
  return BoardLayout(
    template.name,
    mask.first.length,
    List.unmodifiable([
      for (final row in mask)
        for (final cell in row.split('')) cell == '#' ? id++ : null,
    ]),
  );
}

class _PatternTemplate {
  const _PatternTemplate(this.name, this.mask);
  final String name;
  final List<String> mask;
  int get boxCount => mask.join().split('').where((cell) => cell == '#').length;
}

// Composed silhouettes keep random results balanced and connected. Reflection,
// rotation and shuffled ordering vary rows, columns and satisfying tapping paths.
const _patterns = [
  _PatternTemplate('Little tray', ['###', '###']),
  _PatternTemplate('Pebble ring', ['###', '#.#', '###']),
  _PatternTemplate('Stepping stones', ['##..', '###.', '.###', '..##']),
  _PatternTemplate('Diamond', ['..#..', '.###.', '#####', '.###.', '..#..']),
  _PatternTemplate('Clover', ['.##.', '####', '####', '.##.']),
  _PatternTemplate('Butterfly', ['#..#', '####', '####', '#..#']),
  _PatternTemplate('Little leaf', ['.#..', '###.', '.###', '..#.']),
  _PatternTemplate('Ribbon', ['###..', '.###.', '..###']),
  _PatternTemplate('Lantern', ['.#.', '###', '###', '###', '.#.']),
  _PatternTemplate('Bridge', ['#...#', '#####', '#####']),
  _PatternTemplate('Picture frame', ['####', '#..#', '#..#', '####']),
  _PatternTemplate('Patchwork', ['####', '####', '####', '####']),
  _PatternTemplate('Bloom', ['..#..', '..#..', '#####', '..#..', '..#..']),
  _PatternTemplate('Little crown', ['##.##', '#####']),
  _PatternTemplate('Cup', ['#..#', '#..#', '####', '####']),
  _PatternTemplate('Soft stairs', ['##..', '###.', '.###']),
  _PatternTemplate('Feather', ['.##', '.##', '###', '##.', '##.']),
  _PatternTemplate('Petals', ['.#.#.', '#####', '.#.#.']),
  _PatternTemplate('Dome', ['.##.', '####', '####', '####']),
  _PatternTemplate('Crescent', ['.###', '##..', '##..', '.###']),
  _PatternTemplate('Hourglass', ['#####', '.###.', '.###.', '#####']),
  _PatternTemplate('Wings', ['##.##', '#####', '.###.', '..#..']),
];

// Park–Miller arithmetic remains in JS's exact integer range. Desktop previews
// therefore use the same pattern ordering as Flutter web and native phones.
class _PatternRandom {
  _PatternRandom(int seed) : _state = seed % 2147483646 + 1;
  int _state;
  int nextInt(int maximum) {
    _state = (_state * 48271) % 2147483647;
    return _state % maximum;
  }
}

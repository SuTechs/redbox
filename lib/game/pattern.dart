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

/// Small-to-large, reproducible Normal boards. Zen's [patternForLevel] stays unchanged.
BoardLayout normalPatternForLevel(
  int level, {
  required int boxCount,
  int seed = defaultPatternSeed,
}) {
  if (level < 1) throw ArgumentError.value(level, 'level', 'Must be positive');
  final candidates = [
    ..._patterns,
    ..._normalPatterns,
  ].where((pattern) => pattern.boxCount == boxCount).toList();
  if (candidates.isEmpty) {
    throw ArgumentError.value(boxCount, 'boxCount', 'Unsupported board size');
  }
  final random = _PatternRandom(seed + level * 97);
  // Cycle a seeded family deck, rather than independently rolling a family.
  // Adjacent levels with the same size visit different families when available.
  final familyOrder = List.generate(candidates.length, (index) => index);
  final deck = _PatternRandom(seed + boxCount * 31);
  for (var i = familyOrder.length - 1; i > 0; i--) {
    final j = deck.nextInt(i + 1);
    final value = familyOrder[i];
    familyOrder[i] = familyOrder[j];
    familyOrder[j] = value;
  }
  final template = candidates[familyOrder[(level - 1) % candidates.length]];
  var mask = template.mask.toList();
  if (random.nextInt(2) == 1) mask = mask.reversed.toList();
  if (random.nextInt(2) == 1) {
    mask = mask.map((row) => row.split('').reversed.join()).toList();
  }
  // Never rotate a tall board into six or seven columns on a small phone.
  if (mask.length <= 5 && random.nextInt(2) == 1) {
    mask = List.generate(
      mask.first.length,
      (column) => List.generate(mask.length, (row) => mask[row][column]).join(),
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

const _normalPatterns = [
  _PatternTemplate('Little square', ['##', '##']),
  _PatternTemplate('Sprout', ['.#.', '###', '.#.']),
  _PatternTemplate('Little step', ['##.', '###', '..#']),
  _PatternTemplate('Tiny arch', ['###', '#.#', '#.#']),
  _PatternTemplate('Kite', ['.#.', '###', '###', '.#.']),
  _PatternTemplate('Nine patch', ['###', '###', '###']),
  _PatternTemplate('Ribbon fold', ['###.', '####', '.###']),
  _PatternTemplate('Open window', ['####', '#..#', '####', '.##.']),
  _PatternTemplate('Garden gate', ['####', '####', '##.#', '.###']),
  _PatternTemplate('Tulip', ['#.#.#', '#####', '.###.', '.###.', '..#..']),
  _PatternTemplate('Paper boat', ['..#..', '.###.', '#####', '#####', '.###.']),
  _PatternTemplate('Soft canopy', [
    '.###.',
    '#####',
    '#####',
    '.###.',
    '.###.',
  ]),
  _PatternTemplate('Woven path', ['.###.', '#####', '#####', '#####', '.###.']),
  _PatternTemplate('Petal frame', [
    '.###.',
    '#####',
    '##.##',
    '#####',
    '.###.',
  ]),
  _PatternTemplate('Courtyard', ['.###.', '#####', '#####', '#####', '####.']),
  _PatternTemplate('Long arch', ['.###.', '#####', '#####', '#####', '#####']),
  _PatternTemplate('Leaf window', [
    '.###.',
    '#####',
    '#####',
    '#####',
    '.###.',
    '.###.',
  ]),
  _PatternTemplate('Tall diamond', [
    '..#..',
    '.###.',
    '#####',
    '#####',
    '.###.',
    '..#..',
  ]),
  _PatternTemplate('Twin steps', [
    '###..',
    '####.',
    '.####',
    '..###',
    '..###',
    '...#.',
  ]),
  _PatternTemplate('Rounded terrace', [
    '.###.',
    '#####',
    '#####',
    '#####',
    '.##..',
  ]),
  _PatternTemplate('Long leaf', [
    '.###.',
    '#####',
    '#####',
    '#####',
    '..#..',
    '..#..',
  ]),
  _PatternTemplate('Garden lantern', [
    '.###.',
    '#####',
    '#####',
    '#####',
    '.###.',
    '..#..',
  ]),
  _PatternTemplate('Window', [
    '.###.',
    '#####',
    '##.##',
    '##.##',
    '#####',
    '.###.',
  ]),
  _PatternTemplate('Cloud', [
    '.###.',
    '#####',
    '#####',
    '#####',
    '#####',
    '.###.',
  ]),
  _PatternTemplate('Wide ribbon', [
    '.###.',
    '#####',
    '#####',
    '#####',
    '#####',
    '#####',
  ]),
  _PatternTemplate('Mosaic', [
    '#####',
    '#####',
    '#####',
    '#####',
    '#####',
    '#####',
  ]),
];

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

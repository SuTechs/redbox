import 'dart:math';

import 'pattern.dart';
export 'pattern.dart';

enum LevelPace {
  easy('Easy', 'Easy does it', 'New shapes. Just one red box to remember.'),
  gentle(
    'Gentle',
    'A little focus',
    'Lovely patterns, with one or two red boxes.',
  ),
  steady(
    'Steady',
    'Find your rhythm',
    'Take it box by box. There’s plenty of time.',
  ),
  playful(
    'Playful',
    'A little more to explore',
    'Fresh shapes. Up to three boxes to remember.',
  ),
  challenge(
    'Curious',
    'A little curiosity',
    'Try another shape. Enjoy each little tap.',
  ),
  endless(
    'Endless',
    'Keep wandering',
    'New arrangements. Your familiar, calm rhythm.',
  );

  const LevelPace(this.label, this.title, this.description);
  final String label;
  final String title;
  final String description;

  static LevelPace forLevel(int level) {
    if (level <= 50) return easy;
    if (level <= 100) return gentle;
    if (level <= 200) return steady;
    if (level <= 300) return playful;
    if (level <= 400) return challenge;
    return endless;
  }
}

bool isBreatherLevel(int level) => level > 50 && level % 5 == 4;

int redBoxCountForLevel(int level) {
  if (level < 1) throw ArgumentError.value(level, 'level', 'Must be positive');
  if (level <= 50 || isBreatherLevel(level)) return 1;
  if (level <= 150) return 2;
  // Later play mixes a little focus with forgiving moments, indefinitely.
  return level % 5 == 1 ? 2 : 3;
}

class GameRound {
  GameRound({
    required this.level,
    required this.layout,
    required Set<int> redIds,
  }) : redIds = Set.unmodifiable(redIds);
  final int level;
  final BoardLayout layout;
  final Set<int> redIds;
  int get safeCount => layout.boxCount - redIds.length;
  LevelPace get pace => LevelPace.forLevel(level);
  bool get isBreather => isBreatherLevel(level);
}

class RoundGenerator {
  RoundGenerator({Random? random, this.patternSeed = defaultPatternSeed})
    : _random = random ?? Random();
  final int patternSeed;
  final Random _random;
  final Map<int, Set<int>> _recentRedIds = {};

  GameRound generate(int level) {
    final layout = patternForLevel(level, seed: patternSeed);
    final redCount = redBoxCountForLevel(level);
    final ids = layout.slots.whereType<int>().toList()..shuffle(_random);
    final redIds = ids.take(redCount).toSet();
    final previous = _recentRedIds.remove(level);
    if (previous != null &&
        previous.length == redIds.length &&
        previous.containsAll(redIds)) {
      redIds.remove(ids[_random.nextInt(redCount)]);
      redIds.add(ids[redCount + _random.nextInt(ids.length - redCount)]);
    }
    _recentRedIds[level] = Set.of(redIds);
    if (_recentRedIds.length > 128) {
      _recentRedIds.remove(_recentRedIds.keys.first);
    }
    return GameRound(level: level, layout: layout, redIds: redIds);
  }
}

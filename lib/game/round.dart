import 'dart:math';

import 'pattern.dart';
import 'play_mode.dart';
import 'difficulty.dart';
export 'play_mode.dart';
export 'difficulty.dart';
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
    this.mode = PlayMode.zen,
    List<(int, int)> swaps = const [],
  }) : redIds = Set.unmodifiable(redIds),
       swaps = List.unmodifiable(swaps);
  final int level;
  final BoardLayout layout;
  final Set<int> redIds;
  final PlayMode mode;
  final List<(int, int)> swaps;
  NormalDifficulty get difficulty => NormalDifficulty.forLevel(level);
  String get difficultyLabel => mode == PlayMode.zen
      ? (isBreather ? 'Easy moment' : pace.label)
      : difficulty.label;
  Duration previewDuration({int seconds = 3}) => mode == PlayMode.zen
      ? Duration(seconds: seconds)
      : Duration(
          milliseconds: (difficulty.previewMilliseconds * seconds / 3).round(),
        );
  int get safeCount => layout.boxCount - redIds.length;
  LevelPace get pace => LevelPace.forLevel(level);
  bool get isBreather => mode == PlayMode.zen && isBreatherLevel(level);
}

class RoundGenerator {
  RoundGenerator({Random? random, this.patternSeed = defaultPatternSeed})
    : _random = random ?? Random();
  final int patternSeed;
  final Random _random;
  final Map<(PlayMode, int), Set<int>> _recentRedIds = {};

  GameRound generate(int level, {PlayMode mode = PlayMode.zen}) {
    final difficulty = NormalDifficulty.forLevel(level);
    final layout = mode == PlayMode.zen
        ? patternForLevel(level, seed: patternSeed)
        : normalPatternForLevel(
            level,
            boxCount: difficulty.boxCountForLevel(level),
            seed: patternSeed,
          );
    final redCount = mode == PlayMode.zen
        ? redBoxCountForLevel(level)
        : difficulty.redCount;
    final historyKey = (mode, level);
    final ids = layout.slots.whereType<int>().toList()..shuffle(_random);
    final redIds = ids.take(redCount).toSet();
    final previous = _recentRedIds.remove(historyKey);
    if (previous != null &&
        previous.length == redIds.length &&
        previous.containsAll(redIds)) {
      redIds.remove(ids[_random.nextInt(redCount)]);
      redIds.add(ids[redCount + _random.nextInt(ids.length - redCount)]);
    }
    _recentRedIds[historyKey] = Set.of(redIds);
    if (_recentRedIds.length > 128) {
      _recentRedIds.remove(_recentRedIds.keys.first);
    }
    final red = redIds.toList()..shuffle(_random);
    final safe = ids.where((id) => !redIds.contains(id)).toList()
      ..shuffle(_random);
    final swaps = <(int, int)>[];
    if (mode == PlayMode.normal) {
      final slotForId = {
        for (var slot = 0; slot < layout.slots.length; slot++)
          if (layout.slots[slot] case final int id) id: slot,
      };
      int distance(int a, int b) {
        final first = slotForId[a]!;
        final second = slotForId[b]!;
        return (first ~/ layout.columns - second ~/ layout.columns).abs() +
            (first % layout.columns - second % layout.columns).abs();
      }

      for (final id in red.take(difficulty.swapCount)) {
        // Prefer nearby pairs so even the first shuffle is easy to follow.
        safe.sort((a, b) => distance(id, a).compareTo(distance(id, b)));
        final closest = safe
            .takeWhile(
              (other) => distance(id, other) == distance(id, safe.first),
            )
            .length;
        swaps.add((id, safe.removeAt(_random.nextInt(closest))));
      }
    }
    return GameRound(
      level: level,
      layout: layout,
      redIds: redIds,
      mode: mode,
      swaps: swaps,
    );
  }
}

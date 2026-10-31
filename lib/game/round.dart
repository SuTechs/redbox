import 'dart:math';

import 'difficulty.dart';
import 'pattern.dart';
import 'play_mode.dart';
export 'play_mode.dart';
export 'difficulty.dart';
export 'pattern.dart';

class GameRound {
  GameRound({
    required this.level,
    required this.layout,
    required Set<int> redIds,
    required this.mode,
    this.profile = LayoutProfile.portrait,
    List<(int, int)> swaps = const [],
  }) : redIds = Set.unmodifiable(redIds),
       swaps = List.unmodifiable(swaps);

  /// Zen uses zero internally, never a level counter or progression input.
  final int level;
  final BoardLayout layout;
  final Set<int> redIds;
  final PlayMode mode;
  final LayoutProfile profile;
  final List<(int, int)> swaps;
  NormalDifficulty get difficulty => NormalDifficulty.forLevel(level);
  String get difficultyLabel =>
      mode == PlayMode.zen ? 'Just play and relax' : difficulty.label;
  Duration get swapDuration => mode == PlayMode.zen
      ? Duration.zero
      : Duration(milliseconds: difficulty.swapMilliseconds);
  Duration previewDuration({int seconds = 3}) => mode == PlayMode.zen
      ? Duration(seconds: seconds)
      : Duration(
          milliseconds: (difficulty.previewMilliseconds * seconds / 3).round(),
        );
  int get safeCount => layout.boxCount - redIds.length;
  GameRound withLayout(BoardLayout fitted, LayoutProfile profile) => GameRound(
    level: level,
    layout: fitted,
    redIds: redIds,
    mode: mode,
    profile: profile,
    swaps: swaps,
  );
}

class RoundGenerator {
  RoundGenerator({Random? random, this.patternSeed = defaultPatternSeed})
    : _random = random ?? Random();
  final int patternSeed;
  final Random _random;
  final Map<String, Set<int>> _recentRedIds = {};
  final List<int> _zenDeck = [];
  int? _lastZenFamily;

  GameRound generate(
    int level, {
    PlayMode mode = PlayMode.normal,
    LayoutProfile profile = LayoutProfile.portrait,
  }) {
    if (mode == PlayMode.zen) return generateZen(profile: profile);
    final d = NormalDifficulty.forLevel(level);
    final layout = normalPatternForLevel(
      level,
      boxCount: d.boxCountForLevel(level),
      seed: patternSeed,
      profile: profile,
    );
    return _round(level, mode, layout, d.redCount, d.swapCount, profile);
  }

  GameRound generateZen({LayoutProfile profile = LayoutProfile.portrait}) {
    if (_zenDeck.isEmpty) {
      _zenDeck.addAll(
        List.generate(zenPatternNames.length, (i) => i)..shuffle(_random),
      );
      if (_zenDeck.last == _lastZenFamily) {
        final first = _zenDeck[0];
        _zenDeck[0] = _zenDeck.last;
        _zenDeck[_zenDeck.length - 1] = first;
      }
    }
    final family = _zenDeck.removeLast();
    _lastZenFamily = family;
    var layout = zenPattern(family, _random.nextInt(8));
    layout = orientBoard(layout, profile);
    final reds = layout.boxCount >= 10 && _random.nextInt(5) == 0 ? 2 : 1;
    return _round(0, PlayMode.zen, layout, reds, 0, profile);
  }

  GameRound fit(GameRound round, LayoutProfile profile) {
    if (round.profile == profile) return round;
    final layout = round.mode == PlayMode.normal
        ? normalPatternForLevel(
            round.level,
            boxCount: round.layout.boxCount,
            seed: patternSeed,
            profile: profile,
          )
        : orientBoard(round.layout, profile);
    return round.withLayout(layout, profile);
  }

  GameRound _round(
    int level,
    PlayMode mode,
    BoardLayout layout,
    int redCount,
    int swapCount,
    LayoutProfile profile,
  ) {
    final key = '${mode.name}:$level:${layout.mask.join('/')}';
    final ids = layout.slots.whereType<int>().toList()..shuffle(_random);
    final reds = ids.take(redCount).toSet();
    final previous = _recentRedIds.remove(key);
    if (previous != null &&
        previous.length == reds.length &&
        previous.containsAll(reds)) {
      reds.remove(ids[_random.nextInt(redCount)]);
      reds.add(ids[redCount + _random.nextInt(ids.length - redCount)]);
    }
    _recentRedIds[key] = Set.of(reds);
    if (_recentRedIds.length > 128) {
      _recentRedIds.remove(_recentRedIds.keys.first);
    }
    final red = reds.toList()..shuffle(_random);
    final safe = ids.where((id) => !reds.contains(id)).toList()
      ..shuffle(_random);
    final slots = {
      for (var i = 0; i < layout.slots.length; i++)
        if (layout.slots[i] case final int id) id: i,
    };
    int distance(int a, int b) =>
        (slots[a]! ~/ layout.columns - slots[b]! ~/ layout.columns).abs() +
        (slots[a]! % layout.columns - slots[b]! % layout.columns).abs();
    final swaps = <(int, int)>[];
    for (final id in red.take(swapCount)) {
      safe.sort((a, b) => distance(id, a).compareTo(distance(id, b)));
      final tied = safe
          .takeWhile((other) => distance(id, other) == distance(id, safe.first))
          .length;
      swaps.add((id, safe.removeAt(_random.nextInt(tied))));
    }
    return GameRound(
      level: level,
      mode: mode,
      layout: layout,
      redIds: reds,
      swaps: swaps,
      profile: profile,
    );
  }
}

/// Preserve identities when rotating a Zen silhouette.
BoardLayout orientBoard(BoardLayout board, LayoutProfile profile) {
  final shouldTranspose = profile == LayoutProfile.landscape
      ? board.rows > board.columns
      : board.columns > board.rows;
  if (!shouldTranspose) return board;
  return BoardLayout(
    board.name,
    board.rows,
    List.unmodifiable([
      for (var c = 0; c < board.columns; c++)
        for (var r = 0; r < board.rows; r++) board.slots[r * board.columns + c],
    ]),
  );
}

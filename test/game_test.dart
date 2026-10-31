import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:redbox/game/game_controller.dart';
import 'package:redbox/game/round.dart';

void main() {
  const samples = [1, 2, 3, 4, 5, 50, 70, 100, 1000];
  for (final level in samples) {
    test('Level $level produces a reproducible, connected seeded pattern', () {
      final pattern = patternForLevel(level, seed: 20261002);
      final repeat = patternForLevel(level, seed: 20261002);
      expect(repeat.mask, pattern.mask);
      expect(repeat.name, pattern.name);
      expect(repeat.columns, pattern.columns);
      expect(pattern.boxCount, inInclusiveRange(6, 16));
      expect(pattern.rows, inInclusiveRange(2, 5));
      expect(pattern.columns, inInclusiveRange(2, 5));
      expect(
        pattern.slots.whereType<int>().toList(),
        List.generate(pattern.boxCount, (i) => i),
      );
      expect(_connected(pattern), isTrue);
      expect(pattern.mask.first.contains('#'), isTrue);
      expect(pattern.mask.last.contains('#'), isTrue);
    });
  }

  test('Shape variety starts immediately and continues at high levels', () {
    for (final seed in [20261002, 1, 42, -17]) {
      final shapes = <String>{};
      String? previous;
      for (var level = 1; level <= 220; level++) {
        final pattern = patternForLevel(level, seed: seed);
        final shape = pattern.mask.join('/');
        expect(shape, isNot(previous), reason: 'Seed $seed, level $level');
        expect(_connected(pattern), isTrue);
        shapes.add(shape);
        previous = shape;
      }
      expect(shapes.length, greaterThan(25));
      expect(
        List.generate(
          5,
          (i) => patternForLevel(i + 1, seed: seed).name,
        ).toSet().length,
        5,
      );
    }
    expect(
      samples
          .map((level) => patternForLevel(level, seed: 42).mask.join('/'))
          .toList(),
      isNot(
        samples
            .map(
              (level) => patternForLevel(level, seed: 20261002).mask.join('/'),
            )
            .toList(),
      ),
    );
    expect(() => patternForLevel(0), throwsArgumentError);
  });

  testWidgets(
    'Input waits for preview and fade; safe taps are order independent',
    (tester) async {
      final game = GameController(generator: RoundGenerator(random: Random(9)));
      addTearDown(game.dispose);
      game.start(1, preview: const Duration(seconds: 3));
      final forbidden = game.round.redIds.single;
      final safe = game.round.layout.slots
          .whereType<int>()
          .where((id) => id != forbidden)
          .toList()
          .reversed
          .toList();
      expect(game.tap(safe.first), TapResult.ignored);
      await tester.pump(const Duration(seconds: 3));
      expect(game.phase, RoundPhase.fade);
      expect(game.tap(safe.first), TapResult.ignored);
      await tester.pump(const Duration(milliseconds: 280));
      expect(game.phase, RoundPhase.input);
      expect(game.isRed(forbidden), isFalse);
      expect(game.tap(-1), TapResult.ignored);
      expect(game.tap(safe[0]), TapResult.correct);
      expect(game.tap(safe[0]), TapResult.ignored);
      for (final id in safe.skip(1).take(safe.length - 2)) {
        expect(game.tap(id), TapResult.correct);
      }
      expect(game.tap(safe.last), TapResult.complete);
      expect(game.phase, RoundPhase.complete);
      expect(game.selectedCount, safe.length);
      expect(game.isRed(forbidden), isFalse);
      expect(safe.every(game.isRed), isTrue);
    },
  );

  testWidgets(
    'A mistake clears selections; retry starts a fresh pattern at the same level',
    (tester) async {
      final game = GameController(
        generator: RoundGenerator(random: Random(33)),
      );
      addTearDown(game.dispose);
      game.start(4, preview: const Duration(seconds: 3), reducedMotion: true);
      final initial = game.round;
      await tester.pump(const Duration(seconds: 3));
      final safe = initial.layout.slots.whereType<int>().firstWhere(
        (id) => !initial.redIds.contains(id),
      );
      expect(game.tap(safe), TapResult.correct);
      expect(game.tap(initial.redIds.first), TapResult.wrong);
      expect(game.phase, RoundPhase.retry);
      expect(game.selectedCount, 0);
      expect(initial.redIds.every(game.isRed), isTrue);
      game.retry(preview: const Duration(seconds: 5));
      expect(game.round.level, initial.level);
      expect(game.round.layout.mask, initial.layout.mask);
      expect(game.round.redIds, isNot(initial.redIds));
      expect(game.selectedCount, 0);
      expect(game.phase, RoundPhase.preview);
      expect(game.tap(safe), TapResult.ignored);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 280));
      expect(game.phase, RoundPhase.input);
    },
  );

  testWidgets('Pause cancels timers and resume replays the same round', (
    tester,
  ) async {
    final game = GameController(generator: RoundGenerator(random: Random(5)));
    addTearDown(game.dispose);
    game.start(10000, preview: const Duration(seconds: 3));
    final initial = game.round;
    await tester.pump(const Duration(seconds: 1));
    game.pause();
    await tester.pump(const Duration(seconds: 20));
    expect(game.phase, RoundPhase.paused);
    expect(
      game.tap(initial.layout.slots.whereType<int>().first),
      TapResult.ignored,
    );
    game.resume(preview: const Duration(seconds: 3), reducedMotion: true);
    expect(game.phase, RoundPhase.preview);
    expect(identical(game.round, initial), isTrue);
    await tester.pump(const Duration(seconds: 3));
    expect(game.phase, RoundPhase.input);
    for (final id in initial.layout.slots.whereType<int>().where(
      (id) => !initial.redIds.contains(id),
    )) {
      game.tap(id);
    }
    game.pause();
    game.resume(preview: const Duration(seconds: 3));
    expect(game.phase, RoundPhase.complete);
    expect(game.selectedCount, initial.safeCount);
  });
}

bool _connected(BoardLayout pattern) {
  final occupied = <int>{
    for (var i = 0; i < pattern.slots.length; i++)
      if (pattern.slots[i] != null) i,
  };
  final seen = <int>{occupied.first};
  final queue = [occupied.first];
  for (var cursor = 0; cursor < queue.length; cursor++) {
    final index = queue[cursor];
    final row = index ~/ pattern.columns;
    final col = index % pattern.columns;
    for (final (r, c) in [
      (row - 1, col),
      (row + 1, col),
      (row, col - 1),
      (row, col + 1),
    ]) {
      if (r < 0 || r >= pattern.rows || c < 0 || c >= pattern.columns) continue;
      final neighbor = r * pattern.columns + c;
      if (occupied.contains(neighbor) && seen.add(neighbor)) {
        queue.add(neighbor);
      }
    }
  }
  return seen.length == occupied.length;
}

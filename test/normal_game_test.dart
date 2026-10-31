import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:redbox/game/game_controller.dart';
import 'package:redbox/game/round.dart';

void main() {
  test('Normal memory grows through 2,000; preview respects memory load', () {
    var previous = 0;
    for (var level = 1; level <= 10000; level++) {
      final d = NormalDifficulty.forLevel(level);
      expect(d.redCount, inInclusiveRange(previous, 20));
      expect(d.boxCountForLevel(level), inInclusiveRange(4, 40));
      expect(d.boxCountForLevel(level) - d.redCount, inInclusiveRange(3, 23));
      expect(d.swapCount, inInclusiveRange(0, 4));
      previous = d.redCount;
    }
    for (final (l, r, ms, moves) in [
      (1, 1, 3000, 0),
      (300, 10, 3700, 2),
      (500, 12, 4400, 2),
      (600, 13, 4600, 3),
      (1296, 18, 5300, 4),
      (1300, 18, 5200, 4),
      (2000, 20, 6000, 4),
    ]) {
      final d = NormalDifficulty.forLevel(l);
      expect((d.redCount, d.previewMilliseconds, d.swapCount), (r, ms, moves));
    }
    expect(
      List.generate(
        10,
        (i) => NormalDifficulty.forLevel(i + 1).boxCountForLevel(i + 1),
      ),
      [4, 5, 6, 6, 7, 7, 8, 8, 9, 10],
    );
    expect(() => NormalDifficulty.forLevel(0), throwsArgumentError);
  });
  test('Seeded Normal shapes are connected and fit both layout profiles', () {
    for (final seed in [-17, 42, 20261002]) {
      for (final profile in LayoutProfile.values) {
        String? previous;
        for (var l = 1; l <= 2100; l++) {
          final d = NormalDifficulty.forLevel(l);
          final count = d.boxCountForLevel(l);
          final b = normalPatternForLevel(
            l,
            boxCount: count,
            seed: seed,
            profile: profile,
          );
          expect(b.boxCount, count);
          expect(
            b.mask,
            normalPatternForLevel(
              l,
              boxCount: count,
              seed: seed,
              profile: profile,
            ).mask,
          );
          expect(
            b.columns,
            lessThanOrEqualTo(profile == LayoutProfile.portrait ? 6 : 9),
          );
          expect(
            b.rows,
            lessThanOrEqualTo(profile == LayoutProfile.portrait ? 8 : 5),
          );
          expect(connected(b), true, reason: 'level $l $profile seed $seed');
          final key = b.mask.join('/');
          expect(
            key,
            isNot(previous),
            reason: 'repeated shape $l $profile seed $seed',
          );
          previous = key;
        }
      }
    }
  });
  test('Late forty-box levels have broad seeded variety, rather than a short shape cycle', () {
    for (final profile in LayoutProfile.values) {
      final shapes = <String>{};
      for (var l = 1200; l < 2200; l++) {
        shapes.add(
          normalPatternForLevel(
            l,
            boxCount: 40,
            seed: 42,
            profile: profile,
          ).mask.join('/'),
        );
      }
      expect(shapes.length, greaterThan(100), reason: '$profile');
    }
  });
  test(
    'Zen is an endless shuffled deck of beautiful non-rectangular easy shapes',
    () {
      final g = RoundGenerator(random: Random(42));
      String? previous;
      final families = <String>{};
      for (var i = 0; i < 1000; i++) {
        final r = g.generateZen();
        expect(r.level, 0);
        expect(r.layout.boxCount, inInclusiveRange(6, 16));
        expect(r.layout.boxCount, lessThan(r.layout.rows * r.layout.columns));
        expect(connected(r.layout), true);
        expect(r.layout.name, isNot(previous));
        expect(r.redIds.length, inInclusiveRange(1, 2));
        if (r.layout.boxCount < 10) expect(r.redIds.length, 1);
        expect(r.swaps, isEmpty);
        expect(r.previewDuration(), const Duration(seconds: 3));
        families.add(r.layout.name);
        previous = r.layout.name;
      }
      expect(families.length, greaterThan(12));
    },
  );
  test('Retry changes Normal reds, preserves shapes and uses disjoint identity swaps', () {
    final g = RoundGenerator(random: Random(5));
    for (final l in [1, 50, 300, 500, 600, 1296, 1300, 2000, 10000]) {
      final a = g.generate(l);
      final b = g.generate(l);
      expect(a.redIds, isNot(b.redIds));
      expect(a.layout.mask, b.layout.mask);
      final moved = <int>{};
      for (final (red, safe) in a.swaps) {
        expect(a.redIds, contains(red));
        expect(a.redIds, isNot(contains(safe)));
        expect(moved.add(red), true);
        expect(moved.add(safe), true);
      }
    }
  });
  testWidgets(
    'Swaps carry remembered identities, lock input and allow a full win',
    (tester) async {
      final game = GameController(generator: RoundGenerator(random: Random(7)));
      addTearDown(game.dispose);
      game.start(
        50,
        mode: PlayMode.normal,
        preview: const Duration(milliseconds: 10),
      );
      final original = Map.of(game.positions);
      final safe = game.round.layout.slots
          .whereType<int>()
          .where((id) => !game.round.redIds.contains(id))
          .toList();
      expect(game.tap(safe.first), TapResult.ignored);
      await tester.pump(const Duration(milliseconds: 10));
      expect(game.phase, RoundPhase.fade);
      await tester.pump(const Duration(milliseconds: 280));
      for (var i = 0; i < game.round.swaps.length; i++) {
        expect(game.phase, RoundPhase.shuffle);
        expect(game.shuffleStep, i + 1);
        expect(game.tap(safe.first), TapResult.ignored);
        expect(game.round.redIds.any(game.isRed), isFalse);
        await tester.pump(game.swapDuration + GameController.swapSettle);
      }
      expect(game.phase, RoundPhase.input);
      for (final (red, safe) in game.round.swaps) {
        expect(game.positions[red], original[safe]);
        expect(game.positions[safe], original[red]);
      }
      expect(game.positions.values.toSet().length, game.round.layout.boxCount);
      for (final id in safe) {
        game.tap(id);
      }
      expect(game.phase, RoundPhase.complete);
      expect(game.selectedCount, game.round.safeCount);
    },
  );

  testWidgets('A moved red still fails; retry resets positions and memory', (
    tester,
  ) async {
    final game = GameController(generator: RoundGenerator(random: Random(8)));
    addTearDown(game.dispose);
    game.start(50, mode: PlayMode.normal, preview: Duration.zero);
    final original = Map.of(game.positions);
    final initial = game.round;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    await tester.pump(game.swapDuration + GameController.swapSettle);
    expect(game.tap(initial.swaps.first.$1), TapResult.wrong);
    expect(game.phase, RoundPhase.retry);
    game.retry(preview: Duration.zero);
    expect(game.round.mode, PlayMode.normal);
    expect(game.round.redIds, isNot(initial.redIds));
    expect(game.positions, original);
    game.pause(); // No pending retry timer at test teardown.
  });

  for (final pausePhase in [
    RoundPhase.preview,
    RoundPhase.fade,
    RoundPhase.shuffle,
    RoundPhase.input,
  ]) {
    testWidgets(
      'Pause during ${pausePhase.name} replays the same planned round',
      (tester) async {
        final game = GameController(
          generator: RoundGenerator(random: Random(9)),
        );
        addTearDown(game.dispose);
        game.start(
          50,
          mode: PlayMode.normal,
          preview: const Duration(seconds: 1),
        );
        final round = game.round;
        final original = Map.of(game.positions);
        if (pausePhase != RoundPhase.preview) {
          await tester.pump(const Duration(seconds: 1));
        }
        if ([RoundPhase.shuffle, RoundPhase.input].contains(pausePhase)) {
          await tester.pump(const Duration(milliseconds: 280));
        }
        if (pausePhase == RoundPhase.input) {
          await tester.pump(game.swapDuration + GameController.swapSettle);
        }
        expect(game.phase, pausePhase);
        game.pause();
        await tester.pump(const Duration(seconds: 30));
        expect(game.phase, RoundPhase.paused);
        game.resume(preview: const Duration(seconds: 1));
        expect(identical(game.round, round), isTrue);
        expect(game.phase, RoundPhase.preview);
        expect(game.shuffleStep, 0);
        expect(game.positions, original);
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 280));
        await tester.pump(game.swapDuration + GameController.swapSettle);
        expect(game.phase, RoundPhase.input);
        for (final (red, safe) in round.swaps) {
          expect(game.positions[red], original[safe]);
        }
      },
    );
  }

  testWidgets(
    'Reduced motion disables shuffles instead of teleporting hidden boxes',
    (tester) async {
      final game = GameController(generator: RoundGenerator());
      addTearDown(game.dispose);
      game.start(
        400,
        mode: PlayMode.normal,
        preview: const Duration(milliseconds: 10),
        reducedMotion: true,
      );
      final original = Map.of(game.positions);
      expect(game.round.swaps.length, 2);
      expect(game.willShuffle, isFalse);
      await tester.pump(const Duration(milliseconds: 10));
      expect(game.phase, RoundPhase.input);
      expect(game.positions, original);
      expect(game.shuffleStep, 0);
    },
  );

  testWidgets('Disposing during a shuffle cancels further notifications', (
    tester,
  ) async {
    final game = GameController(generator: RoundGenerator());
    game.start(150, mode: PlayMode.normal, preview: Duration.zero);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    expect(game.phase, RoundPhase.shuffle);
    var notifications = 0;
    game.addListener(() => notifications++);
    game.dispose();
    await tester.pump(const Duration(seconds: 30));
    expect(notifications, 0);
  });
}

bool connected(BoardLayout b) {
  final cells = {
    for (var i = 0; i < b.slots.length; i++)
      if (b.slots[i] != null) i,
  };
  final seen = {cells.first};
  final queue = [cells.first];
  for (var i = 0; i < queue.length; i++) {
    final p = queue[i];
    for (final n in [
      p - b.columns,
      p + b.columns,
      if (p % b.columns > 0) p - 1,
      if (p % b.columns < b.columns - 1) p + 1,
    ]) {
      if (cells.contains(n) && seen.add(n)) queue.add(n);
    }
  }
  return seen.length == cells.length;
}

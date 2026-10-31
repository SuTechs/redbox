import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:redbox/game/game_controller.dart';
import 'package:redbox/game/round.dart';

void main() {
  test('Normal grows in memory load, speed, board size and movement', () {
    var previousReds = 0;
    var previousPreview = 3000;
    var previousSwaps = 0;
    for (var level = 1; level <= 2000; level++) {
      final difficulty = NormalDifficulty.forLevel(level);
      expect(difficulty.redCount, inInclusiveRange(previousReds, 10));
      expect(
        difficulty.previewMilliseconds,
        inInclusiveRange(1800, previousPreview),
      );
      expect(difficulty.swapCount, inInclusiveRange(previousSwaps, 5));
      expect(difficulty.boxCountForLevel(level), inInclusiveRange(4, 24));
      previousReds = difficulty.redCount;
      previousPreview = difficulty.previewMilliseconds;
      previousSwaps = difficulty.swapCount;
    }
    expect(NormalDifficulty.forLevel(1).redCount, 1);
    expect(NormalDifficulty.forLevel(5).redCount, 2);
    expect(NormalDifficulty.forLevel(19).swapCount, 0);
    expect(NormalDifficulty.forLevel(20).swapCount, 1);
    expect(NormalDifficulty.forLevel(400).redCount, 10);
    expect(() => NormalDifficulty.forLevel(0), throwsArgumentError);
  });

  test(
    'Opening teaches memory without busywork and holds speed for 29 levels',
    () {
      final counts = [4, 5, 6, 6, 7, 8, 8, 9, 9, 10];
      final reds = [1, 1, 2, 2, 2, 3, 3, 3, 3, 4];
      for (var level = 1; level <= 10; level++) {
        final d = NormalDifficulty.forLevel(level);
        expect(d.boxCountForLevel(level), counts[level - 1]);
        expect(d.redCount, reds[level - 1]);
      }
      for (var level = 1; level <= 2000; level++) {
        final d = NormalDifficulty.forLevel(level);
        expect(
          d.redCount / d.boxCountForLevel(level),
          greaterThanOrEqualTo(.2),
        );
        expect(d.boxCountForLevel(level) - d.redCount, lessThanOrEqualTo(14));
        if (level < 30) expect(d.previewMilliseconds, 3000);
      }
    },
  );

  test(
    'Small-to-large Normal patterns are seeded, connected and phone-sized',
    () {
      final generator = RoundGenerator(random: Random(71));
      final masks = <String>{};
      for (final seed in [-17, 1, 42, 20261002]) {
        String? previousMask;
        for (var level = 1; level <= 1000; level++) {
          final difficulty = NormalDifficulty.forLevel(level);
          final count = difficulty.boxCountForLevel(level);
          final layout = normalPatternForLevel(
            level,
            boxCount: count,
            seed: seed,
          );
          expect(
            layout.mask,
            normalPatternForLevel(level, boxCount: count, seed: seed).mask,
          );
          expect(layout.boxCount, count);
          expect(layout.columns, inInclusiveRange(2, 5));
          expect(layout.rows, inInclusiveRange(2, 7));
          expect(
            layout.slots.whereType<int>().toList(),
            List.generate(count, (i) => i),
          );
          final cells = {
            for (var i = 0; i < layout.slots.length; i++)
              if (layout.slots[i] != null) i,
          };
          final reached = {cells.first};
          final queue = [cells.first];
          for (var i = 0; i < queue.length; i++) {
            final slot = queue[i];
            for (final neighbor in [
              slot - layout.columns,
              slot + layout.columns,
              if (slot % layout.columns > 0) slot - 1,
              if (slot % layout.columns < layout.columns - 1) slot + 1,
            ]) {
              if (cells.contains(neighbor) && reached.add(neighbor)) {
                queue.add(neighbor);
              }
            }
          }
          expect(
            reached,
            cells,
            reason: 'Disconnected level $level seed $seed',
          );
          final mask = layout.mask.join('/');
          expect(
            mask,
            isNot(previousMask),
            reason: 'Repeated adjacent shape at level $level seed $seed',
          );
          previousMask = mask;
          masks.add(mask);
          final round = generator.generate(level, mode: PlayMode.normal);
          expect(round.redIds.length, difficulty.redCount);
          expect(round.safeCount, inInclusiveRange(3, 14));
          expect(round.swaps.length, difficulty.swapCount);
          final moved = <int>{};
          for (final (red, safe) in round.swaps) {
            expect(round.redIds, contains(red));
            expect(round.redIds, isNot(contains(safe)));
            expect(moved.add(red), isTrue);
            expect(moved.add(safe), isTrue);
          }
        }
      }
      expect(masks.length, greaterThan(20));
    },
  );

  test(
    'Retries vary reds independently per mode and keep each seeded shape',
    () {
      final generator = RoundGenerator(random: Random(91));
      for (final mode in PlayMode.values) {
        for (final level in [1, 5, 10, 50, 100, 150, 1000, 1000000]) {
          var previous = generator.generate(level, mode: mode);
          for (var attempt = 0; attempt < 20; attempt++) {
            final fresh = generator.generate(level, mode: mode);
            expect(fresh.redIds, isNot(previous.redIds));
            expect(fresh.layout.mask, previous.layout.mask);
            previous = fresh;
          }
        }
      }
    },
  );

  test(
    'Zen retains the original patterns, memory load and preview options',
    () {
      for (final level in [1, 50, 70, 100, 150, 151, 1000, 1000000]) {
        final round = RoundGenerator().generate(level, mode: PlayMode.zen);
        expect(round.layout.mask, patternForLevel(level).mask);
        expect(round.redIds.length, redBoxCountForLevel(level));
        expect(round.swaps, isEmpty);
        expect(round.previewDuration(seconds: 5), const Duration(seconds: 5));
      }
      final normal = RoundGenerator().generate(400, mode: PlayMode.normal);
      expect(normal.previewDuration(), const Duration(milliseconds: 1800));
      expect(
        normal.previewDuration(seconds: 5),
        greaterThan(normal.previewDuration()),
      );
    },
  );

  testWidgets(
    'Swaps carry remembered identities, lock input and allow a full win',
    (tester) async {
      final game = GameController(generator: RoundGenerator(random: Random(7)));
      addTearDown(game.dispose);
      game.start(
        20,
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
        await tester.pump(
          GameController.swapDuration + GameController.swapSettle,
        );
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
    game.start(20, mode: PlayMode.normal, preview: Duration.zero);
    final original = Map.of(game.positions);
    final initial = game.round;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    await tester.pump(GameController.swapDuration + GameController.swapSettle);
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
          20,
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
          await tester.pump(
            GameController.swapDuration + GameController.swapSettle,
          );
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
        await tester.pump(
          GameController.swapDuration + GameController.swapSettle,
        );
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
      expect(game.round.swaps.length, 5);
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

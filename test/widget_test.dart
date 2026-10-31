import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redbox/core/settings.dart';
import 'package:redbox/core/music.dart';
import 'package:redbox/core/music_track.dart';
import 'package:redbox/core/sound.dart';
import 'package:redbox/game/round.dart';
import 'package:redbox/main.dart';
import 'package:redbox/ui/pocket_widgets.dart';
import 'package:redbox/ui/pocket_theme.dart';

class RecordingSounds implements SoundEffects {
  final List<GameCue> played = [];
  int stops = 0;
  @override
  Future<void> play(GameCue cue) async {
    played.add(cue);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {}
}

class RecordingMusic implements MusicPlayback {
  final List<MusicTrack> played = [];
  @override
  Future<void> play(MusicTrack track) async {
    played.add(track);
  }

  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> dispose() async {}
}

Future<(AppSettings, RecordingSounds)> mount(
  WidgetTester tester, {
  int level = 1,
  double scale = 1,
  PlayMode mode = PlayMode.zen,
  bool reducedMotion = true,
}) async {
  final settings = AppSettings(store: MemorySettingsStore())
    ..mode = mode
    ..level = level
    ..reducedMotion = reducedMotion
    ..haptics = false;
  final sounds = RecordingSounds();
  await tester.pumpWidget(
    RedBoxApp(
      settings: settings,
      sounds: sounds,
      musicPlayback: RecordingMusic(),
      generator: RoundGenerator(random: Random(42)),
    ),
  );
  if (scale != 1) {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: RedBoxApp(
          settings: settings,
          sounds: sounds,
          musicPlayback: RecordingMusic(),
          generator: RoundGenerator(random: Random(42)),
        ),
      ),
    );
  }
  return (settings, sounds);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> begin(WidgetTester tester) async {
  final play = find.byKey(const ValueKey('play'));
  await tester.ensureVisible(play);
  await tapVisible(tester, play);
  await tester.pump();
}

Future<void> showLevel(WidgetTester tester, int level) =>
    tester.scrollUntilVisible(
      find.byKey(ValueKey('level-$level')),
      160,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );

List<int> tileIds(WidgetTester tester) => tester
    .widgetList<PocketTile>(find.byType(PocketTile))
    .map((tile) => tile.id)
    .toList();

void main() {
  testWidgets('Home switches modes and a Normal win unlocks only Normal', (
    tester,
  ) async {
    final (settings, _) = await mount(tester, level: 7);
    expect(settings.zenLevel, 7);
    await tapVisible(tester, find.text('Normal'));
    expect(settings.mode, PlayMode.normal);
    expect(settings.level, 1);
    await begin(tester);
    final reds = tester
        .widgetList<PocketTile>(find.byType(PocketTile))
        .where((tile) => tile.red)
        .map((tile) => tile.id)
        .toSet();
    expect(reds.length, 1);
    await tester.pump(const Duration(seconds: 3));
    for (final id in tileIds(tester).where((id) => !reds.contains(id))) {
      await tapVisible(tester, find.byKey(ValueKey('box-$id')));
    }
    expect(find.text('Lovely!'), findsOneWidget);
    expect(settings.normalLevel, 2);
    expect(settings.zenLevel, 7);
    await tapVisible(tester, find.byTooltip('Return home'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Zen'));
    expect(settings.level, 7);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });

  testWidgets(
    'Settings switches Zen and the levels page follows that progress',
    (tester) async {
      final (settings, _) = await mount(tester, level: 73);
      await tapVisible(tester, find.byKey(const ValueKey('browse-levels')));
      await tester.pumpAndSettle();
      expect(find.text('ZEN LEVELS'), findsOneWidget);
      expect(find.text('51–100'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.widgetWithText(SwitchListTile, 'Zen mode'));
      await tapVisible(tester, find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(settings.mode, PlayMode.normal);
      expect(find.text('NORMAL LEVELS'), findsOneWidget);
      expect(find.text('1–50'), findsOneWidget);
      expect(find.text('Play level 1'), findsOneWidget);
      expect(find.text('Easy moments every 5 levels'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    },
  );

  testWidgets(
    'A visible shuffle moves square boxes, hides red and locks taps',
    (tester) async {
      final (settings, _) = await mount(
        tester,
        level: 10,
        mode: PlayMode.normal,
        reducedMotion: false,
      );
      await begin(tester);
      final red = tester
          .widgetList<PocketTile>(find.byType(PocketTile))
          .firstWhere((tile) => tile.red)
          .id;
      final original = tester.getRect(find.byKey(ValueKey('box-$red')));
      await tester.pump(const Duration(milliseconds: 2400));
      await tester.pump(const Duration(milliseconds: 280));
      expect(find.text('Follow the boxes'), findsOneWidget);
      expect(
        tester
            .widgetList<PocketTile>(find.byType(PocketTile))
            .every((tile) => tile.onTap == null && !tile.red),
        isTrue,
      );
      // The animation has its own frames before the settling interval ends.
      await tester.pump(const Duration(milliseconds: 325));
      final moved = tester.getRect(find.byKey(ValueKey('box-$red')));
      expect(moved.topLeft, isNot(original.topLeft));
      expect(moved.width, closeTo(moved.height, .01));
      await tester.pump(const Duration(milliseconds: 505));
      expect(find.text('Tap the others'), findsOneWidget);
      expect(
        tester
            .widgetList<PocketTile>(find.byType(PocketTile))
            .every((tile) => tile.onTap != null),
        isTrue,
      );
      await tapVisible(tester, find.byKey(ValueKey('box-$red')));
      expect(find.text("Let's try that again"), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    },
  );

  testWidgets('An active round cannot change modes in pause settings', (
    tester,
  ) async {
    final (settings, _) = await mount(tester, mode: PlayMode.normal);
    await begin(tester);
    await tapVisible(tester, find.byTooltip('Pause game'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Music & sound'));
    await tester.pumpAndSettle();
    final toggle = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Zen mode'),
    );
    expect(toggle.onChanged, isNull);
    expect(find.text('Return home to change modes'), findsOneWidget);
    expect(settings.mode, PlayMode.normal);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });

  testWidgets(
    'Turning on reduced motion during a shuffle reveals a fair preview',
    (tester) async {
      final (settings, _) = await mount(
        tester,
        level: 10,
        mode: PlayMode.normal,
        reducedMotion: false,
      );
      await begin(tester);
      await tester.pump(const Duration(milliseconds: 2400));
      await tester.pump(const Duration(milliseconds: 280));
      expect(find.text('Follow the boxes'), findsOneWidget);
      settings.update(reducedMotion: true);
      await tester.pump();
      expect(find.text('Watch the red boxes'), findsOneWidget);
      expect(
        tester
            .widgetList<PocketTile>(find.byType(PocketTile))
            .where((tile) => tile.red)
            .length,
        4,
      );
      await tester.pump(const Duration(milliseconds: 2400));
      expect(find.text('Tap the others'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    },
  );

  for (final textScale in [1.2, 1.4, 1.8, 2.0]) {
    testWidgets(
      'Normal board remains reachable at system text scale $textScale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final (settings, _) = await mount(
          tester,
          level: 151,
          mode: PlayMode.normal,
        );
        final homeError = tester.takeException();
        expect(homeError, isNull, reason: 'Home with large text');
        await begin(tester);
        final gameError = tester.takeException();
        expect(gameError, isNull, reason: 'Game with large text');
        await tester.pump();
        final board = tester.getRect(find.byKey(const ValueKey('game-board')));
        expect(board.top, greaterThanOrEqualTo(0));
        expect(board.bottom, lessThanOrEqualTo(568));
        await tester.ensureVisible(
          find.byKey(ValueKey('box-${tileIds(tester).last}')),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        settings.dispose();
      },
    );
  }

  for (final level in [10, 40, 100, 151, 1000]) {
    testWidgets(
      'Normal level $level keeps 48px square targets on a small phone',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 20);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final (settings, _) = await mount(
          tester,
          level: level,
          mode: PlayMode.normal,
        );
        await begin(tester);
        for (final tile in find.byType(PocketTile).evaluate()) {
          final rect = tester.getRect(find.byWidget(tile.widget));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, closeTo(rect.width, .01));
          expect(rect.top, greaterThanOrEqualTo(20));
          expect(rect.bottom, lessThanOrEqualTo(568));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
        }
        final last = find.byKey(ValueKey('box-${tileIds(tester).last}'));
        await tester.ensureVisible(last);
        await tester.pump();
        expect(tester.getRect(last).bottom, lessThanOrEqualTo(568));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        settings.dispose();
      },
    );
  }

  testWidgets(
    'Landscape previews show a whole large board and rotation replays it',
    (tester) async {
      tester.view.physicalSize = const Size(568, 320);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 20);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final (settings, _) = await mount(
        tester,
        level: 150,
        mode: PlayMode.normal,
      );
      await begin(tester);
      await tester.pump();
      final previewReds = tester
          .widgetList<PocketTile>(find.byType(PocketTile))
          .where((tile) => tile.red)
          .map((tile) => tile.id)
          .toSet();
      expect(previewReds.length, 10);
      for (final tile in find.byType(PocketTile).evaluate()) {
        final rect = tester.getRect(find.byWidget(tile.widget));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, closeTo(rect.width, .01));
        expect(rect.top, greaterThanOrEqualTo(20));
        expect(rect.bottom, lessThanOrEqualTo(320));
      }
      await tester.pump(const Duration(milliseconds: 1400));
      expect(find.text('Tap the others'), findsOneWidget);
      tester.view.physicalSize = const Size(320, 568);
      await tester.pump();
      expect(find.text('Watch the red boxes'), findsOneWidget);
      expect(
        tester
            .widgetList<PocketTile>(find.byType(PocketTile))
            .where((tile) => tile.red)
            .map((tile) => tile.id)
            .toSet(),
        previewReds,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    },
  );

  testWidgets('Privacy policy and support are available inside settings', (
    tester,
  ) async {
    final (settings, _) = await mount(tester);
    await tapVisible(tester, find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Privacy & about'));
    await tester.pumpAndSettle();
    expect(find.text('redbox@sutechs.com'), findsOneWidget);
    expect(
      find.textContaining('Privacy policy · Red Box by SuTechs'),
      findsOneWidget,
    );
    expect(find.textContaining('We do not collect or share'), findsOneWidget);
    await tapVisible(tester, find.text('Open-source licenses'));
    await tester.pumpAndSettle();
    expect(find.text('Licenses'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });

  testWidgets('Home, tutorial and sound settings work', (tester) async {
    final (settings, sounds) = await mount(tester);
    expect(find.text('Red Box'), findsNWidgets(2));
    await tapVisible(tester, find.text('How to play'));
    await tester.pumpAndSettle();
    expect(find.text('Tap the others'), findsOneWidget);
    await tapVisible(tester, find.text('Got it'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Soft sounds'));
    await tester.pump();
    expect(settings.sound, isFalse);
    expect(sounds.stops, 1);
    await tapVisible(tester, find.text('5 seconds'));
    await tester.pump();
    expect(settings.previewSeconds, 5);
    await tapVisible(tester, find.text('Warm keys'));
    await tester.pump();
    expect(settings.musicTrack, MusicTrack.warmKeys);
    expect(settings.musicEnabled, isTrue);
    await tapVisible(tester, find.text('Mute all audio'));
    expect(settings.sound, isFalse);
    expect(settings.musicEnabled, isFalse);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });

  testWidgets(
    'Full round wires correct, wrong, retry, next and continue sounds',
    (tester) async {
      final (settings, sounds) = await mount(tester);
      await begin(tester);
      final originalRed = tester
          .widgetList<PocketTile>(find.byType(PocketTile))
          .where((tile) => tile.red)
          .map((tile) => tile.id)
          .toSet();
      expect(originalRed.length, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Tap the others'), findsOneWidget);
      var safe = tileIds(tester)
          .where((id) => !originalRed.contains(id))
          .toList();
      await tapVisible(tester, find.byKey(ValueKey('box-${safe.first}')));
      await tester.pump();
      expect(sounds.played.last, GameCue.tap);
      await tapVisible(
        tester,
        find.byKey(ValueKey('box-${originalRed.single}')),
      );
      await tester.pump();
      expect(find.text("Let's try that again"), findsOneWidget);
      expect(sounds.played.last, GameCue.wrong);
      await tapVisible(tester, find.byKey(const ValueKey('retry')));
      await tester.pump();
      final retriedRed = tester
          .widgetList<PocketTile>(find.byType(PocketTile))
          .where((tile) => tile.red)
          .map((tile) => tile.id)
          .toSet();
      expect(retriedRed, isNot(originalRed));
      safe = tileIds(tester).where((id) => !retriedRed.contains(id)).toList();
      await tester.pump(const Duration(seconds: 3));
      for (final id in safe) {
        await tapVisible(tester, find.byKey(ValueKey('box-$id')));
        await tester.pump();
      }
      expect(find.text('Lovely!'), findsOneWidget);
      expect(settings.level, 2);
      expect(sounds.played.last, GameCue.complete);
      await tapVisible(tester, find.byKey(const ValueKey('next-level')));
      await tester.pump();
      expect(find.text('LEVEL 02'), findsOneWidget);
      expect(
        tester.widgetList<PocketTile>(find.byType(PocketTile)).length,
        patternForLevel(2).boxCount,
      );
      expect(sounds.played.last, GameCue.continueRound);
      await tapVisible(tester, find.byTooltip('Pause game'));
      await tester.pumpAndSettle();
      expect(find.text('Take a breath'), findsWidgets);
      await tapVisible(tester, find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Watch the red box'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Return home'));
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    },
  );

  testWidgets('Level numbers keep increasing after the early progression', (
    tester,
  ) async {
    final (settings, sounds) = await mount(tester, level: 10000);
    await begin(tester);
    final red = tester
        .widgetList<PocketTile>(find.byType(PocketTile))
        .where((tile) => tile.red)
        .map((tile) => tile.id)
        .toSet();
    final safe = tester
        .widgetList<PocketTile>(find.byType(PocketTile))
        .map((tile) => tile.id)
        .where((id) => !red.contains(id))
        .toList();
    await tester.pump(const Duration(seconds: 3));
    for (final id in safe) {
      await tapVisible(tester, find.byKey(ValueKey('box-$id')));
      await tester.pump();
    }
    expect(find.text('Lovely!'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('next-level')));
    await tester.pump();
    expect(find.text('LEVEL 10001'), findsOneWidget);
    expect(settings.level, 10001);
    expect(sounds.played, contains(GameCue.complete));
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });

  testWidgets('A new round never carries old red paint into its preview', (
    tester,
  ) async {
    final (settings, _) = await mount(tester);
    settings.update(reducedMotion: false);
    await tester.pump();
    await begin(tester);
    final red = tester
        .widgetList<PocketTile>(find.byType(PocketTile))
        .where((tile) => tile.red)
        .map((tile) => tile.id)
        .toSet();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 280));
    for (final id in tileIds(tester).where((id) => !red.contains(id))) {
      await tapVisible(tester, find.byKey(ValueKey('box-$id')));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tapVisible(tester, find.byKey(const ValueKey('next-level')));
    final tiles = find.byType(PocketTile);
    for (var i = 0; i < tiles.evaluate().length; i++) {
      final tile = tester.widget<PocketTile>(tiles.at(i));
      if (!tile.red) {
        final paint = tester.widget<DecoratedBox>(
          find
              .descendant(of: tiles.at(i), matching: find.byType(DecoratedBox))
              .first,
        );
        expect((paint.decoration as BoxDecoration).color, PocketColors.tile);
      }
    }
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });

  testWidgets('Levels replay previous rounds without rolling back progress', (
    tester,
  ) async {
    final (settings, _) = await mount(tester, level: 7);
    await tapVisible(tester, find.byKey(const ValueKey('browse-levels')));
    await tester.pumpAndSettle();
    expect(find.text('Little steps'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Play level 7'), findsOneWidget);
    await showLevel(tester, 8);
    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('level-8'))).onTap,
      isNull,
    );
    await tapVisible(tester, find.byKey(const ValueKey('level-2')));
    final originalRed = tester
        .widgetList<PocketTile>(find.byType(PocketTile))
        .where((tile) => tile.red)
        .map((tile) => tile.id)
        .toSet();
    expect(find.text('LEVEL 02'), findsOneWidget);
    expect(find.text('Zen · Easy'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    for (final id in tileIds(tester).where((id) => !originalRed.contains(id))) {
      await tapVisible(tester, find.byKey(ValueKey('box-$id')));
    }
    expect(find.text('Lovely!'), findsOneWidget);
    expect(settings.level, 7);
    await tapVisible(tester, find.byTooltip('Back to levels'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('level-2')));
    final replayRed = tester
        .widgetList<PocketTile>(find.byType(PocketTile))
        .where((tile) => tile.red)
        .map((tile) => tile.id)
        .toSet();
    expect(replayRed, isNot(originalRed));
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });

  testWidgets(
    'Level chapters stay bounded, show difficulty and unlock the next chapter',
    (tester) async {
      final (settings, _) = await mount(tester, level: 50);
      await tapVisible(tester, find.byKey(const ValueKey('browse-levels')));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byTooltip('Next 50 levels'));
      expect(find.text('Gentle'), findsOneWidget);
      await showLevel(tester, 51);
      expect(
        tester.widget<InkWell>(find.byKey(const ValueKey('level-51'))).onTap,
        isNull,
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('play-current-level')),
      );
      final red = tester
          .widgetList<PocketTile>(find.byType(PocketTile))
          .where((tile) => tile.red)
          .map((tile) => tile.id)
          .toSet();
      await tester.pump(const Duration(seconds: 3));
      for (final id in tileIds(tester).where((id) => !red.contains(id))) {
        await tapVisible(tester, find.byKey(ValueKey('box-$id')));
      }
      expect(settings.level, 51);
      await tapVisible(tester, find.byTooltip('Back to levels'));
      await tester.pumpAndSettle();
      expect(find.text('Play level 51'), findsOneWidget);
      await showLevel(tester, 51);
      expect(
        tester.widget<InkWell>(find.byKey(const ValueKey('level-51'))).onTap,
        isNotNull,
      );
      await tapVisible(tester, find.byKey(const ValueKey('level-51')));
      expect(find.text('Zen · Gentle'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    },
  );

  testWidgets(
    'A very late level page can reach earlier chapters on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (settings, _) = await mount(tester, level: 10000);
      await tapVisible(tester, find.byKey(const ValueKey('browse-levels')));
      await tester.pumpAndSettle();
      expect(find.text('9951–10000'), findsOneWidget);
      expect(find.text('Endless'), findsOneWidget);
      await showLevel(tester, 9951);
      expect(
        tester
            .widget<SliverGrid>(find.byType(SliverGrid))
            .delegate
            .estimatedChildCount,
        50,
      );
      await tapVisible(tester, find.byTooltip('Previous 50 levels'));
      expect(find.text('9901–9950'), findsOneWidget);
      await tapVisible(tester, find.text('Back to your current levels'));
      expect(find.text('9951–10000'), findsOneWidget);
      await showLevel(tester, 9951);
      final tile = tester.getSize(find.byKey(const ValueKey('level-9951')));
      expect(tile.width, greaterThanOrEqualTo(48));
      expect(tile.height, closeTo(tile.width, .01));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    },
  );

  testWidgets(
    'The level picker reaches any unlocked level and rejects a locked one',
    (tester) async {
      final (settings, _) = await mount(tester, level: 10000);
      await tapVisible(tester, find.byKey(const ValueKey('browse-levels')));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('9951–10000'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('level-number')),
        '10001',
      );
      await tapVisible(tester, find.text('Play this level'));
      expect(find.text('Choose a level from 1 to 10000'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('level-number')), '2');
      await tapVisible(tester, find.text('Play this level'));
      await tester.pumpAndSettle();
      expect(find.text('LEVEL 02'), findsOneWidget);
      expect(settings.level, 10000);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    },
  );

  for (final level in [1, 2, 3, 4, 5, 50, 70, 100, 1000]) {
    testWidgets(
      'Small screen keeps all level $level boxes square, reachable and large enough',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final (settings, _) = await mount(tester, level: level);
        await begin(tester);
        await tester.pump(const Duration(seconds: 3));
        final grid = tester.getRect(find.byKey(const ValueKey('game-board')));
        expect(grid.top, greaterThanOrEqualTo(0));
        expect(grid.bottom, lessThanOrEqualTo(568));
        final tiles = find.byType(PocketTile);
        expect(
          tiles.evaluate().length,
          RoundGenerator(random: Random(42)).generate(level).layout.boxCount,
        );
        for (var i = 0; i < tiles.evaluate().length; i++) {
          final rect = tester.getRect(tiles.at(i));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, closeTo(rect.width, .01));
          expect(rect.bottom, lessThanOrEqualTo(grid.bottom + .01));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        settings.dispose();
      },
    );
  }
}

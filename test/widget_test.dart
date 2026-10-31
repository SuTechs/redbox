import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redbox/core/settings.dart';
import 'package:redbox/core/sound.dart';
import 'package:redbox/core/music.dart';
import 'package:redbox/core/music_track.dart';
import 'package:redbox/game/round.dart';
import 'package:redbox/game/game_controller.dart';
import 'package:redbox/main.dart';
import 'package:redbox/ui/pocket_widgets.dart';

class RecordingSounds implements SoundEffects {
  final played = <GameCue>[];
  @override
  Future<void> play(GameCue cue) async {
    played.add(cue);
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

class RecordingMusic implements MusicPlayback {
  final played = <MusicTrack>[];
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

Future<AppSettings> mount(
  WidgetTester t, {
  int level = 1,
  bool reduced = true,
}) async {
  if (t.view.physicalSize / t.view.devicePixelRatio == const Size(800, 600)) {
    viewport(t, const Size(390, 844));
  }
  final s = AppSettings(store: MemorySettingsStore())
    ..level = level
    ..reducedMotion = reduced
    ..haptics = false;
  await t.pumpWidget(
    RedBoxApp(
      settings: s,
      sounds: RecordingSounds(),
      musicPlayback: RecordingMusic(),
      generator: RoundGenerator(random: Random(42)),
    ),
  );
  return s;
}

Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pump();
}

Future<void> begin(WidgetTester t, {bool zen = false}) async {
  await tap(t, find.byKey(ValueKey(zen ? 'play-zen' : 'play')));
  await t.pump();
}

List<PocketTile> tiles(WidgetTester t) =>
    t.widgetList<PocketTile>(find.byType(PocketTile)).toList();
Future<void> finish(
  WidgetTester t, {
  Duration preview = const Duration(seconds: 3),
}) async {
  final reds = tiles(t).where((x) => x.red).map((x) => x.id).toSet();
  await t.pump(preview);
  for (final tile in tiles(t).where((x) => !reds.contains(x.id))) {
    await tap(t, find.byKey(ValueKey('box-${tile.id}')));
  }
}

void viewport(WidgetTester t, Size size, {double scale = 1}) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  t.view.padding = const FakeViewPadding(top: 20, bottom: 20);
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(t.view.resetPadding);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  testWidgets(
    'Home places Zen below Continue, Levels below Settings, both play actions visible',
    (t) async {
      viewport(t, const Size(320, 568));
      final s = await mount(t, level: 1300);
      final play = t.getRect(find.byKey(const ValueKey('play')));
      final zen = t.getRect(find.byKey(const ValueKey('play-zen')));
      expect(zen.top, greaterThan(play.bottom));
      expect(zen.bottom, lessThanOrEqualTo(548));
      expect(
        t.getRect(find.byKey(const ValueKey('browse-levels'))).top,
        greaterThanOrEqualTo(t.getRect(find.byTooltip('Settings')).bottom),
      );
      expect(find.text('Zen mode'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
  testWidgets(
    'Normal wins unlock levels; Zen wins and retries never touch progress',
    (t) async {
      final s = await mount(t);
      await begin(t);
      await finish(t);
      expect(s.level, 2);
      expect(find.text('Lovely!'), findsOneWidget);
      await tap(t, find.byTooltip('Return home'));
      await t.pumpAndSettle();
      await begin(t, zen: true);
      expect(find.textContaining('LEVEL'), findsNothing);
      final mask = tiles(t).map((x) => x.id).toList();
      final reds = tiles(t).where((x) => x.red).map((x) => x.id).toSet();
      await t.pump(const Duration(seconds: 3));
      await tap(t, find.byKey(ValueKey('box-${reds.first}')));
      expect(find.text('Have another look'), findsOneWidget);
      await tap(t, find.byKey(const ValueKey('retry')));
      expect(tiles(t).map((x) => x.id).toList(), mask);
      expect(tiles(t).where((x) => x.red).map((x) => x.id).toSet(), reds);
      await finish(t);
      expect(find.text('Another board'), findsOneWidget);
      expect(s.level, 2);
      await tap(t, find.byKey(const ValueKey('next-level')));
      expect(find.textContaining('LEVEL'), findsNothing);
      expect(s.level, 2);
      await t.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
  testWidgets(
    'Settings has audio, comfort and privacy, with no Zen mode switch',
    (t) async {
      final s = await mount(t);
      await tap(t, find.byTooltip('Settings'));
      await t.pumpAndSettle();
      expect(find.widgetWithText(SwitchListTile, 'Zen mode'), findsNothing);
      await tap(t, find.text('Mute all audio'));
      expect(s.sound, false);
      expect(s.musicEnabled, false);
      await tap(t, find.text('Extra time'));
      expect(s.previewSeconds, 5);
      await tap(t, find.text('Privacy & about'));
      await t.pumpAndSettle();
      expect(find.text('redbox@sutechs.com'), findsOneWidget);
      expect(find.textContaining('We do not collect or share'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
  testWidgets(
    'Levels stays Normal after Zen, has numbered tiles and can replay without losing unlocks',
    (t) async {
      final s = await mount(t, level: 1300);
      await begin(t, zen: true);
      await tap(t, find.byTooltip('Return home'));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const ValueKey('browse-levels')));
      await t.pumpAndSettle();
      expect(find.text('LEVELS'), findsOneWidget);
      expect(find.text('1251–1300'), findsOneWidget);
      expect(find.text('Pattern mastery'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d+ red')), findsNothing);
      await tap(t, find.text('1251–1300'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('level-number')), '1');
      await tap(t, find.text('Play this level'));
      await t.pumpAndSettle();
      expect(find.text('LEVEL 01'), findsOneWidget);
      expect(tiles(t).length, 4);
      expect(s.level, 1300);
      await t.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Dense 1300 board and all shuffle frames fit $size at text $scale',
        (t) async {
          viewport(t, size, scale: scale);
          final s = await mount(t, level: 1300, reduced: false);
          await begin(t);
          expect(tiles(t).length, 40);
          expect(tiles(t).where((x) => x.red).length, 18);
          final originalReds = tiles(t)
              .where((x) => x.red)
              .map((x) => x.id)
              .toSet();
          void check() {
            for (final x in tiles(t)) {
              final r = t.getRect(find.byKey(ValueKey('box-${x.id}')));
              expect(r.width, greaterThanOrEqualTo(48 - 0.01));
              expect(r.height, closeTo(r.width, .01));
              expect(r.left, greaterThanOrEqualTo(0));
              expect(r.right, lessThanOrEqualTo(size.width));
              expect(r.top, greaterThanOrEqualTo(20));
              expect(r.bottom, lessThanOrEqualTo(size.height - 20));
            }
            expect(t.takeException(), isNull);
          }

          check();
          await t.pump(const Duration(milliseconds: 5200));
          await t.pump(const Duration(milliseconds: 280));
          for (var pair = 0; pair < 4; pair++) {
            for (var f = 0; f < 10; f++) {
              check();
              expect(tiles(t).every((x) => x.onTap == null), true);
              await t.pump(const Duration(milliseconds: 70));
            }
            await t.pump(GameController.swapSettle);
          }
          check();
          expect(tiles(t).every((x) => x.onTap != null), true);
          // Rotation must reveal the same red identities on the fitted profile.
          t.view.physicalSize = Size(size.height, size.width);
          await t.pump();
          expect(
            tiles(t).where((x) => x.red).map((x) => x.id).toSet(),
            originalReds,
          );
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
          s.dispose();
        },
      );
    }
  }
  testWidgets(
    'Mid-shuffle reduced motion replays visible identities and stops movement',
    (t) async {
      viewport(t, const Size(320, 568));
      final s = await mount(t, level: 50, reduced: false);
      await begin(t);
      final reds = tiles(t).where((x) => x.red).map((x) => x.id).toSet();
      await t.pump(const Duration(milliseconds: 3200));
      await t.pump(const Duration(milliseconds: 280));
      expect(tiles(t).every((x) => !x.red && x.onTap == null), true);
      s.update(reducedMotion: true);
      await t.pump();
      expect(tiles(t).where((x) => x.red).map((x) => x.id).toSet(), reds);
      await t.pump(const Duration(milliseconds: 3200));
      expect(tiles(t).every((x) => x.onTap != null), true);
      await t.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
  testWidgets(
    'Zen pause can skip to a new shaped board and has no mode toggle',
    (t) async {
      final s = await mount(t, level: 600);
      await begin(t, zen: true);
      await tap(t, find.byTooltip('Pause game'));
      await t.pumpAndSettle();
      await tap(t, find.text('Music & sound'));
      await t.pumpAndSettle();
      expect(find.widgetWithText(SwitchListTile, 'Zen mode'), findsNothing);
      await tap(t, find.byTooltip('Close'));
      await t.pumpAndSettle();
      await tap(t, find.text('New board'));
      await t.pumpAndSettle();
      expect(tiles(t), isNotEmpty);
      expect(find.textContaining('LEVEL'), findsNothing);
      expect(s.level, 600);
      await t.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
  testWidgets(
    'Zen rotation preserves remembered identities across spacious and focused layouts',
    (t) async {
      viewport(t, const Size(390, 844));
      final s = await mount(t, level: 600);
      await begin(t, zen: true);
      final reds = tiles(t).where((x) => x.red).map((x) => x.id).toSet();
      t.view.physicalSize = const Size(844, 390);
      await t.pump();
      expect(tiles(t).where((x) => x.red).map((x) => x.id).toSet(), reds);
      expect(t.takeException(), isNull);
      await finish(t);
      expect(s.level, 600);
      await tap(t, find.byKey(const ValueKey('next-level')));
      expect(tiles(t).where((x) => x.red).length, inInclusiveRange(1, 2));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
  testWidgets(
    'Dense reduced-motion board can be won and its next action remains visible',
    (t) async {
      viewport(t, const Size(320, 568), scale: 2);
      final s = await mount(t, level: 1300);
      await begin(t);
      await finish(t, preview: const Duration(milliseconds: 5200));
      expect(s.level, 1301);
      expect(
        t.getRect(find.byKey(const ValueKey('next-level'))).bottom,
        lessThanOrEqualTo(548),
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
}

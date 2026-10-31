// Run: flutter test tools/capture_screenshots_test.dart
// Renders the real Flutter widgets with local fonts; does not change player data.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redbox/core/music.dart';
import 'package:redbox/core/music_track.dart';
import 'package:redbox/core/settings.dart';
import 'package:redbox/core/sound.dart';
import 'package:redbox/game/round.dart';
import 'package:redbox/main.dart';
import 'package:redbox/ui/pocket_widgets.dart';

class QuietSounds implements SoundEffects {
  @override
  Future<void> play(GameCue cue) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

class QuietMusic implements MusicPlayback {
  @override
  Future<void> play(MusicTrack track) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('Export the real Pocket toy screens', (tester) async {
    const device = String.fromEnvironment(
      'SCREENSHOT_DEVICE',
      defaultValue: 'android',
    );
    final apple = device != 'android';
    final tablet = device == 'ipad';
    tester.view.physicalSize = tablet
        ? const Size(1032, 1376)
        : apple
        ? const Size(440, 956)
        : const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    if (apple) {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      tester.view.padding = FakeViewPadding(
        top: tablet ? 24 : 59,
        bottom: tablet ? 20 : 34,
      );
      tester.view.viewPadding = tester.view.padding;
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final family in ['Fredoka', 'Nunito']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final settings = AppSettings(store: MemorySettingsStore())
      ..level = 14
      ..reducedMotion = true
      ..haptics = false;
    final frame = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: frame,
        child: RedBoxApp(
          settings: settings,
          sounds: QuietSounds(),
          musicPlayback: QuietMusic(),
          generator: RoundGenerator(random: Random(42)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> save(String name) async {
      await tester.pump();
      final boundary =
          frame.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: tablet ? 2 : 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        for (final folder in [
          apple ? 'docs/screenshots/$device' : 'docs/screenshots',
        ]) {
          final file = File('$folder/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
        }
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    await save('01-home');
    await tester.tap(find.byKey(const ValueKey('browse-levels')));
    await tester.pumpAndSettle();
    await save('02-levels');
    await tester.tap(find.byKey(const ValueKey('level-3')));
    await tester.pump();
    await save('03-remember');
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
    await tester.pump();
    for (final id in safe.take(3)) {
      await tester.tap(find.byKey(ValueKey('box-$id')));
      await tester.pump();
    }
    await save('04-tap');
    for (final id in safe.skip(3)) {
      await tester.tap(find.byKey(ValueKey('box-$id')));
      await tester.pump();
    }
    await save('05-lovely');
    await tester.tap(find.byTooltip('Back to levels'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Return home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await save('06-music');
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
}

// Run: flutter test tools/capture_difficulty_test.dart
// Real Flutter UI with in-memory sample progress. No player data is changed.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redbox/core/settings.dart';
import 'package:redbox/game/round.dart';
import 'package:redbox/main.dart';

import 'capture_screenshots_test.dart' as capture;

void main() {
  testWidgets('Capture Normal progression and preserved Zen mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();

    final frame = GlobalKey();
    final settings = AppSettings(store: MemorySettingsStore())
      ..normalLevel = 10
      ..zenLevel = 73
      ..haptics = false;
    Future<void> mount() => tester.pumpWidget(
      RepaintBoundary(
        key: frame,
        child: RedBoxApp(
          settings: settings,
          sounds: capture.QuietSounds(),
          musicPlayback: capture.QuietMusic(),
          generator: RoundGenerator(random: Random(42)),
        ),
      ),
    );
    Future<void> save(String path) async {
      await tester.pump();
      final boundary =
          frame.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();
    }

    await mount();
    await tester.pumpAndSettle();
    await save('docs/difficulty/01-mode-home.png');
    await tap(find.byKey(const ValueKey('play')));
    await tester.pump(const Duration(milliseconds: 240));
    await save('docs/difficulty/02-normal-preview.png');
    await save('release-private/difficulty-frames/00.png');
    await tester.pump(const Duration(milliseconds: 2160));
    for (var step = 0; step < 4; step++) {
      await save(
        'release-private/difficulty-frames/${(step + 1).toString().padLeft(2, '0')}.png',
      );
      await tester.pump(const Duration(milliseconds: 70));
    }
    for (var step = 0; step <= 10; step++) {
      await save(
        'release-private/difficulty-frames/${(step + 5).toString().padLeft(2, '0')}.png',
      );
      if (step == 5) await save('docs/difficulty/03-normal-shuffle.png');
      if (step < 10) await tester.pump(const Duration(milliseconds: 65));
    }
    await tester.pump(const Duration(milliseconds: 180));
    await save('release-private/difficulty-frames/16.png');

    await tester.pumpWidget(const SizedBox());
    settings.normalLevel = 150;
    await mount();
    await tester.pumpAndSettle();
    await tap(find.byKey(const ValueKey('play')));
    await tester.pump(const Duration(milliseconds: 240));
    await save('docs/difficulty/04-normal-expert.png');
    await tester.pumpWidget(const SizedBox());
    settings.update(mode: PlayMode.zen);
    await mount();
    await tester.pumpAndSettle();
    await tap(find.byKey(const ValueKey('play-zen')));
    await tester.pump(const Duration(milliseconds: 240));
    await save('docs/difficulty/05-zen-preview.png');
    await tap(find.byTooltip('Pause game'));
    await tester.pumpAndSettle();
    await tap(find.text('Music & sound'));
    await tester.pumpAndSettle();
    await save('docs/difficulty/06-zen-settings.png');
    await tester.pumpWidget(const SizedBox());
    tester.view.physicalSize = const Size(320, 568);
    tester.view.padding = const FakeViewPadding(top: 20);
    addTearDown(tester.view.resetPadding);
    settings.update(mode: PlayMode.normal);
    await mount();
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('play'))).bottom,
      lessThanOrEqualTo(568),
    );
    await save('docs/difficulty/07-compact-home.png');
    await tester.pumpWidget(const SizedBox());
    await settings.saved;
    settings.dispose();
  });
}

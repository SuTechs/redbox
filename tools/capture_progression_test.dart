// Actual Flutter captures of the approved progression and level-free Zen.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redbox/main.dart';
import 'package:redbox/core/settings.dart';
import 'package:redbox/game/round.dart';
import 'package:redbox/ui/game_page.dart';
import 'package:redbox/ui/pocket_widgets.dart';

import 'capture_screenshots_test.dart' as capture;

void main() {
  testWidgets('Capture real Normal milestones and random sculpted Zen boards', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final settings = AppSettings(store: MemorySettingsStore())
      ..haptics = false
      ..reducedMotion = true;
    final frame = GlobalKey();
    final generator = RoundGenerator(random: Random(42));
    Future<void> save(String name) async {
      await t.pump();
      final boundary =
          frame.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await t.runAsync(() async {
        final img = await boundary.toImage(pixelRatio: 2);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        final f = File('docs/difficulty/$name.png');
        await f.parent.create(recursive: true);
        await f.writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
      expect(t.takeException(), isNull);
    }

    Future<void> mount() async {
      await t.pumpWidget(
        RepaintBoundary(
          key: frame,
          child: RedBoxApp(
            settings: settings,
            sounds: capture.QuietSounds(),
            musicPlayback: capture.QuietMusic(),
            generator: generator,
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    Future<void> tap(Finder f) async {
      await t.ensureVisible(f);
      await t.tap(f);
      await t.pump();
      await t.pump();
    }

    for (final level in [1, 300, 500, 600, 1296, 1300]) {
      settings.level = level;
      await mount();
      if (level == 1300) await save('01-mode-home');
      await tap(find.byKey(const ValueKey('play')));
      await t.pump(const Duration(milliseconds: 240));
      await save('normal-$level');
      if (level == 1) await save('09-first-step');
      if (level == 1300) await save('04-normal-expert');
      await t.pumpWidget(const SizedBox());
    }
    await mount();
    await tap(find.byKey(const ValueKey('browse-levels')));
    await t.pumpAndSettle();
    await save('08-level-shapes');
    await t.pumpWidget(const SizedBox());
    await mount();
    await tap(find.byKey(const ValueKey('play-zen')));
    await t.pump(const Duration(milliseconds: 240));
    for (var i = 0; i < 8; i++) {
      await save('zen-${i + 1}');
      if (i == 0) await save('05-zen-preview');
      final reds = t
          .widgetList<PocketTile>(find.byType(PocketTile))
          .where((x) => x.red)
          .map((x) => x.id)
          .toSet();
      await t.pump(const Duration(seconds: 3));
      final ids = t
          .widgetList<PocketTile>(find.byType(PocketTile))
          .map((x) => x.id)
          .where((id) => !reds.contains(id))
          .toList();
      for (final id in ids) {
        await tap(find.byKey(ValueKey('box-$id')));
      }
      await tap(find.byKey(const ValueKey('next-level')));
    }
    expect(find.byType(GamePage), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await settings.saved;
    settings.dispose();
  });
}

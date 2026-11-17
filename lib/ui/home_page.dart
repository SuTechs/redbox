import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings.dart';
import '../core/music.dart';
import '../core/sound.dart';
import '../game/round.dart';
import 'game_page.dart';
import 'help_and_settings.dart';
import 'levels_page.dart';
import 'pocket_theme.dart';
import 'pocket_widgets.dart';
import 'zen_mark.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.settings,
    required this.sounds,
    required this.generator,
  });
  final AppSettings settings;
  final SoundEffects sounds;
  final RoundGenerator generator;
  void _play(BuildContext context, PlayMode mode) {
    unawaited(MusicScope.of(context).activate());
    unawaited(sounds.play(GameCue.continueRound));
    if (settings.haptics) unawaited(HapticFeedback.selectionClick());
    Navigator.push(
      context,
      pocketRoute<void>(
        context,
        GamePage(
          settings: settings,
          sounds: sounds,
          generator: generator,
          mode: mode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) {
      final compact =
          MediaQuery.sizeOf(context).height -
              MediaQuery.paddingOf(context).vertical <
          700;
      final large = MediaQuery.textScalerOf(context).scale(16) > 20;
      final heading = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Red Box',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 44,
              fontWeight: FontWeight.w500,
              color: PocketColors.ink,
              letterSpacing: -2,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A tiny game. A little reset.',
            textAlign: TextAlign.center,
            style: PocketType.body.copyWith(
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
      return PocketPage(
        minimumHeight: compact ? 480 : 680,
        fillHeight: !large,
        child: Column(
          children: [
            SizedBox(
              height: 100,
              child: Stack(
                children: [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: PocketWordmark(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Column(
                      children: [
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () =>
                              showPocketSettings(context, settings, sounds),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                        IconButton(
                          key: const ValueKey('browse-levels'),
                          tooltip: 'Levels',
                          onPressed: () {
                            unawaited(MusicScope.of(context).activate());
                            Navigator.push(
                              context,
                              pocketRoute<void>(
                                context,
                                LevelsPage(
                                  settings: settings,
                                  sounds: sounds,
                                  generator: generator,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.grid_view_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!large) const Spacer(),
            if (compact && !large)
              Row(
                children: [
                  const SizedBox(
                    width: 78,
                    child: HomeIllustration(height: 88),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: heading),
                ],
              )
            else ...[
              const HomeIllustration(height: 180),
              const SizedBox(height: 18),
              heading,
            ],
            if (!large) const Spacer(flex: 2) else const SizedBox(height: 28),
            if (settings.level > 1) ...[
              Text(
                'Your next little win · Level ${settings.level}',
                style: PocketType.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 10),
            ],
            PocketButton(
              key: const ValueKey('play'),
              label: settings.level > 1 ? 'Continue' : "Let's play",
              icon: Icons.arrow_forward_rounded,
              onPressed: () => _play(context, PlayMode.normal),
            ),
            const SizedBox(height: 12),
            PocketButton(
              key: const ValueKey('play-zen'),
              label: 'Zen mode',
              leading: const ZenMark(size: 28),
              secondary: true,
              onPressed: () => _play(context, PlayMode.zen),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => showHowToPlay(context),
              child: const Text(
                'How to play',
                style: TextStyle(
                  color: PocketColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

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
    if (settings.mode != mode) settings.update(mode: mode);
    unawaited(MusicScope.of(context).activate());
    unawaited(sounds.play(GameCue.continueRound));
    if (settings.haptics) unawaited(HapticFeedback.selectionClick());
    Navigator.push(
      context,
      pocketRoute<void>(
        context,
        GamePage(settings: settings, sounds: sounds, generator: generator),
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
      return PocketPage(
        minimumHeight: compact ? 600 : 670,
        fillHeight: MediaQuery.textScalerOf(context).scale(16) <= 16,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: PocketWordmark()),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const ValueKey('play-zen'),
                      tooltip: 'Play Zen mode',
                      onPressed: () => _play(context, PlayMode.zen),
                      style: IconButton.styleFrom(
                        foregroundColor: PocketColors.zenInk,
                        backgroundColor: PocketColors.zenSurface,
                      ),
                      icon: const Icon(Icons.spa_outlined),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      onPressed: () => showPocketSettings(
                        context,
                        settings,
                        sounds,
                        showModeSetting: false,
                        previewMode: PlayMode.normal,
                      ),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
              ],
            ),
            if (MediaQuery.textScalerOf(context).scale(16) <= 16)
              const Spacer()
            else
              const SizedBox(height: 24),
            HomeIllustration(height: compact ? 130 : 217),
            const SizedBox(height: 20),
            const Text(
              'Red Box',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 48,
                fontWeight: FontWeight.w500,
                color: PocketColors.ink,
                letterSpacing: -2,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A tiny game. A little reset.\nTake it one box at a time.',
              textAlign: TextAlign.center,
              style: PocketType.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (MediaQuery.textScalerOf(context).scale(16) <= 16)
              const Spacer(flex: 2)
            else
              const SizedBox(height: 32),
            if (settings.normalLevel > 1) ...[
              Text(
                'Your next little win · Level ${settings.normalLevel}',
                style: PocketType.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 13),
            ],
            PocketButton(
              key: const ValueKey('play'),
              label: settings.normalLevel > 1 ? 'Continue' : "Let's play",
              icon: Icons.arrow_forward_rounded,
              onPressed: () => _play(context, PlayMode.normal),
            ),
            const SizedBox(height: 14),
            PocketButton(
              key: const ValueKey('browse-levels'),
              label: 'Little steps · Levels',
              icon: Icons.grid_view_rounded,
              secondary: true,
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
            ),
            const SizedBox(height: 8),
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

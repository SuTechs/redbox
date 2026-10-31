import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings.dart';
import '../core/music.dart';
import '../core/sound.dart';
import '../game/round.dart';
import 'game_page.dart';
import 'mode_selector.dart';
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
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) {
      final compact =
          MediaQuery.sizeOf(context).height -
              MediaQuery.paddingOf(context).vertical <
          700;
      return PocketPage(
        minimumHeight: compact ? 620 : 770,
        fillHeight: MediaQuery.textScalerOf(context).scale(16) <= 16,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: PocketWordmark()),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () =>
                      showPocketSettings(context, settings, sounds),
                  icon: const Icon(Icons.tune_rounded),
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
            ModeSelector(settings: settings),
            const SizedBox(height: 6),
            Text(
              settings.mode.description,
              style: PocketType.body.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 18),
            if (settings.level > 1) ...[
              Text(
                'Your next little win · Level ${settings.level}',
                style: PocketType.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 13),
            ],
            PocketButton(
              key: const ValueKey('play'),
              label: settings.level > 1 ? 'Continue' : "Let's play",
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                unawaited(MusicScope.of(context).activate());
                unawaited(sounds.play(GameCue.continueRound));
                if (settings.haptics) {
                  unawaited(HapticFeedback.selectionClick());
                }
                Navigator.push(
                  context,
                  pocketRoute<void>(
                    context,
                    GamePage(
                      settings: settings,
                      sounds: sounds,
                      generator: generator,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            PocketButton(
              key: const ValueKey('browse-levels'),
              label: settings.mode == PlayMode.zen
                  ? 'Little steps · Levels'
                  : 'Challenges · Levels',
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

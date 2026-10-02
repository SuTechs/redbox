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
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => PocketPage(
      minimumHeight: 626,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const PocketWordmark(),
              IconButton(
                tooltip: 'Settings',
                onPressed: () => showPocketSettings(context, settings, sounds),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const Spacer(),
          const HomeIllustration(),
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
          const Spacer(flex: 2),
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
              if (settings.haptics) unawaited(HapticFeedback.selectionClick());
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
    ),
  );
}

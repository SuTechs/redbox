import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings.dart';
import '../core/sound.dart';
import '../game/game_controller.dart';
import '../game/round.dart';
import 'pocket_theme.dart';
import 'help_and_settings.dart';
import 'pocket_widgets.dart';

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.settings,
    required this.sounds,
    required this.generator,
    this.initialLevel,
  });
  final AppSettings settings;
  final SoundEffects sounds;
  final RoundGenerator generator;
  final int? initialLevel;
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final GameController _game;
  late final AnimationController _glow;
  bool _started = false;
  bool _pauseSheetOpen = false;
  bool get _reduced =>
      widget.settings.reducedMotion || MediaQuery.disableAnimationsOf(context);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _game = GameController(generator: widget.generator)
      ..addListener(_phaseChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _game.start(
        widget.initialLevel ?? widget.settings.level,
        preview: widget.settings.previewDuration,
        reducedMotion: _reduced,
      );
    } else if (_reduced) {
      _glow.stop();
    }
  }

  void _phaseChanged() {
    if (_game.phase == RoundPhase.preview && !_reduced) {
      _glow.repeat(reverse: true);
    } else {
      _glow.stop();
    }
    if (_game.phase == RoundPhase.paused && !_pauseSheetOpen) {
      _pauseSheetOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _presentPause();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _game.pause();
      unawaited(widget.sounds.stop());
    }
  }

  Future<void> _presentPause() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => PopScope(
        canPop: false,
        child: PocketSheet(
          title: 'Take a breath',
          close: false,
          children: [
            const Text(
              'Your round is waiting.\nWe’ll show the red boxes again.',
              style: PocketType.body,
            ),
            const SizedBox(height: 25),
            TextButton.icon(
              onPressed: () => showPocketSettings(
                sheetContext,
                widget.settings,
                widget.sounds,
              ),
              icon: const Icon(Icons.music_note_rounded, size: 18),
              label: const Text('Music & sound'),
              style: TextButton.styleFrom(foregroundColor: PocketColors.ink),
            ),
            const SizedBox(height: 12),
            PocketButton(
              label: 'Continue',
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                Navigator.pop(sheetContext);
                _game.resume(
                  preview: widget.settings.previewDuration,
                  reducedMotion: _reduced,
                );
                unawaited(widget.sounds.play(GameCue.continueRound));
              },
            ),
            const SizedBox(height: 13),
            PocketButton(
              label: widget.initialLevel == null
                  ? 'Return home'
                  : 'Back to levels',
              secondary: true,
              onPressed: () {
                Navigator.pop(sheetContext);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
    _pauseSheetOpen = false;
  }

  void _tap(int id) {
    final result = _game.tap(id);
    switch (result) {
      case TapResult.ignored:
        return;
      case TapResult.correct:
        unawaited(widget.sounds.play(GameCue.tap));
      case TapResult.complete:
        widget.settings.unlock(_game.round.level + 1);
        unawaited(widget.sounds.play(GameCue.complete));
      case TapResult.wrong:
        unawaited(widget.sounds.play(GameCue.wrong));
    }
    if (widget.settings.haptics) unawaited(HapticFeedback.selectionClick());
  }

  (String, String) get _instruction => switch (_game.phase) {
    RoundPhase.preview => (
      _game.round.redIds.length == 1
          ? 'Watch the red box'
          : 'Watch the red boxes',
      _game.round.redIds.length == 1
          ? 'Remember where it is.'
          : 'Remember where they are.',
    ),
    RoundPhase.fade => ('Keep them in mind', 'You’re ready in a moment.'),
    RoundPhase.input => ('Tap the others', 'Leave the ones that glowed.'),
    RoundPhase.complete => ('Lovely!', 'Ready for one more?'),
    RoundPhase.retry => (
      "Let's try that again",
      'These were the boxes to leave.',
    ),
    RoundPhase.paused => ('Take a breath', 'Nothing to rush.'),
  };
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _game,
    builder: (context, _) {
      final (title, subtitle) = _instruction;
      final compact = MediaQuery.sizeOf(context).height < 700;
      final progress = switch (_game.phase) {
        RoundPhase.preview || RoundPhase.fade => 'Just watch for a moment',
        RoundPhase.complete => 'Every safe box found',
        RoundPhase.retry => 'A fresh pattern when you try again.',
        RoundPhase.paused => 'Your round is waiting',
        RoundPhase.input =>
          '${_game.selectedCount} of ${_game.round.safeCount} found',
      };
      return PocketPage(
        minimumHeight:
            _boardMetrics(context, _game.round.layout).$3 +
            (compact ? 310 : 380),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: widget.initialLevel == null
                      ? 'Return home'
                      : 'Back to levels',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Flexible(
                  child: Text(
                    'LEVEL ${_game.round.level.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: PocketColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Pause game',
                  onPressed: _game.pause,
                  icon: const Icon(Icons.pause_rounded),
                ),
              ],
            ),
            SizedBox(height: compact ? 4 : 8),
            Text(
              '${_game.round.isBreather ? 'Easy moment' : _game.round.pace.label} · At your pace',
              style: PocketType.body.copyWith(fontSize: 12),
            ),
            SizedBox(height: compact ? 16 : 24),
            Semantics(
              liveRegion: true,
              child: Column(
                children: [
                  Text(
                    title,
                    key: const ValueKey('round-instruction'),
                    textAlign: TextAlign.center,
                    style: PocketType.title.copyWith(
                      fontSize: compact ? 25 : 29,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: PocketType.body,
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 12 : 22),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _glow,
                  builder: (context, _) => _Board(
                    game: _game,
                    onTap: _tap,
                    reducedMotion: _reduced,
                    symbolCue: widget.settings.symbolCue,
                    glow: _game.phase == RoundPhase.preview && !_reduced
                        ? _glow.value
                        : 0,
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 12 : 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _game.round.safeCount,
                (index) => ExcludeSemantics(
                  child: Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3.5),
                    decoration: BoxDecoration(
                      color: index < _game.selectedCount
                          ? PocketColors.red
                          : PocketColors.tileDepth,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 8 : 12),
            Semantics(
              liveRegion: true,
              child: Text(
                progress,
                style: PocketType.body.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: compact ? 12 : 25),
            if (_game.phase == RoundPhase.complete)
              PocketButton(
                key: const ValueKey('next-level'),
                label: 'Next level',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  unawaited(widget.sounds.play(GameCue.continueRound));
                  _game.start(
                    _game.round.level + 1,
                    preview: widget.settings.previewDuration,
                    reducedMotion: _reduced,
                  );
                },
              )
            else if (_game.phase == RoundPhase.retry)
              PocketButton(
                key: const ValueKey('retry'),
                label: 'Try again',
                icon: Icons.replay_rounded,
                onPressed: () {
                  unawaited(widget.sounds.play(GameCue.continueRound));
                  _game.retry(
                    preview: widget.settings.previewDuration,
                    reducedMotion: _reduced,
                  );
                },
              )
            else
              const SizedBox(
                height: 60,
                child: Center(
                  child: Text(
                    'A little focus. No hurry.',
                    style: TextStyle(
                      fontSize: 12,
                      color: PocketColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.removeListener(_phaseChanged);
    _game.dispose();
    _glow.dispose();
    super.dispose();
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.game,
    required this.onTap,
    required this.reducedMotion,
    required this.symbolCue,
    required this.glow,
  });
  final GameController game;
  final ValueChanged<int> onTap;
  final bool reducedMotion;
  final bool symbolCue;
  final double glow;
  @override
  Widget build(BuildContext context) {
    final layout = game.round.layout;
    final (width, gap, height) = _boardMetrics(context, layout);
    final tile = (width - gap * (layout.columns - 1)) / layout.columns;
    return SizedBox(
      width: width,
      height: height,
      child: GridView.count(
        key: ValueKey(game.round),
        crossAxisCount: layout.columns,
        clipBehavior: Clip.none,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: layout.slots
            .map(
              (id) => id == null
                  ? const SizedBox.shrink()
                  : PocketTile(
                      id: id,
                      red: game.isRed(id),
                      selected: game.selectedIds.contains(id),
                      onTap:
                          game.phase == RoundPhase.input &&
                              !game.selectedIds.contains(id)
                          ? () => onTap(id)
                          : null,
                      reducedMotion: reducedMotion,
                      symbolCue: symbolCue,
                      glow: glow,
                      cornerRadius: math.min(18, tile * .22),
                    ),
            )
            .toList(),
      ),
    );
  }
}

(double, double, double) _boardMetrics(
  BuildContext context,
  BoardLayout layout,
) {
  final available = math.min(420.0, MediaQuery.sizeOf(context).width) - 48;
  final maximumWidth = math.min(available, layout.columns == 2 ? 246.0 : 340.0);
  final usableHeight =
      MediaQuery.sizeOf(context).height -
      MediaQuery.paddingOf(context).vertical;
  final maximumHeight = math.max(272.0, math.min(380.0, usableHeight - 375));
  final gap = math.min(
    16.0,
    math.max(
      8.0,
      math.min(
        (maximumWidth - layout.columns * 48) / (layout.columns - 1),
        (maximumHeight - layout.rows * 48) / (layout.rows - 1),
      ),
    ),
  );
  final tile = math.max(
    48.0,
    math.min(
      (maximumWidth - gap * (layout.columns - 1)) / layout.columns,
      (maximumHeight - gap * (layout.rows - 1)) / layout.rows,
    ),
  );
  final width = layout.columns * tile + (layout.columns - 1) * gap;
  return (width, gap, layout.rows * tile + (layout.rows - 1) * gap);
}

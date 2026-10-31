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
  late final PlayMode _mode;
  Duration get _preview =>
      _game.round.previewDuration(seconds: widget.settings.previewSeconds);
  late final AnimationController _glow;
  final _boardKey = GlobalKey();
  bool? _landscape;
  bool _started = false;
  bool _pauseSheetOpen = false;
  bool get _reduced =>
      widget.settings.reducedMotion || MediaQuery.disableAnimationsOf(context);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mode = widget.settings.mode;
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
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final rotated = _landscape != null && _landscape != landscape;
    _landscape = landscape;
    if (!_started) {
      _started = true;
      _game.start(
        widget.initialLevel ?? widget.settings.level,
        mode: _mode,
        previewSeconds: widget.settings.previewSeconds,
        reducedMotion: _reduced,
      );
    } else if (rotated &&
        ![
          RoundPhase.complete,
          RoundPhase.retry,
          RoundPhase.paused,
        ].contains(_game.phase)) {
      _game.replay(preview: _preview, reducedMotion: _reduced);
    } else if (_reduced) {
      _glow.stop();
      if (_game.willShuffle &&
          [
            RoundPhase.preview,
            RoundPhase.fade,
            RoundPhase.shuffle,
          ].contains(_game.phase)) {
        // If reduced motion changes mid-round, reveal the original board again
        // instead of letting concealed tiles jump to new positions.
        _game.replay(preview: _preview, reducedMotion: true);
      }
    }
  }

  void _phaseChanged() {
    if (_game.phase == RoundPhase.preview) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showBoardIfNeeded());
    }
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

  void _showBoardIfNeeded() {
    if (!mounted || _game.phase != RoundPhase.preview) return;
    final boardContext = _boardKey.currentContext;
    final box = boardContext?.findRenderObject();
    if (boardContext == null || box is! RenderBox || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final insets = MediaQuery.paddingOf(context);
    final bottom = MediaQuery.sizeOf(context).height - insets.bottom;
    if (top < insets.top || top + box.size.height > bottom) {
      // Timed previews must show the whole board, even when larger text makes
      // the page scroll. Jump before the first preview frame, without motion.
      unawaited(Scrollable.ensureVisible(boardContext, alignment: .5));
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
                allowModeChange: false,
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
                _game.resume(preview: _preview, reducedMotion: _reduced);
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
        widget.settings.unlock(_game.round.level + 1, mode: _game.round.mode);
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
    RoundPhase.shuffle => (
      'Follow the boxes',
      'The ones that glowed are moving.',
    ),
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
        RoundPhase.shuffle =>
          'Swap ${_game.shuffleStep} of ${_game.round.swaps.length} · Just watch',
        RoundPhase.complete => 'Every safe box found',
        RoundPhase.retry => 'A fresh pattern when you try again.',
        RoundPhase.paused => 'Your round is waiting',
        RoundPhase.input =>
          '${_game.selectedCount} of ${_game.round.safeCount} found',
      };
      final fillHeight = MediaQuery.textScalerOf(context).scale(16) <= 16;
      final board = Center(
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, _) => KeyedSubtree(
            key: _boardKey,
            child: _Board(
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
      );
      return PocketPage(
        backgroundColor: _mode == PlayMode.zen
            ? PocketColors.zenBackground
            : null,
        fillHeight: fillHeight,
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_mode == PlayMode.zen) ...[
                  const Icon(
                    Icons.spa_outlined,
                    size: 16,
                    color: PocketColors.zenInk,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    '${_mode == PlayMode.zen ? 'Zen' : _game.round.layout.name} · ${_game.round.difficultyLabel}',
                    style: PocketType.body.copyWith(
                      fontSize: 12,
                      color: _mode == PlayMode.zen
                          ? PocketColors.zenInk
                          : PocketColors.muted,
                    ),
                  ),
                ),
              ],
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
                    _game.phase == RoundPhase.preview &&
                            _mode == PlayMode.normal
                        ? '${_game.round.redIds.length} red · ${_preview.inMilliseconds / 1000}s · ${_game.willShuffle ? '${_game.round.swaps.length} ${_game.round.swaps.length == 1 ? 'swap' : 'swaps'}' : 'No shuffle'}'
                        : subtitle,
                    textAlign: TextAlign.center,
                    style: PocketType.body,
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 12 : 22),
            if (fillHeight) Expanded(child: board) else board,
            SizedBox(height: compact ? 12 : 22),
            Wrap(
              alignment: WrapAlignment.center,
              runSpacing: 6,
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
                    mode: _mode,
                    previewSeconds: widget.settings.previewSeconds,
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
                  _game.retry(preview: _preview, reducedMotion: _reduced);
                },
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Center(
                  child: Text(
                    _mode == PlayMode.zen
                        ? 'A little focus. No hurry.'
                        : 'Remember. Follow. Tap the others.',
                    style: const TextStyle(
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
    final (rows, columns) = _boardDimensions(context, layout);
    final transposed = columns != layout.columns || rows != layout.rows;
    final tile = (width - gap * (columns - 1)) / columns;
    return SizedBox(
      key: const ValueKey('game-board'),
      width: width,
      height: height,
      child: TweenAnimationBuilder<double>(
        key: ValueKey((game.round, game.shuffleStep)),
        tween: Tween(
          begin: game.phase == RoundPhase.shuffle && !reducedMotion ? 0.0 : 1.0,
          end: 1.0,
        ),
        duration: game.phase == RoundPhase.shuffle && !reducedMotion
            ? GameController.swapDuration
            : Duration.zero,
        curve: Curves.easeInOutCubic,
        builder: (context, progress, _) {
          Offset position(int slot) => Offset(
            (transposed ? slot ~/ layout.columns : slot % layout.columns) *
                (tile + gap),
            (transposed ? slot % layout.columns : slot ~/ layout.columns) *
                (tile + gap),
          );
          final previous = game.previousPositions;
          final positions = game.positions;
          final ids = layout.slots.whereType<int>().toList();
          final moving = game.phase == RoundPhase.shuffle
              ? ids.where((id) => previous[id] != positions[id]).toSet()
              : <int>{};
          Widget tileFor(int id) {
            final from = position(previous[id]!);
            final to = position(positions[id]!);
            final delta = to - from;
            final arc = delta.distance == 0
                ? Offset.zero
                : Offset(-delta.dy, delta.dx) /
                      delta.distance *
                      (math.sin(math.pi * progress) * tile * .52);
            final point = Offset.lerp(from, to, progress)! + arc;
            final partner = Offset.lerp(to, from, progress)! - arc;
            // Shift both paths together at an edge. Independent clamping
            // would squeeze the paths together and hide tile identities.
            double correction(double a, double b, double limit) {
              final low = math.min(a, b);
              final high = math.max(a, b);
              if (low < 0) return -low;
              if (high > limit) return limit - high;
              return 0;
            }

            final offset =
                point +
                Offset(
                  correction(point.dx, partner.dx, width - tile),
                  correction(point.dy, partner.dy, height - tile),
                );
            return Positioned(
              key: ValueKey('tile-position-$id'),
              left: offset.dx,
              top: offset.dy,
              width: tile,
              height: tile,
              child: PocketTile(
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
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final id in ids.where((id) => !moving.contains(id)))
                tileFor(id),
              for (final id in ids.where(moving.contains)) tileFor(id),
            ],
          );
        },
      ),
    );
  }
}

(int, int) _boardDimensions(BuildContext context, BoardLayout layout) {
  final size = MediaQuery.sizeOf(context);
  return size.width > size.height && layout.rows > layout.columns
      ? (layout.columns, layout.rows)
      : (layout.rows, layout.columns);
}

(double, double, double) _boardMetrics(
  BuildContext context,
  BoardLayout layout,
) {
  final (rows, columns) = _boardDimensions(context, layout);
  final available = math.min(420.0, MediaQuery.sizeOf(context).width) - 48;
  final maximumWidth = math.min(available, columns == 2 ? 246.0 : 340.0);
  final usableHeight =
      MediaQuery.sizeOf(context).height -
      MediaQuery.paddingOf(context).vertical;
  final maximumHeight = math.max(272.0, math.min(380.0, usableHeight - 375));
  final gap = math.min(
    16.0,
    math.max(
      8.0,
      math.min(
        (maximumWidth - columns * 48) / (columns - 1),
        (maximumHeight - rows * 48) / (rows - 1),
      ),
    ),
  );
  final tile = math.max(
    48.0,
    math.min(
      (maximumWidth - gap * (columns - 1)) / columns,
      (maximumHeight - gap * (rows - 1)) / rows,
    ),
  );
  final width = columns * tile + (columns - 1) * gap;
  return (width, gap, rows * tile + (rows - 1) * gap);
}

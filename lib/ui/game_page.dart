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
    required this.mode,
  });
  final AppSettings settings;
  final SoundEffects sounds;
  final RoundGenerator generator;
  final int? initialLevel;
  final PlayMode mode;
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
    _mode = widget.mode;
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
        _mode == PlayMode.zen
            ? 0
            : widget.initialLevel ?? widget.settings.level,
        mode: _mode,
        profile: landscape ? LayoutProfile.landscape : LayoutProfile.portrait,
        previewSeconds: widget.settings.previewSeconds,
        reducedMotion: _reduced,
      );
    } else if (rotated) {
      _game.fit(
        landscape ? LayoutProfile.landscape : LayoutProfile.portrait,
        preview: _preview,
        reducedMotion: _reduced,
      );
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
          title: _mode == PlayMode.zen
              ? 'A little pause'
              : 'Level ${_game.round.level}',
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
                previewMode: _mode,
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
            if (_mode == PlayMode.zen)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _nextBoard();
                },
                icon: const Icon(Icons.spa_outlined),
                label: const Text('New board'),
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
        if (_mode == PlayMode.normal) {
          widget.settings.unlock(_game.round.level + 1);
        }
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
      _mode == PlayMode.zen ? 'Have another look' : "Let's try that again",
      'These were the boxes to leave.',
    ),
    RoundPhase.paused => ('Take a breath', 'Nothing to rush.'),
  };
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _game,
    builder: (context, _) {
      final (title, subtitle) = _instruction;
      final size = MediaQuery.sizeOf(context);
      if (_game.round.layout.boxCount > 24 ||
          size.height < 700 ||
          size.width > size.height ||
          MediaQuery.textScalerOf(context).scale(16) > 20) {
        return _focusedGame(context, title);
      }
      final compact = size.height < 700;
      final progress = switch (_game.phase) {
        RoundPhase.preview || RoundPhase.fade => 'Just watch for a moment',
        RoundPhase.shuffle =>
          'Swap ${_game.shuffleStep} of ${_game.round.swaps.length} · Just watch',
        RoundPhase.complete => 'Every safe box found',
        RoundPhase.retry =>
          _mode == PlayMode.zen
              ? 'No hurry. Have another look.'
              : 'Fresh reds when you try again.',
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
                    _mode == PlayMode.zen
                        ? 'ZEN'
                        : 'LEVEL ${_game.round.level.toString().padLeft(2, '0')}',
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
                label: _mode == PlayMode.zen ? 'Another board' : 'Next level',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  unawaited(widget.sounds.play(GameCue.continueRound));
                  _game.start(
                    _mode == PlayMode.zen ? 0 : _game.round.level + 1,
                    mode: _mode,
                    profile: _game.round.profile,
                    previewSeconds: widget.settings.previewSeconds,
                    reducedMotion: _reduced,
                  );
                },
              )
            else if (_game.phase == RoundPhase.retry)
              PocketButton(
                key: const ValueKey('retry'),
                label: _mode == PlayMode.zen ? 'Another look' : 'Try again',
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
  void _nextBoard() {
    unawaited(widget.sounds.play(GameCue.continueRound));
    _game.start(
      _mode == PlayMode.zen ? 0 : _game.round.level + 1,
      mode: _mode,
      profile: _game.round.profile,
      previewSeconds: widget.settings.previewSeconds,
      reducedMotion: _reduced,
    );
  }

  Widget _focusedGame(BuildContext context, String title) {
    final landscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final large = MediaQuery.textScalerOf(context).scale(16) > 20;
    final result = [
      RoundPhase.complete,
      RoundPhase.retry,
    ].contains(_game.phase);
    final label = _mode == PlayMode.zen ? 'Zen' : 'Level ${_game.round.level}';
    final short = switch (_game.phase) {
      RoundPhase.preview =>
        landscape
            ? '${_game.round.redIds.length}\nred'
            : large
            ? '${_game.round.redIds.length} red'
            : 'Remember ${_game.round.redIds.length} red',
      RoundPhase.fade => landscape || large ? 'Wait' : 'Keep them in mind',
      RoundPhase.shuffle =>
        landscape
            ? 'Move'
            : large
            ? 'Follow'
            : 'Follow the boxes',
      RoundPhase.input => landscape || large ? 'Tap' : 'Tap the others',
      RoundPhase.complete => landscape ? 'Done' : 'Lovely!',
      RoundPhase.retry =>
        large || landscape
            ? (_mode == PlayMode.zen ? 'Look' : 'Retry')
            : _mode == PlayMode.zen
            ? 'Another look'
            : 'Try again',
      RoundPhase.paused => 'Take a breath',
    };
    final progress = _game.phase == RoundPhase.shuffle
        ? 'Swap ${_game.shuffleStep} / ${_game.round.swaps.length}'
        : '${_game.selectedCount} / ${_game.round.safeCount}';
    Widget action({bool iconOnly = false}) {
      final next = _game.phase == RoundPhase.complete;
      void run() {
        if (next) {
          _nextBoard();
        } else {
          _game.retry(preview: _preview, reducedMotion: _reduced);
        }
      }

      final text = next
          ? (_mode == PlayMode.zen ? 'Another board' : 'Next level')
          : (_mode == PlayMode.zen ? 'Another look' : 'Try again');
      return iconOnly
          ? IconButton(
              key: ValueKey(next ? 'next-level' : 'retry'),
              tooltip: text,
              onPressed: run,
              style: IconButton.styleFrom(
                backgroundColor: PocketColors.red,
                foregroundColor: PocketColors.buttonInk,
              ),
              icon: Icon(
                next ? Icons.arrow_forward_rounded : Icons.replay_rounded,
              ),
            )
          : PocketButton(
              key: ValueKey(next ? 'next-level' : 'retry'),
              label: text,
              icon: next ? Icons.arrow_forward_rounded : Icons.replay_rounded,
              onPressed: run,
            );
    }

    return Scaffold(
      backgroundColor: _mode == PlayMode.zen
          ? PocketColors.zenBackground
          : PocketColors.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final header = landscape ? 0.0 : 48.0;
            final footer = landscape
                ? 0.0
                : result
                ? 64.0
                : 40.0;
            final availableWidth = bounds.maxWidth - (landscape ? 76 : 12);
            final availableHeight = bounds.maxHeight - header - footer - 16;
            final layout = _game.round.layout;
            final gap = availableHeight < 450 ? 2.0 : 6.0;
            final tile = math.min(
              64.0,
              math.min(
                (availableWidth - gap * (layout.columns - 1)) / layout.columns,
                (availableHeight - gap * (layout.rows - 1) - 6) / layout.rows,
              ),
            );
            final metrics = (
              layout.columns * tile + (layout.columns - 1) * gap,
              gap,
              layout.rows * tile + (layout.rows - 1) * gap,
            );
            final board = Center(
              child: AnimatedBuilder(
                animation: _glow,
                builder: (context, _) => _Board(
                  key: _boardKey,
                  game: _game,
                  onTap: _tap,
                  reducedMotion: _reduced,
                  symbolCue: widget.settings.symbolCue,
                  glow: _game.phase == RoundPhase.preview && !_reduced
                      ? _glow.value
                      : 0,
                  metrics: metrics,
                ),
              ),
            );
            final info = Semantics(
              liveRegion: true,
              label: '$label. $title. $progress',
              child: Text(
                short,
                key: const ValueKey('round-instruction'),
                textAlign: TextAlign.center,
                style: PocketType.body.copyWith(
                  fontSize: landscape ? 12 : 14,
                  fontWeight: FontWeight.w800,
                  color: _mode == PlayMode.zen
                      ? PocketColors.zenInk
                      : PocketColors.ink,
                ),
              ),
            );
            if (landscape) {
              return Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(child: board),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 56,
                      child: Column(
                        children: [
                          IconButton(
                            tooltip: 'Pause game',
                            onPressed: _game.pause,
                            icon: const Icon(Icons.pause_rounded),
                          ),
                          if (!large)
                            Text(
                              _mode == PlayMode.zen
                                  ? 'Zen'
                                  : '${_game.round.level}',
                              textAlign: TextAlign.center,
                              style: PocketType.body.copyWith(fontSize: 12),
                            ),
                          Expanded(child: Center(child: info)),
                          if (result)
                            action(iconOnly: true)
                          else
                            Text(
                              _game.phase == RoundPhase.shuffle
                                  ? '${_game.shuffleStep}\n${_game.round.swaps.length}'
                                  : '${_game.selectedCount}\n${_game.round.safeCount}',
                              textAlign: TextAlign.center,
                              style: PocketType.body.copyWith(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                children: [
                  SizedBox(
                    height: header,
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Return home',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!large)
                                Text(
                                  label.toUpperCase(),
                                  style: PocketType.body.copyWith(
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                ),
                              if (_mode == PlayMode.zen && !large)
                                const SizedBox.shrink(),
                              Flexible(child: info),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Pause game',
                          onPressed: _game.pause,
                          icon: const Icon(Icons.pause_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: board),
                  SizedBox(
                    height: footer,
                    child: result
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              child: action(iconOnly: large),
                            ),
                          )
                        : Center(
                            child: Text(
                              progress,
                              style: PocketType.body.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

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
    super.key,
    required this.game,
    required this.onTap,
    required this.reducedMotion,
    required this.symbolCue,
    required this.glow,
    this.metrics,
  });
  final GameController game;
  final ValueChanged<int> onTap;
  final bool reducedMotion;
  final bool symbolCue;
  final double glow;
  final (double, double, double)? metrics;
  @override
  Widget build(BuildContext context) {
    final layout = game.round.layout;
    final (width, gap, height) = metrics ?? _boardMetrics(context, layout);
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
            ? game.swapDuration
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

(int, int) _boardDimensions(BuildContext context, BoardLayout layout) =>
    (layout.rows, layout.columns);

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

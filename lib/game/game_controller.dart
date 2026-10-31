import 'dart:async';

import 'package:flutter/foundation.dart';

import 'round.dart';

enum RoundPhase { preview, fade, shuffle, input, complete, retry, paused }

enum TapResult { ignored, correct, complete, wrong }

class GameController extends ChangeNotifier {
  GameController({required this.generator});

  final RoundGenerator generator;
  late GameRound round;
  RoundPhase phase = RoundPhase.preview;
  RoundPhase? _beforePause;
  final Set<int> _selected = {};
  Timer? _timer;
  bool _disposed = false;
  bool _reducedMotion = false;
  int shuffleStep = 0;
  Map<int, int> _positions = {};
  Map<int, int> _previousPositions = {};
  static const swapDuration = Duration(milliseconds: 650);
  static const swapSettle = Duration(milliseconds: 180);
  Map<int, int> get positions => Map.unmodifiable(_positions);
  Map<int, int> get previousPositions => Map.unmodifiable(_previousPositions);
  bool get willShuffle => !_reducedMotion && round.swaps.isNotEmpty;

  Set<int> get selectedIds => Set.unmodifiable(_selected);
  int get selectedCount => _selected.length;

  void start(
    int level, {
    Duration? preview,
    int previewSeconds = 3,
    PlayMode mode = PlayMode.zen,
    bool reducedMotion = false,
  }) {
    round = generator.generate(level, mode: mode);
    replay(
      preview: preview ?? round.previewDuration(seconds: previewSeconds),
      reducedMotion: reducedMotion,
    );
  }

  void replay({required Duration preview, bool reducedMotion = false}) {
    _timer?.cancel();
    _selected.clear();
    _beforePause = null;
    _reducedMotion = reducedMotion;
    shuffleStep = 0;
    _positions = {
      for (var slot = 0; slot < round.layout.slots.length; slot++)
        if (round.layout.slots[slot] case final int id) id: slot,
    };
    _previousPositions = Map.of(_positions);
    phase = RoundPhase.preview;
    notifyListeners();
    _timer = Timer(preview, () {
      if (_disposed) return;
      phase = RoundPhase.fade;
      notifyListeners();
      _timer = Timer(
        reducedMotion ? Duration.zero : const Duration(milliseconds: 280),
        () {
          if (_disposed) return;
          _advanceShuffle();
        },
      );
    });
  }

  void retry({required Duration preview, bool reducedMotion = false}) {
    start(
      round.level,
      mode: round.mode,
      preview: preview,
      reducedMotion: reducedMotion,
    );
  }

  void _advanceShuffle() {
    if (_disposed) return;
    if (!willShuffle || shuffleStep >= round.swaps.length) {
      phase = RoundPhase.input;
      notifyListeners();
      return;
    }
    _previousPositions = Map.of(_positions);
    final (first, second) = round.swaps[shuffleStep];
    final slot = _positions[first]!;
    _positions[first] = _positions[second]!;
    _positions[second] = slot;
    shuffleStep++;
    phase = RoundPhase.shuffle;
    notifyListeners();
    _timer = Timer(swapDuration + swapSettle, _advanceShuffle);
  }

  TapResult tap(int id) {
    if (phase != RoundPhase.input ||
        _selected.contains(id) ||
        !round.layout.slots.contains(id)) {
      return TapResult.ignored;
    }
    if (round.redIds.contains(id)) {
      phase = RoundPhase.retry;
      _selected.clear();
      notifyListeners();
      return TapResult.wrong;
    }
    _selected.add(id);
    phase = _selected.length == round.safeCount
        ? RoundPhase.complete
        : RoundPhase.input;
    notifyListeners();
    return phase == RoundPhase.complete
        ? TapResult.complete
        : TapResult.correct;
  }

  void pause() {
    if (phase == RoundPhase.paused) return;
    _timer?.cancel();
    _beforePause = phase;
    phase = RoundPhase.paused;
    notifyListeners();
  }

  void resume({required Duration preview, bool reducedMotion = false}) {
    if (phase != RoundPhase.paused) return;
    if (_beforePause == RoundPhase.complete ||
        _beforePause == RoundPhase.retry) {
      phase = _beforePause!;
      _beforePause = null;
      notifyListeners();
    } else {
      replay(preview: preview, reducedMotion: reducedMotion);
    }
  }

  bool isRed(int id) => switch (phase) {
    RoundPhase.preview || RoundPhase.retry => round.redIds.contains(id),
    RoundPhase.paused => false,
    _ => _selected.contains(id),
  };

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

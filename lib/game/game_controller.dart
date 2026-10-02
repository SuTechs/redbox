import 'dart:async';

import 'package:flutter/foundation.dart';

import 'round.dart';

enum RoundPhase { preview, fade, input, complete, retry, paused }

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

  Set<int> get selectedIds => Set.unmodifiable(_selected);
  int get selectedCount => _selected.length;

  void start(
    int level, {
    required Duration preview,
    bool reducedMotion = false,
  }) {
    round = generator.generate(level);
    replay(preview: preview, reducedMotion: reducedMotion);
  }

  void replay({required Duration preview, bool reducedMotion = false}) {
    _timer?.cancel();
    _selected.clear();
    _beforePause = null;
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
          phase = RoundPhase.input;
          notifyListeners();
        },
      );
    });
  }

  void retry({required Duration preview, bool reducedMotion = false}) {
    start(round.level, preview: preview, reducedMotion: reducedMotion);
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

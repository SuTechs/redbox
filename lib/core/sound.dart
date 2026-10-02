import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum GameCue {
  tap('tap', 340),
  continueRound('continue', 620),
  complete('complete', 920),
  wrong('wrong', 460);

  const GameCue(this.file, this.milliseconds);
  final String file;
  final int milliseconds;
}

abstract interface class SoundEffects {
  Future<void> play(GameCue cue);
  Future<void> stop();
  Future<void> dispose();
}

class PocketSoundEffects implements SoundEffects {
  PocketSoundEffects({required this.enabled});

  final bool Function() enabled;
  final Map<GameCue, Future<AudioPool>> _pools = {};
  final Set<StopFunction> _active = {};
  final Set<Timer> _cleanup = {};
  bool _disposed = false;
  int _generation = 0;

  AudioContext get _context => AudioContext(
    android: const AudioContextAndroid(
      audioFocus: AndroidAudioFocus.none,
      usageType: AndroidUsageType.notificationRingtone,
    ),
    // Ambient obeys the silent switch and mixes with existing audio by default.
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  @override
  Future<void> play(GameCue cue) async {
    if (!enabled() || _disposed) return;
    final generation = _generation;
    try {
      final pool = await _pools.putIfAbsent(
        cue,
        () => AudioPool.create(
          source: AssetSource('sounds/${cue.file}.wav'),
          audioContext: _context,
          minPlayers: 1,
          maxPlayers: cue == GameCue.tap ? 4 : 1,
        ),
      );
      if (!enabled() || _disposed || generation != _generation) return;
      final stop = await pool.start(volume: .65);
      if (!enabled() || _disposed || generation != _generation) {
        await stop();
        return;
      }
      _active.add(stop);
      late Timer cleanup;
      cleanup = Timer(Duration(milliseconds: cue.milliseconds + 200), () {
        _active.remove(stop);
        _cleanup.remove(cleanup);
      });
      _cleanup.add(cleanup);
    } catch (error) {
      _pools.remove(cue);
      debugPrint('Could not play ${cue.file} sound: $error');
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    for (final timer in _cleanup) {
      timer.cancel();
    }
    _cleanup.clear();
    final stops = _active.toList();
    _active.clear();
    await Future.wait(stops.map((stop) => stop()));
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await Future.wait(
      _pools.values.map((pool) async {
        try {
          await (await pool).dispose();
        } catch (_) {
          /* A failed pool has no players. */
        }
      }),
    );
    _pools.clear();
  }
}

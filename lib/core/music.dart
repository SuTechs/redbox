import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'music_track.dart';
import 'settings.dart';

abstract interface class MusicPlayback {
  Future<void> play(MusicTrack track);
  Future<void> pause();
  Future<void> resume();
  Future<void> dispose();
}

class AmbientPlayback implements MusicPlayback {
  final _player = AudioPlayer();
  bool _configured = false;

  @override
  Future<void> play(MusicTrack track) async {
    if (!_configured) {
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
            usageType: AndroidUsageType.media,
          ),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        ),
      );
      await _player.setReleaseMode(ReleaseMode.loop);
      _configured = true;
    }
    await _fade(0, const Duration(milliseconds: 120));
    await _player.stop();
    await _player.play(AssetSource('music/${track.file}.wav'), volume: 0);
    await _fade(.28, const Duration(milliseconds: 240));
  }

  Future<void> _fade(double target, Duration duration) async {
    final start = _player.volume;
    for (var step = 1; step <= 4; step++) {
      await _player.setVolume(start + (target - start) * step / 4);
      await Future<void>.delayed(duration ~/ 4);
    }
  }

  @override
  Future<void> pause() async {
    await _fade(0, const Duration(milliseconds: 120));
    await _player.pause();
  }

  @override
  Future<void> resume() async {
    await _player.setVolume(0);
    await _player.resume();
    await _fade(.28, const Duration(milliseconds: 240));
  }

  @override
  Future<void> dispose() => _player.dispose();
}

class PocketMusic {
  PocketMusic({required this.settings, required this.playback}) {
    settings.addListener(_changed);
  }

  final AppSettings settings;
  final MusicPlayback playback;
  bool _activated = false;
  bool _suspended = false;
  bool _disposed = false;
  bool _playing = false;
  MusicTrack? _loaded;
  Future<void> _pending = Future.value();
  Future<void> get settled => _pending;

  // Wait for a player gesture so browsers also allow audio to start.
  Future<void> activate() {
    _activated = true;
    return _sync();
  }

  Future<void> suspend() {
    _suspended = true;
    return _sync();
  }

  Future<void> restore() {
    _suspended = false;
    return _sync();
  }

  void _changed() => unawaited(_sync());

  Future<void> _sync() {
    _pending = _pending
        .then((_) async {
          if (_disposed) return;
          final shouldPlay = _activated && !_suspended && settings.musicEnabled;
          if (!shouldPlay) {
            if (_playing) await playback.pause();
            _playing = false;
          } else if (_loaded != settings.musicTrack) {
            final track = settings.musicTrack;
            await playback.play(track);
            _loaded = track;
            _playing = true;
          } else if (!_playing) {
            await playback.resume();
            _playing = true;
          }
        })
        .catchError((Object error) {
          _loaded = null;
          _playing = false;
          debugPrint('Could not play background music: $error');
        });
    return _pending;
  }

  Future<void> dispose() async {
    settings.removeListener(_changed);
    _disposed = true;
    await _pending;
    await playback.dispose();
  }
}

class MusicScope extends InheritedWidget {
  const MusicScope({super.key, required this.music, required super.child});
  final PocketMusic music;

  static PocketMusic of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MusicScope>()!.music;

  @override
  bool updateShouldNotify(MusicScope oldWidget) => music != oldWidget.music;
}

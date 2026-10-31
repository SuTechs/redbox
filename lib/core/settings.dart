import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'music_track.dart';
import '../game/play_mode.dart';
export '../game/play_mode.dart';

abstract interface class SettingsStore {
  Future<Map<String, Object?>> read();
  Future<void> write(Map<String, Object?> values);
}

class LocalSettingsStore implements SettingsStore {
  final _preferences = SharedPreferencesAsync();
  static const _key = 'red_box.preferences.v1';

  @override
  Future<Map<String, Object?>> read() async {
    final saved = await _preferences.getString(_key);
    if (saved == null) return {};
    final decoded = jsonDecode(saved);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  @override
  Future<void> write(Map<String, Object?> values) =>
      _preferences.setString(_key, jsonEncode(values));
}

class MemorySettingsStore implements SettingsStore {
  Map<String, Object?> values = {};
  @override
  Future<Map<String, Object?>> read() async => Map.of(values);
  @override
  Future<void> write(Map<String, Object?> values) async {
    this.values = Map.of(values);
  }
}

class AppSettings extends ChangeNotifier {
  AppSettings({required this.store});

  final SettingsStore store;
  PlayMode mode = PlayMode.normal;
  int normalLevel = 1;
  int zenLevel = 1;
  int levelForMode(PlayMode mode) =>
      mode == PlayMode.zen ? zenLevel : normalLevel;
  int get level => levelForMode(mode);
  set level(int value) {
    if (mode == PlayMode.zen) {
      zenLevel = value;
    } else {
      normalLevel = value;
    }
  }

  bool sound = true;
  bool musicEnabled = true;
  MusicTrack musicTrack = MusicTrack.cloudDrift;
  bool haptics = true;
  bool reducedMotion = false;
  bool symbolCue = false;
  int previewSeconds = 3;
  Future<void> _pendingWrite = Future.value();

  Duration get previewDuration => Duration(seconds: previewSeconds);
  Future<void> get saved => _pendingWrite;

  Future<void> load() async {
    try {
      final values = await store.read();
      int validLevel(Object? value) => value is int && value > 0 ? value : 1;
      // v1 progress belongs to the unchanged Zen game, never to Normal.
      zenLevel = validLevel(values['zenLevel'] ?? values['level']);
      normalLevel = validLevel(values['normalLevel']);
      mode = values['mode'] == PlayMode.zen.name
          ? PlayMode.zen
          : PlayMode.normal;
      sound = values['sound'] is bool ? values['sound'] as bool : true;
      musicEnabled = values['musicEnabled'] is bool
          ? values['musicEnabled'] as bool
          : true;
      musicTrack = MusicTrack.values.firstWhere(
        (track) => track.name == values['musicTrack'],
        orElse: () => MusicTrack.cloudDrift,
      );
      haptics = values['haptics'] is bool ? values['haptics'] as bool : true;
      reducedMotion = values['reducedMotion'] == true;
      symbolCue = values['symbolCue'] == true;
      previewSeconds = values['previewSeconds'] == 5 ? 5 : 3;
    } catch (error) {
      debugPrint('Could not load local preferences: $error');
    }
    notifyListeners();
  }

  void update({
    PlayMode? mode,
    bool? sound,
    bool? musicEnabled,
    MusicTrack? musicTrack,
    bool? haptics,
    bool? reducedMotion,
    bool? symbolCue,
    int? previewSeconds,
  }) {
    if (mode != null) this.mode = mode;
    if (sound != null) this.sound = sound;
    if (musicEnabled != null) this.musicEnabled = musicEnabled;
    if (musicTrack != null) this.musicTrack = musicTrack;
    if (haptics != null) this.haptics = haptics;
    if (reducedMotion != null) this.reducedMotion = reducedMotion;
    if (symbolCue != null) this.symbolCue = symbolCue;
    if (previewSeconds != null && [3, 5].contains(previewSeconds)) {
      this.previewSeconds = previewSeconds;
    }
    _persist();
    notifyListeners();
  }

  void unlock(int nextLevel, {PlayMode? mode}) {
    final target = mode ?? this.mode;
    if (nextLevel <= levelForMode(target)) return;
    if (target == PlayMode.zen) {
      zenLevel = nextLevel;
    } else {
      normalLevel = nextLevel;
    }
    _persist();
    notifyListeners();
  }

  void _persist() {
    final snapshot = <String, Object?>{
      'level': zenLevel, // Keep legacy readers on their original Zen progress.
      'zenLevel': zenLevel,
      'normalLevel': normalLevel,
      'mode': mode.name,
      'sound': sound,
      'musicEnabled': musicEnabled,
      'musicTrack': musicTrack.name,
      'haptics': haptics,
      'reducedMotion': reducedMotion,
      'symbolCue': symbolCue,
      'previewSeconds': previewSeconds,
    };
    // Serialize snapshots so fast setting changes cannot save out of order.
    _pendingWrite = _pendingWrite.then((_) => store.write(snapshot)).catchError(
      (Object error) {
        debugPrint('Could not save local preferences: $error');
      },
    );
  }
}

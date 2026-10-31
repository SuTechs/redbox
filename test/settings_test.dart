import 'package:flutter_test/flutter_test.dart';
import 'package:redbox/core/settings.dart';
import 'package:redbox/core/music_track.dart';

void main() {
  test('Legacy Zen progress is archived without promoting a casual player to Normal', () async {
    final store = MemorySettingsStore()
      ..values = {
        'level': 1296,
        'mode': 'zen',
        'sound': false,
        'previewSeconds': 5,
      };
    final settings = AppSettings(store: store);
    await settings.load();
    expect(settings.level, 1);
    expect(settings.legacyZenLevel, 1296);
    expect(settings.sound, false);
    settings.unlock(2);
    await settings.saved;
    expect(store.values.containsKey('mode'), false);
    final restored = AppSettings(store: store);
    await restored.load();
    expect(restored.level, 2);
    expect(restored.legacyZenLevel, 1296);
    settings.dispose();
    restored.dispose();
  });
  test(
    'Existing Normal unlocks survive the removal of the Zen ladder',
    () async {
      final store = MemorySettingsStore()
        ..values = {'normalLevel': 600, 'zenLevel': 73, 'mode': 'zen'};
      final settings = AppSettings(store: store);
      await settings.load();
      expect(settings.level, 600);
      settings.unlock(2);
      await settings.saved;
      expect(settings.level, 600);
      settings.dispose();
    },
  );
  test(
    'Progress and preferences persist and never roll back an unlocked level',
    () async {
      final store = MemorySettingsStore();
      final settings = AppSettings(store: store);
      settings.unlock(10000);
      settings.unlock(2);
      settings.update(
        sound: false,
        musicEnabled: false,
        musicTrack: MusicTrack.warmKeys,
        haptics: false,
        previewSeconds: 5,
        reducedMotion: true,
        symbolCue: true,
      );
      settings.update(sound: true);
      settings.update(sound: false);
      await settings.saved;
      final restored = AppSettings(store: store);
      await restored.load();
      expect(restored.level, 10000);
      expect(restored.sound, isFalse);
      expect(restored.musicEnabled, isFalse);
      expect(restored.musicTrack, MusicTrack.warmKeys);
      expect(restored.haptics, isFalse);
      expect(restored.previewSeconds, 5);
      expect(restored.reducedMotion, isTrue);
      expect(restored.symbolCue, isTrue);
      settings.dispose();
      restored.dispose();
    },
  );
  test('Invalid stored values fall back to comfortable defaults', () async {
    final store = MemorySettingsStore()
      ..values = {'level': -1, 'sound': 'bad', 'previewSeconds': 999};
    final settings = AppSettings(store: store);
    await settings.load();
    expect(settings.level, 1);
    expect(settings.sound, isTrue);
    expect(settings.previewSeconds, 3);
    settings.dispose();
  });
}

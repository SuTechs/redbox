import 'package:flutter_test/flutter_test.dart';
import 'package:redbox/core/settings.dart';
import 'package:redbox/core/music_track.dart';

void main() {
  test(
    'Legacy progress migrates to Zen and retains comfort preferences',
    () async {
      final store = MemorySettingsStore()
        ..values = {
          'level': 174,
          'sound': false,
          'previewSeconds': 5,
          'reducedMotion': true,
          'symbolCue': true,
        };
      final settings = AppSettings(store: store);
      await settings.load();
      expect(settings.mode, PlayMode.normal);
      expect(settings.normalLevel, 1);
      expect(settings.zenLevel, 174);
      expect(settings.sound, isFalse);
      expect(settings.previewSeconds, 5);
      expect(settings.reducedMotion, isTrue);
      expect(settings.symbolCue, isTrue);
      settings.update(mode: PlayMode.zen);
      expect(settings.level, 174);
      await settings.saved;
      final restored = AppSettings(store: store);
      await restored.load();
      expect(restored.mode, PlayMode.zen);
      expect(restored.level, 174);
      expect(restored.normalLevel, 1);
      settings.dispose();
      restored.dispose();
    },
  );

  test(
    'Mode progress never leaks and rapid switches persist in order',
    () async {
      final store = MemorySettingsStore();
      final settings = AppSettings(store: store);
      settings.unlock(21);
      settings.update(mode: PlayMode.zen);
      settings.unlock(70);
      settings.unlock(22, mode: PlayMode.normal);
      settings.unlock(2);
      settings.update(mode: PlayMode.normal);
      expect(settings.level, 22);
      expect(settings.zenLevel, 70);
      await settings.saved;
      final restored = AppSettings(store: store);
      await restored.load();
      expect(restored.mode, PlayMode.normal);
      expect(restored.normalLevel, 22);
      expect(restored.zenLevel, 70);
      settings.dispose();
      restored.dispose();
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

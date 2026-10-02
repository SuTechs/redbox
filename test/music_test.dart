import 'package:flutter_test/flutter_test.dart';
import 'package:redbox/core/music.dart';
import 'package:redbox/core/music_track.dart';
import 'package:redbox/core/settings.dart';

class FakePlayback implements MusicPlayback {
  final List<String> events = [];
  @override
  Future<void> play(MusicTrack track) async {
    events.add(track.name);
  }

  @override
  Future<void> pause() async {
    events.add('pause');
  }

  @override
  Future<void> resume() async {
    events.add('resume');
  }

  @override
  Future<void> dispose() async {
    events.add('dispose');
  }
}

void main() {
  test('Music starts on interaction, switches, mutes independently and respects lifecycle', () async {
    final settings = AppSettings(store: MemorySettingsStore());
    final playback = FakePlayback();
    final music = PocketMusic(settings: settings, playback: playback);
    settings.update(sound: false);
    await music.settled;
    expect(playback.events, isEmpty);
    await music.activate();
    expect(playback.events, ['cloudDrift']);
    settings.update(musicTrack: MusicTrack.warmKeys);
    await music.settled;
    expect(playback.events.last, 'warmKeys');
    settings.update(musicEnabled: false);
    await music.settled;
    expect(playback.events.last, 'pause');
    await music.suspend();
    settings.update(musicEnabled: true);
    await music.settled;
    expect(playback.events.last, 'pause');
    await music.restore();
    expect(playback.events.last, 'resume');
    await music.suspend();
    settings.update(musicTrack: MusicTrack.cloudDrift);
    await music.settled;
    expect(playback.events.last, 'pause');
    await music.restore();
    expect(playback.events.last, 'cloudDrift');
    await music.dispose();
    expect(playback.events.last, 'dispose');
    settings.dispose();
  });

  test(
    'Rapid preference changes leave only the final music choice active',
    () async {
      final settings = AppSettings(store: MemorySettingsStore());
      final playback = FakePlayback();
      final music = PocketMusic(settings: settings, playback: playback);
      await music.activate();
      settings.update(musicTrack: MusicTrack.warmKeys);
      settings.update(musicEnabled: false);
      settings.update(musicTrack: MusicTrack.cloudDrift);
      await music.settled;
      expect(playback.events, ['cloudDrift', 'pause']);
      await music.dispose();
      settings.dispose();
    },
  );
}

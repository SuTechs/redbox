import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/settings.dart';
import 'core/music.dart';
import 'core/sound.dart';
import 'game/round.dart';
import 'ui/home_page.dart';
import 'ui/pocket_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final family in ['Fredoka', 'Nunito']) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString('assets/fonts/$family-OFL.txt'));
    }
  });
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: PocketColors.cream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final settings = AppSettings(store: LocalSettingsStore());
  await settings.load();
  runApp(RedBoxApp(settings: settings));
}

class RedBoxApp extends StatefulWidget {
  const RedBoxApp({
    super.key,
    required this.settings,
    this.sounds,
    this.generator,
    this.musicPlayback,
  });
  final AppSettings settings;
  final SoundEffects? sounds;
  final RoundGenerator? generator;
  final MusicPlayback? musicPlayback;
  @override
  State<RedBoxApp> createState() => _RedBoxAppState();
}

class _RedBoxAppState extends State<RedBoxApp> with WidgetsBindingObserver {
  late final SoundEffects _sounds =
      widget.sounds ?? PocketSoundEffects(enabled: () => widget.settings.sound);
  late final RoundGenerator _generator = widget.generator ?? RoundGenerator();
  late final PocketMusic _music = PocketMusic(
    settings: widget.settings,
    playback: widget.musicPlayback ?? AmbientPlayback(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      state == AppLifecycleState.resumed ? _music.restore() : _music.suspend(),
    );
  }

  @override
  Widget build(BuildContext context) => MusicScope(
    music: _music,
    child: MaterialApp(
      title: 'Red Box',
      debugShowCheckedModeBanner: false,
      theme: pocketTheme(),
      builder: (context, child) => ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                widget.settings.reducedMotion ||
                MediaQuery.disableAnimationsOf(context),
          ),
          child: child!,
        ),
      ),
      home: HomePage(
        settings: widget.settings,
        sounds: _sounds,
        generator: _generator,
      ),
    ),
  );
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_music.dispose());
    if (widget.sounds == null) unawaited(_sounds.dispose());
    super.dispose();
  }
}

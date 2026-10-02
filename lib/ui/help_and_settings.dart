import 'dart:async';

import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../core/music.dart';
import '../core/music_track.dart';
import '../core/sound.dart';
import 'pocket_theme.dart';
import 'pocket_widgets.dart';

Future<void> showHowToPlay(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => PocketSheet(
    title: 'One little rule',
    children: [
      const _HelpStep(
        number: '1',
        title: 'Watch',
        detail: 'Some boxes glow red. Remember where they are.',
      ),
      const _HelpStep(
        number: '2',
        title: 'Wait',
        detail: 'They fade. Every box looks normal again.',
      ),
      const _HelpStep(
        number: '3',
        title: 'Tap the others',
        detail: 'Correct taps turn red too. Leave the remembered boxes alone.',
      ),
      const SizedBox(height: 10),
      PocketButton(label: 'Got it', onPressed: () => Navigator.pop(context)),
    ],
  ),
);

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.number,
    required this.title,
    required this.detail,
  });
  final String number;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 23),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PocketColors.tile,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: PocketColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: PocketColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(detail, style: PocketType.body),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> showPocketSettings(
  BuildContext context,
  AppSettings settings,
  SoundEffects sounds,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => PocketSheet(
      title: 'At your pace',
      children: [
        _SettingSwitch(
          label: 'Background music',
          detail: 'A quiet companion for your little reset',
          value: settings.musicEnabled,
          onChanged: (value) {
            settings.update(musicEnabled: value);
            if (value) unawaited(MusicScope.of(context).activate());
          },
        ),
        RadioGroup<MusicTrack>(
          groupValue: settings.musicTrack,
          onChanged: (track) {
            if (track == null) return;
            settings.update(musicTrack: track, musicEnabled: true);
            unawaited(MusicScope.of(context).activate());
          },
          child: Column(
            children: MusicTrack.values
                .map(
                  (track) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<MusicTrack>(
                      value: track,
                      activeColor: PocketColors.redDepth,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      tileColor:
                          settings.musicTrack == track && settings.musicEnabled
                          ? PocketColors.tile
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        track.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: PocketColors.ink,
                        ),
                      ),
                      subtitle: Text(
                        track.description,
                        style: PocketType.body.copyWith(fontSize: 12),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 6),
        _SettingSwitch(
          label: 'Soft sounds',
          detail: 'Taps and little chimes · separate from music',
          value: settings.sound,
          onChanged: (value) {
            settings.update(sound: value);
            if (value) {
              unawaited(sounds.play(GameCue.tap));
            } else {
              unawaited(sounds.stop());
            }
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              settings.update(sound: false, musicEnabled: false);
              unawaited(sounds.stop());
            },
            icon: const Icon(Icons.volume_off_rounded, size: 18),
            label: const Text('Mute all audio'),
            style: TextButton.styleFrom(foregroundColor: PocketColors.ink),
          ),
        ),
        _SettingSwitch(
          label: 'Gentle haptics',
          detail: 'A tiny response when you tap',
          value: settings.haptics,
          onChanged: (value) => settings.update(haptics: value),
        ),
        const SizedBox(height: 14),
        const Text(
          'Preview time',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: PocketColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 3, label: Text('3 seconds')),
            ButtonSegment(value: 5, label: Text('5 seconds')),
          ],
          selected: {settings.previewSeconds},
          onSelectionChanged: (value) =>
              settings.update(previewSeconds: value.first),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? PocketColors.tileDepth
                  : PocketColors.cream,
            ),
            foregroundColor: const WidgetStatePropertyAll(PocketColors.ink),
            side: const WidgetStatePropertyAll(
              BorderSide(color: PocketColors.tileDepth),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SettingSwitch(
          label: 'Reduced motion',
          detail: 'Hold the red color without a glow',
          value: settings.reducedMotion,
          onChanged: (value) => settings.update(reducedMotion: value),
        ),
        _SettingSwitch(
          label: 'Symbol cue',
          detail: 'Add a circle to every red box',
          value: settings.symbolCue,
          onChanged: (value) => settings.update(symbolCue: value),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showPrivacyAndAbout(context),
            icon: const Icon(Icons.favorite_border_rounded, size: 18),
            label: const Text('Privacy & about'),
            style: TextButton.styleFrom(foregroundColor: PocketColors.ink),
          ),
        ),
        const SizedBox(height: 18),
        PocketButton(label: 'All set', onPressed: () => Navigator.pop(context)),
      ],
    ),
  ),
);

Future<void> showPrivacyAndAbout(
  BuildContext context,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => PocketSheet(
    title: 'Privacy & about',
    children: [
      const Text(
        'Red Box is made by SuTechs. Your levels and preferences stay on '
        'this device. We do not collect or share your gameplay data, and '
        'there are no accounts, ads, tracking, or in-app purchases.',
        style: PocketType.body,
      ),
      const SizedBox(height: 14),
      const Text(
        'You can remove locally saved data by clearing app data or '
        'uninstalling. In a browser, clear this site’s storage. The web '
        'version is hosted by GitHub Pages, which may process ordinary '
        'request logs such as your IP address.',
        style: PocketType.body,
      ),
      const SizedBox(height: 14),
      const Text(
        'Privacy policy · Red Box by SuTechs · October 2, 2026. '
        'If you email us, we receive the information you choose to send and '
        'use it to answer your request. We retain support messages only as '
        'needed for support and any legal obligations. Contact us to request '
        'deletion. We do not knowingly collect personal data from children.',
        style: PocketType.body,
      ),
      const SizedBox(height: 14),
      const SelectableText('redbox@sutechs.com', style: PocketType.body),
      const SizedBox(height: 8),
      const SelectableText(
        'sutechs.github.io/redbox/privacy.html',
        style: PocketType.body,
      ),
      TextButton(
        onPressed: () => showLicensePage(
          context: context,
          applicationName: 'Red Box',
          applicationVersion: '1.0.0',
          applicationLegalese: '© 2026 SuTechs',
        ),
        child: const Text('Open-source licenses'),
      ),
      const SizedBox(height: 12),
      PocketButton(label: 'Lovely', onPressed: () => Navigator.pop(context)),
    ],
  ),
);

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: PocketColors.ink,
      ),
    ),
    subtitle: Text(detail, style: PocketType.body.copyWith(fontSize: 13)),
    value: value,
    onChanged: onChanged,
    activeTrackColor: PocketColors.red,
    activeThumbColor: PocketColors.buttonInk,
  );
}

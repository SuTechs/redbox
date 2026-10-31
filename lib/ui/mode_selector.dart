import 'package:flutter/material.dart';

import '../core/settings.dart';
import 'pocket_theme.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key, required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: SegmentedButton<PlayMode>(
      segments: const [
        ButtonSegment(
          value: PlayMode.normal,
          label: Text('Normal'),
          icon: Icon(Icons.psychology_alt_outlined),
        ),
        ButtonSegment(
          value: PlayMode.zen,
          label: Text('Zen'),
          icon: Icon(Icons.spa_outlined),
        ),
      ],
      selected: {settings.mode},
      onSelectionChanged: (selection) =>
          settings.update(mode: selection.single),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        foregroundColor: const WidgetStatePropertyAll(PocketColors.ink),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? PocketColors.tileDepth
              : PocketColors.cream,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: PocketColors.tileDepth),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
        ),
      ),
    ),
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings.dart';
import '../core/music.dart';
import '../core/sound.dart';
import '../game/round.dart';
import 'game_page.dart';
import 'help_and_settings.dart';
import 'pocket_theme.dart';
import 'pocket_widgets.dart';

class LevelsPage extends StatefulWidget {
  const LevelsPage({
    super.key,
    required this.settings,
    required this.sounds,
    required this.generator,
  });

  final AppSettings settings;
  final SoundEffects sounds;
  final RoundGenerator generator;

  @override
  State<LevelsPage> createState() => _LevelsPageState();
}

class _LevelsPageState extends State<LevelsPage> {
  static const _chapterSize = 50;
  late int _chapter = (widget.settings.level - 1) ~/ _chapterSize;
  final _scroll = ScrollController();

  int get _firstLevel => _chapter * _chapterSize + 1;
  int get _lastLevel => _firstLevel + _chapterSize - 1;

  void _browse(int chapter) {
    setState(() => _chapter = chapter);
    _scroll.jumpTo(0);
  }

  void _play(int level) {
    if (level > widget.settings.level) return;
    unawaited(MusicScope.of(context).activate());
    unawaited(widget.sounds.play(GameCue.continueRound));
    if (widget.settings.haptics) unawaited(HapticFeedback.selectionClick());
    Navigator.push(
      context,
      pocketRoute<void>(
        context,
        GamePage(
          settings: widget.settings,
          sounds: widget.sounds,
          generator: widget.generator,
          initialLevel: level,
          mode: PlayMode.normal,
        ),
      ),
    );
  }

  Future<void> _pickLevel() async {
    final input = TextEditingController(text: '${widget.settings.level}');
    final form = GlobalKey<FormState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: PocketSheet(
          title: 'Pick a little step',
          children: [
            const Text(
              'Every level you’ve unlocked is yours to revisit.',
              style: PocketType.body,
            ),
            const SizedBox(height: 20),
            Form(
              key: form,
              child: TextFormField(
                key: const ValueKey('level-number'),
                controller: input,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Level number',
                  helperText: 'Choose 1–${widget.settings.level}',
                  filled: true,
                  fillColor: PocketColors.tile,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  final level = int.tryParse(value ?? '');
                  return level != null &&
                          level >= 1 &&
                          level <= widget.settings.level
                      ? null
                      : 'Choose a level from 1 to ${widget.settings.level}';
                },
              ),
            ),
            const SizedBox(height: 24),
            PocketButton(
              label: 'Play this level',
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                if (!form.currentState!.validate()) return;
                final level = int.parse(input.text);
                Navigator.pop(sheetContext);
                _play(level);
              },
            ),
          ],
        ),
      ),
    );
    // The sheet's closing animation still uses its field controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.settings,
    builder: (context, _) {
      final featuredLevel = widget.settings.level.clamp(
        _firstLevel,
        _lastLevel,
      );
      final difficulty = NormalDifficulty.forLevel(featuredLevel);
      final currentChapter = (widget.settings.level - 1) ~/ _chapterSize;
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Return home',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            'LEVELS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: PocketColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () => showPocketSettings(
                            context,
                            widget.settings,
                            widget.sounds,
                          ),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => CustomScrollView(
                        controller: _scroll,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Little steps',
                                              style: PocketType.title.copyWith(
                                                fontSize: 36,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Build your memory.\nOne little win at a time.',
                                              style: PocketType.body,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          right: 10,
                                          bottom: 8,
                                        ),
                                        child: SquareMascot(size: 67),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 26),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: PocketColors.tile,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: PocketColors.tileDepth,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'LEVELS $_firstLevel–$_lastLevel',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  letterSpacing: .7,
                                                  fontWeight: FontWeight.w800,
                                                  color: PocketColors.muted,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.auto_awesome_rounded,
                                              size: 18,
                                              color: PocketColors.redDepth,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          difficulty.label,
                                          style: PocketType.title.copyWith(
                                            fontSize: 25,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          difficulty.chapterHint,
                                          style: PocketType.body.copyWith(
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Previous 50 levels',
                                        onPressed: _chapter > 0
                                            ? () => _browse(_chapter - 1)
                                            : null,
                                        icon: const Icon(
                                          Icons.chevron_left_rounded,
                                        ),
                                      ),
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: _pickLevel,
                                          icon: const Icon(
                                            Icons.expand_more_rounded,
                                            size: 17,
                                          ),
                                          label: Text(
                                            '$_firstLevel–$_lastLevel',
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: PocketColors.ink,
                                            textStyle: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Next 50 levels',
                                        onPressed: () => _browse(_chapter + 1),
                                        icon: const Icon(
                                          Icons.chevron_right_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Center(
                                    child: _chapter == currentChapter
                                        ? Text(
                                            'Tap any open level to play',
                                            style: PocketType.body.copyWith(
                                              fontSize: 12,
                                            ),
                                          )
                                        : TextButton.icon(
                                            onPressed: () =>
                                                _browse(currentChapter),
                                            icon: const Icon(
                                              Icons.near_me_outlined,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Back to your current levels',
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: PocketColors.ink,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: constraints.maxWidth < 350
                                        ? 4
                                        : 5,
                                    mainAxisSpacing: 13,
                                    crossAxisSpacing: 12,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final level = _firstLevel + index;
                                return _LevelTile(
                                  level: level,
                                  current: level == widget.settings.level,
                                  completed: level < widget.settings.level,
                                  onTap: level <= widget.settings.level
                                      ? () => _play(level)
                                      : null,
                                );
                              }, childCount: _chapterSize),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: PocketColors.redDepth,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Little wins you can revisit',
                                    style: PocketType.body.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                    child: Column(
                      children: [
                        PocketButton(
                          key: const ValueKey('play-current-level'),
                          label: 'Play level ${widget.settings.level}',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => _play(widget.settings.level),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Every little win is yours to revisit.',
                          style: PocketType.body.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.current,
    required this.completed,
    required this.onTap,
  });

  final int level;
  final bool current;
  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = onTap == null;
    return Semantics(
      label:
          'Level $level, ${current
              ? 'ready to play'
              : completed
              ? 'completed, replay'
              : 'locked'}',
      button: true,
      enabled: !locked,
      onTap: onTap,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: current
                ? PocketColors.red
                : locked
                ? PocketColors.tile.withValues(alpha: .5)
                : PocketColors.tile,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: current
                    ? PocketColors.redDepth
                    : PocketColors.tileDepth.withValues(
                        alpha: locked ? .45 : 1,
                      ),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              key: ValueKey('level-$level'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: FittedBox(
                        child: Text(
                          '$level',
                          style: PocketType.title.copyWith(
                            fontSize: 22,
                            color: current
                                ? PocketColors.buttonInk
                                : PocketColors.ink.withValues(
                                    alpha: locked ? .5 : 1,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (completed || locked)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Icon(
                        completed
                            ? Icons.check_rounded
                            : Icons.lock_outline_rounded,
                        size: 11,
                        color: completed
                            ? PocketColors.redDepth
                            : PocketColors.muted.withValues(alpha: .6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The approved Normal curve. Memory grows; speed is practiced within a band.
class NormalDifficulty {
  const NormalDifficulty._(
    this.level,
    this.firstLevel,
    this.boxCounts,
    this.redCount,
  );
  final int level;
  final int firstLevel;
  final List<int> boxCounts;
  final int redCount;

  static NormalDifficulty forLevel(int level) {
    if (level < 1) {
      throw ArgumentError.value(level, 'level', 'Must be positive');
    }
    const bands = [
      (1, [4, 5], 1),
      (3, [6, 7], 2),
      (7, [8, 9, 10], 3),
      (15, [10, 11, 12], 4),
      (25, [12, 13, 14], 5),
      (40, [14, 15, 16], 6),
      (60, [16, 17, 18], 7),
      (90, [18, 19, 20], 8),
      (140, [20, 21, 22], 9),
      (220, [22, 23, 24], 10),
      (350, [24, 25, 26], 11),
      (500, [28, 29, 30], 12),
      (600, [30, 31, 32], 13),
      (750, [32, 33, 34], 14),
      (900, [34, 35, 36], 15),
      (1000, [36, 37, 38], 16),
      (1100, [38, 39, 40], 17),
      (1200, [40], 18),
      (1500, [40], 19),
      (2000, [40], 20),
    ];
    final band = bands.lastWhere((b) => b.$1 <= level);
    return NormalDifficulty._(level, band.$1, band.$2, band.$3);
  }

  int boxCountForLevel(int level) {
    const opening = [4, 5, 6, 6, 7, 7, 8, 8, 9, 10];
    if (level <= 10) return opening[level - 1];
    return boxCounts[(level - firstLevel) % boxCounts.length];
  }

  int get previewMilliseconds {
    final baseline = (2000 + 200 * redCount).clamp(3000, 6000);
    final practiceStart = firstLevel < 100 ? 100 : firstLevel;
    final steps = level < 100 ? 0 : ((level - practiceStart) ~/ 25).clamp(0, 4);
    return baseline - steps * 100;
  }

  int get swapCount => level < 50
      ? 0
      : level < 175
      ? 1
      : level < 550
      ? 2
      : level < 850
      ? 3
      : 4;
  int get swapMilliseconds => level < 100
      ? 900
      : level < 275
      ? 850
      : level < 675
      ? 800
      : level < 975
      ? 750
      : level < 1350
      ? 700
      : 650;
  String get label => level < 15
      ? 'First steps'
      : level < 50
      ? 'Finding focus'
      : level < 175
      ? 'First moves'
      : level < 500
      ? 'Memory paths'
      : level < 1000
      ? 'Deep focus'
      : level < 2000
      ? 'Pattern mastery'
      : 'Endless expert';
  String get chapterHint => level < 50
      ? 'Learn the shapes. Grow your memory.'
      : level < 175
      ? 'Follow one moving pair. Take your time.'
      : level < 500
      ? 'More to remember. Familiar, gentle moves.'
      : level < 1000
      ? 'Larger patterns. A deeper memory challenge.'
      : level < 2000
      ? 'Rich patterns. Keep the reds in mind.'
      : 'New arrangements. Your expert rhythm.';
}

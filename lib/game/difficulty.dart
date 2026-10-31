class NormalDifficulty {
  const NormalDifficulty._(
    this.boxCounts,
    this.redCount,
    this.previewMilliseconds,
    this.swapCount,
    this.label,
  );

  final List<int> boxCounts;
  final int redCount;
  final int previewMilliseconds;
  final int swapCount;
  final String label;

  static NormalDifficulty forLevel(int level) {
    if (level < 1) {
      throw ArgumentError.value(level, 'level', 'Must be positive');
    }
    if (level == 1) {
      return const NormalDifficulty._([8], 1, 3000, 0, 'Warm-up');
    }
    if (level < 5) {
      return const NormalDifficulty._([10, 12, 10], 2, 3000, 0, 'Warm-up');
    }
    if (level < 10) {
      return const NormalDifficulty._([12, 14, 16], 3, 2600, 0, 'Focus');
    }
    if (level < 20) {
      return const NormalDifficulty._(
        [16, 18],
        4,
        2400,
        1,
        'Follow the shuffle',
      );
    }
    if (level < 30) {
      return const NormalDifficulty._(
        [18, 20, 22],
        5,
        2200,
        2,
        'Memory stretch',
      );
    }
    if (level < 40) {
      return const NormalDifficulty._(
        [20, 22, 24],
        6,
        2000,
        2,
        'Memory stretch',
      );
    }
    if (level < 60) {
      return const NormalDifficulty._([22, 24, 26], 6, 2000, 3, 'Challenge');
    }
    if (level < 80) {
      return const NormalDifficulty._([24, 26, 28], 7, 1800, 4, 'Challenge');
    }
    if (level < 100) {
      return const NormalDifficulty._([26, 28], 8, 1600, 4, 'Expert');
    }
    if (level < 150) {
      return const NormalDifficulty._([26, 28, 30], 8, 1600, 5, 'Expert');
    }
    return const NormalDifficulty._([28, 30, 26, 30], 10, 1400, 6, 'Master');
  }

  int boxCountForLevel(int level) => boxCounts[(level - 1) % boxCounts.length];
}

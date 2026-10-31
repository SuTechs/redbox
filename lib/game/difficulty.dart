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
    if (level <= 1) {
      return const NormalDifficulty._([4], 1, 3000, 0, 'First steps');
    }
    if (level <= 2) {
      return const NormalDifficulty._([5], 1, 3000, 0, 'First steps');
    }
    if (level <= 4) {
      return const NormalDifficulty._([6], 2, 3000, 0, 'First steps');
    }
    if (level <= 5) {
      return const NormalDifficulty._([7], 2, 3000, 0, 'First steps');
    }
    if (level <= 7) {
      return const NormalDifficulty._([8], 3, 3000, 0, 'Finding focus');
    }
    if (level <= 9) {
      return const NormalDifficulty._([9], 3, 3000, 0, 'Finding focus');
    }
    if (level <= 10) {
      return const NormalDifficulty._([10], 4, 3000, 0, 'Finding focus');
    }
    if (level <= 19) {
      return const NormalDifficulty._(
        [10, 11, 12],
        4,
        3000,
        0,
        'Finding focus',
      );
    }
    if (level <= 29) {
      return const NormalDifficulty._([12], 4, 3000, 1, 'First moves');
    }
    if (level <= 39) {
      return const NormalDifficulty._([12, 13, 14], 5, 2800, 1, 'Memory paths');
    }
    if (level <= 49) {
      return const NormalDifficulty._([14], 5, 2800, 2, 'Memory paths');
    }
    if (level <= 69) {
      return const NormalDifficulty._(
        [14, 15, 16],
        6,
        2600,
        2,
        'Building rhythm',
      );
    }
    if (level <= 89) {
      return const NormalDifficulty._(
        [16, 17, 18],
        7,
        2600,
        2,
        'Building rhythm',
      );
    }
    if (level <= 119) {
      return const NormalDifficulty._([18], 7, 2400, 3, 'Moving patterns');
    }
    if (level <= 159) {
      return const NormalDifficulty._(
        [18, 19, 20],
        8,
        2400,
        3,
        'Moving patterns',
      );
    }
    if (level <= 219) {
      return const NormalDifficulty._([20], 8, 2200, 4, 'Deep focus');
    }
    if (level <= 299) {
      return const NormalDifficulty._([20, 21, 22], 9, 2200, 4, 'Deep focus');
    }
    if (level <= 399) {
      return const NormalDifficulty._([22], 9, 2000, 5, 'Pattern mastery');
    }
    return const NormalDifficulty._(
      [22, 23, 24],
      10,
      1800,
      5,
      'Pattern mastery',
    );
  }

  int boxCountForLevel(int level) => boxCounts[(level - 1) % boxCounts.length];
}

enum PlayMode {
  normal('Normal', 'Grow your memory'),
  zen('Zen', 'Just play and relax');

  const PlayMode(this.label, this.description);
  final String label;
  final String description;
}

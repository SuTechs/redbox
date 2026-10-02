enum MusicTrack {
  cloudDrift('cloud-drift', 'Cloud drift', 'Airy chords, slowly drifting'),
  warmKeys('warm-keys', 'Warm keys', 'Soft notes in a cozy little room');

  const MusicTrack(this.file, this.label, this.description);
  final String file;
  final String label;
  final String description;
}

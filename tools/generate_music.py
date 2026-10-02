"""Compose Red Box's original ambient loops. Requires NumPy; no audio downloads."""

from pathlib import Path
import wave

import numpy as np

RATE = 22050
DURATION = 64
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "music"
TIME = np.arange(RATE * DURATION, dtype=np.float64) / RATE

# Cmaj7 → Am7 → Fmaj7 → Gsus2. No beat, voices, or sudden accents.
CHORDS = [(48, 55, 59, 64), (45, 52, 55, 60), (41, 48, 52, 57), (43, 50, 57, 62)]


def frequency(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def pad(midi, start, gain):
    elapsed = (TIME - start) % DURATION
    envelope = np.where(elapsed < 24, np.sin(np.pi * elapsed / 24) ** 2, 0)
    # An integer number of cycles makes the whole loop periodic at its seam.
    pitch = round(frequency(midi) * DURATION) / DURATION
    voice = np.sin(2 * np.pi * pitch * TIME)
    voice += .09 * np.sin(2 * np.pi * pitch * 2 * TIME)
    return gain * voice * envelope


def key(midi, start, gain):
    elapsed = (TIME - start) % DURATION
    envelope = (1 - np.exp(-elapsed * 25)) * np.exp(-elapsed * 1.1)
    envelope *= np.clip((10 - elapsed) / 2, 0, 1)
    pitch = frequency(midi)
    voice = np.sin(2 * np.pi * pitch * elapsed)
    voice += .16 * np.sin(2 * np.pi * pitch * 2 * elapsed) * np.exp(-elapsed * 2)
    return gain * voice * envelope


def compose(name, with_keys):
    samples = np.zeros_like(TIME)
    for bar, chord in enumerate(CHORDS):
        for midi in chord:
            samples += pad(midi, bar * 16 - 4, .024 if with_keys else .036)
        if with_keys:
            # Sparse, soft higher notes, with quiet reflections.
            melody = [chord[2] + 12, chord[3] + 12, chord[1] + 12, chord[2] + 12]
            for step, midi in enumerate(melody):
                start = bar * 16 + step * 4 + 1
                samples += key(midi, start, .085)
                samples += key(midi, start + .28, .014)
                samples += key(midi, start + .64, .008)
    samples -= samples.mean()
    # Leave ample headroom; playback is quieter again underneath tap sounds.
    peak = np.max(np.abs(samples))
    samples *= min(1, .22 / peak)
    pcm = np.round(samples * 32767).astype('<i2')
    with wave.open(str(OUTPUT / f'{name}.wav'), 'wb') as audio:
        audio.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        audio.writeframes(pcm.tobytes())
    print(f'{name}: {DURATION}s; peak {np.max(np.abs(samples)):.3f}; seam {abs(int(pcm[-1]) - int(pcm[0]))} PCM units')


if __name__ == '__main__':
    OUTPUT.mkdir(parents=True, exist_ok=True)
    compose('cloud-drift', False)
    compose('warm-keys', True)

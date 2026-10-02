"""Generate Red Box's original, soft sound effects using only the standard library."""

from math import exp, pi, sin
from pathlib import Path
import struct
import wave

RATE = 44100
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "sounds"


def note(t, frequency, duration, gain=0.19):
    if not 0 <= t < duration:
        return 0.0
    attack = 1 - exp(-t * 180)
    release = min(1, (duration - t) / 0.09)
    decay = exp(-t * 6)
    tone = sin(2 * pi * frequency * t)
    tone += 0.18 * sin(2 * pi * frequency * 2 * t) * exp(-t * 12)
    tone += 0.055 * sin(2 * pi * frequency * 3 * t) * exp(-t * 20)
    return gain * attack * release * decay * tone


def write_sound(name, duration, notes):
    samples = []
    for index in range(int(duration * RATE)):
        t = index / RATE
        value = sum(note(t - start, frequency, length, gain) for start, frequency, length, gain in notes)
        # A quiet reflection gives the notes a little room without a long tail.
        value += 0.14 * sum(note(t - start - 0.075, frequency, length, gain) for start, frequency, length, gain in notes)
        samples.append(max(-0.7, min(0.7, value)))
    path = OUTPUT / f"{name}.wav"
    with wave.open(str(path), "wb") as audio:
        audio.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        audio.writeframes(b"".join(struct.pack("<h", round(value * 32767)) for value in samples))
    print(f"{name}: {duration:.2f}s; peak {max(abs(value) for value in samples):.3f}")


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    write_sound("tap", 0.34, [(0, 523.25, 0.23, 0.18)])
    write_sound("continue", 0.62, [(0, 392.00, 0.35, 0.16), (0.12, 523.25, 0.40, 0.15)])
    write_sound("complete", 0.92, [(0, 523.25, 0.45, 0.13), (0.12, 659.25, 0.46, 0.12), (0.25, 783.99, 0.55, 0.12)])
    write_sound("wrong", 0.46, [(0, 220.00, 0.35, 0.17), (0.09, 196.00, 0.27, 0.065)])

"""Encode the real Flutter preview/fade/shuffle frames for PR review.

First run: flutter test tools/capture_difficulty_test.dart
Requires Pillow, also used by render_store_assets.py. No UI is reconstructed.
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
FRAMES = ROOT / "release-private/difficulty-frames"
OUTPUT = ROOT / "docs/difficulty/shuffle.gif"


def main():
    frames = [Image.open(FRAMES / f"{i:02}.png").convert("RGB") for i in range(17)]
    try:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        frames[0].save(
            OUTPUT,
            save_all=True,
            append_images=frames[1:],
            duration=[2760] + [70] * 4 + [65] * 10 + [180, 1000],
            loop=0,
            disposal=2,
        )
    finally:
        for frame in frames:
            frame.close()
    print(f"Saved {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

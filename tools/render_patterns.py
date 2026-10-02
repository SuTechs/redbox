"""Render the exact Dart sampler data as a shareable pattern diagram (Pillow)."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SAMPLES = json.loads((ROOT / 'design/pattern-samples.json').read_text())
CREAM, INK, MUTED = '#fff8ed', '#40342e', '#806d5c'
TILE, DEPTH, RED, RED_DEPTH = '#f0e6d6', '#ddceba', '#ed6258', '#c6413a'


def font(family, size, weight):
    face = ImageFont.truetype(str(ROOT / f'assets/fonts/{family}.ttf'), size)
    face.set_variation_by_axes([
        weight if axis['name'] == b'Weight' else axis['default']
        for axis in face.get_variation_axes()
    ])
    return face


image = Image.new('RGB', (1120, 1320), CREAM)
draw = ImageDraw.Draw(image)
draw.text((32, 28), 'More shapes. Little moments.', font=font('Fredoka', 39, 500), fill=INK)
draw.text((34, 86), 'Seed 20261002 · exact output from the game’s Dart pattern function', font=font('Nunito', 18, 600), fill=MUTED)
for index, sample in enumerate(SAMPLES):
    left = 32 + index % 3 * 356
    top = 142 + index // 3 * 369
    draw.rounded_rectangle((left, top + 5, left + 344, top + 355), radius=23, fill='#eee2d2')
    draw.rounded_rectangle((left, top, left + 344, top + 350), radius=23, fill='#fffcf5', outline='#ecdfce')
    draw.text((left + 20, top + 18), f"LEVEL {sample['level']:02}", font=font('Nunito', 15, 800), fill=MUTED)
    draw.text((left + 200, top + 18), f"{sample['redCount']} to remember", font=font('Nunito', 14, 700), fill=MUTED)
    cols, rows = sample['columns'], sample['rows']
    gap = 10
    size = min(44, (222 - (max(cols, rows) - 1) * gap) / max(cols, rows))
    width, height = cols * size + (cols - 1) * gap, rows * size + (rows - 1) * gap
    x0, y0 = left + (344 - width) / 2, top + 58 + (225 - height) / 2
    box_id = 0
    for row, mask in enumerate(sample['mask']):
        for col, cell in enumerate(mask):
            if cell == '.':
                continue
            x, y = x0 + col * (size + gap), y0 + row * (size + gap)
            red = box_id in sample['redIds']
            draw.rounded_rectangle((x, y + 5, x + size, y + size + 5), radius=9, fill=RED_DEPTH if red else DEPTH)
            draw.rounded_rectangle((x, y, x + size, y + size), radius=9, fill=RED if red else TILE)
            box_id += 1
    draw.text((left + 20, top + 289), sample['name'], font=font('Fredoka', 25, 500), fill=INK)
    draw.text((left + 20, top + 323), f"{sample['boxes']} boxes · {sample['boxes'] - sample['redCount']} satisfying taps", font=font('Nunito', 15, 600), fill=MUTED)
draw.text((32, 1268), 'Remember the red boxes, then enjoy tapping all the others. No rush.', font=font('Nunito', 19, 600), fill=MUTED)
image.save(ROOT / 'design/pattern-samples.png')

"""Export the approved generated logo into platform icon sizes (requires Pillow)."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
source = Image.open(ROOT / 'assets/brand/logo-source.png').convert('RGB')
logo = source.resize((1024, 1024), Image.Resampling.LANCZOS)
logo.save(ROOT / 'assets/brand/logo.png', optimize=True)

def export(path, size, maskable=False):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    result = logo.resize((size, size), Image.Resampling.LANCZOS)
    if maskable:
        result = Image.new('RGB', (size, size), '#FFF8ED')
        inset = logo.resize((round(size * .72), round(size * .72)), Image.Resampling.LANCZOS)
        result.paste(inset, ((size-inset.width)//2, (size-inset.height)//2))
    result.save(path, optimize=True)

for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    export(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)
    export(f'android/app/src/main/res/drawable-{density}/ic_launcher_foreground.png', round(size*2.25), True)
for size in [192,512]:
    export(f'web/icons/Icon-{size}.png',size)
    export(f'web/icons/Icon-maskable-{size}.png',size,True)
export('web/favicon.png',64)
export('web/icons/apple-touch-icon.png',180)

catalog = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((catalog/'Contents.json').read_text())['images']:
    size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
    export(str((catalog / entry['filename']).relative_to(ROOT)),size)
for scale in [1,2,3]:
    suffix = '' if scale == 1 else f'@{scale}x'
    export(f'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png',168*scale)
export('store/google-play/icon.png',512)

# A marketing layout using the approved logo and the game's own tiles.
canvas = Image.new('RGB',(1024,500),'#FFF8ED')
draw = ImageDraw.Draw(canvas)
title = ImageFont.truetype(str(ROOT/'assets/fonts/Fredoka.ttf'),74)
body = ImageFont.truetype(str(ROOT/'assets/fonts/Nunito.ttf'),26)
draw.text((70,118),'Red Box',font=title,fill='#40342E')
draw.text((73,219),'A tiny game. A little reset.',font=body,fill='#806D5C')
draw.text((73,263),'Take it one box at a time.',font=body,fill='#806D5C')
for x,y,red in [(627,122,False),(719,122,True),(811,122,False),(627,216,False),(719,216,False),(811,216,False)]:
    draw.rounded_rectangle((x,y+6,x+76,y+82),18,fill='#C6413A' if red else '#DDCEBA')
    draw.rounded_rectangle((x,y,x+76,y+76),18,fill='#ED6258' if red else '#F0E6D6')
canvas.save(ROOT/'store/google-play/feature-graphic.png',optimize=True)
canvas.save(ROOT/'docs/banner.png',optimize=True)
print('Exported Android, iOS, web, and store icons; 1024×500 feature graphic.')

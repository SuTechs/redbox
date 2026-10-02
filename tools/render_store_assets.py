"""Compose honest marketing screenshots from the real Flutter captures."""
from pathlib import Path
import argparse
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--device', choices=['android', 'iphone', 'ipad'], default='android')
device = parser.parse_args().device
OUT = ROOT / ('store/google-play/screenshots' if device == 'android' else f'store/app-store/screenshots/{device}')
OUT.mkdir(parents=True, exist_ok=True)
W, H = {'android': (1080,1920), 'iphone': (1320,2868), 'ipad': (2064,2752)}[device]
# Design on the same 1080-wide canvas, then export to the store's exact device size.
scale = W / 1080
H = round(H / scale)
W = 1080
INK, MUTED, RED = '#40342E', '#806D5C', '#ED6258'

def font(family, size, weight):
    face = ImageFont.truetype(str(ROOT / f'assets/fonts/{family}.ttf'), size)
    face.set_variation_by_name(weight)
    return face

def tile(canvas, x, y, size, angle, red=False):
    pad = 26
    art = Image.new('RGBA',(size+pad*2,size+pad*2),(0,0,0,0))
    d=ImageDraw.Draw(art)
    depth = '#C6413A' if red else '#DDCEBA'
    d.rounded_rectangle((pad,pad+8,pad+size,pad+size+8),size//5,fill=depth)
    d.rounded_rectangle((pad,pad,pad+size,pad+size),size//5,fill=RED if red else '#F0E6D6')
    art=art.rotate(angle,resample=Image.Resampling.BICUBIC,expand=True)
    canvas.alpha_composite(art,(x,y))

def wrapped(draw,text,x,y,max_width,face,color,line_height):
    words=text.split(); lines=[]; current=''
    for word in words:
        candidate=(current+' '+word).strip()
        if draw.textlength(candidate,font=face)>max_width and current:
            lines.append(current); current=word
        else: current=candidate
    lines.append(current)
    for line in lines:
        draw.text((x,y),line,font=face,fill=color); y+=line_height
    return y

slides=[
    ('01-a-little-reset','01-home',['A tiny game.','A little reset.'],'Turn a spare moment into a gentle break.','Your own little pocket toy.','#FFF8ED'),
    ('02-remember-and-tap','03-remember',['Remember the red.','Enjoy the rest.'],'One simple rule. So many satisfying taps.','Watch. Remember. Tap the others.','#FFF2EC'),
    ('03-your-own-pace','04-tap',['No rush.','No pressure.'],'Tap at your own pace. Retry whenever you like.','No countdown while you tap.','#F5F5E9'),
    ('04-endless-little-wins','02-levels',['Little wins.','Endless shapes.'],'A fresh pattern to explore, one level at a time.','Replay your favorites anytime.','#FFF8ED'),
    ('05-quiet-soundtrack','06-music',['Find your','quiet soundtrack.'],'Soft background music and little tap sounds.','Two calming tracks. Mute anytime.','#FFF2EC'),
    ('06-one-more-smile','05-lovely',['One more box.','One more smile.'],'Gentle progress, cute shapes, and a moment for you.','A little focus. A softer moment.','#F5F5E9'),
]
logo=Image.open(ROOT/'assets/brand/logo.png').convert('RGBA')
outputs=[]
for index,(name,screen,headline,subtitle,footer,bg) in enumerate(slides):
    canvas=Image.new('RGBA',(W,H),bg)
    d=ImageDraw.Draw(canvas)
    mark=logo.resize((64,64),Image.Resampling.LANCZOS)
    canvas.alpha_composite(mark,(65,40))
    d.text((148,47),'Red Box',font=font('Nunito',28,'ExtraBold'),fill=INK)
    d.text((880,49),f'0{index+1} / 06',font=font('Nunito',24,'Bold'),fill=MUTED)
    y=146
    for line_no,line in enumerate(headline):
        face=font('Fredoka',96,'Medium')
        while d.textlength(line,font=face)>950:
            face=font('Fredoka',face.size-2,'Medium')
        d.text((65,y),line,font=face,fill=RED if line_no==1 else INK)
        y+=116
    wrapped(d,subtitle,69,408,920,font('Nunito',34,'SemiBold'),MUTED,47)

    # Composed, softly framed screenshots; all UI inside is captured from Flutter.
    px,py,pw,ph = {'android': (205,576,670,1191), 'iphone': (142,540,796,1729), 'ipad': (50,475,980,1307)}[device]
    if device == 'ipad':
        # A broad tablet composition gives the real tablet UI room to breathe.
        px,py,pw,ph = 230,480,620,827
    shadow=Image.new('RGBA',(W,H),(0,0,0,0))
    sd=ImageDraw.Draw(shadow)
    sd.rounded_rectangle((px-20,py+22,px+pw+20,py+ph+28),72,fill=(94,65,47,35))
    shadow=shadow.filter(ImageFilter.GaussianBlur(24))
    canvas.alpha_composite(shadow)
    tile(canvas,19,770,113,15)
    tile(canvas,879,min(H-250,1350),111,-12,True)
    tile(canvas,854,643,63,-16)
    d=ImageDraw.Draw(canvas)
    d.rounded_rectangle((px-12,py-12,px+pw+12,py+ph+12),64,fill='#E9DCCB')
    source = 'docs/screenshots' if device == 'android' else f'docs/screenshots/{device}'
    capture=Image.open(ROOT/f'{source}/{screen}.png').convert('RGBA')
    capture=capture.resize((pw,ph),Image.Resampling.LANCZOS)
    mask=Image.new('L',(pw,ph),0)
    ImageDraw.Draw(mask).rounded_rectangle((0,0,pw-1,ph-1),52,fill=255)
    capture.putalpha(mask)
    canvas.alpha_composite(capture,(px,py))
    d=ImageDraw.Draw(canvas)
    footer_face=font('Nunito',28,'Bold')
    fw=d.textlength(footer,font=footer_face)
    d.text(((W-fw)/2,H-65),footer,font=footer_face,fill=MUTED)
    final=canvas.convert('RGB')
    target_size = {'android': (1080,1920), 'iphone': (1320,2868), 'ipad': (2064,2752)}[device]
    final = final.resize(target_size,Image.Resampling.LANCZOS)
    path=OUT/f'{name}.png'; final.save(path,optimize=True)
    outputs.append(final)

# Clear the old raw store exports only after the six marketing assets exist.
for old in (['01-home','02-levels','03-remember','04-tap','05-lovely','06-music'] if device == 'android' else []):
    stale=OUT/f'{old}.png'
    if stale.exists(): stale.unlink()

thumb_h = round(352 * outputs[0].height / outputs[0].width)
sheet=Image.new('RGB',(1080,(thumb_h+34)*2+8),'#E9DCCB')
for i,slide in enumerate(outputs):
    sheet.paste(slide.resize((352,thumb_h),Image.Resampling.LANCZOS),(8+(i%3)*360,8+(i//3)*(thumb_h+34)))
sheet.save(ROOT/('docs/store-preview.jpg' if device == 'android' else f'docs/store-preview-{device}.jpg'),quality=93)
print(f'Rendered six {target_size[0]}×{target_size[1]} {device} marketing screenshots and the review contact sheet.')

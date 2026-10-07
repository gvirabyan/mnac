"""Splits the logo dove into a wing layer and a body layer for the splash
flight animation (lib/presentation/splash/widgets/flying_logo.dart).

The logo is one flat raster, so the wing is cut out along a hand-traced
outline (coordinates are for the 1024x1024 source) and the strip of body it
covered is repainted by diffusing the surrounding body colours inward.

If the logo artwork changes, re-trace WING/BODYFILL and re-run:
    python tool/split_logo_wing.py assets/icon/icon_foreground.png assets/icon
Writes, at 512x512:
  dove_body.png, dove_wing.png  the two flight layers
  dove_wing_far.png             the wing in shadow, played as the far wing
  dove_rim.png                  the silhouette's outline (sharp)
  dove_rim_glow.png             the same outline pre-blurred into a bloom
  dove_halo.png                 the whole silhouette blurred, for the glow
                                behind the logo
The blurs are baked here so the splash never blurs anything at runtime. Needs numpy and Pillow.
"""
import sys, numpy as np
from PIL import Image, ImageDraw, ImageFilter
src, out = sys.argv[1], sys.argv[2]
SIZE = 512
im = Image.open(src).convert('RGBA'); W,H = im.size
a = np.asarray(im).astype(np.float32)

# Wing region (everything above the bird's back, left of the neck).
WING = [(200,90),(330,90),(450,170),(510,300),(535,340),(548,380),(553,430),
        (556,480),(558,510),(553,545),(540,585),(520,605),(478,597),(430,613),
        (390,613),(340,593),(300,571),(200,562)]
# Where the body continues under the wing and needs repainting once the wing
# is cut away: between the neck/shoulder and the top of the tail.
BODYFILL = [(557,505),(600,520),(600,660),(430,660),(470,598)]

def mask(poly, blur=1.2):
    m = Image.new('L', (W,H), 0); ImageDraw.Draw(m).polygon(poly, fill=255)
    return np.asarray(m.filter(ImageFilter.GaussianBlur(blur))).astype(np.float32)/255

wm = mask(WING)
wing = a.copy(); wing[...,3] *= wm
body = a.copy(); body[...,3] *= (1-wm)

# Diffusion inpaint of the body under the wing.
fill = mask(BODYFILL, 0) > 0.5
alpha0 = a[...,3] > 128
hole = fill & alpha0 & (body[...,3] < 250)
known = (~hole) & (body[...,3] > 250)
rgb = body[...,:3].copy(); rgb[~known] = 0
wsum = known.astype(np.float32)
cur_rgb = rgb.copy(); cur_w = wsum.copy()
for _ in range(400):
    k = np.pad(cur_rgb*cur_w[...,None], ((1,1),(1,1),(0,0)))
    kw = np.pad(cur_w, 1)
    s = k[:-2,1:-1]+k[2:,1:-1]+k[1:-1,:-2]+k[1:-1,2:]
    sw = kw[:-2,1:-1]+kw[2:,1:-1]+kw[1:-1,:-2]+kw[1:-1,2:]
    new = np.where(sw[...,None]>0, s/np.maximum(sw,1e-6)[...,None], 0)
    upd = hole & (sw>0)
    cur_rgb[upd] = new[upd]; cur_w = np.where(known, 1, np.where(upd, 1, cur_w))
body[hole,:3] = cur_rgb[hole]; body[hole,3] = 255
def save(arr, name):
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    img.resize((SIZE, SIZE), Image.LANCZOS).save(out + '/' + name, optimize=True)

save(wing, 'dove_wing.png')
save(body, 'dove_body.png')
far = wing.copy()
far[..., :3] *= np.array([0.62, 0.70, 0.84], dtype=np.float32)
save(far, 'dove_wing_far.png')

# Outline of the whole silhouette: a thin band straddling the alpha edge,
# feathered so it reads as light rather than a stroke.
from PIL import ImageChops
sil = Image.fromarray((a[..., 3] > 128).astype(np.uint8) * 255)
# Fill interior holes (the eye) so only the outer edge lights up: anything not
# reachable from the corner counts as inside.
outside = sil.copy()
ImageDraw.floodfill(outside, (0, 0), 128)
sil = Image.fromarray(np.where(np.asarray(outside) == 128, 0, 255).astype(np.uint8))
outer = sil.filter(ImageFilter.MaxFilter(7))
inner = sil.filter(ImageFilter.MinFilter(5))
band = ImageChops.subtract(outer, inner).filter(ImageFilter.GaussianBlur(1.5))
rim = Image.new('RGBA', (W, H), (255, 255, 255, 0))
rim.putalpha(band)
rim.resize((SIZE, SIZE), Image.LANCZOS).save(out + '/dove_rim.png', optimize=True)

def white(alpha):
    img = Image.new('RGBA', (W, H), (255, 255, 255, 0))
    img.putalpha(alpha)
    img.resize((SIZE, SIZE), Image.LANCZOS).save(out + '/' + alpha.info.get('n', ''), optimize=True)

glow = ImageChops.subtract(sil.filter(ImageFilter.MaxFilter(9)),
                           sil.filter(ImageFilter.MinFilter(9)))
glow = glow.filter(ImageFilter.GaussianBlur(10))
# Blurring thins the band out; bring its peak back up to full strength.
g = np.asarray(glow).astype(np.float32)
glow = Image.fromarray(np.clip(g * (255 / max(g.max(), 1)), 0, 255).astype(np.uint8))
glow.info['n'] = 'dove_rim_glow.png'
white(glow)

halo = sil.filter(ImageFilter.GaussianBlur(28))
halo.info['n'] = 'dove_halo.png'
white(halo)

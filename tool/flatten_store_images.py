# Finishes store/ for upload, after: flutter test tool/store_screenshots_test.dart
#
#  * drops the alpha channel from every image (App Store Connect rejects
#    screenshots with transparency; Play's feature graphic must not have it);
#  * checks each one is the size its store slot requires;
#  * writes store/google_play/icon_512.png, the Play listing icon, from the
#    same artwork and background colour as the launcher icon (pubspec.yaml,
#    flutter_launcher_icons).
import glob
import os

from PIL import Image

# Folder (or file) under store/, minus the language folder (hy/ru/en) ->
# required size.
EXPECTED = {
    'app_store/iphone_6_3': (1206, 2622),
    'app_store/ipad_13': (2064, 2752),
    'google_play/phone': (1080, 1920),
    'google_play/feature_graphic.png': (1024, 500),
    'google_play/icon_512.png': (512, 512),
}

LANGUAGES = {'hy', 'ru', 'en'}

ICON_BACKGROUND = '#E0D3BE'

here = os.path.dirname(os.path.abspath(__file__))
store = os.path.normpath(os.path.join(here, '..', 'store'))

foreground = Image.open(os.path.join(here, '..', 'assets', 'icon', 'icon_foreground.png')).convert('RGBA')
icon = Image.new('RGBA', foreground.size, ICON_BACKGROUND)
icon.alpha_composite(foreground)
os.makedirs(os.path.join(store, 'google_play'), exist_ok=True)
icon.convert('RGB').resize((512, 512), Image.LANCZOS).save(os.path.join(store, 'google_play', 'icon_512.png'))

bad = []
files = sorted(glob.glob(os.path.join(store, '**', '*.png'), recursive=True))
for path in files:
    rel = os.path.relpath(path, store).replace(os.sep, '/')
    parts = rel.split('/')
    if len(parts) > 2 and parts[1] in LANGUAGES:
        del parts[1]
    key = '/'.join(parts)
    want = EXPECTED.get(key) or EXPECTED.get(os.path.dirname(key))
    img = Image.open(path)
    if img.size != want:
        bad.append(f'{rel}: {img.size}, want {want}')
    if img.mode != 'RGB':
        img.convert('RGB').save(path, optimize=True)
print(f'{len(files)} images ready in {store}')
if bad:
    raise SystemExit('wrong size:\n' + '\n'.join(bad))

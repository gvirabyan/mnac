# Downloads the app's Google Fonts (Noto Sans / Serif Armenian, every weight,
# and plain Noto Sans / Serif, their Cyrillic fallback)
# for tool/store_screenshots_test.dart: widget tests cannot fetch fonts and
# would otherwise draw every glyph as a box.
#
#   tool/.cache/fonts/NotoSansArmenian_700.ttf          loaded by name, for
#                                                       the frames' captions
#   tool/.cache/google_fonts/NotoSansArmenian_700_<hash>.ttf
#                                                       google_fonts' own
#                                                       on-device cache
#                                                       layout, for the app
#
# Run once before the screenshots: python tool/fetch_store_fonts.py
import glob
import os
import re
import shutil
import urllib.request

FAMILIES = {
    'notoSansArmenian': 'NotoSansArmenian',
    'notoSerifArmenian': 'NotoSerifArmenian',
    'notoSans': 'NotoSans',
    'notoSerif': 'NotoSerif',
}

here = os.path.dirname(os.path.abspath(__file__))
out = os.path.join(here, '.cache', 'fonts')
device = os.path.join(here, '.cache', 'google_fonts')
os.makedirs(out, exist_ok=True)
os.makedirs(device, exist_ok=True)

pub_cache = os.path.join(os.environ['LOCALAPPDATA'], 'Pub', 'Cache', 'hosted', 'pub.dev')
source = sorted(glob.glob(os.path.join(pub_cache, 'google_fonts-*', 'lib', 'src', 'google_fonts_parts', 'part_n.dart')))[-1]
text = open(source, encoding='utf-8').read()

variant = re.compile(
    r'fontWeight: FontWeight\.w(\d+),\s*fontStyle: FontStyle\.(\w+),\s*\): GoogleFontsFile\(\s*\'([0-9a-f]{64})\'')

for method, family in FAMILIES.items():
    start = text.index(f'static TextStyle {method}(')
    block = text[start:text.index('fontFamily:', start)]
    for weight, style, digest in variant.findall(block):
        # google_fonts' own naming: "regular"/"italic" at 400, else "700",
        # "700italic".
        name = ('regular' if style == 'normal' else 'italic') if weight == '400' \
            else weight + ('' if style == 'normal' else 'italic')
        path = os.path.join(out, f'{family}_{name}.ttf')
        if not os.path.exists(path):
            urllib.request.urlretrieve(f'https://fonts.gstatic.com/s/a/{digest}.ttf', path)
            print('fetched', os.path.basename(path))
        cached = os.path.join(device, f'{family}_{name}_{digest}.ttf')
        if not os.path.exists(cached):
            shutil.copyfile(path, cached)

print(len(os.listdir(out)), 'font files in', out)

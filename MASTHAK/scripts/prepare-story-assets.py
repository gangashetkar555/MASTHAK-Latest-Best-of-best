"""Prepare compressed hero and per-panel comic artwork (Python + Pillow + Node)."""
from pathlib import Path
import json, subprocess, sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
data_code = "const fs=require('node:fs'); const code=fs.readFileSync('src/data/comic.ts','utf8').replace(/export const/g,'const'); console.log(JSON.stringify(new Function(code+';return {chapters,frames}')()));"
data = json.loads(subprocess.check_output(['node', '-e', data_code], cwd=ROOT, text=True))
out = ROOT / 'public/assets/story'
out.mkdir(parents=True, exist_ok=True)
for book, chapter in enumerate(data['chapters']):
    with Image.open(ROOT / 'public/assets/comic' / chapter['file']) as source:
        for index, (x, y, w, h) in enumerate(data['frames'][book]):
            panel = source.crop((round(x*source.width), round(y*source.height), round((x+w)*source.width), round((y+h)*source.height))).convert('RGB')
            panel.thumbnail((1200, 1200))
            panel.save(out / f'book-{book+1}-panel-{index+1}.webp', quality=87, method=6)
if len(sys.argv) > 1:
    with Image.open(sys.argv[1]) as source:
        for width, name in [(1680, 'court-wide'), (900, 'court-mobile')]:
            image = source.convert('RGB')
            image.thumbnail((width, 1100))
            image.save(out / f'{name}.webp', quality=85, method=6)
print('Story artwork prepared:', len(list(out.glob('*.webp'))), 'files')

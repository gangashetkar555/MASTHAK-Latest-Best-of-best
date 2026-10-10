"""Build and integrity-check a clean local-use ZIP using Python's standard library."""
from pathlib import Path
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'release'
OUT.mkdir(exist_ok=True)
ARCHIVE = OUT / 'MASTHAK-Local.zip'
ROOT_FILES = ['readme.txt', 'README.md', 'START-LOCAL.cmd', 'package.json',
              'package-lock.json', 'next.config.ts', 'next-env.d.ts',
              'tsconfig.json', '.gitignore', 'AGENTS.md']
SOURCE_DIRS = ['src', 'public', 'godot', 'scripts', 'docs', 'builds/windows']
EXCLUDED_PARTS = {'.godot', '__pycache__', '.git', 'node_modules', '.next', '.tools'}
files = [ROOT / name for name in ROOT_FILES]
for directory in SOURCE_DIRS:
    files.extend(p for p in (ROOT / directory).rglob('*') if p.is_file()
                 and not EXCLUDED_PARTS.intersection(p.relative_to(ROOT).parts)
                 and p.suffix not in {'.log', '.blend1', '.pyc', '.tsbuildinfo'}
                 and not (directory == 'docs' and p.suffix in {'.jpg', '.png'}))
files = sorted(set(files))
for p in files:
    if not p.is_file() or p.is_symlink():
        raise ValueError(f'Missing or symlinked package input: {p}')
with zipfile.ZipFile(ARCHIVE, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for p in files:
        archive.write(p, 'MASTHAK/' + p.relative_to(ROOT).as_posix())
    manifest = '\n'.join(p.relative_to(ROOT).as_posix() for p in files) + '\n'
    archive.writestr('MASTHAK/PACKAGE-CONTENTS.txt', manifest)
with zipfile.ZipFile(ARCHIVE) as archive:
    bad = archive.testzip()
    if bad:
        raise ValueError(f'ZIP integrity failure: {bad}')
    names = archive.namelist()
    for required in ['readme.txt', 'START-LOCAL.cmd', 'package-lock.json',
                     'public/games/masthak/index.pck', 'public/games/masthak/index.wasm',
                     'builds/windows/MASTHAK.exe', 'godot/project.godot',
                     'src/components/Landing.tsx', 'src/components/ScrollStory.tsx',
                     'src/app/cinematic.css', 'src/app/restored-ui.css',
                     'public/assets/soundscape/courtyard-theme.m4a',
                     'public/assets/soundscape/courtyard-ambience.mp3',
                     'public/assets/soundscape/panel-transition.mp3',
                     'public/assets/soundscape/choice-success.mp3',
                     'public/assets/story/court-wide.webp',
                     'public/assets/story/court-mobile.webp',
                     'public/assets/story/book-5-panel-8.webp']:
        if 'MASTHAK/' + required not in names:
            raise ValueError(f'Missing required ZIP entry: {required}')
    if any(EXCLUDED_PARTS.intersection(Path(name).parts) for name in names):
        raise ValueError('Generated/cache folder leaked into ZIP')
digest = hashlib.sha256(ARCHIVE.read_bytes()).hexdigest()
(OUT / 'MASTHAK-Local.sha256.txt').write_text(f'{digest}  {ARCHIVE.name}\n', encoding='ascii')
print(f'{ARCHIVE}: {len(files)} files, {ARCHIVE.stat().st_size / 1024**2:.1f} MiB; CRC and required files verified.')

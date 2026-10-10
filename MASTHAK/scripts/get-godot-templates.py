"""Extract only required templates from the official archive using HTTP ranges."""
import io, json, pathlib, urllib.request, zipfile

URL = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
OUT = pathlib.Path('.tools/godot-templates')
OUT.mkdir(parents=True, exist_ok=True)

class RemoteZip(io.RawIOBase):
    def __init__(self):
        req = urllib.request.Request(URL, headers={'Range': 'bytes=0-0', 'User-Agent': 'MASTHAK-build'})
        with urllib.request.urlopen(req, timeout=90) as response:
            if response.status != 206:
                raise RuntimeError('Server did not support partial download')
            self.size = int(response.headers['Content-Range'].split('/')[-1])
            self.url = response.url
        self.pos = 0
        self.transferred = 0
    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.pos
    def seek(self, offset, whence=0):
        self.pos = offset if whence == 0 else self.pos + offset if whence == 1 else self.size + offset
        return self.pos
    def read(self, size=-1):
        if size < 0: size = self.size - self.pos
        if size == 0: return b''
        end = min(self.size - 1, self.pos + size - 1)
        req = urllib.request.Request(self.url, headers={'Range': f'bytes={self.pos}-{end}'})
        with urllib.request.urlopen(req, timeout=120) as response:
            if response.status != 206: raise RuntimeError('Range request failed')
            data = response.read()
        self.pos += len(data)
        self.transferred += len(data)
        return data

remote = RemoteZip()
with zipfile.ZipFile(remote) as archive:
    names = archive.namelist()
    print('Templates:', ', '.join(names), flush=True)
    wanted = ['web_nothreads_release.zip', 'web_nothreads_debug.zip', 'windows_release_x86_64.exe', 'version.txt']
    for name in wanted:
        match = next((n for n in names if n.endswith('/' + name)), None)
        if match is None: continue
        dest = OUT / name
        if dest.exists(): continue
        with archive.open(match) as source, dest.open('wb') as target:
            while chunk := source.read(1024 * 1024): target.write(chunk)
        print(f'Extracted {name}: {dest.stat().st_size:,} bytes', flush=True)
print(f'Transferred {remote.transferred:,} of {remote.size:,} archive bytes', flush=True)

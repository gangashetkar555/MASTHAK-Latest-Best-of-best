import urllib.request, zipfile, io, pathlib
root=pathlib.Path(__file__).resolve().parents[1]/'.tools'/'kenney'
urls={
'sci-fi-sounds':'https://kenney.nl/media/pages/assets/sci-fi-sounds/6b296f9ecf-1677589334/kenney_sci-fi-sounds.zip',
'interface-sounds':'https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip',
'ui':'https://kenney.nl/media/pages/assets/ui-pack-sci-fi/b67c2acd31-1724181109/kenney_ui-pack-space-expansion.zip',
'urban':'https://kenney.nl/media/pages/assets/retro-urban-kit/8314d4db22-1738147509/kenney_retro-urban-kit.zip'}
for name,url in urls.items():
 target=root/name
 if target.exists(): continue
 request=urllib.request.Request(url,headers={'User-Agent':'MASTHAK game development'})
 data=urllib.request.urlopen(request,timeout=90).read()
 with zipfile.ZipFile(io.BytesIO(data)) as archive:
  target.mkdir(parents=True,exist_ok=True)
  for entry in archive.infolist():
   dest=(target/entry.filename).resolve()
   if not dest.is_relative_to(target.resolve()): raise ValueError('Unsafe archive path')
  archive.extractall(target)
 print(name,len(data),flush=True)

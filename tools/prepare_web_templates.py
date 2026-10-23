import io,json,urllib.request,zipfile
from pathlib import Path
api='https://api.github.com/repos/godotengine/godot/releases/tags/4.7.2-stable'
def request(url,headers=None):
 return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Godot-Web-Export',**(headers or {})}),timeout=60)
with request(api) as r:release=json.load(r)
asset=next(a for a in release['assets'] if a['name']=='Godot_v4.7.2-stable_export_templates.tpz')
class RemoteZip(io.RawIOBase):
 def __init__(self,url,size):self.url=url;self.length=size;self.pos=0
 def seekable(self):return True
 def readable(self):return True
 def tell(self):return self.pos
 def seek(self,offset,whence=0):
  self.pos=offset if whence==0 else self.pos+offset if whence==1 else self.length+offset
  return self.pos
 def read(self,n=-1):
  if n<0:n=self.length-self.pos
  n=min(n,self.length-self.pos)
  if n<=0:return b''
  with request(self.url,{'Range':f'bytes={self.pos}-{self.pos+n-1}'}) as r:
   if r.status!=206:raise RuntimeError(f'Server must support ranges; got {r.status}')
   data=r.read(n)
  if len(data)!=n:raise RuntimeError('Incomplete range download')
  self.pos+=n
  return data
folder=Path('C:/Users/tautv/AppData/Roaming/Godot/export_templates/4.7.2.stable')
folder.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(RemoteZip(asset['browser_download_url'],asset['size'])) as z:
 for name in ['web_nothreads_release.zip','web_nothreads_debug.zip']:
  info=next(i for i in z.infolist() if i.filename.endswith('/'+name))
  print('Downloading',name,info.compress_size,'bytes',flush=True)
  data=z.read(info)
  with zipfile.ZipFile(io.BytesIO(data)) as inner:
   bad=inner.testzip()
   assert bad is None,bad
  (folder/name).write_bytes(data)
  print('INSTALLED',name,len(data),flush=True)
print('WEB_TEMPLATES_READY',folder,flush=True)

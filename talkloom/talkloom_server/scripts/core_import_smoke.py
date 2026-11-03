"""Run real local imports with an isolated guest account (uses configured AI credits).
Run from the server directory: python3 scripts/core_import_smoke.py
Test lessons persist only under this script's anonymous test identity.
"""
import urllib.request,json,time,base64,sys
from pathlib import Path
failed = False
base='http://localhost:8080/'
def call(path,data,token=None):
 h={'Content-Type':'application/json'}
 if token:h['Authorization']='Bearer '+token
 with urllib.request.urlopen(urllib.request.Request(base+path,data=json.dumps(data).encode(),headers=h),timeout=30) as r:return json.load(r)
a=call('anonymousIdp/login',{'token':None}); token=a['token']
cases = [('document',None,'data:text/plain;base64,'+base64.b64encode('Guten Morgen! Ich heiße Anna. Ich lerne Deutsch. Auf Wiedersehen!'.encode()).decode()),('url','https://www.youtube.com/watch?v=RuGmc662HDg',None),('text',None,'Guten Morgen! Hallo! Ich heiße Anna. Wie heißt du? Ich komme aus Deutschland. Ich lerne Deutsch. Guten Abend! Auf Wiedersehen!')]
for filename in sys.argv[1:]:
 path = Path(filename)
 mime = {'.pdf':'application/pdf', '.png':'image/png', '.jpg':'image/jpeg', '.jpeg':'image/jpeg', '.txt':'text/plain'}.get(path.suffix.lower())
 if not mime: raise ValueError('Unsupported fixture extension')
 cases.append(('image' if mime.startswith('image/') else 'document', None, 'data:'+mime+';base64,'+base64.b64encode(path.read_bytes()).decode()))
for kind,url,raw in cases:
 try:
  j=call('ingestion/startImport',dict(type=kind,title='Core check '+kind,targetLanguage='de',supportLanguage='en',cefrLevel='A1',url=url,rawContent=raw),token)
  print('START',kind,j['id'],flush=True)
  for i in range(120):
   time.sleep(2)
   s=call('ingestion/getImportJob',{'jobId':j['id']},token)
   if i%10==0:print('STAGE',kind,s['stage'],flush=True)
   if s['stage'] in ['saved','failed']:
    print('RESULT',kind,s['stage'],s.get('errorCode'),s.get('errorMessage'),flush=True)
    if s['stage']=='failed': failed=True
    if s['stage']=='saved':
     l=call('ingestion/getLessonBySourceId',{'sourceId':s['sourceId']},token)
     print('LESSON',kind,{k:len(json.loads(l[k])) for k in ['vocabulary','grammar','activities']},flush=True)
    break
  else:
   failed=True
   print('FAIL',kind,'polling deadline exceeded',flush=True)
 except Exception as e:
  failed=True
  print('FAIL',kind,type(e).__name__,str(e),flush=True)
sys.exit(1 if failed else 0)

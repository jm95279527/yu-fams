#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
python3 - "$TOK" <<'PY'
import sys,base64,json,time
p=sys.argv[1].split('.')[1]; p+='='*(-len(p)%4)
d=json.loads(base64.urlsafe_b64decode(p))
print('aud=',d.get('aud'),'exp_hours=',round((d['exp']-time.time())/3600,1))
PY
AUD=$(python3 - "$TOK" <<'PY'
import sys,base64,json
p=sys.argv[1].split('.')[1]; p+='='*(-len(p)%4)
d=json.loads(base64.urlsafe_b64decode(p))
print(d['aud'][0])
PY
)
echo "audience=$AUD"
EXP=$(python3 - "$TOK" <<'PY'
import sys,base64,hmac,hashlib,json,time
tok=sys.argv[1]
h,p,s=tok.split('.')
def dec(x): return base64.urlsafe_b64decode(x+'='*(-len(x)%4))
def b64(b): return base64.urlsafe_b64encode(b).rstrip(b'=').decode()
payload=json.loads(dec(p))
payload['exp']=int(time.time())-60
np=b64(json.dumps(payload,separators=(',',':')).encode())
si=(h+'.'+np).encode()
ns=b64(hmac.new(b'admin123',si,hashlib.sha256).digest())
print(h+'.'+np+'.'+ns)
PY
)
echo "--- 过期 token 调用 ---"
curl -s "$B/numberRule/config" -H "token: $EXP"; echo
echo "--- 正常 token 调用 ---"
curl -s "$B/numberRule/config" -H "token: $TOK"; echo

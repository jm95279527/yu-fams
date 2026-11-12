#!/bin/bash
set -e
B=http://127.0.0.1:89
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
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
cat > /www/wwwroot/yufams/expired-test.html <<EOF
<!doctype html>
<html><head><meta charset="utf-8"><title>auth test</title></head>
<body>
<script>
localStorage.setItem('xm-user', JSON.stringify({
  id: 4, username: 'admin', name: '系统管理员', role: 'ADMIN',
  token: '$EXP'
}));
location.replace('/numberRule');
</script>
</body></html>
EOF
chown www:www /www/wwwroot/yufams/expired-test.html
echo TEST_PAGE_READY

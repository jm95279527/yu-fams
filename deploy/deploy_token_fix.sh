#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage35
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== backup ==="
rm -rf /tmp/stage35bak
mkdir -p /tmp/stage35bak
cp $BACK/src/main/java/com/example/utils/TokenUtils.java /tmp/stage35bak/
cp $FRONT/src/utils/request.js $FRONT/src/views/manager/NumberRule.vue /tmp/stage35bak/
echo BACKUP_OK

echo "=== sync ==="
cp -r $SRC/backend/main/java/. $BACK/src/main/java/
cp -r $SRC/frontend/. $FRONT/src/
echo SYNC_OK

echo "=== build backend ==="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1
echo MVN_OK

echo "=== build frontend ==="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo NPM_OK

echo "=== publish + restart ==="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
systemctl restart yufams
sleep 15
systemctl is-active yufams

echo "=== 新 token 有效期 ==="
TOK=$(curl -s -X POST http://127.0.0.1:89/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
python3 - "$TOK" <<'PY'
import sys,base64,json,time
tok=sys.argv[1]
p=tok.split('.')[1]
p+='='*(-len(p)%4)
d=json.loads(base64.urlsafe_b64decode(p))
print('  expires_at=',time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(d['exp'])))
print('  valid_hours=',round((d['exp']-time.time())/3600,2))
PY

echo "=== 过期 token 提示 ==="
python3 - > /tmp/expired_token.txt <<'PY'
import base64,hmac,hashlib,json,time
def b64(b):
    return base64.urlsafe_b64encode(b).rstrip(b'=').decode()
header={"alg":"HS256","typ":"JWT"}
payload={"aud":["1-ADMIN"],"exp":int(time.time())-60}
si=(b64(json.dumps(header,separators=(',',':')).encode())+'.'+b64(json.dumps(payload,separators=(',',':')).encode())).encode()
sig=b64(hmac.new(b'admin123',si,hashlib.sha256).digest())
print(si.decode()+'.'+sig)
PY
EXP=$(cat /tmp/expired_token.txt)
curl -s "http://127.0.0.1:89/numberRule/config" -H "token: $EXP"; echo
echo STAGE35_DONE

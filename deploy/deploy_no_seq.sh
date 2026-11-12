#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage33
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== backup ==="
rm -rf /tmp/stage33bak
mkdir -p /tmp/stage33bak
cp $BACK/src/main/java/com/example/controller/AssetsController.java /tmp/stage33bak/
cp $FRONT/src/views/manager/Assets.vue $FRONT/src/views/manager/Admin.vue $FRONT/src/views/manager/Category.vue $FRONT/src/views/manager/Company.vue $FRONT/src/views/manager/Notice.vue $FRONT/src/views/manager/Staff.vue $FRONT/src/views/manager/AuditLog.vue /tmp/stage33bak/
echo BACKUP_OK

echo "=== sync backend ==="
cp -r $SRC/backend/main/java/. $BACK/src/main/java/
echo BACK_SYNC_OK

echo "=== sync frontend ==="
cp -r $SRC/frontend/. $FRONT/src/
echo FRONT_SYNC_OK

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

echo "=== 导出表头检查（不应有 序号） ==="
TOK=$(curl -s -X POST http://127.0.0.1:89/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
curl -s "http://127.0.0.1:89/assets/export?token=$TOK" -o /tmp/no_seq.xlsx
python3 - <<'PY'
import zipfile,re
z=zipfile.ZipFile('/tmp/no_seq.xlsx')
xml=''
for n in z.namelist():
    if 'sharedStrings' in n or 'worksheets/sheet' in n:
        xml+=z.read(n).decode('utf-8')
texts=re.findall(r'<t[^>]*>([^<]*)</t>',xml)
print('has_seq_header=', '序号' in texts)
print('first_headers=', texts[:6])
PY
rm -f /tmp/no_seq.xlsx
echo STAGE33_DONE

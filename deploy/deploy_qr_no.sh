#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage32
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== backup ==="
if [ ! -d /tmp/stage32bak ]; then
  mkdir -p /tmp/stage32bak
  cp $BACK/src/main/java/com/example/mapper/AssetsMapper.java /tmp/stage32bak/
  cp $BACK/src/main/java/com/example/service/AssetsService.java /tmp/stage32bak/
  cp $BACK/src/main/java/com/example/service/impl/AssetsInventoryServiceImpl.java /tmp/stage32bak/
  cp $BACK/src/main/java/com/example/controller/QrCodeController.java $BACK/src/main/java/com/example/controller/AssetsController.java /tmp/stage32bak/
  cp $BACK/src/main/resources/mapper/AssetsMapper.xml /tmp/stage32bak/
  cp $FRONT/src/router/index.js $FRONT/src/views/Scan.vue /tmp/stage32bak/
  cp $FRONT/src/views/manager/Assets.vue $FRONT/src/views/manager/AssetsIn.vue /tmp/stage32bak/
fi
echo BACKUP_OK

echo "=== sync backend ==="
cp -r $SRC/backend/main/java/. $BACK/src/main/java/
cp -r $SRC/backend/main/resources/. $BACK/src/main/resources/
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
echo "--- 按编号查询 ---"
curl -s "http://127.0.0.1:89/qr/assetByNo/HM-DZ012026090001" | python3 -c 'import sys,json;d=json.load(sys.stdin);print("code=",d["code"]," assetId=",d["data"]["assetId"] if d.get("data") else None)'
echo "--- 旧ID查询兼容 ---"
curl -s "http://127.0.0.1:89/qr/asset/125" | python3 -c 'import sys,json;d=json.load(sys.stdin);print("code=",d["code"]," assetId=",d["data"]["assetId"] if d.get("data") else None)'
echo STAGE32_DONE

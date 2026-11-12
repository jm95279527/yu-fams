#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/stage25
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

mkdir -p /tmp/stage25bak
cp $BACK/src/main/java/com/example/controller/QrCodeController.java /tmp/stage25bak/
cp $BACK/src/main/java/com/example/service/AssetsService.java /tmp/stage25bak/
echo BACKUP_OK

cp $SRC/backend/main/java/com/example/controller/QrCodeController.java $BACK/src/main/java/com/example/controller/
cp $SRC/backend/main/java/com/example/service/AssetsService.java $BACK/src/main/java/com/example/service/

cd $BACK
mvn clean package -DskipTests -q > $SRC/build.log 2>&1
echo MVN_OK
systemctl restart yufams
sleep 15
systemctl is-active yufams

echo "--- 扫码只读接口应带上 使用部门 / 责任人 ---"
curl -s http://127.0.0.1:89/qr/asset/125 | python3 -m json.tool --no-ensure-ascii
echo STAGE25_DONE

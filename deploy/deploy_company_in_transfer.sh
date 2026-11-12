#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage29
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== backup ==="
mkdir -p /tmp/stage29bak
cp $BACK/src/main/java/com/example/entity/AssetsIn.java $BACK/src/main/java/com/example/entity/AssetsTransfer.java /tmp/stage29bak/
cp $BACK/src/main/java/com/example/controller/AssetsInController.java /tmp/stage29bak/
cp $BACK/src/main/resources/mapper/AssetsInMapper.xml $BACK/src/main/resources/mapper/AssetsTransferMapper.xml /tmp/stage29bak/
cp $FRONT/src/views/manager/AssetsIn.vue $FRONT/src/views/manager/AssetsTransfer.vue /tmp/stage29bak/
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
echo STAGE29_DONE

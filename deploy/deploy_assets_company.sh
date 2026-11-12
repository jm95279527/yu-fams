#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage28
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== backup ==="
mkdir -p /tmp/stage28bak
cp $BACK/src/main/java/com/example/entity/Assets.java /tmp/stage28bak/
cp $BACK/src/main/java/com/example/controller/AssetsController.java $BACK/src/main/java/com/example/controller/QrCodeController.java /tmp/stage28bak/
cp $BACK/src/main/resources/mapper/AssetsMapper.xml /tmp/stage28bak/
cp $FRONT/src/utils/siteConfig.js /tmp/stage28bak/
cp $FRONT/src/views/Scan.vue $FRONT/src/views/manager/Assets.vue /tmp/stage28bak/
echo BACKUP_OK

echo "=== apply SQL (scan_fields + company) ==="
$M < $SRC/backend/main/resources/sql/scan_field_company.sql
$M -N -e "select concat('scan_fields = [',ifnull(config_value,''),']') from sys_config where config_key='scan_fields'"

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
echo "--- 公开配置 ---"
curl -s http://127.0.0.1:89/sysConfig/public | python3 -m json.tool --no-ensure-ascii
echo STAGE28_DONE

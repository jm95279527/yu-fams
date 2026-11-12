#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage26
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== backup ==="
mkdir -p /tmp/stage26bak
cp $BACK/src/main/java/com/example/service/SysConfigService.java /tmp/stage26bak/
cp $BACK/src/main/java/com/example/controller/QrCodeController.java /tmp/stage26bak/
cp $BACK/src/main/java/com/example/controller/ScanController.java /tmp/stage26bak/
cp $BACK/src/main/java/com/example/service/AssetsService.java /tmp/stage26bak/
cp $BACK/src/main/java/com/example/mapper/AssetsMapper.java /tmp/stage26bak/
cp $BACK/src/main/resources/mapper/AssetsMapper.xml /tmp/stage26bak/
cp $BACK/src/main/java/com/example/common/filter/AuditLogFilter.java /tmp/stage26bak/
cp $FRONT/src/views/Scan.vue $FRONT/src/views/Login.vue /tmp/stage26bak/
cp $FRONT/src/utils/siteConfig.js /tmp/stage26bak/
cp $FRONT/src/views/manager/PageSetting.vue /tmp/stage26bak/
echo BACKUP_OK

echo "=== apply SQL (scan_fields) ==="
$M < $SRC/backend/main/resources/sql/scan_fields.sql
$M -N -e "select concat('  ',config_key,' = [',ifnull(config_value,''),']') from sys_config where config_key='scan_fields'"

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

echo "--- 公开配置应含 scanFields ---"
curl -s http://127.0.0.1:89/sysConfig/public | python3 -m json.tool --no-ensure-ascii
echo "--- 扫码资产接口应含 depreciate ---"
curl -s http://127.0.0.1:89/qr/asset/125 | python3 -m json.tool --no-ensure-ascii
echo "--- 已撤销的编辑接口应 404 ---"
for u in /scan/editInfo/125 /scan/staffList; do
  printf "  GET %-24s -> %s\n" "$u" "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:89$u)"
done
printf "  POST /scan/updateAsset        -> %s\n" "$(curl -s -o /dev/null -w '%{http_code}' -X POST http://127.0.0.1:89/scan/updateAsset -H 'Content-Type: application/json' -d '{"id":125,"name":"x"}')"
echo STAGE26_DONE

#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage30
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== backup ==="
rm -rf /tmp/stage30bak
mkdir -p /tmp/stage30bak
cp -a $BACK/src/main /tmp/stage30bak/backend-main
cp -a $FRONT/src /tmp/stage30bak/frontend-src
echo BACKUP_OK

echo "=== apply SQL (asset_field_config) ==="
$M < $SRC/backend/main/resources/sql/asset_field_config.sql
echo "--- 字段配置 ---"
$M -N -e "select concat(field_key,' = ',label,' | type=',field_type,' | enabled=',enabled,' | system=',is_system) from asset_field_config order by sort_num,id"
echo "--- assets 自定义列 ---"
$M -N -e "select column_name from information_schema.columns where table_schema='xm-assets' and table_name='assets' and column_name like 'custom%' order by column_name"
echo "--- 菜单 24 ---"
$M -N -e "select concat(id,' | ',name,' | api=',ifnull(api,''),' | role2=',(select count(*) from sys_role_menu where role_id=2 and menu_id=24)) from sys_menu where id=24"

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
echo "--- 公开字段接口 ---"
curl -s http://127.0.0.1:89/assetField/public | python3 -m json.tool --no-ensure-ascii | head -40
echo STAGE30_DONE

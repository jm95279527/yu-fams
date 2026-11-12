#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage19
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== 1. backup ==="
mkdir -p /tmp/stage19bak
cp $BACK/src/main/java/com/example/common/config/WebConfig.java /tmp/stage19bak/
cp $FRONT/src/main.js /tmp/stage19bak/
cp $FRONT/src/router/index.js /tmp/stage19bak/
cp $FRONT/src/views/Manager.vue $FRONT/src/views/Login.vue /tmp/stage19bak/
cp $FRONT/src/views/manager/Home.vue /tmp/stage19bak/
echo BACKUP_OK

echo "=== 2. apply SQL ==="
$M < $SRC/backend/main/resources/sql/page_setting.sql
$M -N -e "select concat('  sys_config 行数=',count(*)) from sys_config"
$M -N -e "select concat('  ',config_key,' = ',ifnull(config_value,'(空)')) from sys_config order by id"
$M -N -e "select concat('  菜单56=',name,' path=',path,' api=',api,' parent=',parent_id,' sort=',sort) from sys_menu where id=56"
$M -N -e "select concat('  授权角色数=',count(*)) from sys_role_menu where menu_id=56"
echo SQL_OK

echo "=== 3. sync backend ==="
cp -r $SRC/backend/main/java/. $BACK/src/main/java/
cp -r $SRC/backend/main/resources/. $BACK/src/main/resources/
echo BACK_SYNC_OK

echo "=== 4. sync frontend ==="
cp -r $SRC/frontend/. $FRONT/src/
echo FRONT_SYNC_OK

echo "=== 5. build backend ==="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1
echo MVN_OK
ls -la target/springboot-0.0.1-SNAPSHOT.jar

echo "=== 6. build frontend ==="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo NPM_OK
ls -la dist/index.html

echo "=== 7. publish + restart ==="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
systemctl restart yufams
sleep 15
systemctl is-active yufams
curl -s -o /dev/null -w "login89=%{http_code}\n" -X POST http://127.0.0.1:89/login
curl -s -o /dev/null -w "front88=%{http_code}\n" http://127.0.0.1:88/
echo "--- 免登录公开配置接口 ---"
curl -s -o /dev/null -w "sysConfig/public(无token)=%{http_code}\n" http://127.0.0.1:89/sysConfig/public
curl -s http://127.0.0.1:89/sysConfig/public
echo ""
echo STAGE19_DONE

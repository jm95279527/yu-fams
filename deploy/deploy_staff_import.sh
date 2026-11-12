#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage14
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== 1. backup ==="
mkdir -p /tmp/stage14bak
cp $BACK/src/main/java/com/example/service/StaffService.java /tmp/stage14bak/
cp $BACK/src/main/java/com/example/controller/StaffController.java /tmp/stage14bak/
cp -r $BACK/src/main/resources/mapper /tmp/stage14bak/mapper.bak
cp $FRONT/src/views/manager/Staff.vue $FRONT/src/views/manager/Department.vue /tmp/stage14bak/
echo BACKUP_OK

echo "=== 2. apply SQL ==="
$M < $SRC/backend/main/resources/sql/staff_menu.sql
$M -N -e "select concat(id,' | parent=',parent_id,' | ',name,' | sort=',sort) from sys_menu where id in (20,21,22,23,24,43,55) order by parent_id,sort"
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
echo STAGE14_DONE

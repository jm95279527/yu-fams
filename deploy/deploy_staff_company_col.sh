#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage15
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== backup ==="
mkdir -p /tmp/stage15bak
cp $BACK/src/main/java/com/example/service/StaffService.java /tmp/stage15bak/
cp $BACK/src/main/java/com/example/controller/StaffController.java /tmp/stage15bak/
cp $FRONT/src/views/manager/Staff.vue /tmp/stage15bak/
echo BACKUP_OK

echo "=== copy ==="
cp $SRC/backend/main/java/com/example/service/StaffService.java $BACK/src/main/java/com/example/service/
cp $SRC/backend/main/java/com/example/controller/StaffController.java $BACK/src/main/java/com/example/controller/
cp $SRC/frontend/views/manager/Staff.vue $FRONT/src/views/manager/
grep -n 'row1.put("公司"' $BACK/src/main/java/com/example/controller/StaffController.java
grep -n 'cell(row, "公司")' $BACK/src/main/java/com/example/service/StaffService.java
echo COPY_OK

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
curl -s -o /dev/null -w "login89=%{http_code}\n" -X POST http://127.0.0.1:89/login
curl -s -o /dev/null -w "front88=%{http_code}\n" http://127.0.0.1:88/
echo STAGE15_DONE

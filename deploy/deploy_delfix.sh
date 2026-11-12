#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/delfix
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== backup ==="
mkdir -p /tmp/delfixbak
cp $BACK/src/main/java/com/example/service/AssetsReceiveService.java /tmp/delfixbak/
cp $FRONT/src/views/manager/AssetsReceive.vue $FRONT/src/views/manager/AssetsRepair.vue /tmp/delfixbak/ 2>/dev/null || true
echo BACKUP_OK

echo "=== copy backend ==="
cp $SRC/backend/main/java/com/example/service/AssetsReceiveService.java $BACK/src/main/java/com/example/service/
grep -c restoreStockIfBorrowed $BACK/src/main/java/com/example/service/AssetsReceiveService.java

echo "=== copy frontend ==="
cp $SRC/frontend/views/manager/AssetsReceive.vue $SRC/frontend/views/manager/AssetsRepair.vue $FRONT/src/views/manager/
grep -n -F "user.role === 'ADMIN' || scope.row.status" $FRONT/src/views/manager/AssetsReceive.vue $FRONT/src/views/manager/AssetsRepair.vue

echo "=== build backend ==="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1
echo MVN_OK
ls -la target/springboot-0.0.1-SNAPSHOT.jar

echo "=== build frontend ==="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo NPM_OK
ls -la dist/index.html

echo "=== publish + restart ==="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
systemctl restart yufams
sleep 15
systemctl is-active yufams
curl -s -o /dev/null -w "login89=%{http_code}\n" -X POST http://127.0.0.1:89/login
curl -s -o /dev/null -w "front88=%{http_code}\n" http://127.0.0.1:88/
echo DELFIX_DONE

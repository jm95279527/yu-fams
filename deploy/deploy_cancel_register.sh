#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage20
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== 1. backup ==="
mkdir -p /tmp/stage20bak
cp $BACK/src/main/java/com/example/controller/WebController.java /tmp/stage20bak/
cp $BACK/src/main/java/com/example/common/config/WebConfig.java /tmp/stage20bak/
cp $BACK/src/main/java/com/example/common/filter/AuditLogFilter.java /tmp/stage20bak/
cp $BACK/src/main/java/com/example/service/StaffService.java $BACK/src/main/java/com/example/service/AdminService.java /tmp/stage20bak/
cp $FRONT/src/views/Login.vue $FRONT/src/views/Front.vue /tmp/stage20bak/
cp $FRONT/src/router/index.js /tmp/stage20bak/
cp $FRONT/src/views/Register.vue /tmp/stage20bak/ 2>/dev/null || true
echo BACKUP_OK

echo "=== 2. 删除服务端 Register.vue ==="
rm -f $FRONT/src/views/Register.vue
echo "  Register.vue 是否存在：$([ -f $FRONT/src/views/Register.vue ] && echo 是 || echo 否)"

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
echo "--- /register 应已下线 ---"
curl -s -X POST http://127.0.0.1:89/register -H 'Content-Type: application/json' \
  -d '{"username":"hacker","password":"123","role":"STAFF"}' -o /tmp/reg.out -w "http=%{http_code} " ; cat /tmp/reg.out; echo
echo STAGE20_DONE

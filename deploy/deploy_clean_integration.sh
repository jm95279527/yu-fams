#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage17
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== 1. backup ==="
mkdir -p /tmp/stage17bak
cp -r $BACK/src/main/java/com/example /tmp/stage17bak/example.bak 2>/dev/null || true
cp -r $BACK/src/main/resources/mapper /tmp/stage17bak/mapper.bak
cp $FRONT/src/router/index.js /tmp/stage17bak/router_index.js.bak
cp $FRONT/src/views/Manager.vue /tmp/stage17bak/Manager.vue.bak
echo BACKUP_OK

echo "=== 2. 删除服务端死代码文件 ==="
rm -f $BACK/src/main/java/com/example/controller/IntegrationController.java
rm -f $BACK/src/main/java/com/example/service/WechatWorkService.java
rm -f $BACK/src/main/java/com/example/service/WechatWorkSyncService.java
rm -f $BACK/src/main/java/com/example/mapper/WechatWorkConfigMapper.java
rm -f $BACK/src/main/resources/mapper/WechatWorkConfigMapper.xml
rm -f $BACK/src/main/java/com/example/entity/WechatWorkConfig.java
rm -f $BACK/src/main/java/com/example/entity/DingTalkConfig.java
rm -f $FRONT/src/views/WechatCallback.vue
rm -f $FRONT/src/views/manager/Integration.vue
echo "--- 残留检查（应无输出）---"
ls $BACK/src/main/java/com/example/controller/IntegrationController.java \
   $BACK/src/main/java/com/example/service/WechatWork*.java \
   $BACK/src/main/java/com/example/entity/WechatWorkConfig.java \
   $BACK/src/main/java/com/example/entity/DingTalkConfig.java \
   $FRONT/src/views/WechatCallback.vue $FRONT/src/views/manager/Integration.vue 2>&1 | grep -v 'No such file' || echo DELETED_OK

echo "=== 3. 同步本次改动的源码 ==="
cp -r $SRC/backend/main/java/. $BACK/src/main/java/
cp -r $SRC/backend/main/resources/. $BACK/src/main/resources/
cp -r $SRC/frontend/. $FRONT/src/
echo SYNC_OK

echo "=== 4. 应用 SQL（移除菜单 31）==="
$M < $SRC/backend/main/resources/sql/cleanup_integration.sql
$M -N -e "select concat('菜单31剩余=',count(*)) from sys_menu where id=31"
$M -N -e "select concat('角色授权31剩余=',count(*)) from sys_role_menu where menu_id=31"
echo SQL_OK

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
echo STAGE17_DONE

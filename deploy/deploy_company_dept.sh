#!/bin/bash
# 需求13：借用到期提醒 + 一物一码 + 分子公司 + 部门导入  部署脚本
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage13
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"

echo "===== 0. env check ====="
grep -q "VUE_APP_BASEURL='/api'" $FRONT/.env.production && echo ENV_OK
grep -n '^front-base-url' $BACK/src/main/resources/application.yml || true

echo "===== 1. backup ====="
mkdir -p /tmp/stage13bak
cp $BACK/src/main/resources/application.yml /tmp/stage13bak/application.yml.bak
cp -r $BACK/src/main/java/com/example /tmp/stage13bak/example.bak 2>/dev/null || true
cp $FRONT/src/router/index.js /tmp/stage13bak/router_index.js.bak
echo BACKUP_OK

echo "===== 2. apply SQL ====="
$M < $SRC/backend/main/resources/sql/borrow_remind.sql
$M < $SRC/backend/main/resources/sql/company_dept.sql
echo SQL_OK

echo "===== 3. sync backend src ====="
cp -r $SRC/backend/main/java/. $BACK/src/main/java/
cp -r $SRC/backend/main/resources/. $BACK/src/main/resources/
echo BACK_SYNC_OK

echo "===== 4. sync frontend src ====="
cp -r $SRC/frontend/. $FRONT/src/
echo FRONT_SYNC_OK

echo "===== 5. build backend ====="
cd $BACK
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1
echo MVN_OK
ls -la target/springboot-0.0.1-SNAPSHOT.jar

echo "===== 6. build frontend ====="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo NPM_OK
ls -la dist/index.html

echo "===== 7. publish + restart ====="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
systemctl restart yufams
sleep 15
systemctl is-active yufams
echo RESTART_OK

echo "===== 8. verify ====="
$M -N -e "select concat('company_rows=',count(*)) from company"
$M -N -e "select concat('menu55=',name,' api=',api) from sys_menu where id=55"
$M -N -e "select concat('tpl=',event_key,' enabled=',enabled) from notify_template where event_key='RECEIVE_DUE'"
$M -N -e "select concat('dep_company_col=',count(*)) from information_schema.columns where table_schema='xm-assets' and table_name='department' and column_name='company_id'"
curl -s -o /dev/null -w "login89=%{http_code}\n" -X POST http://127.0.0.1:89/login
curl -s -o /dev/null -w "front88=%{http_code}\n" http://127.0.0.1:88/
echo ALL_DONE

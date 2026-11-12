#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage_inv
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== sync backend ==="
cp -r $SRC/backend/main/java/. $BACK/src/main/java/
cp -r $SRC/backend/main/resources/. $BACK/src/main/resources/
echo BACK_SYNC_OK

echo "=== sync frontend ==="
cp -r $SRC/frontend/. $FRONT/src/
echo FRONT_SYNC_OK

echo "=== migrate db ==="
if ! mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SHOW COLUMNS FROM inventory_task LIKE 'access_code'" 2>/dev/null | grep -q access_code; then
  mysql -uroot -pYOUR_DB_PASSWORD xm-assets < $BACK/src/main/resources/sql/inventory_access_code.sql
  echo DB_MIGRATED
else
  echo DB_ALREADY
fi

echo "=== build backend ==="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1 || { tail -n 80 $SRC/build-back.log; exit 1; }
echo MVN_OK

echo "=== build frontend ==="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1 || { tail -n 80 $SRC/build-front.log; exit 1; }
echo NPM_OK

echo "=== publish + restart ==="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
systemctl restart yufams
sleep 15
systemctl is-active yufams
echo STAGE_INV_DONE

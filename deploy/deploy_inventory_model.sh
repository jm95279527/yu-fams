#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage_invmodel
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== sync ==="
cp -r $SRC/backend/main/java/. $BACK/src/main/java/
cp -r $SRC/backend/main/resources/. $BACK/src/main/resources/
cp -r $SRC/frontend/. $FRONT/src/
echo SYNC_OK

echo "=== migrate db ==="
if ! mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SHOW COLUMNS FROM inventory_item LIKE 'model'" 2>/dev/null | grep -q model; then
  mysql -uroot -pYOUR_DB_PASSWORD xm-assets < $BACK/src/main/resources/sql/inventory_item_model.sql
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
echo STAGE_INVMODEL_DONE

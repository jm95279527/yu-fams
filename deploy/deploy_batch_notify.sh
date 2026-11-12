#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/batchnotify
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"

echo "===== 1. 应用 SQL（新增 ASSETS_IN_BATCH 模板）====="
$M < $SRC/notify_submit.sql
$M -N -e "SELECT CONCAT(event_key,' enabled=',enabled) FROM notify_template WHERE event_key LIKE '%SUBMIT%' OR event_key='ASSETS_IN_BATCH' ORDER BY id;"
$M -N -e "SELECT CONCAT('模板总数=',COUNT(*),' 启用=',SUM(enabled)) FROM notify_template;"

echo "===== 2. 覆盖后端 ====="
cp $SRC/AssetsInService.java $BACK/src/main/java/com/example/service/
cp $SRC/notify_submit.sql $BACK/src/main/resources/sql/

echo "===== 3. 构建 + 重启 ====="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build.log 2>&1
echo "build exit=$?"
tail -4 $SRC/build.log
pkill -9 -f 'springboot-0.0.1-SNAPSHOT' || true
sleep 3
bash /tmp/restart89.sh
echo DONE

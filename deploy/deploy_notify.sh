#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/rr_notify
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"

echo "===== 1. 应用 SQL ====="
$M < $SRC/backend/main/resources/sql/robot_notify.sql
echo "sql ok"
$M -N -e "SELECT CONCAT('robot_config=',COUNT(*)) FROM robot_config; SELECT CONCAT('notify_template=',COUNT(*)) FROM notify_template; SELECT CONCAT('menus=',COUNT(*)) FROM sys_menu WHERE path IN ('/robotConfig','/notifyConfig');"

echo "===== 2. 后端 java ====="
B=$SRC/backend/main/java/com/example
cp $B/entity/RobotConfig.java $B/entity/NotifyTemplate.java $B/entity/NotifyLog.java $BACK/src/main/java/com/example/entity/
cp $B/mapper/RobotConfigMapper.java $B/mapper/NotifyTemplateMapper.java $B/mapper/NotifyLogMapper.java $BACK/src/main/java/com/example/mapper/
cp $B/service/NotifyService.java $BACK/src/main/java/com/example/service/
cp $B/service/AssetsInService.java $B/service/AssetsReceiveService.java $BACK/src/main/java/com/example/service/
cp $B/service/impl/AssetsScrapServiceImpl.java $B/service/impl/AssetsTransferServiceImpl.java $B/service/impl/AssetsRepairServiceImpl.java $BACK/src/main/java/com/example/service/impl/
cp $B/controller/RobotConfigController.java $B/controller/NotifyController.java $BACK/src/main/java/com/example/controller/
echo copied

echo "===== 3. 后端 xml / sql ====="
cp $SRC/backend/main/resources/mapper/RobotConfigMapper.xml $SRC/backend/main/resources/mapper/NotifyTemplateMapper.xml $SRC/backend/main/resources/mapper/NotifyLogMapper.xml $BACK/src/main/resources/mapper/
cp $SRC/backend/main/resources/sql/robot_notify.sql $BACK/src/main/resources/sql/

echo "===== 4. 前端（含 router 差异检查）====="
echo "--- router/index.js diff（服务器现有 vs 本次上传）---"
diff $FRONT/src/router/index.js $SRC/frontend/router/index.js || true
cp $SRC/frontend/router/index.js $FRONT/src/router/index.js
cp $SRC/frontend/views/manager/RobotConfig.vue $SRC/frontend/views/manager/NotifyConfig.vue $FRONT/src/views/manager/

echo "===== 5. 构建后端 ====="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1
echo "backend build exit=$?"
tail -8 $SRC/build-back.log

echo "===== 6. 构建前端 ====="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo "frontend build exit=$?"
tail -4 $SRC/build-front.log

echo "===== 7. 发布 + 重启后端 ====="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
nginx -s reload
bash /tmp/restart89.sh
echo DONE

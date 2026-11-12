#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/borrow
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"

echo "===== 1. 应用 SQL（新增字段 + 文案）====="
$M < $SRC/backend/main/resources/sql/borrow_repair.sql
$M -N -e "SELECT CONCAT('assets_receive 新列: ',GROUP_CONCAT(COLUMN_NAME)) FROM information_schema.columns WHERE table_schema='xm-assets' AND table_name='assets_receive' AND COLUMN_NAME IN ('borrower_name','borrower_phone');"
$M -N -e "SELECT CONCAT('assets_repair 新列: ',GROUP_CONCAT(COLUMN_NAME)) FROM information_schema.columns WHERE table_schema='xm-assets' AND table_name='assets_repair' AND COLUMN_NAME IN ('reporter_name','reporter_phone');"
$M -N -e "SELECT CONCAT('菜单14=',name) FROM sys_menu WHERE id=14;"
$M -N -e "SELECT CONCAT('模板 ',event_key,' biz=',biz_type,' name=',event_name) FROM notify_template WHERE event_key LIKE 'RECEIVE%';"

echo "===== 2. 后端文件 ====="
B=$SRC/backend/main/java/com/example
cp $B/entity/AssetsReceive.java $B/entity/AssetsRepair.java $B/entity/NotifyTemplate.java $BACK/src/main/java/com/example/entity/
cp $B/service/AssetsReceiveService.java $BACK/src/main/java/com/example/service/
cp $B/service/impl/AssetsRepairServiceImpl.java $BACK/src/main/java/com/example/service/impl/
cp $B/controller/AssetsReceiveController.java $B/controller/ScanController.java $BACK/src/main/java/com/example/controller/
cp $SRC/backend/main/resources/mapper/AssetsReceiveMapper.xml $SRC/backend/main/resources/mapper/AssetsRepairMapper.xml $BACK/src/main/resources/mapper/
cp $SRC/backend/main/resources/sql/borrow_repair.sql $BACK/src/main/resources/sql/
echo copied

echo "===== 3. 前端文件 ====="
cp $SRC/frontend/views/Scan.vue $SRC/frontend/views/Manager.vue $FRONT/src/views/
cp $SRC/frontend/views/manager/Assets.vue $SRC/frontend/views/manager/AssetsReceive.vue $SRC/frontend/views/manager/AssetsRepair.vue $SRC/frontend/views/manager/StaffAssets.vue $SRC/frontend/views/manager/NotifyConfig.vue $FRONT/src/views/manager/
echo "--- router diff（服务器现有 vs 本次）---"
diff $FRONT/src/router/index.js $SRC/frontend/router/index.js || true
cp $SRC/frontend/router/index.js $FRONT/src/router/index.js

echo "===== 4. 构建后端 ====="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1
echo "backend build exit=$?"
tail -8 $SRC/build-back.log

echo "===== 5. 构建前端 ====="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo "frontend build exit=$?"
tail -4 $SRC/build-front.log

echo "===== 6. 发布 + 重启 ====="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
nginx -s reload
bash /tmp/restart89.sh
echo DONE

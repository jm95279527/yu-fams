#!/bin/bash
set -e
BE=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FE=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/inv_deploy
export MYSQL_PWD=YOUR_DB_PASSWORD

echo "== [1/7] apply SQL =="
mysql -uroot xm-assets < $SRC/inventory_deal.sql
mysql -uroot xm-assets -N -e "SHOW COLUMNS FROM inventory_item LIKE 'deal_status'; SHOW COLUMNS FROM inventory_task LIKE 'pending_diff_count';"

echo "== [2/7] copy source files =="
cp $SRC/InventoryItem.java            $BE/src/main/java/com/example/entity/
cp $SRC/InventoryTask.java            $BE/src/main/java/com/example/entity/
cp $SRC/InventoryItemMapper.java      $BE/src/main/java/com/example/mapper/
cp $SRC/InventoryItemMapper.xml       $BE/src/main/resources/mapper/
cp $SRC/InventoryTaskMapper.xml       $BE/src/main/resources/mapper/
cp $SRC/AssetsInventoryService.java   $BE/src/main/java/com/example/service/
cp $SRC/AssetsInventoryServiceImpl.java $BE/src/main/java/com/example/service/impl/
cp $SRC/AssetsInventoryController.java $BE/src/main/java/com/example/controller/
cp $SRC/AssetsInventory.vue           $FE/src/views/manager/

echo "== [3/7] backend mvn build =="
cd $BE
mvn clean package -DskipTests -q
ls -la target/springboot-0.0.1-SNAPSHOT.jar

echo "== [4/7] frontend build =="
cd $FE
npm run build > /tmp/inv_deploy/npm_build.log 2>&1
test -d $FE/dist
tail -3 /tmp/inv_deploy/npm_build.log

echo "== [5/7] publish dist + reload nginx =="
rm -rf /www/wwwroot/yufams/*
cp -r $FE/dist/* /www/wwwroot/yufams/
nginx -s reload

echo "== [6/7] restart backend =="
bash /tmp/restart_backend.sh
sleep 8

echo "== [7/7] health check =="
curl -s -X POST http://localhost:89/login -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | head -c 200
echo ""
echo DEPLOY_DONE

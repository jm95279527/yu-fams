#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage_inv_company/opt/yu-fams
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== sync ==="
cp $SRC/Yu-FAMS-SpringBoot-master/src/main/java/com/example/service/impl/AssetsInventoryServiceImpl.java $BACK/src/main/java/com/example/service/impl/
cp $SRC/Yu-FAMS-SpringBoot-master/src/main/java/com/example/controller/AssetsInventoryController.java $BACK/src/main/java/com/example/controller/
cp $SRC/Yu-FAMS-SpringBoot-master/src/main/java/com/example/entity/InventoryTask.java $BACK/src/main/java/com/example/entity/
cp $SRC/Yu-FAMS-Vue-master/src/views/manager/AssetsInventory.vue $FRONT/src/views/manager/
echo SYNC_OK

echo "=== build backend ==="
cd $BACK
mvn clean package -DskipTests -q > /tmp/inv_company_back.log 2>&1 || { tail -n 80 /tmp/inv_company_back.log; exit 1; }
echo MVN_OK

echo "=== build frontend ==="
cd $FRONT
npm run build > /tmp/inv_company_front.log 2>&1 || { tail -n 80 /tmp/inv_company_front.log; exit 1; }
echo NPM_OK

echo "=== publish + restart ==="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
systemctl restart yufams
sleep 15
systemctl is-active yufams
echo STAGE_INV_COMPANY_DONE

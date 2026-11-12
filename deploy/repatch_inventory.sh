#!/bin/bash
set -e
BE=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/inv_deploy
cp $SRC/AssetsInventoryController.java $BE/src/main/java/com/example/controller/
cp $SRC/AssetsInventoryServiceImpl.java $BE/src/main/java/com/example/service/impl/
cp $SRC/InventoryItem.java $BE/src/main/java/com/example/entity/
cd $BE
mvn clean package -DskipTests -q
echo "BUILD_OK"
bash /tmp/restart_backend.sh
sleep 8
curl -s -X POST http://localhost:89/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | head -c 60
echo ""
echo RESTART_DONE

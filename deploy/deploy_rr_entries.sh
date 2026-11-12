#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/rr

echo "===== 1. 覆盖后端 ====="
cp $SRC/AssetsReceiveService.java $BACK/src/main/java/com/example/service/
echo "===== 2. 覆盖前端 ====="
cp $SRC/Assets.vue $SRC/AssetsReceive.vue $SRC/AssetsRepair.vue $FRONT/src/views/manager/
echo copied

echo "===== 3. 构建后端 ====="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1
echo "backend build exit=$?"
tail -4 $SRC/build-back.log

echo "===== 4. 构建前端 ====="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo "frontend build exit=$?"
tail -5 $SRC/build-front.log

echo "===== 5. 发布前端 ====="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
nginx -s reload
echo "===== 6. 重启后端 ====="
bash /tmp/restart89.sh
echo DONE

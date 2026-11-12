#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage34
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== backup ==="
rm -rf /tmp/stage34bak
mkdir -p /tmp/stage34bak
cp $BACK/src/main/java/com/example/entity/Category.java /tmp/stage34bak/
cp $BACK/src/main/java/com/example/mapper/CategoryMapper.java /tmp/stage34bak/
cp $BACK/src/main/java/com/example/service/CategoryService.java /tmp/stage34bak/
cp $BACK/src/main/resources/mapper/CategoryMapper.xml /tmp/stage34bak/
cp $FRONT/src/views/manager/Category.vue $FRONT/src/views/manager/Assets.vue $FRONT/src/views/manager/AssetsIn.vue $FRONT/src/views/manager/NumberRule.vue $FRONT/src/views/manager/AssetsInventory.vue /tmp/stage34bak/
echo BACKUP_OK

echo "=== apply SQL (category_level2) ==="
$M < $SRC/backend/main/resources/sql/category_level2.sql
$M -e "desc category"
$M -e "select id,name,code,pid from category order by id"

echo "=== sync backend ==="
cp -r $SRC/backend/main/java/. $BACK/src/main/java/
cp -r $SRC/backend/main/resources/. $BACK/src/main/resources/
echo BACK_SYNC_OK

echo "=== sync frontend ==="
cp -r $SRC/frontend/. $FRONT/src/
echo FRONT_SYNC_OK

echo "=== build backend ==="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1
echo MVN_OK

echo "=== build frontend ==="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo NPM_OK

echo "=== publish + restart ==="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
systemctl restart yufams
sleep 15
systemctl is-active yufams

echo "=== 分类接口检查 ==="
TOK=$(curl -s -X POST http://127.0.0.1:89/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
curl -s "http://127.0.0.1:89/category/selectAll" -H "token: $TOK" | python3 -m json.tool --no-ensure-ascii
echo STAGE34_DONE

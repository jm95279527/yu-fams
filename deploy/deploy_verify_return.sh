#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/ret
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
B=http://127.0.0.1:89
J='Content-Type: application/json'

echo "===== 1. 构建后端 ====="
cp $SRC/AssetsReceiveService.java $BACK/src/main/java/com/example/service/
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1
echo "backend build exit=$?"
tail -4 $SRC/build-back.log

echo "===== 2. 构建前端 ====="
cp $SRC/AssetsReceive.vue $FRONT/src/views/manager/
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo "frontend build exit=$?"
tail -3 $SRC/build-front.log

echo "===== 3. 发布 + 重启 ====="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
nginx -s reload
bash /tmp/restart89.sh

echo "===== 4. 归还流程验证 ====="
TOK=$(curl -s "$B/login" -H "$J" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"
AID=$($M -e "SELECT id FROM assets WHERE num > 0 ORDER BY num DESC LIMIT 1;" 2>/dev/null)
N0=$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)
echo "  测试资产 id=$AID 初始库存=$N0"

curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" \
  -d "{\"assetsId\":$AID,\"borrowerName\":\"归还测试\",\"borrowerPhone\":\"13100000001\",\"returnDate\":\"2026-12-31\",\"comment\":\"E2E归还验证\"}" > /dev/null
RID=$($M -e "SELECT id FROM assets_receive WHERE comment='E2E归还验证' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "  借用单 id=$RID 状态=$($M -e "SELECT CONCAT(status,'/',return_status) FROM assets_receive WHERE id=$RID;" 2>/dev/null)"

echo -n "  a) 审核通过 -> 库存应 -1: "
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" -d "{\"id\":$RID,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"未归还\",\"returnDate\":\"2026-12-31\"}" > /dev/null
echo "$N0 -> $($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)"

echo -n "  b) 再次提交“通过”（防重复扣减）-> 库存应不变: "
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" -d "{\"id\":$RID,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"未归还\",\"returnDate\":\"2026-12-31\"}" > /dev/null
echo "$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)"

echo -n "  c) 归还 -> 库存应 +1 回到 $N0: "
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" -d "{\"id\":$RID,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"已归还\"}" > /dev/null
echo "$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)  状态=$($M -e "SELECT CONCAT(status,'/',return_status) FROM assets_receive WHERE id=$RID;" 2>/dev/null)"

echo -n "  d) 重复归还 -> 库存应不再增加: "
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" -d "{\"id\":$RID,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"已归还\"}" > /dev/null
echo "$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)"

echo "===== 5. 清理 ====="
$M -e "DELETE FROM notify_log;" 2>/dev/null
$M -e "DELETE FROM robot_config;" 2>/dev/null
$M -e "DELETE FROM assets_receive WHERE comment='E2E归还验证';" 2>/dev/null
$M -e "UPDATE assets SET num=$N0 WHERE id=$AID;" 2>/dev/null
$M -e "SELECT CONCAT('  receive剩余=',COUNT(*)) FROM assets_receive; SELECT CONCAT('  asset$AID num=',num) FROM assets WHERE id=$AID;" 2>/dev/null
echo DONE

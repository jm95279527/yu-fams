#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/submit
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
B=http://127.0.0.1:89
J='Content-Type: application/json'

echo "===== 1. 应用 SQL（新增 5 个提交模板）====="
$M < $SRC/notify_submit.sql
$M -N -e "SELECT CONCAT(event_key,' enabled=',enabled) FROM notify_template WHERE event_key LIKE '%_SUBMIT' ORDER BY id;"

echo "===== 2. 覆盖后端文件 ====="
cp $SRC/AssetsReceiveService.java $SRC/AssetsInService.java $BACK/src/main/java/com/example/service/
cp $SRC/AssetsRepairServiceImpl.java $SRC/AssetsScrapServiceImpl.java $SRC/AssetsTransferServiceImpl.java $BACK/src/main/java/com/example/service/impl/
cp $SRC/notify_submit.sql $BACK/src/main/resources/sql/
cp $SRC/NotifyConfig.vue $FRONT/src/views/manager/
echo copied

echo "===== 3. 构建后端 ====="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1
echo "backend build exit=$?"
tail -6 $SRC/build-back.log

echo "===== 4. 构建前端 ====="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo "frontend build exit=$?"
tail -3 $SRC/build-front.log

echo "===== 5. 发布 + 重启 ====="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
nginx -s reload
pkill -9 -f 'springboot-0.0.1-SNAPSHOT' || true
sleep 3
bash /tmp/restart89.sh

echo "===== 6. 提交类通知验证（5 类）====="
TOK=$(curl -s "$B/login" -H "$J" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"
curl -s -X POST "$B/robotConfig/add" -H "$H" -H "$J" \
  -d '{"name":"E2E临时","type":"wechat","webhookUrl":"https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=e2e-submit","enabled":true}' > /dev/null

AID=$($M -e "SELECT id FROM assets WHERE num > 0 ORDER BY num DESC LIMIT 1;" 2>/dev/null)
DID=$($M -e "SELECT department_id FROM assets WHERE id=$AID;" 2>/dev/null)
DID2=$($M -e "SELECT id FROM department WHERE id <> $DID LIMIT 1;" 2>/dev/null)
echo "  测试资产 id=$AID 部门=$DID → 目标部门=$DID2"

echo -n "  a) 扫码借用（匿名）: "
curl -s -X POST "$B/scan/borrow" -H "$J" -d "{\"assetsId\":$AID,\"borrowerName\":\"提交通知测试\",\"borrowerPhone\":\"13100000011\",\"returnDate\":\"2026-12-31\",\"comment\":\"E2E提交通知借用\"}" | head -c 60; echo
echo -n "  b) 扫码报修（匿名）: "
curl -s -X POST "$B/scan/repair" -H "$J" -d "{\"assetsId\":$AID,\"assetsName\":\"E2E资产\",\"assetsCode\":\"E2E-SUB\",\"reporterName\":\"提交通知测试\",\"reporterPhone\":\"13100000012\",\"reason\":\"E2E提交通知报修\",\"faultDesc\":\"测试\"}" | head -c 60; echo
echo -n "  c) 入库提交: "
curl -s -X POST "$B/assetsIn/add" -H "$H" -H "$J" -d '{"name":"E2E入库资产","category":"办公设备","num":1,"money":100,"purchaseNo":"E2E-IN-SUB"}' | head -c 60; echo
echo -n "  d) 调拨申请: "
curl -s -X POST "$B/assetsTransfer/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"toDepartmentId\":$DID2,\"toLocation\":\"E2E新地点\",\"reason\":\"E2E调拨提交\"}" | head -c 90; echo
echo -n "  e) 报废申请: "
curl -s -X POST "$B/assetsScrap/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"scrapType\":\"正常报废\",\"reason\":\"E2E报废提交\"}" | head -c 90; echo

sleep 2
echo "--- 通知记录（应为 5 条 SUBMIT）---"
$M -e "SELECT CONCAT('  ',event_key,' | ',biz_type,' | ',status,' | ',REPLACE(LEFT(content,90),CHAR(10),' / ')) FROM notify_log ORDER BY id;" 2>/dev/null

echo "===== 7. 清理 ====="
$M -e "DELETE FROM notify_log;" 2>/dev/null
$M -e "DELETE FROM robot_config;" 2>/dev/null
$M -e "DELETE FROM assets_in WHERE purchase_no='E2E-IN-SUB';" 2>/dev/null
$M -e "DELETE FROM assets_transfer WHERE reason='E2E调拨提交';" 2>/dev/null
$M -e "DELETE FROM assets_scrap WHERE reason='E2E报废提交';" 2>/dev/null
$M -e "DELETE FROM assets_receive WHERE comment='E2E提交通知借用';" 2>/dev/null
$M -e "DELETE FROM assets_repair WHERE reason='E2E提交通知报修';" 2>/dev/null
$M -e "SELECT CONCAT('  in=',(SELECT COUNT(*) FROM assets_in WHERE purchase_no='E2E-IN-SUB'),' transfer=',(SELECT COUNT(*) FROM assets_transfer WHERE reason='E2E调拨提交'),' scrap=',(SELECT COUNT(*) FROM assets_scrap WHERE reason='E2E报废提交'),' receive=',(SELECT COUNT(*) FROM assets_receive WHERE comment='E2E提交通知借用'),' repair=',(SELECT COUNT(*) FROM assets_repair WHERE reason='E2E提交通知报修'),' log=',(SELECT COUNT(*) FROM notify_log),' robot=',(SELECT COUNT(*) FROM robot_config));" 2>/dev/null
$M -e "SELECT CONCAT('  模板总数=',COUNT(*),' 启用=',SUM(enabled)) FROM notify_template;" 2>/dev/null
echo DONE

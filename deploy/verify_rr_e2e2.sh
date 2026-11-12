#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"
AID=$($M -e "SELECT id FROM assets WHERE num > 0 ORDER BY id DESC LIMIT 1;" 2>/dev/null)
NUM0=$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)
ADMIN_ID=$($M -e "SELECT id FROM admin ORDER BY id LIMIT 1;" 2>/dev/null)
echo "asset=$AID num0=$NUM0 admin=$ADMIN_ID"

echo "=== 1) 新增领用（header token，不传 staffId → 应回退为当前管理员）==="
curl -s -X POST "$B/assetsReceive/add" -H "$H" -H 'Content-Type: application/json' \
  -d "{\"assetsId\":$AID,\"returnDate\":\"2026-12-31\",\"comment\":\"E2E临时\"}" | head -c 200; echo
RID=$($M -e "SELECT id FROM assets_receive ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "  领用单=$RID staff_id=$($M -e "SELECT IFNULL(staff_id,'NULL') FROM assets_receive WHERE id=$RID;" 2>/dev/null) (期望 $ADMIN_ID)"

echo "=== 2) 新增领用指定 staffId（模拟已建员工）==="
curl -s -X POST "$B/assetsReceive/add" -H "$H" -H 'Content-Type: application/json' \
  -d "{\"assetsId\":$AID,\"staffId\":9999,\"returnDate\":\"2026-12-31\",\"comment\":\"E2E指定员工\"}" | head -c 200; echo
RID2=$($M -e "SELECT id FROM assets_receive ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "  领用单=$RID2 staff_id=$($M -e "SELECT IFNULL(staff_id,'NULL') FROM assets_receive WHERE id=$RID2;" 2>/dev/null) (期望 9999)"

echo "=== 3) 审核通过（资产 num 应 -1）==="
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H 'Content-Type: application/json' \
  -d "{\"id\":$RID,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"未归还\",\"returnDate\":\"2026-12-31\"}" | head -c 200; echo
echo "  num: $NUM0 -> $($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)"

echo "=== 4) 新增报修 ==="
curl -s -X POST "$B/assetsRepair/add" -H "$H" -H 'Content-Type: application/json' \
  -d "{\"assetsId\":$AID,\"assetsName\":\"E2E测试资产\",\"assetsCode\":\"E2E-CODE\",\"reason\":\"E2E理由\",\"faultDesc\":\"E2E故障\"}" | head -c 200; echo
PID=$($M -e "SELECT id FROM assets_repair ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "  报修单=$PID staff_id=$($M -e "SELECT IFNULL(staff_id,'NULL') FROM assets_repair WHERE id=$PID;" 2>/dev/null) (期望 $ADMIN_ID)"
$M -e "SELECT CONCAT('  assets_id=',assets_id,' name=',IFNULL(assets_name,''),' code=',IFNULL(assets_code,''),' status=',status) FROM assets_repair WHERE id=$PID;" 2>/dev/null

echo "=== 5) 报修 -> 维修中 ==="
curl -s -X PUT "$B/assetsRepair/update" -H "$H" -H 'Content-Type: application/json' -d "{\"id\":$PID,\"status\":\"维修中\"}" | head -c 200; echo

echo "=== 6) 完成维修（不传 completeTime，后端自动写入）==="
curl -s -X PUT "$B/assetsRepair/update" -H "$H" -H 'Content-Type: application/json' \
  -d "{\"id\":$PID,\"status\":\"已完成\",\"repairResult\":\"维修完成\"}" | head -c 200; echo
$M -e "SELECT CONCAT('  status=',status,' complete_time=',IFNULL(complete_time,'NULL')) FROM assets_repair WHERE id=$PID;" 2>/dev/null

echo "=== 7) 对照：仍传非法 completeTime 字符串（复现原500，印证前端修复必要性）==="
curl -s -X PUT "$B/assetsRepair/update" -H "$H" -H 'Content-Type: application/json' \
  -d "{\"id\":$PID,\"status\":\"已完成\",\"completeTime\":\"2026/9/14 15:40:00\"}" | head -c 200; echo

echo "=== 列表校验 ==="
curl -s "$B/assetsReceive/selectPage?pageNum=1&pageSize=5" -H "$H" | python3 -c "import sys,json;d=json.load(sys.stdin);print('领用 total',d['data']['total'])"
curl -s "$B/assetsRepair/selectPage?pageNum=1&pageSize=5" -H "$H" | python3 -c "import sys,json;d=json.load(sys.stdin);print('报修 total',d['data']['total'])"

echo "=== 清理 ==="
$M -e "DELETE FROM assets_repair WHERE id=$PID; DELETE FROM assets_receive WHERE id IN ($RID,$RID2); UPDATE assets SET num=$NUM0 WHERE id=$AID;" 2>/dev/null
$M -e "SELECT CONCAT('assets_receive=',COUNT(*)) FROM assets_receive; SELECT CONCAT('assets_repair=',COUNT(*)) FROM assets_repair; SELECT CONCAT('num=',num) FROM assets WHERE id=$AID;" 2>/dev/null
echo DONE

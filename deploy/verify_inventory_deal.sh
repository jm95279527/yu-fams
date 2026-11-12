#!/bin/bash
# 资产盘点-差异处理闭环 接口验证
BASE=http://localhost:89
export MYSQL_PWD=YOUR_DB_PASSWORD
mysqlq(){ mysql -uroot xm-assets -N -e "$1" 2>/dev/null; }

PASS=0; FAIL=0
chk(){ if [ "$1" = "$2" ]; then echo "PASS: $3 ($1)"; PASS=$((PASS+1)); else echo "FAIL: $3 [expected=$2 got=$1] $4"; FAIL=$((FAIL+1)); fi; }
jget(){ python3 -c "import sys,json;d=json.load(sys.stdin);print($1)" 2>/dev/null; }

TOKEN=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | jget "d['data']['token']")
AUTH="token: $TOKEN"

echo "===== 任务1：部门12（应盘2项：26/32） ====="
T1=$(curl -s -X POST $BASE/assetsInventory/add -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"name":"RF盘点_部门12","scopeType":"DEPT","scopeId":12}')
T1ID=$(echo "$T1" | jget "d['data']['id']")
chk "$(echo "$T1" | jget "d['code']")" "200" "创建盘点任务"
chk "$(echo "$T1" | jget "d['data']['totalCount']")" "2" "部门12快照2项"
chk "$(echo "$T1" | jget "d['data']['pendingDiffCount']")" "0" "新任务待处理=0"

# 快照明细 deal_status 应为 NULL（IFNULL 输出空串）
SNAP_DS=$(mysqlq "SELECT IFNULL(deal_status,'') FROM inventory_item WHERE task_id=$T1ID AND assets_id=26")
chk "$SNAP_DS" "" "未盘快照无处理状态"

echo "===== 扫码：26正常 / 32异常 ====="
S1=$(curl -s -X POST $BASE/assetsInventory/scan/$T1ID -H "$AUTH" -H "Content-Type: application/json" -d '{"code":"26"}')
chk "$(echo "$S1" | jget "d['data']['itemStatus']")" "正常" "26扫为正常"
chk "$(echo "$S1" | jget "d['data']['dealStatus']")" "None" "正常项无处理状态"

S2=$(curl -s -X POST $BASE/assetsInventory/scan/$T1ID -H "$AUTH" -H "Content-Type: application/json" -d '{"code":"32","abnormal":true,"actualLocation":"仓库B","comment":"地点不符"}')
chk "$(echo "$S2" | jget "d['data']['itemStatus']")" "异常" "32扫为异常"
chk "$(echo "$S2" | jget "d['data']['dealStatus']")" "待处理" "异常自动进入待处理"
I32=$(echo "$S2" | jget "d['data']['id']")
PEND=$(curl -s "$BASE/assetsInventory/selectById/$T1ID" -H "$AUTH" | jget "d['data']['pendingDiffCount']")
chk "$PEND" "1" "任务待处理差异=1"

echo "===== 异常恢复正常再标回异常（处理状态联动） ====="
curl -s -X POST $BASE/assetsInventory/markItem/$I32 -H "$AUTH" -H "Content-Type: application/json" -d '{"itemStatus":"正常"}' >/dev/null
chk "$(mysqlq "SELECT IFNULL(deal_status,'') FROM inventory_item WHERE id=$I32")" "" "恢复正常清空处理状态"
curl -s -X POST $BASE/assetsInventory/markItem/$I32 -H "$AUTH" -H "Content-Type: application/json" -d '{"itemStatus":"异常"}' >/dev/null
chk "$(mysqlq "SELECT deal_status FROM inventory_item WHERE id=$I32")" "待处理" "再标异常恢复待处理"

echo "===== 处理校验 ====="
R1=$(curl -s -X POST $BASE/assetsInventory/dealItem/$I32 -H "$AUTH" -H "Content-Type: application/json" -d '{}')
chk "$(echo "$R1" | jget "d['code']")" "500" "未选处理方式被拦截"
R2=$(curl -s -X POST $BASE/assetsInventory/dealItem/$I32 -H "$AUTH" -H "Content-Type: application/json" -d '{"dealType":"报损"}')
chk "$(echo "$R2" | jget "d['code']")" "500" "异常项用盘亏处理方式被拦截"
R3=$(curl -s -X POST $BASE/assetsInventory/dealItem/$I32 -H "$AUTH" -H "Content-Type: application/json" -d '{"dealType":"调拨修正","dealRemark":"已调至仓库B"}')
chk "$(echo "$R3" | jget "d['code']")" "200" "合法处理成功"
chk "$(echo "$R3" | jget "d['data']['dealStatus']")" "已处理" "状态变已处理"
chk "$(echo "$R3" | jget "d['data']['dealType']")" "调拨修正" "处理方式落库"
chk "$(echo "$R3" | jget "d['data']['dealUser']")" "系统管理员" "处理人记录"
chk "$(mysqlq "SELECT pending_diff_count FROM inventory_task WHERE id=$T1ID")" "0" "处理后待处理归零"
R4=$(curl -s -X POST $BASE/assetsInventory/dealItem/$I32 -H "$AUTH" -H "Content-Type: application/json" -d '{"dealType":"信息更正"}')
chk "$(echo "$R4" | jget "d['code']")" "500" "重复处理被拦截"

echo "===== 范围外盘盈：扫部门13的资产27 ====="
S3=$(curl -s -X POST $BASE/assetsInventory/scan/$T1ID -H "$AUTH" -H "Content-Type: application/json" -d '{"code":"27"}')
chk "$(echo "$S3" | jget "d['data']['itemStatus']")" "盘盈" "范围外资产登记盘盈"
chk "$(echo "$S3" | jget "d['data']['isExtra']")" "1" "盘盈标记范围外"
chk "$(echo "$S3" | jget "d['data']['dealStatus']")" "待处理" "盘盈自动待处理"
I27=$(echo "$S3" | jget "d['data']['id']")
chk "$(mysqlq "SELECT total_count FROM inventory_task WHERE id=$T1ID")" "3" "总数含盘盈=3"

echo "===== 完盘后仍可处理差异 ====="
F1=$(curl -s -X POST $BASE/assetsInventory/finish/$T1ID -H "$AUTH")
chk "$(echo "$F1" | jget "d['data']['status']")" "已完成" "任务1完成（无未盘→无盘亏）"
chk "$(echo "$F1" | jget "d['data']['pendingDiffCount']")" "1" "完成后待处理=盘盈1项"
D1=$(curl -s -X POST $BASE/assetsInventory/dealItem/$I27 -H "$AUTH" -H "Content-Type: application/json" -d '{"dealType":"补录入账","dealRemark":"补录台账"}')
chk "$(echo "$D1" | jget "d['code']")" "200" "完盘后处理盘盈成功"
chk "$(mysqlq "SELECT pending_diff_count FROM inventory_task WHERE id=$T1ID")" "0" "处理后待处理清零"
# 正常项不能处理
I26=$(mysqlq "SELECT id FROM inventory_item WHERE task_id=$T1ID AND assets_id=26")
R5=$(curl -s -X POST $BASE/assetsInventory/dealItem/$I26 -H "$AUTH" -H "Content-Type: application/json" -d '{"dealType":"误盘"}')
chk "$(echo "$R5" | jget "d['code']")" "500" "正常项处理被拦截"

echo "===== 任务2：部门13直接完盘→2项盘亏 ====="
T2=$(curl -s -X POST $BASE/assetsInventory/add -H "$AUTH" -H "Content-Type: application/json" -d '{"name":"RF盘点_部门13","scopeType":"DEPT","scopeId":13}')
T2ID=$(echo "$T2" | jget "d['data']['id']")
F2=$(curl -s -X POST $BASE/assetsInventory/finish/$T2ID -H "$AUTH")
chk "$(echo "$F2" | jget "d['data']['lossCount']")" "2" "未盘2项记盘亏"
chk "$(echo "$F2" | jget "d['data']['pendingDiffCount']")" "2" "盘亏2项待处理"
chk "$(mysqlq "SELECT COUNT(*) FROM inventory_item WHERE task_id=$T2ID AND item_status='盘亏' AND deal_status='待处理'")" "2" "盘亏明细均待处理"
L1=$(mysqlq "SELECT id FROM inventory_item WHERE task_id=$T2ID LIMIT 1")
DL=$(curl -s -X POST $BASE/assetsInventory/dealItem/$L1 -H "$AUTH" -H "Content-Type: application/json" -d '{"dealType":"报损","dealRemark":"走报废流程"}')
chk "$(echo "$DL" | jget "d['code']")" "200" "盘亏按报损处理成功"
chk "$(mysqlq "SELECT pending_diff_count FROM inventory_task WHERE id=$T2ID")" "1" "任务2待处理=1"

echo "===== 工作量统计 ====="
W=$(curl -s "$BASE/assetsInventory/workload/$T1ID" -H "$AUTH")
chk "$(echo "$W" | jget "d['data'][0]['scannerName']")" "系统管理员" "工作量有admin"
chk "$(echo "$W" | jget "d['data'][0]['total']")" "3" "admin盘点3项"
chk "$(echo "$W" | jget "d['data'][0]['normalCnt']+d['data'][0]['abnormalCnt']+d['data'][0]['profitCnt']")" "3" "正常1+异常1+盘盈1=3"

echo "===== 导出报告（中文列/无内部字段） ====="
curl -s "$BASE/assetsInventory/export/$T1ID" -H "$AUTH" -o /tmp/rf_inv_rpt.xlsx
chk "$(file -b /tmp/rf_inv_rpt.xlsx | grep -c 'OOXML\|Excel')" "1" "导出为xlsx"
mkdir -p /tmp/rf_rptx && rm -rf /tmp/rf_rptx/* && cd /tmp/rf_rptx && unzip -o -q /tmp/rf_inv_rpt.xlsx
chk "$(grep -ra '处理状态' . | wc -l)" "1" "报告含处理状态列"
chk "$(grep -ra '范围外盘盈' . | wc -l)" "1" "报告含范围外盘盈列"
chk "$(grep -ra '待处理差异' . | wc -l)" "1" "报告头含待处理差异汇总"
chk "$(grep -ra 'taskId\|departmentId\|scannerId' . | wc -l)" "0" "无内部英文字段泄漏"

echo "===== 清理 ====="
mysqlq "DELETE FROM inventory_item WHERE task_id IN ($T1ID,$T2ID)"
mysqlq "DELETE FROM inventory_task WHERE id IN ($T1ID,$T2ID)"
chk "$(mysqlq "SELECT COUNT(*) FROM inventory_task WHERE name LIKE 'RF盘点%'")" "0" "测试任务已清理"

echo ""
echo "RESULT: PASS=$PASS FAIL=$FAIL"

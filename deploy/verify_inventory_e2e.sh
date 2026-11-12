#!/bin/bash
set -e
B=http://127.0.0.1:89
PASS=0; FAIL=0
check(){ if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "PASS: $1"; else FAIL=$((FAIL+1)); echo "FAIL: $1 (got=$2 want=$3)"; fi; }
jqc(){ python3 -c "import sys,json; print(json.load(sys.stdin)$1)"; }

# 0. 登录 admin
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | jqc '["data"]["token"]')
[ -n "$TOK" ] && check "admin登录" ok ok || check "admin登录" fail ok
H="-H token:$TOK"

# 1. 创建全盘任务
TASKID=$(curl -s "$B/assetsInventory/add" $H -H 'Content-Type: application/json' -d '{"type":"全部","departmentId":"","name":"E2E验证任务","remark":"e2e"}' | jqc '["data"]["id"]')
[ -n "$TASKID" ] && check "创建全盘任务(id=$TASKID)" ok ok || check "创建全盘任务" fail ok

# 2. 任务列表分页 sizes
PS=$(curl -s "$B/assetsInventory/selectPage?pageNum=1&pageSize=20" $H)
TOTAL=$(echo "$PS" | jqc '["data"]["total"]')
check "任务列表分页total>=1" "$([ $TOTAL -ge 1 ] && echo yes)" yes

# 3. 工作台明细列表
ITEMS=$(curl -s "$B/assetsInventory/items/$TASKID" $H)
ICNT=$(echo "$ITEMS" | jqc '["data"].__len__()')
check "工作台明细数>0" "$([ $ICNT -gt 0 ] && echo yes)" yes

# 取第一个资产ID
AID=$(echo "$ITEMS" | jqc '["data"][0]["assetsId"]')
IID=$(echo "$ITEMS" | jqc '["data"][0]["id"]')

# 4. 扫码盘点（正常）
curl -s "$B/assetsInventory/scan/$TASKID" $H -H 'Content-Type: application/json' -d "{\"code\":\"$AID\",\"actualLocation\":\"测试地点\",\"abnormal\":false,\"comment\":\"e2e-scan\"}" >/dev/null
STATUS=$(curl -s "$B/assetsInventory/items/$TASKID" $H | jqc "[\"data\"][] | select(.id==$IID) | .itemStatus")
check "扫码后状态=已盘" "$STATUS" "已盘"

# 5. 工作量统计
WL=$(curl -s "$B/assetsInventory/workload/$TASKID" $H)
WLCNT=$(echo "$WL" | jqc '["data"].__len__()')
check "工作量统计返回>0" "$([ $WLCNT -gt 0 ] && echo yes)" yes

# 6. 完成任务
curl -s "$B/assetsInventory/finish/$TASKID" $H >/dev/null
TSTATUS=$(curl -s "$B/assetsInventory/selectById/$TASKID" $H | jqc '["data"]["status"]')
check "任务状态=已完成" "$TSTATUS" "已完成"

# 7. 导出报告无内部列
curl -s "$B/assetsInventory/export/$TASKID" $H -o /tmp/inv_e2e.xlsx
XLEN=$(python3 -c "
import zipfile
z=zipfile.ZipFile('/tmp/inv_e2e.xlsx')
s=z.read('xl/sharedStrings.xml').decode('utf-8','ignore')
bad=[w for w in ['taskId','departmentId','isExtra','assetsId','createBy','itemId'] if w in s]
print('CLEAN' if not bad else 'BAD:'+','.join(bad))
")
check "导出无内部列" "$XLEN" "CLEAN"

# 8. 差异处理闭环（取一条盘亏/异常明细处理）
# 找一条非"正常"的明细
DIFFID=$(curl -s "$B/assetsInventory/items/$TASKID" $H | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; ids=[x['id'] for x in d if x.get('itemStatus')!='正常']; print(ids[0] if ids else '')")
if [ -n "$DIFFID" ]; then
  curl -s "$B/assetsInventory/dealItem/$DIFFID" $H -H 'Content-Type: application/json' -d '{"dealType":"报损","dealRemark":"e2e处理"}' >/dev/null
  DS=$(curl -s "$B/assetsInventory/items/$TASKID" $H | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print([x['dealStatus'] for x in d if x['id']==$DIFFID][0])")
  check "差异处理后状态=已处理" "$DS" "已处理"
else
  check "差异处理(无差异项跳过)" ok ok
fi

# 9. 清理
curl -s -X DELETE "$B/assetsInventory/delete/$TASKID" $H >/dev/null
sleep 1
LEFT=$(mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SELECT COUNT(*) FROM inventory_task WHERE id=$TASKID;" 2>/dev/null)
check "清理测试任务" "$LEFT" "0"

echo "===== $PASS PASS / $FAIL FAIL ====="
[ $FAIL -eq 0 ]

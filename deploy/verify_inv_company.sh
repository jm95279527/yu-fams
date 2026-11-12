#!/bin/bash
set -e
API=http://127.0.0.1:89
DB="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -B"

TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')

echo "=== 公司列表接口 ==="
curl -s $API/assetsInventory/companies -H "token: $TOKEN" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d["code"], [(c["id"], c["name"]) for c in d["data"]])'

COMPANY_ID=$($DB -e "select c.id from company c join department d on d.company_id=c.id join assets a on a.department_id=d.id where a.status <> '报废' group by c.id order by count(*) desc limit 1;" 2>/dev/null | head -n 1)
echo "测试公司ID=$COMPANY_ID"

EXPECT=$($DB -e "select count(*) from assets a join department d on a.department_id=d.id where d.company_id=$COMPANY_ID and a.status <> '报废';" 2>/dev/null | head -n 1)
echo "库里应盘资产数=$EXPECT"

echo "=== 创建按公司盘点任务 ==="
RESP=$(curl -s -X POST $API/assetsInventory/add -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"name\":\"公司盘点测试-$(date +%H%M%S)\",\"scopeType\":\"COMPANY\",\"scopeId\":$COMPANY_ID,\"remark\":\"company scope test\"}")
echo "$RESP" | python3 -m json.tool
TASK_ID=$(echo "$RESP" | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["id"])')
TOTAL=$(echo "$RESP" | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["totalCount"])')
echo "任务ID=$TASK_ID 总资产=$TOTAL"

echo "=== 任务明细抽检 ==="
$DB -e "select ii.assets_no, ii.department_name from inventory_item ii where ii.task_id=$TASK_ID order by ii.id limit 5;" 2>/dev/null

if [ "$TOTAL" = "$EXPECT" ]; then echo "COUNT_MATCH=YES"; else echo "COUNT_MATCH=NO"; fi

echo "=== 缺少公司校验 ==="
curl -s -X POST $API/assetsInventory/add -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"公司盘点校验","scopeType":"COMPANY"}' | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d["code"], d["msg"])'

echo "=== 清理测试任务 ==="
$DB -e "delete from inventory_item where task_id=$TASK_ID; delete from inventory_task where id=$TASK_ID;" 2>/dev/null
$DB -e "select count(*) from inventory_task where name like '公司盘点测试-%' or name='公司盘点校验';" 2>/dev/null
echo TEST_DONE

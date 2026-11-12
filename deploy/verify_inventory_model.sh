#!/bin/bash
set -e
API=http://127.0.0.1:89
CP=$(cat /tmp/cp.txt)
TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')

echo "=== 表结构 & 回填 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "SHOW COLUMNS FROM inventory_item LIKE 'model'; select count(*) total, sum(model is not null and model<>'') with_model from inventory_item;" 2>/dev/null

ID=$(mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "select id from inventory_task order by id desc limit 1" 2>/dev/null)
echo "TASK_ID=$ID"

echo "=== 明细接口含型号 ==="
curl -s "$API/assetsInventory/items/$ID" -H "token: $TOKEN" | python3 -c 'import sys,json;d=json.load(sys.stdin);rows=d.get("data") or [];print([(r["assetsNo"],r.get("model")) for r in rows[:4]])'

echo "=== 导出报告 ==="
curl -s -o /tmp/inv_report.xlsx "$API/assetsInventory/export/$ID?token=$TOKEN"
ls -lh /tmp/inv_report.xlsx

javac -encoding UTF-8 -cp "$CP" -d /tmp /tmp/DumpXlsx.java
java -cp "/tmp:$CP" DumpXlsx /tmp/inv_report.xlsx
echo REPORT_TEST_DONE

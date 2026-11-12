#!/bin/bash
API=http://127.0.0.1:89
TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
C=$(curl -s -X POST $API/assetsInventory/add -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"手机端页面验证-临时","scopeType":"ALL"}')
echo "$C" | python3 -c 'import sys,json;d=json.load(sys.stdin)["data"];print("id=%s access=%s total=%s" % (d["id"],d["accessCode"],d["totalCount"]))'
ID=$(echo "$C" | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["id"])')
A=$(echo "$C" | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["accessCode"])')
echo "--- items 未盘 ---"
curl -s -G "$API/inventoryPublic/items/$A" --data-urlencode 'tab=未盘' | head -c 300; echo
echo "--- items 已盘 ---"
curl -s -G "$API/inventoryPublic/items/$A" --data-urlencode 'tab=已盘' | head -c 200; echo
echo "--- 手机页 ---"
curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:88/inventory/$A"
echo "--- 前端chunk存在 ---"
grep -o 'inventory' /www/wwwroot/yufams/index.html | head -n 2
ls /www/wwwroot/yufams/js | grep -i -E 'InventoryScan' | head -n 3
echo "KEEP_ID=$ID KEEP_ACCESS=$A"

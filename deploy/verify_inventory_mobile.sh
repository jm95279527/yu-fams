#!/bin/bash
API=http://127.0.0.1:89
DB="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"

TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOKEN_LEN=${#TOKEN}"

ASSET_NO=$($DB -e "select no from assets where status<>'报废' and no is not null and no<>'' limit 1" 2>/dev/null)
ASSET_NO2=$($DB -e "select no from assets where status<>'报废' and category<>(select category from assets where no='$ASSET_NO' limit 1) and no is not null and no<>'' limit 1" 2>/dev/null)
ASSET_CAT=$($DB -e "select category from assets where no='$ASSET_NO' limit 1" 2>/dev/null)
echo "ASSET_NO=$ASSET_NO  OTHER=$ASSET_NO2  CAT=$ASSET_CAT"

echo "--- 1. 创建盘点单（无 token 应 401） ---"
curl -s -X POST $API/assetsInventory/add -H 'Content-Type: application/json' -d '{"name":"x","scopeType":"ALL"}' | head -c 200; echo

echo "--- 2. 创建盘点单（带 token） ---"
CREATE=$(curl -s -X POST $API/assetsInventory/add -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"name\":\"手机盘点验证-临时\",\"scopeType\":\"CATEGORY\",\"scopeId\":$($DB -e "select id from category where name='$ASSET_CAT' limit 1" 2>/dev/null)}")
echo "$CREATE" | head -c 400; echo
TASK_ID=$(echo "$CREATE" | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["id"])')
ACCESS=$(echo "$CREATE" | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["accessCode"])')
echo "TASK_ID=$TASK_ID ACCESS=$ACCESS"

echo "--- 3. 公开任务概览（无 token） ---"
curl -s $API/inventoryPublic/task/$ACCESS; echo

echo "--- 4. 公开未盘列表 ---"
curl -s "$API/inventoryPublic/items/$ACCESS?tab=未盘" | head -c 300; echo

echo "--- 5. 扫码查询资产 ---"
curl -s -X POST $API/inventoryPublic/lookup/$ACCESS -H 'Content-Type: application/json' \
  -d "{\"code\":\"http://your-domain.com:88/scan/$ASSET_NO\"}"; echo

echo "--- 6. 确认盘点（带备注） ---"
curl -s -X POST $API/inventoryPublic/scan/$ACCESS -H 'Content-Type: application/json' \
  -d "{\"code\":\"http://your-domain.com:88/scan/$ASSET_NO\",\"comment\":\"手机端验证备注\"}"; echo

echo "--- 7. 再次查询（应已盘） ---"
curl -s -X POST $API/inventoryPublic/lookup/$ACCESS -H 'Content-Type: application/json' \
  -d "{\"code\":\"$ASSET_NO\"}"; echo

echo "--- 8. 重复扫码（应提示已盘点） ---"
curl -s -X POST $API/inventoryPublic/scan/$ACCESS -H 'Content-Type: application/json' \
  -d "{\"code\":\"$ASSET_NO\"}"; echo

echo "--- 9. 范围外资产（应盘盈） ---"
if [ -n "$ASSET_NO2" ]; then
  curl -s -X POST $API/inventoryPublic/lookup/$ACCESS -H 'Content-Type: application/json' -d "{\"code\":\"$ASSET_NO2\"}"; echo
  curl -s -X POST $API/inventoryPublic/scan/$ACCESS -H 'Content-Type: application/json' -d "{\"code\":\"$ASSET_NO2\",\"comment\":\"范围外验证\"}"; echo
fi

echo "--- 10. 任务概览统计 ---"
curl -s $API/inventoryPublic/task/$ACCESS; echo

echo "--- 11. 前台不能完结/删除 ---"
curl -s -X POST $API/assetsInventory/finish/$TASK_ID | head -c 200; echo
curl -s -X DELETE $API/assetsInventory/delete/$TASK_ID | head -c 200; echo

echo "--- 12. 无效盘点码 ---"
curl -s $API/inventoryPublic/task/not-exists-code; echo

echo "--- 13. 清理临时任务 ---"
curl -s -X DELETE $API/assetsInventory/delete/$TASK_ID -H "token: $TOKEN"; echo
echo VERIFY_DONE

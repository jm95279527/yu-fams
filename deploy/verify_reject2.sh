#!/bin/bash
BASE=http://YOUR_SERVER_IP:89
LOGIN=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}')
TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
echo "TOKEN OK"

echo "===== 1. 新建一条报废申请（资产104）====="
curl -s -X POST "$BASE/assetsScrap/add" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"assetsId":104,"scrapType":"丢失","reason":"资产遗失测试驳回","residualValue":0}'
echo ""

echo "===== 2. 取待审批单ID ====="
LIST=$(curl -s "$BASE/assetsScrap/selectPage?pageNum=1&pageSize=10&status=待审批" -H "token: $TOKEN")
# 从 list 数组取第一个对象的 id（紧跟 assetsId）
SID=$(echo "$LIST" | grep -o '"id":[0-9]*,"assetsId"' | head -1 | grep -o '[0-9]*')
echo "待审批报废单ID=$SID"

if [ -z "$SID" ]; then echo "未取到ID，退出"; exit 1; fi

echo ""
echo "===== 3. 带原因驳回 ====="
curl -s -X POST "$BASE/assetsScrap/audit/$SID" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"pass":false,"rejectReason":"残值评估过高，请重新评估"}'
echo ""

echo ""
echo "===== 4. 确认状态=已拒绝 + 审批意见已写入 ====="
curl -s "$BASE/assetsScrap/selectById/$SID" -H "token: $TOKEN" | grep -oE '"status":"[^"]*"|"approveComment":"[^"]*"|"approverName":"[^"]*"'

echo ""
echo "===== 5. 驳回后编辑重新提交，应回到待审批 ====="
curl -s -X PUT "$BASE/assetsScrap/update" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"id\":$SID,\"assetsId\":104,\"scrapType\":\"丢失\",\"reason\":\"资产遗失（已修正残值）\",\"residualValue\":10}"
echo ""
curl -s "$BASE/assetsScrap/selectById/$SID" -H "token: $TOKEN" | grep -oE '"status":"[^"]*"|"approveComment":[^,]*|"approverName":[^,]*'

echo ""
echo "===== 清理 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "DELETE FROM assets_scrap;" 2>&1 | grep -v "Warning"
echo "完成"

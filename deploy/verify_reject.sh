#!/bin/bash
BASE=http://YOUR_SERVER_IP:89
LOGIN=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}')
TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')

echo "===== 查看待审批报废单 ====="
LIST=$(curl -s "$BASE/assetsScrap/selectPage?pageNum=1&pageSize=10&status=待审批" -H "token: $TOKEN")
echo "$LIST" | grep -o '"id":[0-9]*,"assetsId":[0-9]*' | head

# 取第一条待审批的纯 id（id 字段，紧跟 assetsId）
SID=$(echo "$LIST" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data']['list'][0]['id'] if d['data']['list'] else '')" 2>/dev/null)
echo "待审批报废单ID=$SID"

if [ -z "$SID" ]; then
  echo "无待审批单，新建一条用于驳回"
  curl -s -X POST "$BASE/assetsScrap/add" -H "token: $TOKEN" -H 'Content-Type: application/json' \
    -d '{"assetsId":104,"scrapType":"丢失","reason":"资产遗失","residualValue":0}'
  LIST=$(curl -s "$BASE/assetsScrap/selectPage?pageNum=1&pageSize=10&status=待审批" -H "token: $TOKEN")
  SID=$(echo "$LIST" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data']['list'][0]['id'])")
  echo "新建待审批单ID=$SID"
fi

echo ""
echo "===== 带原因驳回单 $SID ====="
curl -s -X POST "$BASE/assetsScrap/audit/$SID" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"pass":false,"rejectReason":"残值评估过高，请重新评估"}'
echo ""

echo ""
echo "===== 确认状态变为已拒绝 ====="
curl -s "$BASE/assetsScrap/selectById/$SID" -H "token: $TOKEN" | grep -o '"status":"[^"]*"'
curl -s "$BASE/assetsScrap/selectById/$SID" -H "token: $TOKEN" | grep -o '"approveComment":"[^"]*"'

echo ""
echo "===== 驳回后编辑重新提交，应回到待审批 ====="
curl -s -X PUT "$BASE/assetsScrap/update" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"id\":$SID,\"assetsId\":104,\"scrapType\":\"丢失\",\"reason\":\"资产遗失（已修正）\",\"residualValue\":10}"
echo ""
curl -s "$BASE/assetsScrap/selectById/$SID" -H "token: $TOKEN" | grep -o '"status":"[^"]*"'

echo ""
echo "===== 清理测试数据 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "DELETE FROM assets_scrap;" 2>&1 | grep -v "Warning"
echo "完成"

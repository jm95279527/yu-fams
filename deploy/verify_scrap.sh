#!/bin/bash
# 资产报废模块全流程验证
set -e
BASE=http://YOUR_SERVER_IP:89

echo "===== 1. 登录 admin ====="
LOGIN=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}')
echo "$LOGIN"
TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
if [ -z "$TOKEN" ]; then echo "登录失败，退出"; exit 1; fi
echo "TOKEN=$TOKEN"

echo ""
echo "===== 2. 查询报废列表（应为空）====="
curl -s "$BASE/assetsScrap/selectPage?pageNum=1&pageSize=10" -H "token: $TOKEN"
echo ""

echo ""
echo "===== 3. 查询资产列表，找一个非已报废的资产 ====="
ASSETS=$(curl -s "$BASE/assets/selectAll" -H "token: $TOKEN")
echo "$ASSETS" | head -c 600
echo ""
# 取第一个非已报废资产 id
ASSET_ID=$(echo "$ASSETS" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
echo "选用资产ID=$ASSET_ID"

echo ""
echo "===== 4. 提交报废申请 ====="
curl -s -X POST "$BASE/assetsScrap/add" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"assetsId\":$ASSET_ID,\"scrapType\":\"正常报废\",\"reason\":\"达到使用年限，无法继续使用\",\"residualValue\":200,\"comment\":\"测试报废\"}"
echo ""

echo ""
echo "===== 5. 查询报废列表（应有一条待审批）====="
LIST=$(curl -s "$BASE/assetsScrap/selectPage?pageNum=1&pageSize=10" -H "token: $TOKEN")
echo "$LIST" | head -c 800
echo ""
SCRAP_ID=$(echo "$LIST" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
echo "报废单ID=$SCRAP_ID"

echo ""
echo "===== 6. 审核通过 ====="
curl -s -X POST "$BASE/assetsScrap/audit/$SCRAP_ID" -H "token: $TOKEN" -H 'Content-Type: application/json' -d '{"pass":true}'
echo ""

echo ""
echo "===== 7. 确认资产状态变为已报废 ====="
curl -s "$BASE/assets/selectById/$ASSET_ID" -H "token: $TOKEN" | grep -o '"status":"[^"]*"'
echo ""

echo ""
echo "===== 8. 查询该资产报废记录（历史）====="
curl -s "$BASE/assetsScrap/selectByAssetsId/$ASSET_ID" -H "token: $TOKEN" | head -c 400
echo ""

echo ""
echo "===== 9. 重复审核应拦截 ====="
curl -s -X POST "$BASE/assetsScrap/audit/$SCRAP_ID" -H "token: $TOKEN" -H 'Content-Type: application/json' -d '{"pass":true}'
echo ""

echo ""
echo "===== 10. 再次报废同资产应拦截（已报废）====="
curl -s -X POST "$BASE/assetsScrap/add" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"assetsId\":$ASSET_ID,\"scrapType\":\"毁损\",\"reason\":\"重复报废测试\"}"
echo ""

echo ""
echo "===== 验证完成 ====="

#!/bin/bash
# 资产报废-驳回流程 + 导出验证
BASE=http://YOUR_SERVER_IP:89

echo "===== 1. 登录 ====="
LOGIN=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}')
TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
echo "TOKEN acquired"

echo ""
echo "===== 2. 提交资产105报废申请 ====="
curl -s -X POST "$BASE/assetsScrap/add" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"assetsId":105,"scrapType":"毁损","reason":"设备严重损坏无法维修","residualValue":50}'
echo ""

echo ""
echo "===== 3. 查询报废列表 ====="
LIST=$(curl -s "$BASE/assetsScrap/selectPage?pageNum=1&pageSize=10" -H "token: $TOKEN")
echo "$LIST" | grep -o '"id":[0-9]*,"assetsId":[0-9]*[^}]*status":"[^"]*"'
# 找待审批的报废单ID（第二条）
SCRAP_ID=$(echo "$LIST" | grep -o '"id":[0-9]*' | sed -n 2p | grep -o '[0-9]*')
echo "待驳回报废单ID=$SCRAP_ID"

echo ""
echo "===== 4. 驳回（应成功）====="
curl -s -X POST "$BASE/assetsScrap/audit/$SCRAP_ID" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"pass":false,"rejectReason":"残值评估过高，请重新评估后提交"}'
echo ""

echo ""
echo "===== 5. 驳回时不填原因应拦截 ====="
# 先再提交一条用于测试空原因驳回
curl -s -X POST "$BASE/assetsScrap/add" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"assetsId":104,"scrapType":"丢失","reason":"资产遗失","residualValue":0}' > /dev/null
LIST2=$(curl -s "$BASE/assetsScrap/selectPage?pageNum=1&pageSize=10" -H "token: $TOKEN")
SCRAP_ID2=$(echo "$LIST2" | grep -o '"id":[0-9]*' | sed -n 1p | grep -o '[0-9]*')
echo "测试空原因驳回的单ID=$SCRAP_ID2"
curl -s -X POST "$BASE/assetsScrap/audit/$SCRAP_ID2" -H "token: $TOKEN" -H 'Content-Type: application/json' -d '{"pass":false}'
echo ""

echo ""
echo "===== 6. 导出报废表（HTTP状态码）====="
CODE=$(curl -s -o /tmp/scrap_export.xlsx -w "%{http_code}" "$BASE/assetsScrap/export" -H "token: $TOKEN")
echo "导出HTTP状态=$CODE"
ls -l /tmp/scrap_export.xlsx | awk '{print "文件大小:", $5, "字节"}'

echo ""
echo "===== 7. 查看资产105状态（驳回不应改变资产状态）====="
curl -s "$BASE/assets/selectById/105" -H "token: $TOKEN" | grep -o '"status":"[^"]*"'

echo ""
echo "===== 清理测试数据 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "DELETE FROM assets_scrap; DELETE FROM assets_detail WHERE operation_type='报废';" 2>&1 | grep -v "Warning"
# 把资产106状态恢复为正常
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "UPDATE assets SET status='正常' WHERE id=106;" 2>&1 | grep -v "Warning"
echo "已清理报废单和报废明细，资产106恢复正常"
echo "===== 完成 ====="

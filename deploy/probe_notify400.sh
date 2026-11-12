#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"

echo "=== assets_receive 残留 ==="
$M -e "SELECT CONCAT('id=',id,' assets_id=',assets_id,' staff_id=',IFNULL(staff_id,'NULL'),' status=',IFNULL(status,''),' cmt=',IFNULL(comment,'')) FROM assets_receive;" 2>/dev/null
echo "=== 清理残留 ==="
$M -e "DELETE FROM assets_receive WHERE comment='E2E通知验证';" 2>/dev/null
$M -e "SELECT CONCAT('assets_receive=',COUNT(*)) FROM assets_receive;" 2>/dev/null

echo "=== 测试发送：URL 编码后（模拟前端 axios params）==="
RID=$($M -e "SELECT id FROM robot_config ORDER BY id DESC LIMIT 1;" 2>/dev/null)
curl -s -X POST "$B/robotConfig/add" -H "$H" -H 'Content-Type: application/json' \
  -d '{"name":"E2E测试机器人","type":"wechat","webhookUrl":"https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=e2e-test-key","enabled":true}' > /dev/null
RID=$($M -e "SELECT id FROM robot_config ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "  robot_id=$RID"
echo -n "  未编码: "; curl -s -o /dev/null -w "HTTP=%{http_code}\n" -X POST "$B/robotConfig/test/$RID?message=**测试**" -H "$H"
echo -n "  已编码: "; curl -s -w " HTTP=%{http_code}\n" -X POST "$B/robotConfig/test/$RID" -H "$H" --get --data-urlencode "message=**E2E 连通性测试**"
echo -n "  不带参数: "; curl -s -w " HTTP=%{http_code}\n" -X POST "$B/robotConfig/test/$RID" -H "$H"
echo "=== 清理测试机器人与记录 ==="
$M -e "DELETE FROM robot_config; DELETE FROM notify_log;" 2>/dev/null
$M -e "SELECT CONCAT('robot_config=',COUNT(*)) FROM robot_config; SELECT CONCAT('notify_log=',COUNT(*)) FROM notify_log;" 2>/dev/null
echo DONE

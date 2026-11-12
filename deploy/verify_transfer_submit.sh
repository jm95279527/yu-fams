#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
B=http://127.0.0.1:89
J='Content-Type: application/json'
TOK=$(curl -s "$B/login" -H "$J" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"
curl -s -X POST "$B/robotConfig/add" -H "$H" -H "$J" \
  -d '{"name":"E2E临时","type":"wechat","webhookUrl":"https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=e2e-tr","enabled":true}' > /dev/null

AID=$($M -e "SELECT id FROM assets ORDER BY id LIMIT 1;" 2>/dev/null)
DID=$($M -e "SELECT id FROM department ORDER BY id LIMIT 1;" 2>/dev/null)
echo "资产 id=$AID  目标部门 id=$DID"
echo -n "调拨申请: "
curl -s -X POST "$B/assetsTransfer/add" -H "$H" -H "$J" \
  -d "{\"assetsId\":$AID,\"toDepartmentId\":$DID,\"toLocation\":\"E2E新地点\",\"reason\":\"E2E调拨提交\"}" | head -c 200; echo
sleep 1
echo "--- 调拨提交通知 ---"
$M -e "SELECT CONCAT('  ',event_key,' | ',biz_type,' | ',REPLACE(LEFT(content,150),CHAR(10),' / ')) FROM notify_log WHERE event_key='TRANSFER_SUBMIT';" 2>/dev/null

echo "=== 清理 ==="
$M -e "DELETE FROM notify_log;" 2>/dev/null
$M -e "DELETE FROM robot_config;" 2>/dev/null
$M -e "DELETE FROM assets_transfer WHERE reason='E2E调拨提交';" 2>/dev/null
$M -e "SELECT CONCAT('transfer残留=',COUNT(*),' log=',(SELECT COUNT(*) FROM notify_log),' robot=',(SELECT COUNT(*) FROM robot_config)) FROM assets_transfer WHERE reason='E2E调拨提交';" 2>/dev/null
echo DONE

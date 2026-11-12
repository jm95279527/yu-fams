#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
B=http://127.0.0.1:89

echo "=== 清理上次残留 ==="
$M -e "DELETE FROM notify_log; DELETE FROM robot_config; DELETE FROM assets_receive WHERE id=31; UPDATE assets SET num=1 WHERE id=26;" 2>/dev/null
$M -e "SELECT CONCAT('robot_config=',COUNT(*)) FROM robot_config; SELECT CONCAT('notify_log=',COUNT(*)) FROM notify_log; SELECT CONCAT('receive=',COUNT(*)) FROM assets_receive; SELECT CONCAT('asset26_num=',num) FROM assets WHERE id=26;" 2>/dev/null

TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"; J='Content-Type: application/json'

# 选一个库存>=2的资产，避免审核扣减后无法再次申请
AID=$($M -e "SELECT id FROM assets WHERE num >= 2 ORDER BY id LIMIT 1;" 2>/dev/null)
if [ -z "$AID" ]; then AID=26; $M -e "UPDATE assets SET num=2 WHERE id=26;" 2>/dev/null; fi
NUM0=$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)
echo "=== 测试资产 id=$AID 库存=$NUM0 ==="

curl -s -X POST "$B/robotConfig/add" -H "$H" -H "$J" \
  -d '{"name":"E2E临时","type":"wechat","webhookUrl":"https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=e2e-temp","enabled":true}' > /dev/null

echo "=== A) 模板启用 -> 应产生通知 ==="
$M -e "UPDATE notify_template SET enabled=1 WHERE event_key='RECEIVE_PASS';" 2>/dev/null
curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"returnDate\":\"2026-12-31\",\"comment\":\"A启用模板\"}" > /dev/null
RA=$($M -e "SELECT id FROM assets_receive WHERE comment='A启用模板' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" -d "{\"id\":$RA,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"未归还\",\"returnDate\":\"2026-12-31\"}" > /dev/null
sleep 1
N1=$($M -e "SELECT COUNT(*) FROM notify_log;" 2>/dev/null)
echo "  receive=$RA 通知条数=$N1 （应>=1）"
$M -e "SELECT CONCAT('  content=',REPLACE(content,CHAR(10),' | ')) FROM notify_log ORDER BY id DESC LIMIT 1;" 2>/dev/null

echo "=== B) 模板停用 -> 不应新增通知 ==="
$M -e "UPDATE notify_template SET enabled=0 WHERE event_key='RECEIVE_PASS';" 2>/dev/null
curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"returnDate\":\"2026-12-31\",\"comment\":\"B停用模板\"}" > /dev/null
RB=$($M -e "SELECT id FROM assets_receive WHERE comment='B停用模板' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" -d "{\"id\":$RB,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"未归还\",\"returnDate\":\"2026-12-31\"}" > /dev/null
sleep 1
N2=$($M -e "SELECT COUNT(*) FROM notify_log;" 2>/dev/null)
echo "  receive=$RB 通知条数=$N1 -> $N2 （应不变）"

echo "=== C) 拒绝类模板默认停用 -> 不推送 ==="
curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"returnDate\":\"2026-12-31\",\"comment\":\"C拒绝验证\"}" > /dev/null
RC=$($M -e "SELECT id FROM assets_receive WHERE comment='C拒绝验证' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" -d "{\"id\":$RC,\"assetsId\":$AID,\"status\":\"拒绝\",\"returnStatus\":\"未归还\"}" > /dev/null
sleep 1
$M -e "UPDATE notify_template SET enabled=1 WHERE event_key='RECEIVE_PASS';" 2>/dev/null
echo "  receive=$RC 通知条数=$N1 -> $($M -e "SELECT COUNT(*) FROM notify_log;" 2>/dev/null) （应不变，RECEIVE_REJECT 默认停用）"

echo "=== 清理 ==="
$M -e "DELETE FROM notify_log; DELETE FROM robot_config; DELETE FROM assets_receive WHERE id IN ($RA,$RB,$RC); UPDATE assets SET num=$NUM0 WHERE id=$AID;" 2>/dev/null
$M -e "SELECT CONCAT('robot_config=',COUNT(*)) FROM robot_config; SELECT CONCAT('notify_log=',COUNT(*)) FROM notify_log; SELECT CONCAT('receive=',COUNT(*)) FROM assets_receive; SELECT CONCAT('asset=$AID num=',num) FROM assets WHERE id=$AID; SELECT CONCAT('tpl=',event_key,' enabled=',enabled) FROM notify_template WHERE event_key LIKE 'RECEIVE%';" 2>/dev/null
echo DONE
